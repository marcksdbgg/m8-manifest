-- 002_pagos_reconciliacion.sql

-- Tabla intermedia para pagos recibidos por Webhook (Yape/Plin)
-- Se usa para reconciliación asíncrona con el Bot
CREATE TABLE IF NOT EXISTS pagos_recibidos (
  id BIGSERIAL PRIMARY KEY,
  
  -- Datos extraídos del SMS/Notificación
  codigo_operacion VARCHAR(64) UNIQUE NOT NULL, -- Clave única para evitar duplicados
  monto NUMERIC(10,2) NOT NULL,
  remitente VARCHAR(255), -- Nombre de la persona que pagó (Ej: Sixto M. Caceres T.)
  mensaje_original TEXT,  -- Guardamos el texto crudo por auditoría
  
  -- Estado del proceso de validación
  estado VARCHAR(32) DEFAULT 'PENDIENTE', 
  -- Valores: 'PENDIENTE', 'ASIGNADO', 'MANUAL'
  
  -- Vinculación futura (se llena cuando el usuario envía la foto)
  pedido_id BIGINT REFERENCES pedidos(id) ON DELETE SET NULL,
  
  fecha_recepcion TIMESTAMPTZ DEFAULT now(),
  actualizado_en TIMESTAMPTZ DEFAULT now()
);

-- Trigger para actualizar fecha
CREATE TRIGGER actualizar_pagos_recibidos_timestamp
BEFORE UPDATE ON pagos_recibidos
FOR EACH ROW
EXECUTE PROCEDURE actualizar_columna_actualizado_en();

-- Índices para búsqueda rápida (CRÍTICO para el tiempo de respuesta del bot)
CREATE INDEX IF NOT EXISTS idx_pagos_codigo 
  ON pagos_recibidos (codigo_operacion);
  
CREATE INDEX IF NOT EXISTS idx_pagos_estado 
  ON pagos_recibidos (estado);