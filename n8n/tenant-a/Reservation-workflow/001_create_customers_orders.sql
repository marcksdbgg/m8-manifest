-- 001_set_db.sql

-- Tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
  id BIGSERIAL PRIMARY KEY,
  telefono VARCHAR(32) UNIQUE NOT NULL,
  nombre VARCHAR(255),
  primer_mensaje TEXT,
  metadatos JSONB,
  creado_en TIMESTAMPTZ DEFAULT now(),
  actualizado_en TIMESTAMPTZ DEFAULT now()
);

-- Tabla de pedidos (cabecera)
CREATE TABLE IF NOT EXISTS pedidos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT REFERENCES clientes(id) ON DELETE SET NULL,
  numero_orden VARCHAR(64) UNIQUE,
  estado VARCHAR(32) DEFAULT 'pendiente',
  tipo_pedido VARCHAR(16) NOT NULL,
  CONSTRAINT chk_tipo_pedido
    CHECK (tipo_pedido IN ('recojo', 'delivery')),

  -- Campos reflejo del JSON del LLM
  accion VARCHAR(32),         -- JSON.accion
  respuesta TEXT,             -- JSON.respuesta
  resumen_pedido TEXT,        -- JSON.resumen_pedido
  errores JSONB DEFAULT '[]'::jsonb, -- JSON.errores (array de strings)

  -- Datos monetarios / logísticos
  total NUMERIC(10,2),        -- JSON.total
  hora_programada TIMESTAMPTZ,

  -- Ubicación enviada por WhatsApp (solo latitud/longitud)
  ubicacion JSONB,
  CONSTRAINT chk_pedidos_ubicacion_lat_lon
    CHECK (
      ubicacion IS NULL OR (
        ubicacion ? 'latitud' AND
        ubicacion ? 'longitud' AND
        jsonb_typeof(ubicacion->'latitud') = 'number' AND
        jsonb_typeof(ubicacion->'longitud') = 'number'
      )
    ),

  -- Campo libre para cualquier extra (ej: JSON original)
  metadatos JSONB,

  creado_en TIMESTAMPTZ DEFAULT now(),
  actualizado_en TIMESTAMPTZ DEFAULT now()
);

-- Tabla de líneas de pedido (detalle de pedido_parseado)
CREATE TABLE IF NOT EXISTS pedido_items (
  id BIGSERIAL PRIMARY KEY,
  pedido_id BIGINT NOT NULL
    REFERENCES pedidos(id) ON DELETE CASCADE,

  producto_id VARCHAR(64) NOT NULL,
  producto_nombre VARCHAR(255),
  categoria_id VARCHAR(64),

  cantidad INTEGER NOT NULL CHECK (cantidad >= 1),

  variant_id VARCHAR(128) NOT NULL,
  variant_label VARCHAR(64),
  size_code VARCHAR(64) NOT NULL,

  precio_unitario NUMERIC(10,2) NOT NULL,
  subtotal NUMERIC(10,2) NOT NULL,

  metadatos JSONB
);

-- Función para actualizar actualizado_en
CREATE OR REPLACE FUNCTION actualizar_columna_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en = now();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Triggers de actualización
CREATE TRIGGER actualizar_clientes_actualizado_en
BEFORE UPDATE ON clientes
FOR EACH ROW
EXECUTE PROCEDURE actualizar_columna_actualizado_en();

CREATE TRIGGER actualizar_pedidos_actualizado_en
BEFORE UPDATE ON pedidos
FOR EACH ROW
EXECUTE PROCEDURE actualizar_columna_actualizado_en();

-- Índices útiles
CREATE INDEX IF NOT EXISTS idx_clientes_telefono
  ON clientes (telefono);

CREATE INDEX IF NOT EXISTS idx_pedidos_numero_orden
  ON pedidos (numero_orden);

CREATE INDEX IF NOT EXISTS idx_pedidos_ubicacion_gin
  ON pedidos
  USING GIN (ubicacion);

CREATE INDEX IF NOT EXISTS idx_pedido_items_pedido_id
  ON pedido_items (pedido_id);

CREATE INDEX IF NOT EXISTS idx_pedido_items_producto_id
  ON pedido_items (producto_id);
