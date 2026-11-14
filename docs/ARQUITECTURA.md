# 📐 Arquitectura 100% Serverless en AWS - CitasAcudientes

Plataforma móvil diseñada para instituciones educativas, orientada a la gestión de citas entre **acudientes** (quienes solicitan la atención) y **docentes** (quienes atienden la cita).

---

## 🌟 Componentes de la Arquitectura AWS

| Servicio AWS | Propósito en la Plataforma |
| :--- | :--- |
| **Amazon S3** | Alojamiento de los activos estáticos del frontend móvil (SPA / PWA: HTML, CSS, JS e íconos). Bloqueo de acceso público activado. |
| **Amazon CloudFront** | Red de entrega de contenido (CDN) con cifrado SSL/TLS (HTTPS), caché perimetral para teléfonos móviles y Origin Access Control (OAC) hacia S3. |
| **Amazon API Gateway** | Punto de entrada seguro para la API REST. Gestiona validación de esquemas JSON, control de tasa (throttling), CORS y autenticación mediante JWT Authorizer. |
| **AWS Lambda** | Cómputo serverless sin servidor para la lógica de negocio (consultar disponibilidad, agendar citas de forma transaccional, gestionar estados de citas y actas). |
| **Amazon DynamoDB** | Base de datos NoSQL con modo On-Demand. Implementa *Single-Table Design* y transacciones ACID (`TransactWriteItems`) para prevenir reservas duplicadas. |
| **AWS IAM** | Seguridad transversal con políticas de menor privilegio por función Lambda y roles de ejecución específicos. |

---

## 📱 Diagrama Interactivo en HTML

Se ha generado un diagrama interactivo completo que puedes visualizar en tu navegador:
👉 **[Ver Diagrama de Arquitectura (HTML)](file:///C:/Users/Yoimer%20Barrera/ACME/citasacudientes/docs/arquitectura.html)**

### Funcionalidades del diagrama:
1. **Filtro por Actor:** Alterna entre el flujo del **Acudiente** (reserva de citas desde el celular), el flujo del **Docente** (publicación de horarios y registro de compromisos), o la **Arquitectura Completa**.
2. **Detalles Interactivos:** Haz clic sobre cualquier servicio o tarjeta para desplegar su configuración técnica, modelo de datos y políticas IAM de menor privilegio.

---

## 🔄 Flujo de Trabajo

### 1. Flujo del Acudiente (Reserva Móvil)
1. El acudiente abre la aplicación PWA en su celular (cargada a alta velocidad vía **CloudFront** desde **S3**).
2. Consulta el directorio de profesores y sus franjas disponibles:
   - `GET /disponibilidad?profesorId=...&fecha=...` → **API Gateway** → **Lambda Disponibilidad** → **DynamoDB Query**.
3. Selecciona una franja y envía la solicitud:
   - `POST /citas` → **API Gateway** → **Lambda Agendar Cita**.
4. La función **Lambda Agendar Cita** ejecuta un `TransactWriteItems` en **DynamoDB**:
   - Inserta la cita con estado `SOLICITADA`.
   - Modifica el estado de la franja horaria a `OCUPADA` con una condición atómica: si otro acudiente reservó al mismo tiempo, la transacción falla y se le notifica inmediatamente para elegir otro horario.

### 2. Flujo del Docente (Gestión y Atención)
1. El profesor ingresa desde su celular y publica sus franjas de atención semanal:
   - `POST /disponibilidad` → **API Gateway** → **Lambda Disponibilidad** → **DynamoDB PutItem**.
2. Recibe y revisa las citas solicitadas por acudientes:
   - `GET /citas?estado=SOLICITADA` → **Lambda Gestión Citas**.
3. Confirma o reprograma la reunión (`PATCH /citas/{id}`).
4. Durante o después de la reunión, registra las observaciones y compromisos pedagógicos acordados.

---

## 🗄️ Modelo de Datos en DynamoDB (Single-Table Design)

Nombre de la tabla: **`CitasAcudientesTable`** (Billing Mode: `PAY_PER_REQUEST`).

| Entidad | Partition Key (`PK`) | Sort Key (`SK`) | Atributos Principales |
| :--- | :--- | :--- | :--- |
| **Docente** | `DOCENTE#<id>` | `METADATA` | Nombre, Asignatura, Grados, Email |
| **Disponibilidad** | `DOCENTE#<id>` | `SLOT#<fecha>#<hora>` | Estado (`LIBRE`/`RESERVADO`), Aula, Modalidad |
| **Cita** | `CITA#<id>` | `METADATA` | DocenteId, AcudienteId, Estudiante, Fecha, Hora, Estado, Compromisos |
| **Acudiente** | `ACUDIENTE#<id>` | `METADATA` | Nombre, Teléfono, Estudiantes Asociados |

### Índices Secundarios Globales (GSI):
- **`GSI1` (Consultas por Acudiente):**
  - Partition Key: `GSI1_PK = ACUDIENTE#<id>`
  - Sort Key: `GSI1_SK = FECHA#<timestamp>`
  - *Permite al acudiente ver su historial cronológico de citas.*

- **`GSI2` (Consultas por Estado/Fecha para Coordinación):**
  - Partition Key: `GSI2_PK = ESTADO#<estado>`
  - Sort Key: `GSI2_SK = FECHA#<timestamp>`
  - *Permite monitorear citas pendientes de atención.*

---

## 🔐 Seguridad y Políticas IAM (Mínimo Privilegio)

Cada función Lambda posee un rol exclusivo:
- **`LambdaBookingRole`**: Únicamente con permiso `dynamodb:TransactWriteItems` y `dynamodb:PutItem` sobre `CitasAcudientesTable`.
- **`LambdaReadRole`**: Únicamente con permiso `dynamodb:Query` y `dynamodb:GetItem`.
- **`S3OriginAccessControl (OAC)`**: El bucket S3 rechaza cualquier conexión pública externa; solo responde a solicitudes firmadas por la distribución CloudFront designada.
