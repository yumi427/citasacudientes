# CitasAcudientes

Sistema de gestión y asignación de citas para acudientes e instituciones educativas.

## 📌 Descripción

**CitasAcudientes** es una plataforma orientada a facilitar y organizar el proceso de atención a padres de familia y acudientes por parte del personal docente, orientadores y directivos docentes. Permite optimizar los tiempos de atención, evitar aglomeraciones y mantener un registro estructurado de cada encuentro.

---

## ✨ Características Principales

- **Gestión de Disponibilidad:** Los docentes y directivos pueden publicar sus franjas horarias habilitadas para atención a padres.
- **Reserva de Citas:** Los acudientes pueden consultar y reservar citas de acuerdo a la disponibilidad del docente y el grado del estudiante.
- **Notificaciones y Recordatorios:** Confirmación de citas y alertas previas a la reunión.
- **Historial y Seguimiento:** Registro de asistencia, observaciones y compromisos establecidos durante la sesión.
- **Roles y Permisos:** Soporte para administradores, docentes y acudientes.

---

## 🚀 Estructura del Proyecto

```text
citasacudientes/
├── src/               # Código fuente de la aplicación (Lambdas y Frontend)
├── docs/              # Documentación técnica y diagramas
│   ├── arquitectura.html # Diagrama interactivo de arquitectura AWS Serverless
│   └── ARQUITECTURA.md   # Especificación técnica detallada y modelo DynamoDB
├── tests/             # Pruebas unitarias y de integración
├── .gitignore         # Archivos y carpetas ignorados por git
└── README.md          # Documentación general del proyecto
```

---

## ☁️ Arquitectura AWS (100% Serverless con Cifrado E2E)

La solución utiliza una arquitectura totalmente Serverless, directa y síncrona (**sin DynamoDB Streams**), con protección de datos de grado bancario:

- **Cifrado en Tránsito:** Canales **TLS 1.3** forzados en todos los saltos (Móvil ↔ CloudFront, CloudFront ↔ S3, Móvil ↔ API Gateway, Lambda ↔ DynamoDB).
- **Cifrado en Reposo:** **AWS KMS** (Customer Managed Key) habilitado en el bucket S3 (SSE-KMS), tablas e índices de DynamoDB y variables de entorno de Lambda.
- **Frontend Móvil (PWA):** Alojado en **Amazon S3** (privado con OAC) y distribuido de forma ultra-rápida vía **Amazon CloudFront** con SSL.
- **API & Enrutamiento:** **Amazon API Gateway** para endpoints REST con validación JSON y control de tasa.
- **Lógica de Negocio:** Funciones **AWS Lambda** (Disponibilidad, Agendamiento Transaccional y Gestión de Citas).
- **Base de Datos:** **Amazon DynamoDB** (Single-Table Design con transacciones ACID directas `TransactWriteItems`).
- **Seguridad:** **AWS IAM** con principio de menor privilegio por función Lambda.

👉 **Explora el [Diagrama Interactivo de Arquitectura (HTML)](file:///C:/Users/Yoimer%20Barrera/ACME/citasacudientes/docs/arquitectura.html)** y la **[Especificación Técnica Completa](file:///C:/Users/Yoimer%20Barrera/ACME/citasacudientes/docs/ARQUITECTURA.md)**.

---

## ⚙️ Requisitos Previos

*(Adapta esta sección según la tecnología o stack a implementar: Node.js, Python, Java, PHP, etc.)*

- Control de versiones: [Git](https://git-scm.com/)
- Entorno de ejecución / SDK según el stack seleccionado.

---

## 🛠️ Puesta en Marcha

1. **Clonar o descargar el repositorio:**
   ```bash
   git clone <URL_DEL_REPOSITORIO>
   cd citasacudientes
   ```

2. **Configuración de variables de entorno:**
   Copia el archivo de ejemplo (cuando esté disponible):
   ```bash
   cp .env.example .env
   ```

3. **Instalación de dependencias:**
   *(Ejecuta el comando correspondiente al gestor de paquetes elegido)*

4. **Ejecutar en modo desarrollo:**
   *(Comando de inicio de desarrollo)*

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si deseas colaborar:
1. Haz un Fork del proyecto.
2. Crea una rama para tu funcionalidad (`git checkout -b feature/nueva-funcionalidad`).
3. Realiza tus cambios y haz commit (`git commit -m 'Agrega nueva funcionalidad'`).
4. Haz push a la rama (`git push origin feature/nueva-funcionalidad`).
5. Abre un Pull Request.

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.
