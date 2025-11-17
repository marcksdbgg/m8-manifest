# m8-manifest — Infraestructura n8n multi-tenant con ArgoCD

Proyecto de manifiestos Kubernetes para desplegar una plataforma n8n multi-tenant con ArgoCD. Incluye la infraestructura de la base de datos (Postgres), Redis y plantillas de tenant (main + worker) con ensayos/ejemplos de workflows SQL.

---

## 🔎 Descripción

Este repositorio contiene manifiestos YAML y secretos base64-encoded (para demo) para desplegar una solución multi-tenant de n8n en Kubernetes bajo un enfoque GitOps con ArgoCD (app-of-apps). La topología incluye:

- ArgoCD para gestionar la sincronización de manifiestos
- Plataforma compartida: PostgreSQL y Redis (namespace `platform-dbs`)
- Un conjunto de inquilinos/tenants (`n8n/tenant-*`) con despliegues `main` y `worker` en el namespace `n8n-tenants`.

---

## 📁 Estructura del repositorio

Ficheros y carpetas principales:

- `argocd/` — root application y apps de ArgoCD (1-platform y 2-tenants)
- `platform/` — StatefulSets / Services para Postgres y Redis
- `n8n/` — Configmap compartido y definición de tenants (ingress, main, worker, service)
  - `n8n/config/n8n-common-configmap.yaml` — variables de entorno comunes
  - `n8n/tenant-a` — ejemplo de tenant A (ingress, main, worker, servicio). Contiene también `Reservation-workflow` con SQLs
  - `n8n/tenant-b` — ejemplo de tenant B
- `namespaces/` — namespaces bootstrap para argocd, platform-dbs y n8n-tenants
- `secrets/` — secretos demo (base64) para plataforma y tenants
- `argocd/apps/*` — Aplicaciones que ArgoCD desplegará (platform y tenants)

---

## 🏗️ Arquitectura y convenciones

- App-of-apps: `argocd/root-application.yaml` crea y gestiona `argocd/apps/1-platform.yaml` y `argocd/apps/2-tenants.yaml`.
- `platform` (namespace `platform-dbs`) contiene: PostgreSQL (StatefulSet + Service) y Redis (StatefulSet + Service).
- `n8n-tenants` contiene uno o más tenants; cada tenant tiene:
  - `Deployment` principal (role: main) expuesto por `Service` y `Ingress`
  - `Deployment` worker (role: worker), configurado con `initContainer` que espera al main
  - `Secret` propio con `N8N_ENCRYPTION_KEY`, DB password, Redis password, etc.
- ConfigMap `n8n-common-config` centraliza variables comunes y debe referenciarse en despliegues con `envFrom`.

---

## ⚙️ Variables y configuraciones importantes

- `n8n-common-configmap.yaml` contiene:
  - `N8N_LISTEN_ADDRESS: 0.0.0.0`
  - `TZ` — timezone
  - `DB_TYPE: postgresdb`
  - `DB_POSTGRESDB_SSL=false` (para pruebas locales dentro del mismo cluster)
  - `EXECUTIONS_MODE=queue` (modo “queue” para workers)
- Cada tenant define en `Deployment` (env vars):
  - `DB_POSTGRESDB_HOST: postgres-svc.platform-dbs.svc.cluster.local`
  - `DB_POSTGRESDB_DATABASE: n8n_tenant_<id>` (p.ej. `n8n_tenant_a`)
  - `DB_POSTGRESDB_USER` y `DB_POSTGRESDB_PASSWORD`
  - `QUEUE_BULL_REDIS_HOST: redis-svc.platform-dbs.svc.cluster.local`
  - `QUEUE_BULL_REDIS_DB` diferente por tenant para aislamiento lógico (p.ej. 1, 2)
  - `WEBHOOK_URL` — **DEBE** incluir la URL del ingress del tenant y terminar con `/` (ej. `https://tenant-a.n8n.atenex.pe/`)

---

## 🔐 Manejo de secretos y buenas prácticas

- Los secretos de ejemplo en `secrets/` están **codificados en base64** solo para demostración; **no** lo use así en producción. En entorno real, use `sealed-secrets`, HashiCorp Vault, o `kubectl create secret` con valores sensibles.
- `N8N_ENCRYPTION_KEY` debe ser de 32 caracteres de longitud y única por tenant.
- Nunca comite claves de producción en texto plano en un repositorio público.
- Para regenerar valores a partir de texto en base64:

```bash
# Generar base64 de una contraseña (ejemplo):
printf "my-password" | base64 -w0

# Convertir base64 a texto (verificar):
printf "bnlybzEyMw==" | base64 -d
```

---

## 🧭 Despliegue (bootstrap) rápido

1. Aplica los namespaces:

```bash
kubectl apply -f namespaces/
```

2. Aplica la app root de ArgoCD (o usar ArgoCD UI):

```bash
kubectl apply -f argocd/root-application.yaml -n argocd
```

ArgoCD creará automáticamente `platform-dbs` y `n8n-tenants` apps.

