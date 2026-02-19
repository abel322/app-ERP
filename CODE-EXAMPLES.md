# Ejemplos de Código

## Sistema ERP/MRP para Fabricación de Polietileno

Este documento contiene ejemplos de código para los módulos principales del sistema.

---

## 📑 Tabla de Contenidos

1. [Backend Examples](#backend-examples)
   - [Configuración](#configuración-backend)
   - [Modelos](#modelos)
   - [Controladores](#controladores)
   - [Rutas](#rutas)
   - [Middleware](#middleware)
   - [Servicios](#servicios)
2. [Frontend Examples](#frontend-examples)
   - [Configuración](#configuración-frontend)
   - [Componentes](#componentes)
   - [Páginas](#páginas)
   - [Hooks](#hooks)
   - [Servicios API](#servicios-api)
3. [Utilidades](#utilidades)

---

## Backend Examples

### Configuración Backend

#### `src/config/database.js`

```javascript
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

pool.on('connect', () => {
  console.log('✅ Database connected successfully');
});

pool.on('error', (err) => {
  console.error('❌ Unexpected database error:', err);
  process.exit(-1);
});

module.exports = pool;
```

#### `src/config/jwt.js`

```javascript
require('dotenv').config();

module.exports = {
  secret: process.env.JWT_SECRET,
  expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
};
```

---

### Modelos

#### `src/models/User.js`

```javascript
const pool = require('../config/database');
const bcrypt = require('bcrypt');

class User {
  static async findAll(filters = {}) {
    const { role, is_active, search, limit = 50, offset = 0 } = filters;
    
    let query = 'SELECT id, username, email, full_name, role, is_active, created_at FROM users WHERE 1=1';
    const params = [];
    let paramCount = 1;

    if (role) {
      query += ` AND role = $${paramCount}`;
      params.push(role);
      paramCount++;
    }

    if (is_active !== undefined) {
      query += ` AND is_active = $${paramCount}`;
      params.push(is_active);
      paramCount++;
    }

    if (search) {
      query += ` AND (full_name ILIKE $${paramCount} OR username ILIKE $${paramCount} OR email ILIKE $${paramCount})`;
      params.push(`%${search}%`);
      paramCount++;
    }

    query += ` ORDER BY created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);
    return result.rows;
  }

  static async findById(id) {
    const result = await pool.query(
      'SELECT id, username, email, full_name, role, is_active, created_at FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0];
  }

  static async findByUsername(username) {
    const result = await pool.query(
      'SELECT * FROM users WHERE username = $1',
      [username]
    );
    return result.rows[0];
  }

  static async findByEmail(email) {
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email]
    );
    return result.rows[0];
  }

  static async create(userData) {
    const { username, email, password, full_name, role } = userData;
    const password_hash = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (username, email, password_hash, full_name, role) 
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id, username, email, full_name, role, is_active, created_at`,
      [username, email, password_hash, full_name, role]
    );

    return result.rows[0];
  }

  static async update(id, userData) {
    const fields = [];
    const values = [];
    let paramCount = 1;

    Object.keys(userData).forEach((key) => {
      if (userData[key] !== undefined && key !== 'password') {
        fields.push(`${key} = $${paramCount}`);
        values.push(userData[key]);
        paramCount++;
      }
    });

    if (userData.password) {
      const password_hash = await bcrypt.hash(userData.password, 10);
      fields.push(`password_hash = $${paramCount}`);
      values.push(password_hash);
      paramCount++;
    }

    values.push(id);

    const result = await pool.query(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramCount} 
       RETURNING id, username, email, full_name, role, is_active, updated_at`,
      values
    );

    return result.rows[0];
  }

  static async delete(id) {
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async updateLastLogin(id) {
    await pool.query('UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1', [id]);
  }
}

module.exports = User;
```

#### `src/models/ProductionRecord.js`

```javascript
const pool = require('../config/database');

class ProductionRecord {
  static async create(data) {
    const {
      production_order_id,
      machine_id,
      area,
      production_date,
      shift,
      shift_start,
      shift_end,
      produced_quantity_kg,
      produced_quantity_units,
      waste_quantity_kg,
      operation_time_hours,
      downtime_hours,
      machine_parameters,
      operator_id,
      supervisor_id,
      notes,
    } = data;

    const result = await pool.query(
      `INSERT INTO production_records (
        production_order_id, machine_id, area, production_date, shift,
        shift_start, shift_end, produced_quantity_kg, produced_quantity_units,
        waste_quantity_kg, operation_time_hours, downtime_hours,
        machine_parameters, operator_id, supervisor_id, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *`,
      [
        production_order_id, machine_id, area, production_date, shift,
        shift_start, shift_end, produced_quantity_kg, produced_quantity_units,
        waste_quantity_kg, operation_time_hours, downtime_hours,
        JSON.stringify(machine_parameters), operator_id, supervisor_id, notes,
      ]
    );

    return result.rows[0];
  }

  static async calculateMetrics(id) {
    // Obtener el registro
    const record = await this.findById(id);
    if (!record) throw new Error('Production record not found');

    // Obtener velocidad estándar de la máquina
    const machineResult = await pool.query(
      'SELECT standard_speed FROM machines WHERE id = $1',
      [record.machine_id]
    );
    const standardSpeed = machineResult.rows[0].standard_speed;

    // Calcular métricas
    const totalProduced = parseFloat(record.produced_quantity_kg) + parseFloat(record.waste_quantity_kg);
    const wastePercentage = (parseFloat(record.waste_quantity_kg) / totalProduced) * 100;

    // Disponibilidad = (Tiempo Operación / Tiempo Planificado) * 100
    const plannedTime = parseFloat(record.operation_time_hours) + parseFloat(record.downtime_hours);
    const availability = (parseFloat(record.operation_time_hours) / plannedTime) * 100;

    // Rendimiento = (Producción Real / Producción Teórica) * 100
    const theoreticalProduction = standardSpeed * parseFloat(record.operation_time_hours);
    const performance = (parseFloat(record.produced_quantity_kg) / theoreticalProduction) * 100;

    // Calidad = (Unidades Conformes / Unidades Totales) * 100
    const quality = (parseFloat(record.produced_quantity_kg) / totalProduced) * 100;

    // OEE = Disponibilidad * Rendimiento * Calidad / 10000
    const oee = (availability * performance * quality) / 10000;

    // Actualizar registro
    await pool.query(
      `UPDATE production_records 
       SET waste_percentage = $1, machine_efficiency = $2, 
           performance_rate = $3, quality_rate = $4, oee = $5
       WHERE id = $6`,
      [
        wastePercentage.toFixed(2),
        availability.toFixed(2),
        performance.toFixed(2),
        quality.toFixed(2),
        oee.toFixed(2),
        id,
      ]
    );

    return {
      waste_percentage: wastePercentage.toFixed(2),
      availability: availability.toFixed(2),
      performance: performance.toFixed(2),
      quality: quality.toFixed(2),
      oee: oee.toFixed(2),
    };
  }

  static async findById(id) {
    const result = await pool.query(
      `SELECT pr.*, 
              m.name as machine_name, 
              p.name as product_name,
              u.full_name as operator_name
       FROM production_records pr
       LEFT JOIN machines m ON pr.machine_id = m.id
       LEFT JOIN production_orders po ON pr.production_order_id = po.id
       LEFT JOIN products p ON po.product_id = p.id
       LEFT JOIN users u ON pr.operator_id = u.id
       WHERE pr.id = $1`,
      [id]
    );
    return result.rows[0];
  }

  static async findByDateRange(startDate, endDate, filters = {}) {
    const { area, machine_id, operator_id } = filters;
    
    let query = `
      SELECT pr.*, 
             m.name as machine_name, 
             p.name as product_name,
             u.full_name as operator_name
      FROM production_records pr
      LEFT JOIN machines m ON pr.machine_id = m.id
      LEFT JOIN production_orders po ON pr.production_order_id = po.id
      LEFT JOIN products p ON po.product_id = p.id
      LEFT JOIN users u ON pr.operator_id = u.id
      WHERE pr.production_date BETWEEN $1 AND $2
    `;
    
    const params = [startDate, endDate];
    let paramCount = 3;

    if (area) {
      query += ` AND pr.area = $${paramCount}`;
      params.push(area);
      paramCount++;
    }

    if (machine_id) {
      query += ` AND pr.machine_id = $${paramCount}`;
      params.push(machine_id);
      paramCount++;
    }

    if (operator_id) {
      query += ` AND pr.operator_id = $${paramCount}`;
      params.push(operator_id);
      paramCount++;
    }

    query += ' ORDER BY pr.production_date DESC, pr.shift_start DESC';

    const result = await pool.query(query, params);
    return result.rows;
  }
}

module.exports = ProductionRecord;
```

---

### Controladores

#### `src/controllers/authController.js`

```javascript
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const jwtConfig = require('../config/jwt');

class AuthController {
  static async login(req, res) {
    try {
      const { username, password } = req.body;

      // Validar entrada
      if (!username || !password) {
        return res.status(400).json({
          success: false,
          message: 'Username and password are required',
        });
      }

      // Buscar usuario
      const user = await User.findByUsername(username);
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
        });
      }

      // Verificar si está activo
      if (!user.is_active) {
        return res.status(403).json({
          success: false,
          message: 'User account is disabled',
        });
      }

      // Verificar contraseña
      const isValidPassword = await User.verifyPassword(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          message: 'Invalid credentials',
        });
      }

      // Generar tokens
      const accessToken = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        jwtConfig.secret,
        { expiresIn: jwtConfig.expiresIn }
      );

      const refreshToken = jwt.sign(
        { id: user.id },
        jwtConfig.secret,
        { expiresIn: jwtConfig.refreshExpiresIn }
      );

      // Actualizar último login
      await User.updateLastLogin(user.id);

      // Responder
      res.json({
        success: true,
        data: {
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
            full_name: user.full_name,
            role: user.role,
          },
          accessToken,
          refreshToken,
        },
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token is required',
        });
      }

      // Verificar refresh token
      const decoded = jwt.verify(refreshToken, jwtConfig.secret);

      // Buscar usuario
      const user = await User.findById(decoded.id);
      if (!user || !user.is_active) {
        return res.status(403).json({
          success: false,
          message: 'Invalid refresh token',
        });
      }

      // Generar nuevo access token
      const accessToken = jwt.sign(
        { id: user.id, username: user.username, role: user.role },
        jwtConfig.secret,
        { expiresIn: jwtConfig.expiresIn }
      );

      res.json({
        success: true,
        data: { accessToken },
      });
    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(403).json({
        success: false,
        message: 'Invalid or expired refresh token',
      });
    }
  }

  static async me(req, res) {
    try {
      const user = await User.findById(req.user.id);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
        });
      }

      res.json({
        success: true,
        data: {
          id: user.id,
          username: user.username,
          email: user.email,
          full_name: user.full_name,
          role: user.role,
          is_active: user.is_active,
        },
      });
    } catch (error) {
      console.error('Get user error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }
}

module.exports = AuthController;
```

#### `src/controllers/productionController.js`

```javascript
const ProductionRecord = require('../models/ProductionRecord');
const MaterialConsumption = require('../models/MaterialConsumption');

class ProductionController {
  static async createRecord(req, res) {
    try {
      const data = req.body;
      data.operator_id = req.user.id; // Usuario autenticado

      // Crear registro de producción
      const record = await ProductionRecord.create(data);

      // Calcular métricas automáticamente
      const metrics = await ProductionRecord.calculateMetrics(record.id);

      // Registrar consumo de materiales si se proporciona
      if (data.materials && Array.isArray(data.materials)) {
        for (const material of data.materials) {
          await MaterialConsumption.create({
            production_record_id: record.id,
            material_id: material.material_id,
            quantity_consumed: material.quantity,
            batch_number: material.batch_number,
          });
        }
      }

      res.status(201).json({
        success: true,
        data: { ...record, metrics },
        message: 'Production record created successfully',
      });
    } catch (error) {
      console.error('Create production record error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Internal server error',
      });
    }
  }

  static async getRecords(req, res) {
    try {
      const { start_date, end_date, area, machine_id, operator_id } = req.query;

      const records = await ProductionRecord.findByDateRange(
        start_date || new Date().toISOString().split('T')[0],
        end_date || new Date().toISOString().split('T')[0],
        { area, machine_id, operator_id }
      );

      res.json({
        success: true,
        data: records,
        count: records.length,
      });
    } catch (error) {
      console.error('Get production records error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async getRecordById(req, res) {
    try {
      const { id } = req.params;
      const record = await ProductionRecord.findById(id);

      if (!record) {
        return res.status(404).json({
          success: false,
          message: 'Production record not found',
        });
      }

      res.json({
        success: true,
        data: record,
      });
    } catch (error) {
      console.error('Get production record error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error',
      });
    }
  }

  static async recalculateMetrics(req, res) {
    try {
      const { id } = req.params;
      const metrics = await ProductionRecord.calculateMetrics(id);

      res.json({
        success: true,
        data: metrics,
        message: 'Metrics recalculated successfully',
      });
    } catch (error) {
      console.error('Recalculate metrics error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Internal server error',
      });
    }
  }
}

module.exports = ProductionController;
```

---

### Rutas

#### `src/routes/authRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const AuthController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/login', AuthController.login);
router.post('/refresh-token', AuthController.refreshToken);
router.get('/me', authMiddleware, AuthController.me);

module.exports = router;
```

#### `src/routes/productionRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const ProductionController = require('../controllers/productionController');
const authMiddleware = require('../middleware/authMiddleware');
const roleMiddleware = require('../middleware/roleMiddleware');

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Crear registro de producción (operadores y superiores)
router.post(
  '/records',
  roleMiddleware(['operador_maquina', 'supervisor_area', 'gerente_produccion', 'super_admin']),
  ProductionController.createRecord
);

// Obtener registros
router.get('/records', ProductionController.getRecords);

// Obtener registro específico
router.get('/records/:id', ProductionController.getRecordById);

// Recalcular métricas
router.post(
  '/records/:id/recalculate-metrics',
  roleMiddleware(['supervisor_area', 'gerente_produccion', 'super_admin']),
  ProductionController.recalculateMetrics
);

module.exports = router;
```

---

### Middleware

#### `src/middleware/authMiddleware.js`

```javascript
const jwt = require('jsonwebtoken');
const jwtConfig = require('../config/jwt');

module.exports = (req, res, next) => {
  try {
    // Obtener token del header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided',
      });
    }

    const token = authHeader.substring(7); // Remover 'Bearer '

    // Verificar token
    const decoded = jwt.verify(token, jwtConfig.secret);

    // Agregar usuario al request
    req.user = decoded;

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expired',
      });
    }

    return res.status(401).json({
      success: false,
      message: 'Invalid token',
    });
  }
};
```

#### `src/middleware/roleMiddleware.js`

```javascript
module.exports = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Unauthorized',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: 'Insufficient permissions',
      });
    }

    next();
  };
};
```

---

### Servicios

#### `src/services/calculationService.js`

```javascript
class CalculationService {
  /**
   * Calcula el OEE (Overall Equipment Effectiveness)
   * @param {number} availability - Disponibilidad (%)
   * @param {number} performance - Rendimiento (%)
   * @param {number} quality - Calidad (%)
   * @returns {number} OEE (%)
   */
  static calculateOEE(availability, performance, quality) {
    return (availability * performance * quality) / 10000;
  }

