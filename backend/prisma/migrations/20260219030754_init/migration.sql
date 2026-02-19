-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('super_admin', 'gerente_produccion', 'supervisor_area', 'operador_maquina', 'almacenista', 'vendedor', 'control_calidad');

-- CreateEnum
CREATE TYPE "MachineType" AS ENUM ('extrusora', 'selladora', 'impresora', 'refiladora', 'molino');

-- CreateEnum
CREATE TYPE "ProductionArea" AS ENUM ('extrusion', 'sellado', 'impresion', 'refilado', 'peletizado');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('pendiente', 'aprobado', 'en_produccion', 'completado', 'cancelado');

-- CreateEnum
CREATE TYPE "ProductionOrderStatus" AS ENUM ('planificada', 'en_proceso', 'pausada', 'completada', 'cancelada');

-- CreateEnum
CREATE TYPE "PriorityLevel" AS ENUM ('baja', 'media', 'alta', 'urgente');

-- CreateEnum
CREATE TYPE "MaterialType" AS ENUM ('pebd', 'pead', 'pelbd', 'pigmento', 'aditivo', 'reciclado');

-- CreateEnum
CREATE TYPE "InventoryStatus" AS ENUM ('disponible', 'reservado', 'en_transito', 'despachado', 'rechazado');

-- CreateEnum
CREATE TYPE "QualityResult" AS ENUM ('aprobado', 'rechazado', 'condicional');

-- CreateEnum
CREATE TYPE "InspectionType" AS ENUM ('recepcion_mp', 'proceso', 'producto_terminado', 'pre_despacho');

-- CreateEnum
CREATE TYPE "StopType" AS ENUM ('programada', 'no_programada');

-- CreateEnum
CREATE TYPE "StopReason" AS ENUM ('mantenimiento', 'cambio_producto', 'falta_material', 'falla_mecanica', 'falla_electrica', 'falta_personal', 'almuerzo', 'otros');

-- CreateEnum
CREATE TYPE "TaskStatus" AS ENUM ('pendiente', 'en_progreso', 'completada', 'cancelada');

-- CreateEnum
CREATE TYPE "WarehouseLocation" AS ENUM ('galpon_1', 'galpon_2');

-- CreateEnum
CREATE TYPE "TrainingModuleType" AS ENUM ('manual', 'procedimiento', 'video', 'diagrama', 'buenas_practicas');

