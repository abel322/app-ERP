-- =====================================================
-- ERP/MRP Sistema de Gestión de Producción de Polietileno
-- Base de Datos PostgreSQL 15+
-- =====================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- TIPOS ENUMERADOS
-- =====================================================

CREATE TYPE user_role AS ENUM (
    'super_admin',
    'gerente_produccion',
    'supervisor_area',
    'operador_maquina',
    'almacenista',
    'vendedor',
    'control_calidad'
);

CREATE TYPE machine_type AS ENUM (
    'extrusora',
    'selladora',
    'impresora',
    'refiladora',
    'molino'
);

CREATE TYPE production_area AS ENUM (
    'extrusion',
    'sellado',
    'impresion',
    'refilado',
    'peletizado'
);

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

CREATE TYPE priority_level AS ENUM (
    'baja',
    'media',
    'alta',
    'urgente'
);

CREATE TYPE material_type AS ENUM (
    'pebd',
    'pead',
    'pelbd',
    'pigmento',
    'aditivo',
    'reciclado'
);

CREATE TYPE inventory_status AS ENUM (
    'disponible',
    'reservado',
    'en_transito',
    'despachado',
    'rechazado'
);

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

CREATE TYPE task_status AS ENUM (
    'pendiente',
    'en_progreso',
    'completada',
    'cancelada'
);

CREATE TYPE warehouse_location AS ENUM (
    'galpon_1',
    'galpon_2'
);

CREATE TYPE training_module_type AS ENUM (
    'manual',
    'procedimiento',
    'video',
    'diagrama',
    'buenas_practicas'
);

-- =====================================================
-- TABLA: roles
-- =====================================================
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    permissions JSONB NOT NULL DEFAULT '{}',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLA: users
-- =====================================================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role user_role NOT NULL DEFAULT 'operador_maquina',
    role_id INTEGER REFERENCES roles(id),
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_active ON users(is_active);

-- =====================================================
-- TABLA: customers
-- =====================================================
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    business_name VARCHAR(200) NOT NULL,
    tax_id VARCHAR(50) UNIQUE,
    contact_name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Venezuela',
    credit_limit DECIMAL(12,2),
    payment_terms INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_customers_code ON customers(code);
CREATE INDEX idx_customers_active ON customers(is_active);

-- =====================================================
-- TABLA: products
-- =====================================================
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Especificaciones técnicas
    width_cm DECIMAL(8,2) NOT NULL,
    length_cm DECIMAL(8,2),
    caliber_microns DECIMAL(6,2) NOT NULL,
    
    -- Características
    has_gusset BOOLEAN DEFAULT false,
    gusset_width_cm DECIMAL(8,2),
    has_perforation BOOLEAN DEFAULT false,
    perforation_type VARCHAR(50),
    has_valve BOOLEAN DEFAULT false,
    valve_width_cm DECIMAL(8,2),
    has_print BOOLEAN DEFAULT false,
    print_colors INTEGER,
    
    -- Propiedades
    max_reel_weight_kg DECIMAL(8,2),
    is_heat_shrinkable BOOLEAN DEFAULT false,
    requires_trimming BOOLEAN DEFAULT false,
    requires_corona_treatment BOOLEAN DEFAULT false,
    
    -- Peso y empaque
    bag_weight_grams DECIMAL(8,3),
    bags_per_reel INTEGER,
    reels_per_bundle INTEGER,
    
    -- Material
    material_type material_type NOT NULL DEFAULT 'pebd',
    color VARCHAR(50),
    recycled_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Comercial
    unit_price DECIMAL(12,2),
    cost_price DECIMAL(12,2),
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_material ON products(material_type);

