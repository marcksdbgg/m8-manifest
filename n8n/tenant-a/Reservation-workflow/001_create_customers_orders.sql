-- Active: 1763092255851@@127.0.0.1@5432@n8n_tenant_a
#001_crear_clientes_pedidos.sql
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY,
  telefono VARCHAR(32) UNIQUE NOT NULL,
  nombre VARCHAR(255),
  primer_mensaje TEXT,
  metadatos JSONB,
  creado_en TIMESTAMPTZ DEFAULT now(),
  actualizado_en TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pedidos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  numero_orden VARCHAR(64) UNIQUE,
  estado VARCHAR(32) DEFAULT 'pendiente',
  articulos JSONB,
  total NUMERIC(10,2),
  hora_programada TIMESTAMPTZ,
  creado_en TIMESTAMPTZ DEFAULT now(),
  actualizado_en TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION actualizar_columna_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER IF NOT EXISTS actualizar_clientes_actualizado_en
BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE PROCEDURE actualizar_columna_actualizado_en();

CREATE TRIGGER IF NOT EXISTS actualizar_pedidos_actualizado_en
BEFORE UPDATE ON pedidos FOR EACH ROW EXECUTE PROCEDURE actualizar_columna_actualizado_en();

CREATE INDEX IF NOT EXISTS idx_clientes_telefono ON clientes(telefono);
CREATE INDEX IF NOT EXISTS idx_pedidos_numero_orden ON pedidos(numero_orden);