  /**
   * Calcula el porcentaje de merma
   * @param {number} waste - Desperdicio (kg)
   * @param {number} produced - Producido (kg)
   * @returns {number} Porcentaje de merma
   */
  static calculateWastePercentage(waste, produced) {
    const total = waste + produced;
    if (total === 0) return 0;
    return (waste / total) * 100;
  }

  /**
   * Calcula el rendimiento de máquina
   * @param {number} actualProduction - Producción real (kg)
   * @param {number} operationTime - Tiempo de operación (horas)
   * @param {number} standardSpeed - Velocidad estándar (kg/hora)
   * @returns {number} Rendimiento (%)
   */
  static calculateMachineEfficiency(actualProduction, operationTime, standardSpeed) {
    const theoreticalProduction = operationTime * standardSpeed;
    if (theoreticalProduction === 0) return 0;
    return (actualProduction / theoreticalProduction) * 100;
  }

  /**
   * Calcula el consumo teórico de materia prima
   * @param {number} producedKg - Kg producidos
   * @param {number} historicalWastePercentage - % de merma histórico
   * @returns {number} Consumo teórico (kg)
   */
  static calculateTheoreticalConsumption(producedKg, historicalWastePercentage) {
    return producedKg / (1 - historicalWastePercentage / 100);
  }