-- =====================================================
-- TABLA: machines
-- =====================================================
CREATE TABLE machines (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    type machine_type NOT NULL,
    area production_area NOT NULL,
    
    -- Especificaciones técnicas
    brand VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(100),
    year_manufactured INTEGER,
    
    -- Capacidad
    standard_speed DECIMAL(8,2) NOT NULL, -- kg/hora o unidades/hora
    max_speed DECIMAL(8,2),
    min_speed DECIMAL(8,2),
    
    -- Ubicación
    warehouse_location warehouse_location NOT NULL DEFAULT 'galpon_1',
    
    -- Especificaciones eléctricas y mecánicas (JSON)
    technical_specs JSONB DEFAULT '{}',
    
    -- Estado
    is_active BOOLEAN DEFAULT true,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_machines_code ON machines(code);
CREATE INDEX idx_machines_type ON machines(type);
CREATE INDEX idx_machines_area ON machines(area);
CREATE INDEX idx_machines_active ON machines(is_active);

-- =====================================================
-- TABLA: product_machine_params
-- =====================================================
CREATE TABLE product_machine_params (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    machine_id INTEGER NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
    area production_area NOT NULL,
    
    -- Parámetros específicos por área (JSON)
    -- Extrusión: temperaturas, velocidades, presiones
    -- Sellado: temperaturas, velocidad, altura
    -- Impresión: velocidad, tensión, registro
    -- Refilado: ancho de corte, velocidad
    parameters JSONB NOT NULL DEFAULT '{}',
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(product_id, machine_id, area)
);

CREATE INDEX idx_product_machine_params_product ON product_machine_params(product_id);
CREATE INDEX idx_product_machine_params_machine ON product_machine_params(machine_id);

-- =====================================================
-- TABLA: orders
-- =====================================================
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    delivery_date DATE NOT NULL,
    
    status order_status NOT NULL DEFAULT 'pendiente',
    priority priority_level DEFAULT 'media',
    
    subtotal DECIMAL(12,2) DEFAULT 0,
    tax_percentage DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    total_amount DECIMAL(12,2) DEFAULT 0,
    
    notes TEXT,
    internal_notes TEXT,
    
    created_by INTEGER REFERENCES users(id),
    approved_by INTEGER REFERENCES users(id),
    approved_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);

