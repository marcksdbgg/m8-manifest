-- 002_create_conversaciones.sql
-- Adds a table to store all inbound and outbound conversations/messages per customer

CREATE TABLE IF NOT EXISTS conversaciones (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  direccion VARCHAR(16) NOT NULL, -- inbound/outbound
  contenido TEXT NOT NULL,
  metadatos JSONB,
  creado_en TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_conversaciones_cliente_id ON conversaciones(cliente_id);
