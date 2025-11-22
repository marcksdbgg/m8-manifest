-- Crear DB y Usuario para Chatwoot Tenant A
CREATE DATABASE chatwoot_tenant_a;
CREATE USER user_chatwoot_a WITH PASSWORD 'nyro123';
GRANT ALL PRIVILEGES ON DATABASE chatwoot_tenant_a TO user_chatwoot_a;
-- Dar permisos de superusuario es necesario para Chatwoot para habilitar extensiones (pg_trgm, hstore)
ALTER USER user_chatwoot_a WITH SUPERUSER;