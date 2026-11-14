variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre base del proyecto"
  type        = string
  default     = "citasacudientes"
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, prod)"
  type        = string
  default     = "prod"
}

variable "lambda_log_retention_days" {
  description = "Días de retención para CloudWatch Logs de las Lambdas"
  type        = number
  default     = 14
}