-- CreateTable
CREATE TABLE "users" (
    "id" SERIAL NOT NULL,
    "username" VARCHAR(50) NOT NULL,
    "email" VARCHAR(100) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "full_name" VARCHAR(100) NOT NULL,
    "role" "UserRole" NOT NULL,
    "role_id" INTEGER,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roles" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "permissions" JSONB NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" SERIAL NOT NULL,
    "code" VARCHAR(20) NOT NULL,
    "business_name" VARCHAR(200) NOT NULL,
    "tax_id" VARCHAR(50),
    "contact_name" VARCHAR(100),
    "phone" VARCHAR(20),
    "email" VARCHAR(100),
    "address" TEXT,
    "city" VARCHAR(100),
    "state" VARCHAR(100),
    "country" VARCHAR(100) DEFAULT 'Venezuela',
    "credit_limit" DECIMAL(12,2),
    "payment_terms" INTEGER DEFAULT 30,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "products" (
    "id" SERIAL NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "width_cm" DECIMAL(8,2) NOT NULL,
    "length_cm" DECIMAL(8,2),
    "caliber_microns" DECIMAL(6,2) NOT NULL,
    "has_gusset" BOOLEAN NOT NULL DEFAULT false,
    "gusset_width_cm" DECIMAL(8,2),
    "has_perforation" BOOLEAN NOT NULL DEFAULT false,
    "perforation_type" VARCHAR(50),
    "has_valve" BOOLEAN NOT NULL DEFAULT false,
    "valve_width_cm" DECIMAL(8,2),
    "has_print" BOOLEAN NOT NULL DEFAULT false,
    "print_colors" INTEGER,
    "max_reel_weight_kg" DECIMAL(8,2),
    "is_heat_shrinkable" BOOLEAN NOT NULL DEFAULT false,
    "requires_trimming" BOOLEAN NOT NULL DEFAULT false,
    "requires_corona_treatment" BOOLEAN NOT NULL DEFAULT false,
    "bag_weight_grams" DECIMAL(8,3),
    "bags_per_reel" INTEGER,
    "reels_per_bundle" INTEGER,
    "material_type" "MaterialType" NOT NULL,
    "color" VARCHAR(50),
    "recycled_percentage" DECIMAL(5,2) DEFAULT 0,
    "unit_price" DECIMAL(12,2),
    "cost_price" DECIMAL(12,2),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "machines" (
    "id" SERIAL NOT NULL,
    "code" VARCHAR(20) NOT NULL,
    "name" VARCHAR(100) NOT NULL,
    "type" "MachineType" NOT NULL,
    "area" "ProductionArea" NOT NULL,
    "brand" VARCHAR(100),
    "model" VARCHAR(100),
    "serial_number" VARCHAR(100),
    "year_manufactured" INTEGER,
    "standard_speed" DECIMAL(8,2) NOT NULL,
    "max_speed" DECIMAL(8,2),
    "min_speed" DECIMAL(8,2),
    "warehouse_location" "WarehouseLocation" NOT NULL,
    "technical_specs" JSONB DEFAULT '{}',
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_maintenance_date" DATE,
    "next_maintenance_date" DATE,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "machines_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "product_machine_params" (
    "id" SERIAL NOT NULL,
    "product_id" INTEGER NOT NULL,
    "machine_id" INTEGER NOT NULL,
    "area" "ProductionArea" NOT NULL,
    "parameters" JSONB NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "product_machine_params_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" SERIAL NOT NULL,
    "order_number" VARCHAR(50) NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "order_date" DATE NOT NULL,
    "delivery_date" DATE NOT NULL,
    "status" "OrderStatus" NOT NULL,
    "priority" "PriorityLevel" NOT NULL DEFAULT 'media',
    "subtotal" DECIMAL(12,2) DEFAULT 0,
    "tax_percentage" DECIMAL(5,2) DEFAULT 0,
    "tax_amount" DECIMAL(12,2) DEFAULT 0,
    "total_amount" DECIMAL(12,2) DEFAULT 0,
    "notes" TEXT,
    "internal_notes" TEXT,
    "created_by" INTEGER,
    "approved_by" INTEGER,
    "approved_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" SERIAL NOT NULL,
    "order_id" INTEGER NOT NULL,
    "product_id" INTEGER NOT NULL,
    "quantity_units" INTEGER,
    "quantity_kg" DECIMAL(10,2),
    "unit_price" DECIMAL(12,2) NOT NULL,
    "subtotal" DECIMAL(12,2) NOT NULL,
    "specifications" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "production_orders" (
    "id" SERIAL NOT NULL,
    "po_number" VARCHAR(50) NOT NULL,
    "order_id" INTEGER,
    "product_id" INTEGER NOT NULL,
    "planned_quantity_kg" DECIMAL(10,2) NOT NULL,
    "planned_quantity_units" INTEGER,
    "produced_quantity_kg" DECIMAL(10,2) DEFAULT 0,
    "produced_quantity_units" INTEGER DEFAULT 0,
    "start_date" DATE NOT NULL,
    "end_date" DATE,
    "actual_start_date" DATE,
    "actual_end_date" DATE,
    "status" "ProductionOrderStatus" NOT NULL,
    "priority" "PriorityLevel" NOT NULL DEFAULT 'media',
    "assigned_machine_id" INTEGER,
    "assigned_operator_id" INTEGER,
    "notes" TEXT,
    "created_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "production_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "production_records" (
    "id" SERIAL NOT NULL,
    "production_order_id" INTEGER NOT NULL,
    "machine_id" INTEGER NOT NULL,
    "area" "ProductionArea" NOT NULL,
    "production_date" DATE NOT NULL,
    "shift" VARCHAR(20),
    "shift_start" TIME,
    "shift_end" TIME,
    "produced_quantity_kg" DECIMAL(10,2) NOT NULL,
    "produced_quantity_units" INTEGER,
    "waste_quantity_kg" DECIMAL(10,2) DEFAULT 0,
    "waste_percentage" DECIMAL(5,2) DEFAULT 0,
    "planned_time_hours" DECIMAL(6,2),
    "operation_time_hours" DECIMAL(6,2) NOT NULL,
    "downtime_hours" DECIMAL(6,2) DEFAULT 0,
    "machine_efficiency" DECIMAL(5,2),
    "performance_rate" DECIMAL(5,2),
    "quality_rate" DECIMAL(5,2),
    "oee" DECIMAL(5,2),
    "machine_parameters" JSONB DEFAULT '{}',
    "operator_id" INTEGER,
    "supervisor_id" INTEGER,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "production_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "raw_materials" (
    "id" SERIAL NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "name" VARCHAR(200) NOT NULL,
    "type" "MaterialType" NOT NULL,
    "supplier" VARCHAR(200),
    "supplier_code" VARCHAR(100),
    "unit_cost" DECIMAL(12,2),
    "unit_measure" VARCHAR(20) DEFAULT 'kg',
    "min_stock" DECIMAL(10,2) DEFAULT 0,
    "max_stock" DECIMAL(10,2),
    "reorder_point" DECIMAL(10,2),
    "specifications" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "raw_materials_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "raw_material_inventory" (
    "id" SERIAL NOT NULL,
    "material_id" INTEGER NOT NULL,
    "quantity" DECIMAL(10,2) NOT NULL,
    "batch_number" VARCHAR(100),
    "entry_date" DATE NOT NULL,
    "expiry_date" DATE,
    "warehouse_location" VARCHAR(100),
    "status" "InventoryStatus" NOT NULL DEFAULT 'disponible',
    "purchase_order" VARCHAR(100),
    "invoice_number" VARCHAR(100),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "raw_material_inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "material_consumption" (
    "id" SERIAL NOT NULL,
    "production_record_id" INTEGER NOT NULL,
    "material_id" INTEGER NOT NULL,
    "inventory_id" INTEGER,
    "quantity_consumed" DECIMAL(10,2) NOT NULL,
    "theoretical_consumption" DECIMAL(10,2),
    "variance_percentage" DECIMAL(5,2),
    "batch_number" VARCHAR(100),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "material_consumption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "finished_goods_inventory" (
    "id" SERIAL NOT NULL,
    "product_id" INTEGER NOT NULL,
    "production_record_id" INTEGER,
    "batch_number" VARCHAR(100) NOT NULL,
    "lot_number" VARCHAR(100),
    "quantity_kg" DECIMAL(10,2) NOT NULL,
    "quantity_units" INTEGER,
    "reels_count" INTEGER,
    "bags_per_reel" INTEGER,
    "bundles_count" INTEGER,
    "warehouse_location" VARCHAR(100),
    "status" "InventoryStatus" NOT NULL DEFAULT 'disponible',
    "production_date" DATE NOT NULL,
    "entry_date" DATE DEFAULT CURRENT_TIMESTAMP,
    "reserved_for_order_id" INTEGER,
    "quality_approved" BOOLEAN DEFAULT false,
    "quality_approved_by" INTEGER,
    "quality_approved_at" TIMESTAMP(3),
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "finished_goods_inventory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quality_controls" (
    "id" SERIAL NOT NULL,
    "production_record_id" INTEGER,
    "product_id" INTEGER NOT NULL,
    "finished_goods_id" INTEGER,
    "inspection_date" DATE NOT NULL,
    "inspection_time" TIME DEFAULT CURRENT_TIMESTAMP,
    "inspection_type" "InspectionType" NOT NULL,
    "test_results" JSONB NOT NULL,
    "result_status" "QualityResult" NOT NULL,
    "observations" TEXT,
    "corrective_actions" TEXT,
    "inspector_id" INTEGER NOT NULL,
    "approved_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "quality_controls_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dispatches" (
    "id" SERIAL NOT NULL,
    "dispatch_number" VARCHAR(50) NOT NULL,
    "order_id" INTEGER NOT NULL,
    "customer_id" INTEGER NOT NULL,
    "dispatch_date" DATE NOT NULL,
    "dispatch_time" TIME DEFAULT CURRENT_TIMESTAMP,
    "vehicle_plate" VARCHAR(20),
    "driver_name" VARCHAR(100),
    "driver_id" VARCHAR(50),
    "driver_phone" VARCHAR(20),
    "status" "OrderStatus" NOT NULL DEFAULT 'pendiente',
    "total_weight_kg" DECIMAL(10,2),
    "total_packages" INTEGER,
    "notes" TEXT,
    "created_by" INTEGER,
    "approved_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "dispatches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "dispatch_items" (
    "id" SERIAL NOT NULL,
    "dispatch_id" INTEGER NOT NULL,
    "finished_goods_id" INTEGER NOT NULL,
    "quantity_kg" DECIMAL(10,2) NOT NULL,
    "quantity_units" INTEGER,
    "packages_count" INTEGER,
    "batch_number" VARCHAR(100),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "dispatch_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pelletizing_records" (
    "id" SERIAL NOT NULL,
    "pelletizing_date" DATE NOT NULL,
    "shift" VARCHAR(20),
    "input_waste_kg" DECIMAL(10,2) NOT NULL,
    "output_pellet_kg" DECIMAL(10,2) NOT NULL,
    "yield_percentage" DECIMAL(5,2),
    "waste_source" "ProductionArea",
    "material_type" "MaterialType",
    "batch_number" VARCHAR(100),
    "operator_id" INTEGER,
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pelletizing_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "machine_stops" (
    "id" SERIAL NOT NULL,
    "machine_id" INTEGER NOT NULL,
    "production_record_id" INTEGER,
    "stop_start" TIMESTAMP(3) NOT NULL,
    "stop_end" TIMESTAMP(3),
    "duration_minutes" INTEGER,
    "stop_type" "StopType" NOT NULL,
    "stop_reason" "StopReason" NOT NULL,
    "description" TEXT,
    "corrective_action" TEXT,
    "reported_by" INTEGER,
    "resolved_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "machine_stops_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tasks" (
    "id" SERIAL NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "priority" "PriorityLevel" NOT NULL DEFAULT 'media',
    "status" "TaskStatus" NOT NULL DEFAULT 'pendiente',
    "due_date" DATE,
    "assigned_to" INTEGER,
    "created_by" INTEGER NOT NULL,
    "related_machine_id" INTEGER,
    "related_order_id" INTEGER,
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tasks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "plant_map_positions" (
    "id" SERIAL NOT NULL,
    "machine_id" INTEGER NOT NULL,
    "warehouse" "WarehouseLocation" NOT NULL,
    "position_x" DECIMAL(8,2) NOT NULL,
    "position_y" DECIMAL(8,2) NOT NULL,
    "width" DECIMAL(8,2) NOT NULL DEFAULT 100,
    "height" DECIMAL(8,2) NOT NULL DEFAULT 80,
    "rotation" DECIMAL(5,2) NOT NULL DEFAULT 0,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "plant_map_positions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "training_modules" (
    "id" SERIAL NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "content" TEXT,
    "module_type" "TrainingModuleType" NOT NULL,
    "file_url" VARCHAR(500),
    "thumbnail_url" VARCHAR(500),
    "order_index" INTEGER DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "training_modules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER,
    "action" VARCHAR(50) NOT NULL,
    "table_name" VARCHAR(100),
    "record_id" INTEGER,
    "old_values" JSONB,
    "new_values" JSONB,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "system_settings" (
    "id" SERIAL NOT NULL,
    "setting_key" VARCHAR(100) NOT NULL,
    "setting_value" TEXT,
    "setting_type" VARCHAR(50),
    "description" TEXT,
    "updated_by" INTEGER,
    "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "system_settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "roles_name_key" ON "roles"("name");

-- CreateIndex
CREATE UNIQUE INDEX "customers_code_key" ON "customers"("code");

-- CreateIndex
CREATE UNIQUE INDEX "customers_tax_id_key" ON "customers"("tax_id");

-- CreateIndex
CREATE UNIQUE INDEX "products_code_key" ON "products"("code");

-- CreateIndex
CREATE UNIQUE INDEX "machines_code_key" ON "machines"("code");

-- CreateIndex
CREATE UNIQUE INDEX "product_machine_params_product_id_machine_id_area_key" ON "product_machine_params"("product_id", "machine_id", "area");

-- CreateIndex
CREATE UNIQUE INDEX "orders_order_number_key" ON "orders"("order_number");

-- CreateIndex
CREATE UNIQUE INDEX "production_orders_po_number_key" ON "production_orders"("po_number");

-- CreateIndex
CREATE UNIQUE INDEX "raw_materials_code_key" ON "raw_materials"("code");

-- CreateIndex
CREATE UNIQUE INDEX "finished_goods_inventory_batch_number_key" ON "finished_goods_inventory"("batch_number");

-- CreateIndex
CREATE UNIQUE INDEX "dispatches_dispatch_number_key" ON "dispatches"("dispatch_number");

-- CreateIndex
CREATE UNIQUE INDEX "plant_map_positions_machine_id_key" ON "plant_map_positions"("machine_id");

-- CreateIndex
CREATE UNIQUE INDEX "system_settings_setting_key_key" ON "system_settings"("setting_key");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_role_id_fkey" FOREIGN KEY ("role_id") REFERENCES "roles"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_machine_params" ADD CONSTRAINT "product_machine_params_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "product_machine_params" ADD CONSTRAINT "product_machine_params_machine_id_fkey" FOREIGN KEY ("machine_id") REFERENCES "machines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_orders" ADD CONSTRAINT "production_orders_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_orders" ADD CONSTRAINT "production_orders_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_orders" ADD CONSTRAINT "production_orders_assigned_machine_id_fkey" FOREIGN KEY ("assigned_machine_id") REFERENCES "machines"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_orders" ADD CONSTRAINT "production_orders_assigned_operator_id_fkey" FOREIGN KEY ("assigned_operator_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_orders" ADD CONSTRAINT "production_orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_records" ADD CONSTRAINT "production_records_production_order_id_fkey" FOREIGN KEY ("production_order_id") REFERENCES "production_orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_records" ADD CONSTRAINT "production_records_machine_id_fkey" FOREIGN KEY ("machine_id") REFERENCES "machines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_records" ADD CONSTRAINT "production_records_operator_id_fkey" FOREIGN KEY ("operator_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "production_records" ADD CONSTRAINT "production_records_supervisor_id_fkey" FOREIGN KEY ("supervisor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "raw_material_inventory" ADD CONSTRAINT "raw_material_inventory_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "raw_materials"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "material_consumption" ADD CONSTRAINT "material_consumption_production_record_id_fkey" FOREIGN KEY ("production_record_id") REFERENCES "production_records"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "material_consumption" ADD CONSTRAINT "material_consumption_material_id_fkey" FOREIGN KEY ("material_id") REFERENCES "raw_materials"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "material_consumption" ADD CONSTRAINT "material_consumption_inventory_id_fkey" FOREIGN KEY ("inventory_id") REFERENCES "raw_material_inventory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "finished_goods_inventory" ADD CONSTRAINT "finished_goods_inventory_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "finished_goods_inventory" ADD CONSTRAINT "finished_goods_inventory_production_record_id_fkey" FOREIGN KEY ("production_record_id") REFERENCES "production_records"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "finished_goods_inventory" ADD CONSTRAINT "finished_goods_inventory_reserved_for_order_id_fkey" FOREIGN KEY ("reserved_for_order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "finished_goods_inventory" ADD CONSTRAINT "finished_goods_inventory_quality_approved_by_fkey" FOREIGN KEY ("quality_approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quality_controls" ADD CONSTRAINT "quality_controls_production_record_id_fkey" FOREIGN KEY ("production_record_id") REFERENCES "production_records"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quality_controls" ADD CONSTRAINT "quality_controls_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quality_controls" ADD CONSTRAINT "quality_controls_finished_goods_id_fkey" FOREIGN KEY ("finished_goods_id") REFERENCES "finished_goods_inventory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quality_controls" ADD CONSTRAINT "quality_controls_inspector_id_fkey" FOREIGN KEY ("inspector_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quality_controls" ADD CONSTRAINT "quality_controls_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatches" ADD CONSTRAINT "dispatches_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatches" ADD CONSTRAINT "dispatches_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatches" ADD CONSTRAINT "dispatches_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatches" ADD CONSTRAINT "dispatches_approved_by_fkey" FOREIGN KEY ("approved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatch_items" ADD CONSTRAINT "dispatch_items_dispatch_id_fkey" FOREIGN KEY ("dispatch_id") REFERENCES "dispatches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "dispatch_items" ADD CONSTRAINT "dispatch_items_finished_goods_id_fkey" FOREIGN KEY ("finished_goods_id") REFERENCES "finished_goods_inventory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pelletizing_records" ADD CONSTRAINT "pelletizing_records_operator_id_fkey" FOREIGN KEY ("operator_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "machine_stops" ADD CONSTRAINT "machine_stops_machine_id_fkey" FOREIGN KEY ("machine_id") REFERENCES "machines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "machine_stops" ADD CONSTRAINT "machine_stops_production_record_id_fkey" FOREIGN KEY ("production_record_id") REFERENCES "production_records"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "machine_stops" ADD CONSTRAINT "machine_stops_reported_by_fkey" FOREIGN KEY ("reported_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "machine_stops" ADD CONSTRAINT "machine_stops_resolved_by_fkey" FOREIGN KEY ("resolved_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_related_machine_id_fkey" FOREIGN KEY ("related_machine_id") REFERENCES "machines"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tasks" ADD CONSTRAINT "tasks_related_order_id_fkey" FOREIGN KEY ("related_order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "plant_map_positions" ADD CONSTRAINT "plant_map_positions_machine_id_fkey" FOREIGN KEY ("machine_id") REFERENCES "machines"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "training_modules" ADD CONSTRAINT "training_modules_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "system_settings" ADD CONSTRAINT "system_settings_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