  /**
   * Calcula la variación de consumo
   * @param {number} actualConsumption - Consumo real
   * @param {number} theoreticalConsumption - Consumo teórico
   * @returns {number} Variación (%)
   */
  static calculateConsumptionVariance(actualConsumption, theoreticalConsumption) {
    if (theoreticalConsumption === 0) return 0;
    return ((actualConsumption - theoreticalConsumption) / theoreticalConsumption) * 100;
  }
}

module.exports = CalculationService;
```

---

## Frontend Examples

### Configuración Frontend

#### `src/api/axios.config.js`

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000/api/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // Si el token expiró, intentar refrescarlo
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        const refreshToken = localStorage.getItem('refreshToken');
        const response = await axios.post(
          `${import.meta.env.VITE_API_URL}/auth/refresh-token`,
          { refreshToken }
        );

        const { accessToken } = response.data.data;
        localStorage.setItem('accessToken', accessToken);

        originalRequest.headers.Authorization = `Bearer ${accessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        // Si falla el refresh, redirigir al login
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default api;
```

---

### Componentes

#### `src/components/common/Table.jsx`

```jsx
import React, { useState } from 'react';
import { ChevronUpIcon, ChevronDownIcon } from '@heroicons/react/24/outline';

const Table = ({ columns, data, onRowClick, loading = false }) => {
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
  };

  const sortedData = React.useMemo(() => {
    if (!sortConfig.key) return data;

    return [...data].sort((a, b) => {
      const aValue = a[sortConfig.key];
      const bValue = b[sortConfig.key];

      if (aValue < bValue) {
        return sortConfig.direction === 'asc' ? -1 : 1;
      }
      if (aValue > bValue) {
        return sortConfig.direction === 'asc' ? 1 : -1;
      }
      return 0;
    });
  }, [data, sortConfig]);

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100"
                onClick={() => column.sortable && handleSort(column.key)}
              >
                <div className="flex items-center space-x-1">
                  <span>{column.label}</span>
                  {column.sortable && (
                    <span className="ml-2">
                      {sortConfig.key === column.key ? (
                        sortConfig.direction === 'asc' ? (
                          <ChevronUpIcon className="h-4 w-4" />
                        ) : (
                          <ChevronDownIcon className="h-4 w-4" />
                        )
                      ) : (
                        <ChevronUpIcon className="h-4 w-4 text-gray-300" />
                      )}
                    </span>
                  )}
                </div>
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {sortedData.map((row, index) => (
            <tr
              key={index}
              onClick={() => onRowClick && onRowClick(row)}
              className={onRowClick ? 'hover:bg-gray-50 cursor-pointer' : ''}
            >
              {columns.map((column) => (
                <td key={column.key} className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {column.render ? column.render(row[column.key], row) : row[column.key]}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
      {sortedData.length === 0 && (
        <div className="text-center py-12 text-gray-500">No hay datos para mostrar</div>
      )}
    </div>
  );
};

export default Table;
```

#### `src/components/dashboard/KPICard.jsx`

```jsx
import React from 'react';
import { ArrowUpIcon, ArrowDownIcon } from '@heroicons/react/24/solid';

const KPICard = ({ title, value, unit, trend, trendValue, icon: Icon, color = 'blue' }) => {
  const colorClasses = {
    blue: 'bg-blue-500',
    green: 'bg-green-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
  };

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <div className="mt-2 flex items-baseline">
            <p className="text-3xl font-semibold text-gray-900">{value}</p>
            {unit && <span className="ml-2 text-sm text-gray-500">{unit}</span>}
          </div>
          {trend && (
            <div className="mt-2 flex items-center">
              {trend === 'up' ? (
                <ArrowUpIcon className="h-4 w-4 text-green-500" />
              ) : (
                <ArrowDownIcon className="h-4 w-4 text-red-500" />
              )}
              <span
                className={`ml-1 text-sm font-medium ${
                  trend === 'up' ? 'text-green-600' : 'text-red-600'
                }`}
              >
                {trendValue}%
              </span>
              <span className="ml-2 text-sm text-gray-500">vs mes anterior</span>
            </div>
          )}
        </div>
        {Icon && (
          <div className={`${colorClasses[color]} rounded-full p-3`}>
            <Icon className="h-6 w-6 text-white" />
          </div>
        )}
      </div>
    </div>
  );
};

export default KPICard;
```

---

### Páginas

#### `src/pages/dashboard/Dashboard.jsx`

```jsx
import React, { useState, useEffect } from 'react';
import KPICard from '../../components/dashboard/KPICard';
import ProductionChart from '../../components/dashboard/ProductionChart';
import MachineStatusGrid from '../../components/dashboard/MachineStatusGrid';
import { dashboardService } from '../../api/services/dashboardService';
import {
  ChartBarIcon,
  CogIcon,
  ExclamationTriangleIcon,
  CubeIcon,
} from '@heroicons/react/24/outline';

const Dashboard = () => {
  const [kpis, setKpis] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const data = await dashboardService.getKPIs();
      setKpis(data);
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-primary-500"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard Industrial</h1>
        <p className="mt-1 text-sm text-gray-500">
          Resumen de producción y métricas clave
        </p>
      </div>

      {/* KPIs */}
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard
          title="OEE Global"
          value={kpis?.oee || 0}
          unit="%"
          trend="up"
          trendValue={2.5}
          icon={ChartBarIcon}
          color="blue"
        />
        <KPICard
          title="Producción Hoy"
          value={kpis?.production_today || 0}
          unit="kg"
          trend="up"
          trendValue={5.2}
          icon={CubeIcon}
          color="green"
        />
        <KPICard
          title="Eficiencia Promedio"
          value={kpis?.avg_efficiency || 0}
          unit="%"
          trend="down"
          trendValue={1.3}
          icon={CogIcon}
          color="yellow"
        />
        <KPICard
          title="Merma Promedio"
          value={kpis?.avg_waste || 0}
          unit="%"
          icon={ExclamationTriangleIcon}
          color="red"
        />
      </div>

      {/* Gráficos */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <ProductionChart />
        <MachineStatusGrid />
      </div>
    </div>
  );
};

export default Dashboard;
```

---

### Hooks

#### `src/hooks/useTable.js`

```javascript
import { useState, useCallback } from 'react';

export const useTable = (initialData = []) => {
  const [data, setData] = useState(initialData);
  const [filters, setFilters] = useState({});
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 10,
    total: 0,
  });
  const [loading, setLoading] = useState(false);

  const updateFilters = useCallback((newFilters) => {
    setFilters((prev) => ({ ...prev, ...newFilters }));
    setPagination((prev) => ({ ...prev, page: 1 })); // Reset to first page
  }, []);

  const changePage = useCallback((newPage) => {
    setPagination((prev) => ({ ...prev, page: newPage }));
  }, []);

  const changeLimit = useCallback((newLimit) => {
    setPagination((prev) => ({ ...prev, limit: newLimit, page: 1 }));
  }, []);

  return {
    data,
    setData,
    filters,
    updateFilters,
    pagination,
    changePage,
    changeLimit,
    loading,
    setLoading,
  };
};
```

---

### Servicios API

#### `src/api/services/dashboardService.js`

```javascript
import api from '../axios.config';

export const dashboardService = {
  getKPIs: async () => {
    const response = await api.get('/dashboard/kpis');
    return response.data.data;
  },

  getProductionSummary: async (startDate, endDate) => {
    const response = await api.get('/dashboard/production-summary', {
      params: { start_date: startDate, end_date: endDate },
    });
    return response.data.data;
  },

  getMachineStatus: async () => {
    const response = await api.get('/dashboard/machine-status');
    return response.data.data;
  },

  getInventoryAlerts: async () => {
    const response = await api.get('/dashboard/inventory-alerts');
    return response.data.data;
  },
};
```

---

## Utilidades

### `src/utils/calculations.js`

```javascript
/**
 * Formatea un número como porcentaje
 */
export const formatPercentage = (value, decimals = 2) => {
  return `${parseFloat(value).toFixed(decimals)}%`;
};

/**
 * Formatea un número con separadores de miles
 */
export const formatNumber = (value, decimals = 2) => {
  return parseFloat(value).toLocaleString('es-VE', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
};

/**
 * Calcula el OEE
 */
export const calculateOEE = (availability, performance, quality) => {
  return (availability * performance * quality) / 10000;
};

/**
 * Determina el color según el valor de OEE
 */
export const getOEEColor = (oee) => {
  if (oee >= 85) return 'text-green-600';
  if (oee >= 75) return 'text-yellow-600';
  return 'text-red-600';
};

/**
 * Formatea una fecha
 */
export const formatDate = (date, format = 'short') => {
  const d = new Date(date);
  
  if (format === 'short') {
    return d.toLocaleDateString('es-VE');
  }
  
  if (format === 'long') {
    return d.toLocaleDateString('es-VE', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }
  
  if (format === 'datetime') {
    return d.toLocaleString('es-VE');
  }
  
  return d.toISOString();
};
```

---

**Última actualización:** 2026-02-14  
**Versión:** 1.0
