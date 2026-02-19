# Guía de Inicio Rápido

## Sistema ERP/MRP para Fabricación de Polietileno

Esta guía te ayudará a configurar el entorno de desarrollo y comenzar a trabajar en el proyecto.

---

## 📋 Prerrequisitos

### Software Requerido

- **Node.js** 
- **PostgreSQL** 
- **Git** 
- **Editor de Código:** VS Code (recomendado)

### Extensiones de VS Code Recomendadas

- ESLint
- Prettier
- PostgreSQL (ckolkman.vscode-postgres)
- Tailwind CSS IntelliSense
- ES7+ React/Redux/React-Native snippets

---

## 🚀 Configuración Inicial

### 1. Clonar el Repositorio

```bash
# Clonar el proyecto
git clone https://github.com/tu-empresa/erp-polietileno.git
cd erp-polietileno
```

### 2. Configurar Base de Datos

```bash
# Conectar a PostgreSQL
psql -U postgres

# Crear base de datos
CREATE DATABASE erp_polietileno;
CREATE USER erp_user WITH ENCRYPTED PASSWORD 'tu_password_seguro';
GRANT ALL PRIVILEGES ON DATABASE erp_polietileno TO erp_user;
\q

# Ejecutar migraciones
cd backend
psql -U erp_user -d erp_polietileno -f database/schema.sql
```

### 3. Configurar Backend

```bash
cd backend

# Instalar dependencias
npm install

# Crear archivo .env
cp .env.example .env

# Editar .env con tus configuraciones
nano .env
```

**Contenido de `.env`:**

```env
# Server
NODE_ENV=development
PORT=5000
API_VERSION=v1

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=erp_polietileno
DB_USER=erp_user
DB_PASSWORD=tu_password_seguro

# JWT
JWT_SECRET=tu_secret_key_muy_seguro_aqui_cambiar_en_produccion
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=http://localhost:5173

# Uploads
UPLOAD_DIR=./uploads
MAX_FILE_SIZE=10485760

# Email (opcional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tu_email@gmail.com
SMTP_PASSWORD=tu_password

# Logs
LOG_LEVEL=debug
```

### 4. Configurar Frontend

```bash
cd ../frontend

# Instalar dependencias
npm install

# Crear archivo .env
cp .env.example .env

# Editar .env
nano .env
```

**Contenido de `.env`:**

```env
VITE_API_URL=http://localhost:5000/api/v1
VITE_APP_NAME=ERP Polietileno
VITE_APP_VERSION=1.0.0
```

---

## 🏃 Ejecutar el Proyecto

### Opción 1: Desarrollo Local

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm run dev
```

Acceder a: `http://localhost:5173`

### Opción 2: Docker (Recomendado)

```bash
# En la raíz del proyecto
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener
docker-compose down
```

---

## 📁 Estructura del Proyecto

```
erp-polietileno/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   ├── controllers/
│   │   ├── middleware/
│   │   ├── models/
│   │   ├── routes/
│   │   ├── services/
│   │   ├── utils/
│   │   └── app.js
│   ├── database/
│   │   ├── migrations/
│   │   ├── seeders/
│   │   └── schema.sql
│   ├── tests/
│   ├── .env.example
│   ├── package.json
│   └── server.js
├── frontend/
│   ├── src/
│   │   ├── api/
│   │   ├── assets/
│   │   ├── components/
│   │   ├── contexts/
│   │   ├── hooks/
│   │   ├── pages/
│   │   ├── redux/
│   │   ├── routes/
│   │   ├── utils/
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── public/
│   ├── .env.example
│   ├── package.json
│   ├── vite.config.js
│   └── tailwind.config.js
├── docs/
├── docker-compose.yml
└── README.md
```

---

## 🔑 Credenciales por Defecto

**Usuario Administrador:**
- Username: `admin`
- Password: `Admin123!`

⚠️ **IMPORTANTE:** Cambiar estas credenciales inmediatamente en producción.

---

## 🧪 Ejecutar Tests

### Backend

```bash
cd backend

# Todos los tests
npm test

# Tests con cobertura
npm run test:coverage

# Tests en modo watch
npm run test:watch
```

### Frontend

```bash
cd frontend

# Tests unitarios
npm test

# Tests E2E
npm run test:e2e
```

---

## 📦 Scripts Disponibles

### Backend

| Script | Descripción |
|--------|-------------|
| `npm run dev` | Inicia servidor en modo desarrollo con nodemon |
| `npm start` | Inicia servidor en modo producción |
| `npm test` | Ejecuta tests |
| `npm run lint` | Ejecuta ESLint |
| `npm run format` | Formatea código con Prettier |
| `npm run migrate` | Ejecuta migraciones de BD |
| `npm run seed` | Ejecuta seeders |

### Frontend

