# Esquema de Base de Datos PostgreSQL

## Sistema ERP/MRP para Fabricación de Polietileno

Este documento contiene el esquema completo de la base de datos PostgreSQL para el sistema ERP/MRP.

---

## 📊 Resumen del Modelo de Datos

### Tablas Principales (27 tablas)

1. **Gestión de Usuarios y Seguridad**
   - [`users`](#tabla-users) - Usuarios del sistema
   - [`roles`](#tabla-roles) - Roles y permisos
   - [`audit_logs`](#tabla-audit_logs) - Auditoría de acciones

2. **Gestión Comercial**
   - [`customers`](#tabla-customers) - Clientes
   - [`orders`](#tabla-orders) - Pedidos
   - [`order_items`](#tabla-order_items) - Ítems de pedidos

3. **Catálogos**
   - [`products`](#tabla-products) - Productos (bolsas y bobinas)
   - [`machines`](#tabla-machines) - Máquinas de producción
   - [`raw_materials`](#tabla-raw_materials) - Materias primas

4. **Producción**
   - [`production_orders`](#tabla-production_orders) - Órdenes de producción
   - [`production_records`](#tabla-production_records) - Registros de producción
   - [`product_machine_params`](#tabla-product_machine_params) - Parámetros por producto/máquina
   - [`machine_stops`](#tabla-machine_stops) - Paradas de máquina
   - [`pelletizing_records`](#tabla-pelletizing_records) - Peletizado

5. **Inventarios**
   - [`raw_material_inventory`](#tabla-raw_material_inventory) - Inventario MP
   - [`material_consumption`](#tabla-material_consumption) - Consumo de MP
   - [`finished_goods_inventory`](#tabla-finished_goods_inventory) - Inventario PT

6. **Calidad**
   - [`quality_controls`](#tabla-quality_controls) - Control de calidad

7. **Despachos**
   - [`dispatches`](#tabla-dispatches) - Despachos
   - [`dispatch_items`](#tabla-dispatch_items) - Ítems de despacho

8. **Operaciones**
   - [`tasks`](#tabla-tasks) - Tareas y planificación
   - [`plant_map_positions`](#tabla-plant_map_positions) - Mapa de planta

9. **Capacitación**
   - [`training_modules`](#tabla-training_modules) - Módulos de entrenamiento

10. **Configuración**
    - [`system_settings`](#tabla-system_settings) - Configuración del sistema

---

## 🔧 Tipos Enumerados (ENUMs)

```sql
-- Roles de usuario
CREATE TYPE user_role AS ENUM (
    'super_admin',
    'gerente_produccion',
    'supervisor_area',
    'operador_maquina',
    'almacenista',
    'vendedor',
    'control_calidad'
);

-- Tipos de máquina
CREATE TYPE machine_type AS ENUM (
    'extrusora',
    'selladora',
    'impresora',
    'refiladora',
    'molino'
);

-- Áreas de producción
CREATE TYPE production_area AS ENUM (
    'extrusion',
    'sellado',
    'impresion',
    'refilado',
    'peletizado'
);

-- Estados de pedido/orden
CREATE TYPE order_status AS ENUM (
    'pendiente',
    'aprobado',
    'en_produccion',
    'completado',
    'cancelado'
);

CREATE TYPE production_order_status AS ENUM (
    'planificada',
    'en_proceso',
    'pausada',
    'completada',
    'cancelada'
);

-- Prioridades
CREATE TYPE priority_level AS ENUM (
    'baja',
    'media',
    'alta',
    'urgente'
);

-- Tipos de material
CREATE TYPE material_type AS ENUM (
    'pebd',
    'pead',
    'pelbd',
    'pigmento',
    'aditivo',
    'reciclado'
);

-- Estados de inventario
CREATE TYPE inventory_status AS ENUM (
    'disponible',
    'reservado',
    'en_transito',
    'despachado',
    'rechazado'
);

-- Resultados de calidad
CREATE TYPE quality_result AS ENUM (
    'aprobado',
    'rechazado',
    'condicional'
);

CREATE TYPE inspection_type AS ENUM (
    'recepcion_mp',
    'proceso',
    'producto_terminado',
    'pre_despacho'
);

-- Paradas de máquina
CREATE TYPE stop_type AS ENUM (
    'programada',
    'no_programada'
);

CREATE TYPE stop_reason AS ENUM (
    'mantenimiento',
    'cambio_producto',
    'falta_material',
    'falla_mecanica',
    'falla_electrica',
    'falta_personal',
    'almuerzo',
    'otros'
);

-- Estados de tarea
CREATE TYPE task_status AS ENUM (
    'pendiente',
    'en_progreso',
    'completada',
    'cancelada'
);

-- Ubicaciones
CREATE TYPE warehouse_location AS ENUM (
    'galpon_1',
    'galpon_2'
);

-- Tipos de módulo de entrenamiento
CREATE TYPE training_module_type AS ENUM (
    'manual',
    'procedimiento',
    'video',
    'diagrama',
    'buenas_practicas'
);
```

---

## 📋 Definición de Tablas

### Tabla: users

Almacena los usuarios del sistema con sus credenciales y roles.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| username | VARCHAR(50) | UNIQUE, NOT NULL | Nombre de usuario |
| email | VARCHAR(100) | UNIQUE, NOT NULL | Correo electrónico |
| password_hash | VARCHAR(255) | NOT NULL | Hash de contraseña (bcrypt) |
| full_name | VARCHAR(100) | NOT NULL | Nombre completo |
| role | user_role | NOT NULL | Rol del usuario |
| role_id | INTEGER | FK → roles(id) | Referencia a rol personalizado |
| is_active | BOOLEAN | DEFAULT true | Usuario activo |
| last_login | TIMESTAMP | | Último inicio de sesión |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_users_role` en `role`
- `idx_users_active` en `is_active`

---

### Tabla: roles

Define roles personalizados con permisos específicos.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| name | VARCHAR(50) | UNIQUE, NOT NULL | Nombre del rol |
| permissions | JSONB | NOT NULL | Permisos en formato JSON |
| description | TEXT | | Descripción del rol |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

---

### Tabla: customers

Gestión de clientes de la empresa.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| code | VARCHAR(20) | UNIQUE, NOT NULL | Código de cliente |
| business_name | VARCHAR(200) | NOT NULL | Razón social |
| tax_id | VARCHAR(50) | UNIQUE | RIF/NIT |
| contact_name | VARCHAR(100) | | Nombre de contacto |
| phone | VARCHAR(20) | | Teléfono |
| email | VARCHAR(100) | | Correo electrónico |
| address | TEXT | | Dirección |
| city | VARCHAR(100) | | Ciudad |
| state | VARCHAR(100) | | Estado |
| country | VARCHAR(100) | DEFAULT 'Venezuela' | País |
| credit_limit | DECIMAL(12,2) | | Límite de crédito |
| payment_terms | INTEGER | DEFAULT 30 | Días de crédito |
| is_active | BOOLEAN | DEFAULT true | Cliente activo |
| notes | TEXT | | Notas adicionales |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_customers_code` en `code`
- `idx_customers_active` en `is_active`

---

### Tabla: products

Catálogo de productos (bolsas y bobinas de polietileno).

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| code | VARCHAR(50) | UNIQUE, NOT NULL | Código de producto |
| name | VARCHAR(200) | NOT NULL | Nombre del producto |
| description | TEXT | | Descripción |
| **Especificaciones Técnicas** |
| width_cm | DECIMAL(8,2) | NOT NULL | Ancho en cm |
| length_cm | DECIMAL(8,2) | | Largo en cm |
| caliber_microns | DECIMAL(6,2) | NOT NULL | Calibre en micrones |
| **Características** |
| has_gusset | BOOLEAN | DEFAULT false | Tiene fuelle |
| gusset_width_cm | DECIMAL(8,2) | | Ancho de fuelle |
| has_perforation | BOOLEAN | DEFAULT false | Tiene perforación |
| perforation_type | VARCHAR(50) | | Tipo de perforación |
| has_valve | BOOLEAN | DEFAULT false | Tiene válvula |
| valve_width_cm | DECIMAL(8,2) | | Ancho de válvula |
| has_print | BOOLEAN | DEFAULT false | Tiene impresión |
| print_colors | INTEGER | | Número de colores |
| **Propiedades** |
| max_reel_weight_kg | DECIMAL(8,2) | | Peso máximo de bobina |
| is_heat_shrinkable | BOOLEAN | DEFAULT false | Termoencogible |
| requires_trimming | BOOLEAN | DEFAULT false | Requiere refilado |
| requires_corona_treatment | BOOLEAN | DEFAULT false | Requiere tratamiento corona |
| **Peso y Empaque** |
| bag_weight_grams | DECIMAL(8,3) | | Peso de bolsa en gramos |
| bags_per_reel | INTEGER | | Bolsas por rollo |
| reels_per_bundle | INTEGER | | Rollos por bulto |
| **Material** |
| material_type | material_type | NOT NULL | Tipo de material |
| color | VARCHAR(50) | | Color |
| recycled_percentage | DECIMAL(5,2) | DEFAULT 0 | % de reciclado |
| **Comercial** |
| unit_price | DECIMAL(12,2) | | Precio unitario |
| cost_price | DECIMAL(12,2) | | Costo de producción |
| is_active | BOOLEAN | DEFAULT true | Producto activo |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_products_code` en `code`
- `idx_products_active` en `is_active`
- `idx_products_material` en `material_type`

---

### Tabla: machines

Catálogo de máquinas de producción.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| code | VARCHAR(20) | UNIQUE, NOT NULL | Código de máquina |
| name | VARCHAR(100) | NOT NULL | Nombre de la máquina |
| type | machine_type | NOT NULL | Tipo de máquina |
| area | production_area | NOT NULL | Área de producción |
| **Especificaciones** |
| brand | VARCHAR(100) | | Marca |
| model | VARCHAR(100) | | Modelo |
| serial_number | VARCHAR(100) | | Número de serie |
| year_manufactured | INTEGER | | Año de fabricación |
| **Capacidad** |
| standard_speed | DECIMAL(8,2) | NOT NULL | Velocidad estándar (kg/h) |
| max_speed | DECIMAL(8,2) | | Velocidad máxima |
| min_speed | DECIMAL(8,2) | | Velocidad mínima |
| **Ubicación** |
| warehouse_location | warehouse_location | NOT NULL | Ubicación en planta |
| technical_specs | JSONB | DEFAULT '{}' | Especificaciones técnicas |
| **Estado** |
| is_active | BOOLEAN | DEFAULT true | Máquina activa |
| last_maintenance_date | DATE | | Último mantenimiento |
| next_maintenance_date | DATE | | Próximo mantenimiento |
| notes | TEXT | | Notas adicionales |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_machines_code` en `code`
- `idx_machines_type` en `type`
- `idx_machines_area` en `area`
- `idx_machines_active` en `is_active`

---

### Tabla: product_machine_params

Parámetros de máquina específicos por producto y área.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| product_id | INTEGER | FK → products(id), NOT NULL | Producto |
| machine_id | INTEGER | FK → machines(id), NOT NULL | Máquina |
| area | production_area | NOT NULL | Área de producción |
| parameters | JSONB | NOT NULL | Parámetros en JSON |
| is_active | BOOLEAN | DEFAULT true | Parámetros activos |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Restricción UNIQUE:** `(product_id, machine_id, area)`

**Índices:**
- `idx_product_machine_params_product` en `product_id`
- `idx_product_machine_params_machine` en `machine_id`

**Ejemplo de JSON de parámetros para Extrusión:**
```json
{
  "temperaturas": {
    "zona_1": 140,
    "zona_2": 165,
    "zona_3": 165,
    "filtro": 170,
    "cabezal_1": 170,
    "cabezal_2": 170
  },
  "velocidad_extrusion": 60,
  "ancho_pelicula": 47,
  "calibre_objetivo": 0.008,
  "tratamiento_corona": true,
  "rebobinado": {
    "down": 3.96,
    "central": 17.16,
    "up": 0
  }
}
```

---

### Tabla: orders

Pedidos de clientes.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| order_number | VARCHAR(50) | UNIQUE, NOT NULL | Número de pedido |
| customer_id | INTEGER | FK → customers(id), NOT NULL | Cliente |
| order_date | DATE | NOT NULL | Fecha de pedido |
| delivery_date | DATE | NOT NULL | Fecha de entrega |
| status | order_status | NOT NULL | Estado del pedido |
| priority | priority_level | DEFAULT 'media' | Prioridad |
| subtotal | DECIMAL(12,2) | DEFAULT 0 | Subtotal |
| tax_percentage | DECIMAL(5,2) | DEFAULT 0 | % de impuesto |
| tax_amount | DECIMAL(12,2) | DEFAULT 0 | Monto de impuesto |
| total_amount | DECIMAL(12,2) | DEFAULT 0 | Total |
| notes | TEXT | | Notas para el cliente |
| internal_notes | TEXT | | Notas internas |
| created_by | INTEGER | FK → users(id) | Creado por |
| approved_by | INTEGER | FK → users(id) | Aprobado por |
| approved_at | TIMESTAMP | | Fecha de aprobación |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_orders_number` en `order_number`
- `idx_orders_customer` en `customer_id`
- `idx_orders_status` en `status`
- `idx_orders_date` en `order_date`

---

### Tabla: order_items

Ítems de pedidos.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| order_id | INTEGER | FK → orders(id), NOT NULL | Pedido |
| product_id | INTEGER | FK → products(id), NOT NULL | Producto |
| quantity_units | INTEGER | | Cantidad en unidades |
| quantity_kg | DECIMAL(10,2) | | Cantidad en kg |
| unit_price | DECIMAL(12,2) | NOT NULL | Precio unitario |
| subtotal | DECIMAL(12,2) | NOT NULL | Subtotal |
| specifications | TEXT | | Especificaciones adicionales |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |

**Índices:**
- `idx_order_items_order` en `order_id`
- `idx_order_items_product` en `product_id`

---

### Tabla: production_orders

Órdenes de producción.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| po_number | VARCHAR(50) | UNIQUE, NOT NULL | Número de OP |
| order_id | INTEGER | FK → orders(id) | Pedido relacionado |
| product_id | INTEGER | FK → products(id), NOT NULL | Producto |
| planned_quantity_kg | DECIMAL(10,2) | NOT NULL | Cantidad planificada (kg) |
| planned_quantity_units | INTEGER | | Cantidad planificada (unidades) |
| produced_quantity_kg | DECIMAL(10,2) | DEFAULT 0 | Cantidad producida (kg) |
| produced_quantity_units | INTEGER | DEFAULT 0 | Cantidad producida (unidades) |
| start_date | DATE | NOT NULL | Fecha inicio planificada |
| end_date | DATE | | Fecha fin planificada |
| actual_start_date | DATE | | Fecha inicio real |
| actual_end_date | DATE | | Fecha fin real |
| status | production_order_status | NOT NULL | Estado de la OP |
| priority | priority_level | DEFAULT 'media' | Prioridad |
| assigned_machine_id | INTEGER | FK → machines(id) | Máquina asignada |
| assigned_operator_id | INTEGER | FK → users(id) | Operador asignado |
| notes | TEXT | | Notas |
| created_by | INTEGER | FK → users(id) | Creado por |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_production_orders_number` en `po_number`
- `idx_production_orders_order` en `order_id`
- `idx_production_orders_product` en `product_id`
- `idx_production_orders_status` en `status`
- `idx_production_orders_dates` en `(start_date, end_date)`

---

### Tabla: production_records

Registros de producción por turno/máquina.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| production_order_id | INTEGER | FK → production_orders(id), NOT NULL | Orden de producción |
| machine_id | INTEGER | FK → machines(id), NOT NULL | Máquina |
| area | production_area | NOT NULL | Área de producción |
| production_date | DATE | NOT NULL | Fecha de producción |
| shift | VARCHAR(20) | | Turno (mañana/tarde/noche) |
| shift_start | TIME | | Hora inicio turno |
| shift_end | TIME | | Hora fin turno |
| **Producción** |
| produced_quantity_kg | DECIMAL(10,2) | NOT NULL | Cantidad producida (kg) |
| produced_quantity_units | INTEGER | | Cantidad producida (unidades) |
| waste_quantity_kg | DECIMAL(10,2) | DEFAULT 0 | Desperdicio (kg) |
| waste_percentage | DECIMAL(5,2) | DEFAULT 0 | % de merma |
| **Tiempos** |
| planned_time_hours | DECIMAL(6,2) | | Tiempo planificado (horas) |
| operation_time_hours | DECIMAL(6,2) | NOT NULL | Tiempo de operación (horas) |
| downtime_hours | DECIMAL(6,2) | DEFAULT 0 | Tiempo de parada (horas) |
| **Métricas** |
| machine_efficiency | DECIMAL(5,2) | | Eficiencia de máquina (%) |
| performance_rate | DECIMAL(5,2) | | Tasa de rendimiento (%) |
| quality_rate | DECIMAL(5,2) | | Tasa de calidad (%) |
| oee | DECIMAL(5,2) | | OEE (%) |
| machine_parameters | JSONB | DEFAULT '{}' | Parámetros usados |
| **Personal** |
| operator_id | INTEGER | FK → users(id) | Operador |
| supervisor_id | INTEGER | FK → users(id) | Supervisor |
| notes | TEXT | | Notas |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_production_records_po` en `production_order_id`
- `idx_production_records_machine` en `machine_id`
- `idx_production_records_area` en `area`
- `idx_production_records_date` en `production_date`
- `idx_production_records_operator` en `operator_id`

---

### Tabla: raw_materials

Catálogo de materias primas.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| code | VARCHAR(50) | UNIQUE, NOT NULL | Código de material |
| name | VARCHAR(200) | NOT NULL | Nombre del material |
| type | material_type | NOT NULL | Tipo de material |
| supplier | VARCHAR(200) | | Proveedor |
| supplier_code | VARCHAR(100) | | Código del proveedor |
| unit_cost | DECIMAL(12,2) | | Costo unitario |
| unit_measure | VARCHAR(20) | DEFAULT 'kg' | Unidad de medida |
| min_stock | DECIMAL(10,2) | DEFAULT 0 | Stock mínimo |
| max_stock | DECIMAL(10,2) | | Stock máximo |
| reorder_point | DECIMAL(10,2) | | Punto de reorden |
| specifications | TEXT | | Especificaciones |
| is_active | BOOLEAN | DEFAULT true | Material activo |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_raw_materials_code` en `code`
- `idx_raw_materials_type` en `type`
- `idx_raw_materials_active` en `is_active`

---

### Tabla: raw_material_inventory

Inventario de materias primas.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| material_id | INTEGER | FK → raw_materials(id), NOT NULL | Material |
| quantity | DECIMAL(10,2) | NOT NULL | Cantidad disponible |
| batch_number | VARCHAR(100) | | Número de lote |
| entry_date | DATE | NOT NULL | Fecha de ingreso |
| expiry_date | DATE | | Fecha de vencimiento |
| warehouse_location | VARCHAR(100) | | Ubicación en almacén |
| status | inventory_status | DEFAULT 'disponible' | Estado |
| purchase_order | VARCHAR(100) | | Orden de compra |
| invoice_number | VARCHAR(100) | | Número de factura |
| notes | TEXT | | Notas |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_raw_material_inventory_material` en `material_id`
- `idx_raw_material_inventory_batch` en `batch_number`
- `idx_raw_material_inventory_status` en `status`

---

### Tabla: material_consumption

Consumo de materias primas en producción.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| production_record_id | INTEGER | FK → production_records(id), NOT NULL | Registro de producción |
| material_id | INTEGER | FK → raw_materials(id), NOT NULL | Material |
| inventory_id | INTEGER | FK → raw_material_inventory(id) | Inventario específico |
| quantity_consumed | DECIMAL(10,2) | NOT NULL | Cantidad consumida |
| theoretical_consumption | DECIMAL(10,2) | | Consumo teórico |
| variance_percentage | DECIMAL(5,2) | | % de variación |
| batch_number | VARCHAR(100) | | Número de lote |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |

**Índices:**
- `idx_material_consumption_production` en `production_record_id`
- `idx_material_consumption_material` en `material_id`

---

### Tabla: finished_goods_inventory

Inventario de producto terminado.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| product_id | INTEGER | FK → products(id), NOT NULL | Producto |
| production_record_id | INTEGER | FK → production_records(id) | Registro de producción |
| batch_number | VARCHAR(100) | UNIQUE, NOT NULL | Número de lote |
| lot_number | VARCHAR(100) | | Número de lote alternativo |
| quantity_kg | DECIMAL(10,2) | NOT NULL | Cantidad en kg |
| quantity_units | INTEGER | | Cantidad en unidades |
| reels_count | INTEGER | | Número de bobinas |
| bags_per_reel | INTEGER | | Bolsas por rollo |
| bundles_count | INTEGER | | Número de bultos |
| warehouse_location | VARCHAR(100) | | Ubicación en almacén |
| status | inventory_status | DEFAULT 'disponible' | Estado |
| production_date | DATE | NOT NULL | Fecha de producción |
| entry_date | DATE | DEFAULT CURRENT_DATE | Fecha de ingreso |
| reserved_for_order_id | INTEGER | FK → orders(id) | Reservado para pedido |
| quality_approved | BOOLEAN | DEFAULT false | Aprobado por calidad |
| quality_approved_by | INTEGER | FK → users(id) | Aprobado por |
| quality_approved_at | TIMESTAMP | | Fecha de aprobación |
| notes | TEXT | | Notas |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_finished_goods_product` en `product_id`
- `idx_finished_goods_batch` en `batch_number`
- `idx_finished_goods_status` en `status`
- `idx_finished_goods_production_date` en `production_date`

---

### Tabla: quality_controls

Registros de control de calidad.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| production_record_id | INTEGER | FK → production_records(id) | Registro de producción |
| product_id | INTEGER | FK → products(id), NOT NULL | Producto |
| finished_goods_id | INTEGER | FK → finished_goods_inventory(id) | Inventario PT |
| inspection_date | DATE | NOT NULL | Fecha de inspección |
| inspection_time | TIME | DEFAULT CURRENT_TIME | Hora de inspección |
| inspection_type | inspection_type | NOT NULL | Tipo de inspección |
| test_results | JSONB | NOT NULL | Resultados de pruebas |
| result_status | quality_result | NOT NULL | Resultado |
| observations | TEXT | | Observaciones |
| corrective_actions | TEXT | | Acciones correctivas |
| inspector_id | INTEGER | FK → users(id), NOT NULL | Inspector |
| approved_by | INTEGER | FK → users(id) | Aprobado por |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_quality_controls_production` en `production_record_id`
- `idx_quality_controls_product` en `product_id`
- `idx_quality_controls_date` en `inspection_date`
- `idx_quality_controls_result` en `result_status`

**Ejemplo de JSON de test_results:**
```json
{
  "dimensiones": {
    "ancho_cm": 47.2,
    "largo_cm": 66.1,
    "tolerancia_ancho": "OK"
  },
  "calibre": {
    "punto_1": 0.0081,
    "punto_2": 0.0079,
    "punto_3": 0.0080,
    "promedio": 0.0080,
    "tolerancia": "OK"
  },
  "resistencia": {
    "traccion_kg": 15.2,
    "elongacion_pct": 450,
    "resultado": "APROBADO"
  },
  "sellado": {
    "resistencia_kg": 8.5,
    "hermeticidad": "OK"
  },
  "visual": {
    "defectos": "Ninguno",
    "transparencia": "Buena"
  }
}
```

---

### Tabla: dispatches

Despachos a clientes.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| dispatch_number | VARCHAR(50) | UNIQUE, NOT NULL | Número de despacho |
| order_id | INTEGER | FK → orders(id), NOT NULL | Pedido |
| customer_id | INTEGER | FK → customers(id), NOT NULL | Cliente |
| dispatch_date | DATE | NOT NULL | Fecha de despacho |
| dispatch_time | TIME | DEFAULT CURRENT_TIME | Hora de despacho |
| vehicle_plate | VARCHAR(20) | | Placa del vehículo |
| driver_name | VARCHAR(100) | | Nombre del conductor |
| driver_id | VARCHAR(50) | | Cédula del conductor |
| driver_phone | VARCHAR(20) | | Teléfono del conductor |
| status | order_status | DEFAULT 'pendiente' | Estado |
| total_weight_kg | DECIMAL(10,2) | | Peso total |
| total_packages | INTEGER | | Total de bultos |
| notes | TEXT | | Notas |
| created_by | INTEGER | FK → users(id) | Creado por |
| approved_by | INTEGER | FK → users(id) | Aprobado por |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_dispatches_number` en `dispatch_number`
- `idx_dispatches_order` en `order_id`
- `idx_dispatches_customer` en `customer_id`
- `idx_dispatches_date` en `dispatch_date`

---

### Tabla: dispatch_items

Ítems de despacho.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| dispatch_id | INTEGER | FK → dispatches(id), NOT NULL | Despacho |
| finished_goods_id | INTEGER | FK → finished_goods_inventory(id), NOT NULL | Inventario PT |
| quantity_kg | DECIMAL(10,2) | NOT NULL | Cantidad en kg |
| quantity_units | INTEGER | | Cantidad en unidades |
| packages_count | INTEGER | | Número de bultos |
| batch_number | VARCHAR(100) | | Número de lote |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |

**Índices:**
- `idx_dispatch_items_dispatch` en `dispatch_id`
- `idx_dispatch_items_finished_goods` en `finished_goods_id`

---

### Tabla: pelletizing_records

Registros de peletizado de desperdicio.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| pelletizing_date | DATE | NOT NULL | Fecha de peletizado |
| shift | VARCHAR(20) | | Turno |
| input_waste_kg | DECIMAL(10,2) | NOT NULL | Desperdicio de entrada (kg) |
| output_pellet_kg | DECIMAL(10,2) | NOT NULL | Pellet de salida (kg) |
| yield_percentage | DECIMAL(5,2) | | % de rendimiento |
| waste_source | production_area | | Área de origen |
| material_type | material_type | | Tipo de material |
| batch_number | VARCHAR(100) | | Número de lote |
| operator_id | INTEGER | FK → users(id) | Operador |
| notes | TEXT | | Notas |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_pelletizing_date` en `pelletizing_date`
- `idx_pelletizing_operator` en `operator_id`

---

### Tabla: machine_stops

Paradas de máquina (programadas y no programadas).

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| machine_id | INTEGER | FK → machines(id), NOT NULL | Máquina |
| production_record_id | INTEGER | FK → production_records(id) | Registro de producción |
| stop_start | TIMESTAMP | NOT NULL | Inicio de parada |
| stop_end | TIMESTAMP | | Fin de parada |
| duration_minutes | INTEGER | | Duración en minutos |
| stop_type | stop_type | NOT NULL | Tipo de parada |
| stop_reason | stop_reason | NOT NULL | Razón de parada |
| description | TEXT | | Descripción |
| corrective_action | TEXT | | Acción correctiva |
| reported_by | INTEGER | FK → users(id) | Reportado por |
| resolved_by | INTEGER | FK → users(id) | Resuelto por |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_machine_stops_machine` en `machine_id`
- `idx_machine_stops_start` en `stop_start`
- `idx_machine_stops_type` en `stop_type`
- `idx_machine_stops_reason` en `stop_reason`

---

### Tabla: tasks

Tareas y planificación.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| title | VARCHAR(200) | NOT NULL | Título de la tarea |
| description | TEXT | | Descripción |
| priority | priority_level | DEFAULT 'media' | Prioridad |
| status | task_status | DEFAULT 'pendiente' | Estado |
| due_date | DATE | | Fecha de vencimiento |
| assigned_to | INTEGER | FK → users(id) | Asignado a |
| created_by | INTEGER | FK → users(id), NOT NULL | Creado por |
| related_machine_id | INTEGER | FK → machines(id) | Máquina relacionada |
| related_order_id | INTEGER | FK → orders(id) | Pedido relacionado |
| completed_at | TIMESTAMP | | Fecha de completado |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_tasks_assigned` en `assigned_to`
- `idx_tasks_status` en `status`
- `idx_tasks_due_date` en `due_date`

---

### Tabla: plant_map_positions

Posiciones de máquinas en el mapa de planta.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| machine_id | INTEGER | UNIQUE, FK → machines(id), NOT NULL | Máquina |
| warehouse | warehouse_location | NOT NULL | Galpón |
| position_x | DECIMAL(8,2) | NOT NULL | Posición X |
| position_y | DECIMAL(8,2) | NOT NULL | Posición Y |
| width | DECIMAL(8,2) | DEFAULT 100 | Ancho |
| height | DECIMAL(8,2) | DEFAULT 80 | Alto |
| rotation | DECIMAL(5,2) | DEFAULT 0 | Rotación en grados |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_plant_map_machine` en `machine_id`
- `idx_plant_map_warehouse` en `warehouse`

---

### Tabla: training_modules

Módulos de entrenamiento y capacitación.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| title | VARCHAR(200) | NOT NULL | Título del módulo |
| content | TEXT | | Contenido |
| module_type | training_module_type | NOT NULL | Tipo de módulo |
| file_url | VARCHAR(500) | | URL del archivo |
| thumbnail_url | VARCHAR(500) | | URL de miniatura |
| order_index | INTEGER | DEFAULT 0 | Orden de visualización |
| is_active | BOOLEAN | DEFAULT true | Módulo activo |
| created_by | INTEGER | FK → users(id) | Creado por |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

**Índices:**
- `idx_training_modules_type` en `module_type`
- `idx_training_modules_order` en `order_index`

---

### Tabla: audit_logs

Auditoría de acciones en el sistema.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| user_id | INTEGER | FK → users(id) | Usuario |
| action | VARCHAR(50) | NOT NULL | Acción (CREATE, UPDATE, DELETE, LOGIN) |
| table_name | VARCHAR(100) | | Tabla afectada |
| record_id | INTEGER | | ID del registro |
| old_values | JSONB | | Valores anteriores |
| new_values | JSONB | | Valores nuevos |
| ip_address | INET | | Dirección IP |
| user_agent | TEXT | | User agent |
| created_at | TIMESTAMP | DEFAULT NOW() | Fecha de creación |

**Índices:**
- `idx_audit_logs_user` en `user_id`
- `idx_audit_logs_action` en `action`
- `idx_audit_logs_table` en `table_name`
- `idx_audit_logs_created` en `created_at`

---

### Tabla: system_settings

Configuración del sistema.

| Campo | Tipo | Restricciones | Descripción |
|-------|------|---------------|-------------|
| id | SERIAL | PRIMARY KEY | Identificador único |
| setting_key | VARCHAR(100) | UNIQUE, NOT NULL | Clave de configuración |
| setting_value | TEXT | | Valor |
| setting_type | VARCHAR(50) | | Tipo (string, number, boolean, json) |
| description | TEXT | | Descripción |
| updated_by | INTEGER | FK → users(id) | Actualizado por |
| updated_at | TIMESTAMP | DEFAULT NOW() | Última actualización |

---

## 📊 Vistas Útiles

### v_raw_material_stock

Vista consolidada de inventario de materia prima.

```sql
CREATE VIEW v_raw_material_stock AS
SELECT 
    rm.id,
    rm.code,
    rm.name,
    rm.type,
    SUM(rmi.quantity) as total_quantity,
    rm.unit_measure,
    rm.min_stock,
    CASE 
        WHEN SUM(rmi.quantity) <= rm.min_stock THEN 'bajo'
        WHEN SUM(rmi.quantity) <= rm.reorder_point THEN 'reordenar'
        ELSE 'normal'
    END as stock_status
FROM raw_materials rm
LEFT JOIN raw_material_inventory rmi ON rm.id = rmi.material_id 
    AND rmi.status = 'disponible'
WHERE rm.is_active = true
GROUP BY rm.id;
```

### v_finished_goods_stock

Vista consolidada de inventario de producto terminado.

```sql
CREATE VIEW v_finished_goods_stock AS
SELECT 
    p.id as product_id,
    p.code as product_code,
    p.name as product_name,
    SUM(fgi.quantity_kg) as total_kg,
    SUM(fgi.quantity_units) as total_units,
    SUM(fgi.reels_count) as total_reels,
    COUNT(DISTINCT fgi.batch_number) as batch_count
FROM products p
LEFT JOIN finished_goods_inventory fgi ON p.id = fgi.product_id 
    AND fgi.status = 'disponible'
WHERE p.is_active = true
GROUP BY p.id;
```

### v_active_production_orders

Vista de órdenes de producción activas.

```sql
CREATE VIEW v_active_production_orders AS
SELECT 
    po.id,
    po.po_number,
    po.status,
    po.priority,
    p.code as product_code,
    p.name as product_name,
    po.planned_quantity_kg,
    po.produced_quantity_kg,
    ROUND((po.produced_quantity_kg / NULLIF(po.planned_quantity_kg, 0) * 100)::numeric, 2) as completion_percentage,
    m.name as machine_name,
    u.full_name as operator_name,
    po.start_date,
    po.end_date
FROM production_orders po
JOIN products p ON po.product_id = p.id
LEFT JOIN machines m ON po.assigned_machine_id = m.id
LEFT JOIN users u ON po.assigned_operator_id = u.id
WHERE po.status IN ('planificada', 'en_proceso', 'pausada');
```

### v_machine_efficiency

Vista de eficiencia de máquinas (últimos 30 días).

```sql
CREATE VIEW v_machine_efficiency AS
SELECT 
    m.id,
    m.code,
    m.name,
    m.type,
    m.area,
    COUNT(pr.id) as production_records_count,
    ROUND(AVG(pr.machine_efficiency)::numeric, 2) as avg_efficiency,
    ROUND(AVG(pr.oee)::numeric, 2) as avg_oee,
    SUM(pr.produced_quantity_kg) as total_produced_kg,
    SUM(pr.waste_quantity_kg) as total_waste_kg,
    ROUND((SUM(pr.waste_quantity_kg) / NULLIF(SUM(pr.produced_quantity_kg + pr.waste_quantity_kg), 0) * 100)::numeric, 2) as avg_waste_percentage
FROM machines m
LEFT JOIN production_records pr ON m.id = pr.machine_id 
    AND pr.production_date >= CURRENT_DATE - INTERVAL '30 days'
WHERE m.is_active = true
GROUP BY m.id;
```

---

## ⚙️ Funciones y Triggers

### Trigger: update_updated_at

Actualiza automáticamente el campo `updated_at` en todas las tablas.

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar a todas las tablas con updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
-- (repetir para todas las tablas)
```

### Trigger: calculate_order_totals

Calcula automáticamente los totales de pedidos.

```sql
CREATE OR REPLACE FUNCTION calculate_order_totals()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE orders SET
        subtotal = (SELECT COALESCE(SUM(subtotal), 0) FROM order_items WHERE order_id = NEW.order_id),
        tax_amount = subtotal * (tax_percentage / 100),
        total_amount = subtotal + tax_amount
    WHERE id = NEW.order_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_totals AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW EXECUTE FUNCTION calculate_order_totals();
```

### Trigger: calculate_waste_percentage

Calcula automáticamente el porcentaje de merma.

```sql
CREATE OR REPLACE FUNCTION calculate_waste_percentage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.produced_quantity_kg > 0 OR NEW.waste_quantity_kg > 0 THEN
        NEW.waste_percentage = ROUND(
            (NEW.waste_quantity_kg / NULLIF(NEW.produced_quantity_kg + NEW.waste_quantity_kg, 0) * 100)::numeric, 
            2
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_production_waste BEFORE INSERT OR UPDATE ON production_records
    FOR EACH ROW EXECUTE FUNCTION calculate_waste_percentage();
```

### Trigger: calculate_stop_duration

Calcula automáticamente la duración de paradas de máquina.

```sql
CREATE OR REPLACE FUNCTION calculate_stop_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stop_end IS NOT NULL AND NEW.stop_start IS NOT NULL THEN
        NEW.duration_minutes = EXTRACT(EPOCH FROM (NEW.stop_end - NEW.stop_start)) / 60;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_machine_stop_duration BEFORE INSERT OR UPDATE ON machine_stops
    FOR EACH ROW EXECUTE FUNCTION calculate_stop_duration();
```

---

## 🔐 Datos Iniciales

### Roles Predefinidos

```sql
INSERT INTO roles (name, description, permissions) VALUES
('Super Administrador', 'Acceso total al sistema', '{"all": true}'),
('Gerente de Producción', 'Gestión completa de producción', '{"production": "full", "reports": "full", "orders": "full"}'),
('Supervisor de Área', 'Supervisión de área específica', '{"production": "area", "quality": "full", "reports": "area"}'),
('Operador de Máquina', 'Operación de máquinas', '{"production": "register", "machines": "read"}'),
('Almacenista', 'Gestión de inventarios', '{"inventory": "full", "dispatches": "full"}'),
('Vendedor', 'Gestión de ventas', '{"customers": "full", "orders": "full", "inventory": "read"}'),
('Control de Calidad', 'Control de calidad', '{"quality": "full", "production": "read", "reports": "quality"}');
```

### Usuario Administrador

```sql
-- Contraseña: Admin123! (debe cambiarse en producción)
INSERT INTO users (username, email, password_hash, full_name, role, is_active) VALUES
('admin', 'admin@inverplastic.com', '$2b$10$...', 'Administrador del Sistema', 'super_admin', true);
```

### Configuraciones del Sistema

```sql
INSERT INTO system_settings (setting_key, setting_value, setting_type, description) VALUES
('company_name', 'Inverplastic 79, C.A.', 'string', 'Nombre de la empresa'),
('company_tax_id', 'J-XXXXXXXX-X', 'string', 'RIF de la empresa'),
('default_tax_percentage', '16', 'number', 'Porcentaje de IVA por defecto'),
('min_waste_alert_percentage', '5', 'number', 'Porcentaje mínimo de merma para generar alerta'),
('oee_target', '75', 'number', 'Objetivo de OEE (%)'),
('backup_retention_days', '30', 'number', 'Días de retención de backups');
```

---

## 📝 Notas de Implementación

### Índices

Todos los índices están diseñados para optimizar las consultas más frecuentes:
- Búsquedas por código/número
- Filtros por estado
- Filtros por fecha
- Joins frecuentes (foreign keys)

### Campos JSONB

Los campos JSONB se utilizan para almacenar datos estructurados flexibles:
- **machine_parameters**: Parámetros específicos de producción
- **technical_specs**: Especificaciones técnicas de máquinas
- **test_results**: Resultados de pruebas de calidad
- **permissions**: Permisos de roles

### Triggers Automáticos

Los triggers garantizan la integridad de datos:
- Actualización automática de `updated_at`
- Cálculo de totales de pedidos
- Cálculo de porcentajes de merma
- Cálculo de duración de paradas

### Vistas

Las vistas simplifican consultas complejas frecuentes:
- Stock consolidado de materiales
- Órdenes activas con información completa
- Métricas de eficiencia de máquinas

---

## 🚀 Script de Creación Completo

El script SQL completo para crear toda la base de datos está disponible en el archivo adjunto `database-schema.sql`.

Para ejecutarlo:

```bash
# Crear base de datos
createdb erp_polietileno

# Ejecutar script
psql -U postgres -d erp_polietileno -f database-schema.sql
```

---

**Última actualización:** 2026-02-14  
**Versión:** 1.0