-- =====================================================
-- TABLA: order_items
-- =====================================================
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    
    quantity_units INTEGER,
    quantity_kg DECIMAL(10,2),
    
    unit_price DECIMAL(12,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    
    specifications TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- =====================================================
-- TABLA: production_orders
-- =====================================================
CREATE TABLE production_orders (
    id SERIAL PRIMARY KEY,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    
    planned_quantity_kg DECIMAL(10,2) NOT NULL,
    planned_quantity_units INTEGER,
    
    produced_quantity_kg DECIMAL(10,2) DEFAULT 0,
    produced_quantity_units INTEGER DEFAULT 0,
    
    start_date DATE NOT NULL,
    end_date DATE,
    actual_start_date DATE,
    actual_end_date DATE,
    
    status production_order_status NOT NULL DEFAULT 'planificada',
    priority priority_level DEFAULT 'media',
    
    assigned_machine_id INTEGER REFERENCES machines(id),
    assigned_operator_id INTEGER REFERENCES users(id),
    
    notes TEXT,
    
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_production_orders_number ON production_orders(po_number);
CREATE INDEX idx_production_orders_order ON production_orders(order_id);
CREATE INDEX idx_production_orders_product ON production_orders(product_id);
CREATE INDEX idx_production_orders_status ON production_orders(status);
CREATE INDEX idx_production_orders_dates ON production_orders(start_date, end_date);

-- =====================================================
-- TABLA: production_records
-- =====================================================
CREATE TABLE production_records (
    id SERIAL PRIMARY KEY,
    production_order_id INTEGER NOT NULL REFERENCES production_orders(id),
    machine_id INTEGER NOT NULL REFERENCES machines(id),
    area production_area NOT NULL,
    
    production_date DATE NOT NULL DEFAULT CURRENT_DATE,
    shift VARCHAR(20), -- 'mañana', 'tarde', 'noche'
    shift_start TIME,
    shift_end TIME,
    
    -- Producción
    produced_quantity_kg DECIMAL(10,2) NOT NULL,
    produced_quantity_units INTEGER,
    waste_quantity_kg DECIMAL(10,2) DEFAULT 0,
    waste_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Tiempos
    planned_time_hours DECIMAL(6,2),
    operation_time_hours DECIMAL(6,2) NOT NULL,
    downtime_hours DECIMAL(6,2) DEFAULT 0,
    
    -- Métricas calculadas
    machine_efficiency DECIMAL(5,2), -- %
    performance_rate DECIMAL(5,2), -- %
    quality_rate DECIMAL(5,2), -- %
    oee DECIMAL(5,2), -- %
    
    -- Parámetros de máquina usados (JSON)
    machine_parameters JSONB DEFAULT '{}',
    
    -- Personal
    operator_id INTEGER REFERENCES users(id),
    supervisor_id INTEGER REFERENCES users(id),
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_production_records_po ON production_records(production_order_id);
CREATE INDEX idx_production_records_machine ON production_records(machine_id);
CREATE INDEX idx_production_records_area ON production_records(area);
CREATE INDEX idx_production_records_date ON production_records(production_date);
CREATE INDEX idx_production_records_operator ON production_records(operator_id);

-- =====================================================
-- TABLA: raw_materials
-- =====================================================
CREATE TABLE raw_materials (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    type material_type NOT NULL,
    
    supplier VARCHAR(200),
    supplier_code VARCHAR(100),
    
    unit_cost DECIMAL(12,2),
    unit_measure VARCHAR(20) DEFAULT 'kg', -- kg, litros, unidades
    
    min_stock DECIMAL(10,2) DEFAULT 0,
    max_stock DECIMAL(10,2),
    reorder_point DECIMAL(10,2),
    
    specifications TEXT,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_raw_materials_code ON raw_materials(code);
CREATE INDEX idx_raw_materials_type ON raw_materials(type);
CREATE INDEX idx_raw_materials_active ON raw_materials(is_active);

-- =====================================================
-- TABLA: raw_material_inventory
-- =====================================================
CREATE TABLE raw_material_inventory (
    id SERIAL PRIMARY KEY,
    material_id INTEGER NOT NULL REFERENCES raw_materials(id),
    
    quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
    batch_number VARCHAR(100),
    
    entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    warehouse_location VARCHAR(100),
    status inventory_status DEFAULT 'disponible',
    
    purchase_order VARCHAR(100),
    invoice_number VARCHAR(100),
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_raw_material_inventory_material ON raw_material_inventory(material_id);
CREATE INDEX idx_raw_material_inventory_batch ON raw_material_inventory(batch_number);
CREATE INDEX idx_raw_material_inventory_status ON raw_material_inventory(status);

-- =====================================================
-- TABLA: material_consumption
-- =====================================================
CREATE TABLE material_consumption (
    id SERIAL PRIMARY KEY,
    production_record_id INTEGER NOT NULL REFERENCES production_records(id) ON DELETE CASCADE,
    material_id INTEGER NOT NULL REFERENCES raw_materials(id),
    inventory_id INTEGER REFERENCES raw_material_inventory(id),
    
    quantity_consumed DECIMAL(10,2) NOT NULL,
    theoretical_consumption DECIMAL(10,2),
    variance_percentage DECIMAL(5,2),
    
    batch_number VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_material_consumption_production ON material_consumption(production_record_id);
CREATE INDEX idx_material_consumption_material ON material_consumption(material_id);

-- =====================================================
-- TABLA: finished_goods_inventory
-- =====================================================
CREATE TABLE finished_goods_inventory (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL REFERENCES products(id),
    production_record_id INTEGER REFERENCES production_records(id),
    
    batch_number VARCHAR(100) UNIQUE NOT NULL,
    lot_number VARCHAR(100),
    
    quantity_kg DECIMAL(10,2) NOT NULL,
    quantity_units INTEGER,
    reels_count INTEGER,
    bags_per_reel INTEGER,
    bundles_count INTEGER,
    
    warehouse_location VARCHAR(100),
    status inventory_status DEFAULT 'disponible',
    
    production_date DATE NOT NULL,
    entry_date DATE DEFAULT CURRENT_DATE,
    
    reserved_for_order_id INTEGER REFERENCES orders(id),
    
    quality_approved BOOLEAN DEFAULT false,
    quality_approved_by INTEGER REFERENCES users(id),
    quality_approved_at TIMESTAMP,
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_finished_goods_product ON finished_goods_inventory(product_id);
CREATE INDEX idx_finished_goods_batch ON finished_goods_inventory(batch_number);
CREATE INDEX idx_finished_goods_status ON finished_goods_inventory(status);
CREATE INDEX idx_finished_goods_production_date ON finished_goods_inventory(production_date);

-- =====================================================
-- TABLA: quality_controls
-- =====================================================
CREATE TABLE quality_controls (
    id SERIAL PRIMARY KEY,
    production_record_id INTEGER REFERENCES production_records(id),
    product_id INTEGER NOT NULL REFERENCES products(id),
    finished_goods_id INTEGER REFERENCES finished_goods_inventory(id),
    
    inspection_date DATE NOT NULL DEFAULT CURRENT_DATE,
    inspection_time TIME DEFAULT CURRENT_TIME,
    inspection_type inspection_type NOT NULL,
    
    -- Resultados de pruebas (JSON)
    -- Puede incluir: dimensiones, calibre, resistencia, etc.
    test_results JSONB NOT NULL DEFAULT '{}',
    
    result_status quality_result NOT NULL,
    
    observations TEXT,
    corrective_actions TEXT,
    
    inspector_id INTEGER NOT NULL REFERENCES users(id),
    approved_by INTEGER REFERENCES users(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_quality_controls_production ON quality_controls(production_record_id);
CREATE INDEX idx_quality_controls_product ON quality_controls(product_id);
CREATE INDEX idx_quality_controls_date ON quality_controls(inspection_date);
CREATE INDEX idx_quality_controls_result ON quality_controls(result_status);

-- =====================================================
-- TABLA: dispatches
-- =====================================================
CREATE TABLE dispatches (
    id SERIAL PRIMARY KEY,
    dispatch_number VARCHAR(50) UNIQUE NOT NULL,
    order_id INTEGER NOT NULL REFERENCES orders(id),
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    
    dispatch_date DATE NOT NULL DEFAULT CURRENT_DATE,
    dispatch_time TIME DEFAULT CURRENT_TIME,
    
    vehicle_plate VARCHAR(20),
    driver_name VARCHAR(100),
    driver_id VARCHAR(50),
    driver_phone VARCHAR(20),
    
    status order_status DEFAULT 'pendiente',
    
    total_weight_kg DECIMAL(10,2),
    total_packages INTEGER,
    
    notes TEXT,
    
    created_by INTEGER REFERENCES users(id),
    approved_by INTEGER REFERENCES users(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dispatches_number ON dispatches(dispatch_number);
CREATE INDEX idx_dispatches_order ON dispatches(order_id);
CREATE INDEX idx_dispatches_customer ON dispatches(customer_id);
CREATE INDEX idx_dispatches_date ON dispatches(dispatch_date);

-- =====================================================
-- TABLA: dispatch_items
-- =====================================================
CREATE TABLE dispatch_items (
    id SERIAL PRIMARY KEY,
    dispatch_id INTEGER NOT NULL REFERENCES dispatches(id) ON DELETE CASCADE,
    finished_goods_id INTEGER NOT NULL REFERENCES finished_goods_inventory(id),
    
    quantity_kg DECIMAL(10,2) NOT NULL,
    quantity_units INTEGER,
    packages_count INTEGER,
    
    batch_number VARCHAR(100),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_dispatch_items_dispatch ON dispatch_items(dispatch_id);
CREATE INDEX idx_dispatch_items_finished_goods ON dispatch_items(finished_goods_id);

-- =====================================================
-- TABLA: pelletizing_records
-- =====================================================
CREATE TABLE pelletizing_records (
    id SERIAL PRIMARY KEY,
    
    pelletizing_date DATE NOT NULL DEFAULT CURRENT_DATE,
    shift VARCHAR(20),
    
    input_waste_kg DECIMAL(10,2) NOT NULL,
    output_pellet_kg DECIMAL(10,2) NOT NULL,
    yield_percentage DECIMAL(5,2),
    
    waste_source production_area, -- de qué área viene el desperdicio
    material_type material_type,
    
    batch_number VARCHAR(100),
    
    operator_id INTEGER REFERENCES users(id),
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_pelletizing_date ON pelletizing_records(pelletizing_date);
CREATE INDEX idx_pelletizing_operator ON pelletizing_records(operator_id);

-- =====================================================
-- TABLA: machine_stops
-- =====================================================
CREATE TABLE machine_stops (
    id SERIAL PRIMARY KEY,
    machine_id INTEGER NOT NULL REFERENCES machines(id),
    production_record_id INTEGER REFERENCES production_records(id),
    
    stop_start TIMESTAMP NOT NULL,
    stop_end TIMESTAMP,
    duration_minutes INTEGER,
    
    stop_type stop_type NOT NULL,
    stop_reason stop_reason NOT NULL,
    
    description TEXT,
    corrective_action TEXT,
    
    reported_by INTEGER REFERENCES users(id),
    resolved_by INTEGER REFERENCES users(id),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_machine_stops_machine ON machine_stops(machine_id);
CREATE INDEX idx_machine_stops_start ON machine_stops(stop_start);
CREATE INDEX idx_machine_stops_type ON machine_stops(stop_type);
CREATE INDEX idx_machine_stops_reason ON machine_stops(stop_reason);

-- =====================================================
-- TABLA: tasks
-- =====================================================
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    
    priority priority_level DEFAULT 'media',
    status task_status DEFAULT 'pendiente',
    
    due_date DATE,
    
    assigned_to INTEGER REFERENCES users(id),
    created_by INTEGER NOT NULL REFERENCES users(id),
    
    related_machine_id INTEGER REFERENCES machines(id),
    related_order_id INTEGER REFERENCES orders(id),
    
    completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_assigned ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

-- =====================================================
-- TABLA: plant_map_positions
-- =====================================================
CREATE TABLE plant_map_positions (
    id SERIAL PRIMARY KEY,
    machine_id INTEGER UNIQUE NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
    
    warehouse warehouse_location NOT NULL,
    
    position_x DECIMAL(8,2) NOT NULL,
    position_y DECIMAL(8,2) NOT NULL,
    width DECIMAL(8,2) DEFAULT 100,
    height DECIMAL(8,2) DEFAULT 80,
    rotation DECIMAL(5,2) DEFAULT 0,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_plant_map_machine ON plant_map_positions(machine_id);
CREATE INDEX idx_plant_map_warehouse ON plant_map_positions(warehouse);

-- =====================================================
-- TABLA: training_modules
-- =====================================================
CREATE TABLE training_modules (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    module_type training_module_type NOT NULL,
    
    file_url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    
    order_index INTEGER DEFAULT 0,
    
    is_active BOOLEAN DEFAULT true,
    
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_training_modules_type ON training_modules(module_type);
CREATE INDEX idx_training_modules_order ON training_modules(order_index);

-- =====================================================
-- TABLA: audit_logs
-- =====================================================
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    
    action VARCHAR(50) NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'LOGIN', etc.
    table_name VARCHAR(100),
    record_id INTEGER,
    
    old_values JSONB,
    new_values JSONB,
    
    ip_address INET,
    user_agent TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_table ON audit_logs(table_name);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- =====================================================
-- TABLA: system_settings
-- =====================================================
CREATE TABLE system_settings (
    id SERIAL PRIMARY KEY,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(50), -- 'string', 'number', 'boolean', 'json'
    description TEXT,
    
    updated_by INTEGER REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- VISTAS ÚTILES
-- =====================================================

-- Vista de inventario de materia prima consolidado
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
GROUP BY rm.id, rm.code, rm.name, rm.type, rm.unit_measure, rm.min_stock, rm.reorder_point;

-- Vista de inventario de producto terminado consolidado
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
GROUP BY p.id, p.code, p.name;

-- Vista de órdenes de producción activas
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

-- Vista de eficiencia de máquinas
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
GROUP BY m.id, m.code, m.name, m.type, m.area;

-- =====================================================
-- FUNCIONES Y TRIGGERS
-- =====================================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a todas las tablas con updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_machines_updated_at BEFORE UPDATE ON machines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_production_orders_updated_at BEFORE UPDATE ON production_orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_production_records_updated_at BEFORE UPDATE ON production_records
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_finished_goods_updated_at BEFORE UPDATE ON finished_goods_inventory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para calcular totales de orden
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

-- Función para calcular porcentaje de merma
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

-- Función para calcular duración de parada
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

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Insertar roles predefinidos
INSERT INTO roles (name, description, permissions) VALUES
('Super Administrador', 'Acceso total al sistema', '{"all": true}'),
('Gerente de Producción', 'Gestión completa de producción', '{"production": "full", "reports": "full", "orders": "full"}'),
('Supervisor de Área', 'Supervisión de área específica', '{"production": "area", "quality": "full", "reports": "area"}'),
('Operador de Máquina', 'Operación de máquinas', '{"production": "register", "machines": "read"}'),
('Almacenista', 'Gestión de inventarios', '{"inventory": "full", "dispatches": "full"}'),
('Vendedor', 'Gestión de ventas', '{"customers": "full", "orders": "full", "inventory": "read"}'),
('Control de Calidad', 'Control de calidad', '{"quality": "full", "production": "read", "reports": "quality"}');

-- Insertar usuario administrador por defecto
-- Contraseña: Admin123! (debe cambiarse en producción)
INSERT INTO users (username, email, password_hash, full_name, role, is_active) VALUES
('admin', 'admin@inverplastic.com', '$2b$10$rKvVPZqGhXqKJIqKqKqKqOqKqKqKqKqKqKqKqKqKqKqKqKqKqKqKq', 'Administrador del Sistema', 'super_admin', true);

-- Insertar configuraciones del sistema
INSERT INTO system_settings (setting_key, setting_value, setting_type, description) VALUES
('company_name', 'Inverplastic 79, C.A.', 'string', 'Nombre de la empresa'),
('company_tax_id', 'J-XXXXXXXX-X', 'string', 'RIF de la empresa'),
('default_tax_percentage', '16', 'number', 'Porcentaje de IVA por defecto'),
('min_waste_alert_percentage', '5', 'number', 'Porcentaje mínimo de merma para generar alerta'),
('oee_target', '75', 'number', 'Objetivo de OEE (%)'),
('backup_retention_days', '30', 'number', 'Días de retención de backups');

-- =====================================================
-- COMENTARIOS EN TABLAS
-- =====================================================

COMMENT ON TABLE users IS 'Usuarios del sistema con roles y permisos';
COMMENT ON TABLE customers IS 'Clientes de la empresa';
COMMENT ON TABLE products IS 'Catálogo de productos (bolsas y bobinas)';
COMMENT ON TABLE machines IS 'Máquinas de producción';
COMMENT ON TABLE product_machine_params IS 'Parámetros de máquina específicos por producto';
COMMENT ON TABLE orders IS 'Pedidos de clientes';
COMMENT ON TABLE production_orders IS 'Órdenes de producción';
COMMENT ON TABLE production_records IS 'Registros de producción por turno/máquina';
COMMENT ON TABLE raw_materials IS 'Catálogo de materias primas';
COMMENT ON TABLE raw_material_inventory IS 'Inventario de materias primas';
COMMENT ON TABLE finished_goods_inventory IS 'Inventario de producto terminado';
COMMENT ON TABLE quality_controls IS 'Registros de control de calidad';
COMMENT ON TABLE dispatches IS 'Despachos a clientes';
COMMENT ON TABLE pelletizing_records IS 'Registros de peletizado de desperdicio';
COMMENT ON TABLE machine_stops IS 'Paradas de máquina (programadas y no programadas)';
COMMENT ON TABLE audit_logs IS 'Auditoría de acciones en el sistema';

-- =====================================================
-- FIN DEL SCRIPT
-- =====================================================