| Script | Descripción |
|--------|-------------|
| `npm run dev` | Inicia servidor de desarrollo Vite |
| `npm run build` | Construye para producción |
| `npm run preview` | Preview del build de producción |
| `npm test` | Ejecuta tests |
| `npm run lint` | Ejecuta ESLint |
| `npm run format` | Formatea código con Prettier |

---

## 🔧 Configuración de Herramientas

### ESLint

**`.eslintrc.json` (Backend):**

```json
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": ["eslint:recommended"],
  "parserOptions": {
    "ecmaVersion": 12
  },
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "warn"
  }
}
```

**`.eslintrc.json` (Frontend):**

```json
{
  "env": {
    "browser": true,
    "es2021": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:react/recommended",
    "plugin:react-hooks/recommended"
  ],
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "rules": {
    "react/prop-types": "off",
    "react/react-in-jsx-scope": "off"
  }
}
```

### Prettier

**`.prettierrc`:**

```json
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
```

### Tailwind CSS

**`tailwind.config.js`:**

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#2563eb',
          600: '#1d4ed8',
          700: '#1e40af',
        },
        success: '#10b981',
        warning: '#f59e0b',
        danger: '#ef4444',
      },
    },
  },
  plugins: [],
}
```

---

## 🗄️ Seeders de Datos de Prueba

### Ejecutar Seeders

```bash
cd backend
npm run seed
```

Esto creará:
- 1 usuario administrador
- 5 clientes de ejemplo
- 10 productos de ejemplo
- 5 máquinas de ejemplo
- Datos de configuración

---

## 🐛 Debugging

### Backend (VS Code)

Crear `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Backend",
      "skipFiles": ["<node_internals>/**"],
      "program": "${workspaceFolder}/backend/server.js",
      "envFile": "${workspaceFolder}/backend/.env"
    }
  ]
}
```

### Frontend (Chrome DevTools)

1. Abrir Chrome DevTools (F12)
2. Ir a Sources
3. Buscar archivos en `webpack://`
4. Colocar breakpoints

---

## 📚 Recursos Adicionales

### Documentación

- [Arquitectura del Sistema](./ERP-MRP-POLIETILENO-ARCHITECTURE.md)
- [Esquema de Base de Datos](./DATABASE-SCHEMA.md)
- [Ejemplos de Código](./CODE-EXAMPLES.md)
- [API Documentation](http://localhost:5000/api-docs) (Swagger)

### Tutoriales

- [React Documentation](https://react.dev/)
- [Express.js Guide](https://expressjs.com/)
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [Tailwind CSS](https://tailwindcss.com/docs)

---

## ❓ Solución de Problemas Comunes

### Error: "Cannot connect to database"

**Solución:**
```bash
# Verificar que PostgreSQL esté corriendo
sudo systemctl status postgresql

# Verificar credenciales en .env
# Verificar que la base de datos exista
psql -U postgres -l
```

### Error: "Port 5000 already in use"

**Solución:**
```bash
# Cambiar puerto en backend/.env
PORT=5001

# O matar el proceso que usa el puerto
lsof -ti:5000 | xargs kill -9
```

### Error: "Module not found"

**Solución:**
```bash
# Reinstalar dependencias
rm -rf node_modules package-lock.json
npm install
```

### Error de CORS

**Solución:**
```javascript
// backend/src/app.js
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true
}));
```

---

## 🤝 Contribuir

### Flujo de Trabajo Git

```bash
# Crear rama para nueva feature
git checkout -b feature/nombre-feature

# Hacer commits
git add .
git commit -m "feat: descripción del cambio"

# Push a remoto
git push origin feature/nombre-feature

# Crear Pull Request en GitHub
```

### Convención de Commits

Seguir [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nueva funcionalidad
- `fix:` Corrección de bug
- `docs:` Cambios en documentación
- `style:` Cambios de formato
- `refactor:` Refactorización de código
- `test:` Agregar o modificar tests
- `chore:` Tareas de mantenimiento

---

## 📞 Soporte

Para preguntas o problemas:

1. Revisar la [documentación](./ERP-MRP-POLIETILENO-ARCHITECTURE.md)
2. Buscar en [Issues](https://github.com/tu-empresa/erp-polietileno/issues)
3. Crear un nuevo Issue si es necesario
4. Contactar al equipo de desarrollo

---

## ✅ Checklist de Configuración

- [ ] Node.js 18+ instalado
- [ ] PostgreSQL 15+ instalado
- [ ] Repositorio clonado
- [ ] Base de datos creada
- [ ] Backend configurado (.env)
- [ ] Frontend configurado (.env)
- [ ] Dependencias instaladas
- [ ] Migraciones ejecutadas
- [ ] Seeders ejecutados
- [ ] Backend corriendo en puerto 5000
- [ ] Frontend corriendo en puerto 5173
- [ ] Login exitoso con credenciales por defecto
- [ ] Tests pasando

---

**¡Listo para comenzar a desarrollar!** 🚀

**Última actualización:** 2026-02-14  
**Versión:** 1.0
