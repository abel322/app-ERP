const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
    console.log('Start seeding...');

    // 1. Roles
    const rolesData = [
        {
            name: 'Super Admin',
            description: 'Acceso total al sistema',
            permissions: { all: true },
            key: 'super_admin' // Mapping to enum
        },
        {
            name: 'Gerente de Producción',
            description: 'Gestión completa de producción',
            permissions: { production: 'full', reports: 'full', orders: 'full' },
            key: 'gerente_produccion'
        },
        {
            name: 'Supervisor de Área',
            description: 'Supervisión de área específica',
            permissions: { production: 'area', quality: 'full', reports: 'area' },
            key: 'supervisor_area'
        },
        {
            name: 'Operador de Máquina',
            description: 'Operación de máquinas',
            permissions: { production: 'register', machines: 'read' },
            key: 'operador_maquina'
        },
        {
            name: 'Almacenista',
            description: 'Gestión de inventarios',
            permissions: { inventory: 'full', dispatches: 'full' },
            key: 'almacenista'
        },
        {
            name: 'Vendedor',
            description: 'Gestión de ventas',
            permissions: { customers: 'full', orders: 'full', inventory: 'read' },
            key: 'vendedor'
        },
        {
            name: 'Control de Calidad',
            description: 'Control de calidad',
            permissions: { quality: 'full', production: 'read', reports: 'quality' },
            key: 'control_calidad'
        }
    ];

    for (const role of rolesData) {
        const existingRole = await prisma.role.findUnique({ where: { name: role.name } });
        if (!existingRole) {
            await prisma.role.create({
                data: {
                    name: role.name,
                    description: role.description,
                    permissions: role.permissions,
                },
            });
            console.log(`Created role: ${role.name}`);
        }
    }

    // 2. Super Admin User
    const adminEmail = 'admin@inverplastic.com';
    const existingAdmin = await prisma.user.findUnique({ where: { email: adminEmail } });

    if (!existingAdmin) {
        const hashedPassword = await bcrypt.hash('Admin123!', 10);

        // Find the role ID for Super Admin to link relation
        const superAdminRole = await prisma.role.findUnique({ where: { name: 'Super Admin' } });

        await prisma.user.create({
            data: {
                username: 'admin',
                email: adminEmail,
                password_hash: hashedPassword,
                full_name: 'Administrador del Sistema',
                role: 'super_admin', // Enum value
                role_id: superAdminRole ? superAdminRole.id : null,
                is_active: true,
            },
        });
        console.log(`Created admin user: ${adminEmail}`);
    }

    // 3. System Settings
    const settingsData = [
        { key: 'company_name', value: 'Inverplastic 79, C.A.', type: 'string', desc: 'Nombre de la empresa' },
        { key: 'company_tax_id', value: 'J-XXXXXXXX-X', type: 'string', desc: 'RIF de la empresa' },
        { key: 'default_tax_percentage', value: '16', type: 'number', desc: 'Porcentaje de IVA por defecto' },
        { key: 'min_waste_alert_percentage', value: '5', type: 'number', desc: 'Porcentaje mínimo de merma para generar alerta' },
        { key: 'oee_target', value: '75', type: 'number', desc: 'Objetivo de OEE (%)' },
        { key: 'backup_retention_days', value: '30', type: 'number', desc: 'Días de retención de backups' },
    ];

    for (const setting of settingsData) {
        const existingSetting = await prisma.systemSetting.findUnique({ where: { setting_key: setting.key } });
        if (!existingSetting) {
            await prisma.systemSetting.create({
                data: {
                    setting_key: setting.key,
                    setting_value: setting.value,
                    setting_type: setting.type,
                    description: setting.desc,
                },
            });
            console.log(`Created setting: ${setting.key}`);
        }
    }

    console.log('Seeding finished.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
