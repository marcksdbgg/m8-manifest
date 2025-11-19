# Receptor de webhook para tenant-a

Esta carpeta contiene un receptor de webhook simple Deployment, Service e Ingress para `tenant-a`.

Uso:
- Endpoint (externo): `https://tenant-a.n8n.atenex.pe/webhook-receiver` (POST)
- Servicio interno (desde el clúster, ej. n8n): `http://n8n-tenant-a-webhook-svc.n8n-tenants.svc.cluster.local:8080/` (POST)

Ejemplo curl para probar externamente (si DNS resuelve / TLS configurado):
```
curl -k -X POST https://tenant-a.n8n.atenex.pe/webhook-receiver -d '{"message":"hello"}' -H "Content-Type: application/json"
```

Ejemplo curl desde dentro del clúster (desde un pod, ej. contenedor `n8n`):
```
curl -X POST http://n8n-tenant-a-webhook-svc.n8n-tenants.svc.cluster.local:8080/ -d '{"message":"hello"}' -H "Content-Type: application/json"
```

Este receptor imprime las solicitudes de webhook en los logs del pod. Configura tu flujo de trabajo de n8n (HTTP Request o Polling) para conectarte al servicio interno para leer o procesar payloads.