3. Verifica el estado:

```bash
kubectl get applications.argoproj.io -n argocd
kubectl get pods -n platform-dbs
kubectl get pods -n n8n-tenants
```

> Nota: `argocd/argocd-ingress.yaml` usa `ingressClassName: traefik`. Las entradas `Ingress` de tenants también usan `traefik` (ver `n8n/tenant-a/n8n-tenant-a-ingress.yaml`).

---

## ✅ Verificación y comandos útiles

- Inspeccionar logs del main y worker:

```bash
kubectl logs deployment/n8n-tenant-a-main -n n8n-tenants -c n8n-main
kubectl logs deployment/n8n-tenant-a-worker -n n8n-tenants -c n8n-worker
```

- Portforward a Postgres para tareas locales:

```bash
kubectl port-forward service/postgres-svc 5432:5432 -n platform-dbs
```

- Comandos de ArgoCD (si ArgoCD CLI está instalado):

```bash
argocd app get n8n-saas-root
argocd app sync platform-dbs
argocd app sync n8n-tenants
```

---

### 🧾 Crear base de datos/usuario (ejemplo)

El archivo `secrets/argocd/registro.txt` incluye comandos útiles para crear las DBs y usuarios por tenant en Postgres.

```sql
CREATE DATABASE n8n_tenant_a;
CREATE USER user_tenant_a WITH PASSWORD 'nyro123';
GRANT ALL PRIVILEGES ON DATABASE n8n_tenant_a TO user_tenant_a;

CREATE DATABASE n8n_tenant_b;
CREATE USER user_tenant_b WITH PASSWORD 'nyro123';
GRANT ALL PRIVILEGES ON DATABASE n8n_tenant_b TO user_tenant_b;
```

> Recomiendo ejecutar estos comandos con `psql` conectado al servicio Postgres desde un bastion o vía `kubectl port-forward`.

---

## 🧩 Añadir un Tenant (pasos)

1. Copie una carpeta `n8n/tenant-a` y renombre (ej. `tenant-c`).
2. Actualice nombres y labels (`tenant: tenant-c`, DB name `n8n_tenant_c`, `QUEUE_BULL_REDIS_DB` en ambos deployments).
3. Cree secretos en `secrets/tenants/tenant-c` con `N8N_ENCRYPTION_KEY`, `DB_POSTGRESDB_PASSWORD` y `QUEUE_BULL_REDIS_PASSWORD`.
4. Añada `n8n-tenant-c-main-deployment.yaml`, `n8n-tenant-c-worker-deployment.yaml`, `n8n-tenant-c-service.yaml` y `n8n-tenant-c-ingress.yaml`.
5. Actualice el `WEBHOOK_URL` para el tenant en `main`.
6. Si usa ArgoCD, commit y push al repo para que ArgoCD realice el apply automáticamente.

---

## 🩺 Salud del cluster y troubleshooting

- `main` y `worker` usan probes:
  - Liveness & Readiness: `/healthz` en puerto `5678`.
- El worker usa un `initContainer` que espera al service del main (usando `nc`); si no arranca, revise logs y servicio `n8n-tenant-*-svc`.
- Comprobar que `WEBHOOK_URL` coincide con el `Ingress` y que termina en `/`.
- Si hay errores de base de datos, verifique que la base y el usuario existen (ver `secrets/argocd/registro.txt` con comandos SQL de ejemplo).

---

## 📂 Workflows y scripts de ejemplo

- `n8n/tenant-a/Reservation-workflow` contiene scripts SQL de ejemplo para crear tablas `clientes`, `pedidos` y `conversaciones`.
- Estos ficheros son útiles como punto de partida para crear triggers o extraer lógica basada en datos para su tenant.

---

## ⚠️ Avisos & Buenas prácticas

- No uses secretos hard-coded en repositorios de producción.
- Habilitar SSL en PostgreSQL para entornos que salgan del cluster o para mayor seguridad.
- Mantén la paridad de versiones entre `main` y `worker` para evitar incompatibilidades.
- Uso de ArgoCD `prune: true` y `selfHeal: true` hará que eliminar archivos del repo borre recursos del cluster — tenga cuidado.

- Asegúrese de que `WEBHOOK_URL` coincide con el `Ingress` y tenga la barra final (`/`), ya que n8n usa esto para las URL de webhook y OAuth.

---

## 💡 Tips

- Reutiliza `n8n-common-config` para evitar duplicar variables globales por tenant.
- Siempre comprueba `kubectl describe` y `kubectl logs` para encontrar errores de despliegue.

---

## 📣 Cómo contribuir

1. Haz fork del repo.
2. Crea una rama con tu cambio: `git checkout -b feat/my-change`.
3. Haz commit y push.
4. Crea un PR y revisa.

---

## ⚖️ Licencia

Este repositorio no define explícitamente una licencia; por favor añade un `LICENSE` si quieres usarlo públicamente.

---

## Contacto

Para preguntas, crea un issue o contacta al mantenedor del repositorio.

---

© 2025 — m8-manifest
