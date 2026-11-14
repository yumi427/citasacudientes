# 🛠️ Infraestructura como Código (IaC) con Terraform - CitasAcudientes

Este módulo de Terraform despliega la arquitectura 100% Serverless de **CitasAcudientes** en AWS, con cifrado en reposo y en tránsito de extremo a extremo y sin DynamoDB Streams.

---

## 📁 Estructura del Código Terraform

```text
terraform/
├── versions.tf               # Versión de Terraform y configuración del proveedor AWS
├── variables.tf              # Definición de variables parametrizables
├── terraform.tfvars.example  # Ejemplo de valores para variables
├── kms.tf                    # Clave KMS CMK para cifrado en reposo (S3, DynamoDB, Lambda)
├── s3_cloudfront.tf          # Bucket S3 privado + CloudFront CDN + OAC + TLS 1.3
├── dynamodb.tf               # Tabla NoSQL Single-Table (On-Demand, GSI1, GSI2, SSE-KMS)
├── iam.tf                    # Roles y políticas IAM bajo principio de menor privilegio
├── lambda.tf                 # Empaquetado y definición de Lambdas Python 3.12 + Logs KMS
├── api_gateway.tf            # HTTP API REST + CORS + Rutas + Permisos de invocación
├── outputs.tf                # URLs generadas (CloudFront, API Gateway, DynamoDB, KMS)
└── README.md                 # Guía de despliegue y administración
```

---

## ⚙️ Recursos Desplegados

1. **Seguridad y Criptografía:**
   * `aws_kms_key` & `aws_kms_alias`: Clave administrada por el cliente (CMK) con rotación automática anual.
   * `aws_iam_role` & `aws_iam_role_policy`: 3 roles independientes para cada función Lambda con acceso mínimo necesario.

2. **Frontend & Edge:**
   * `aws_s3_bucket`: Bucket privado con bloqueo de acceso público y cifrado SSE-KMS.
   * `aws_cloudfront_origin_access_control`: Control de acceso criptográfico SigV4 hacia S3.
   * `aws_cloudfront_distribution`: CDN con redirección forzosa a HTTPS (TLS 1.3) y reescritura de rutas para Single Page Application (SPA).
   * `aws_s3_bucket_policy`: Denegación explícita de peticiones HTTP no seguras (`aws:SecureTransport: false`).

3. **Base de Datos NoSQL:**
   * `aws_dynamodb_table`: `CitasAcudientesTable` con facturación On-Demand, clave compuesta (`PK`, `SK`), índices `GSI1` y `GSI2`, cifrado KMS y Point-in-Time Recovery (PITR).

4. **Cómputo Serverless (Microservicios en Python 3.12):**
   * `citasacudientes-disponibilidad`: Gestión de horarios de docentes.
   * `citasacudientes-agendar-cita`: Transacciones atómicas ACID anti-sobrecupo (`TransactWriteItems`).
   * `citasacudientes-gestion-citas`: Consultas, confirmaciones y compromisos de citas.
   * `aws_cloudwatch_log_group`: Grupos de logs cifrados con la clave KMS.

5. **API & Enrutamiento:**
   * `aws_apigatewayv2_api`: API Gateway HTTP síncrono de baja latencia con CORS móvil.
   * Rutas expuestas:
     * `GET /disponibilidad`
     * `POST /disponibilidad`
     * `POST /citas`
     * `GET /citas`
     * `GET /citas/{id}`
     * `PATCH /citas/{id}`

---

## 🚀 Guía de Despliegue

### 1. Requisitos Previos
* [Terraform](https://developer.hashicorp.com/terraform/install) (v1.5+)
* [AWS CLI](https://aws.amazon.com/cli/) instalado y autenticado (`aws configure`) con permisos de administrador en la cuenta.

### 2. Configurar Parámetros
Copia el archivo de variables de ejemplo:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edita `terraform.tfvars` con la región y ambiente deseados:
```hcl
aws_region                = "us-east-1"
project_name              = "citasacudientes"
environment               = "prod"
lambda_log_retention_days = 14
```

### 3. Inicializar y Planificar
```bash
# Inicializar los proveedores (AWS y Archive)
terraform init

# Generar y revisar el plan de ejecución
terraform plan
```

### 4. Desplegar Infraestructura
```bash
terraform apply
```
*(Escribe `yes` cuando te solicite confirmación).*

---

## 📤 Resultados de Salida (Outputs)

Al finalizar el despliegue, Terraform mostrará en consola:

* `cloudfront_domain_name`: URL pública con HTTPS de la aplicación móvil PWA.
* `api_gateway_endpoint`: URL base de la API REST para conectar el frontend móvil.
* `s3_frontend_bucket_name`: Nombre del bucket S3 para sincronizar los archivos estáticos (`aws s3 sync dist/ s3://<bucket>`).
* `dynamodb_table_name`: Nombre de la tabla DynamoDB (`CitasAcudientesTable`).
* `kms_key_arn`: ARN de la clave criptográfica.

---

## 🧹 Destrucción de Recursos

Si necesitas eliminar toda la infraestructura para evitar costos:
```bash
terraform destroy
```
