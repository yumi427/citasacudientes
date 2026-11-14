# ==========================================
# EMPAQUETADO DE CÓDIGO PYTHON (ARCHIVE)
# ==========================================
data "archive_file" "lambda_disponibilidad_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/disponibilidad/index.py"
  output_path = "${path.module}/build/disponibilidad.zip"
}

data "archive_file" "lambda_agendar_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/agendar_cita/index.py"
  output_path = "${path.module}/build/agendar_cita.zip"
}

data "archive_file" "lambda_gestion_zip" {
  type        = "zip"
  source_file = "${path.module}/../src/lambdas/gestion_citas/index.py"
  output_path = "${path.module}/build/gestion_citas.zip"
}

# ==========================================
# GRUPOS DE LOGS EN CLOUDWATCH (CIFRADOS CON KMS)
# ==========================================
resource "aws_cloudwatch_log_group" "lambda_disponibilidad" {
  name              = "/aws/lambda/${var.project_name}-disponibilidad"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-disponibilidad-logs"
  }
}

resource "aws_cloudwatch_log_group" "lambda_agendar" {
  name              = "/aws/lambda/${var.project_name}-agendar-cita"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-agendar-logs"
  }
}

resource "aws_cloudwatch_log_group" "lambda_gestion" {
  name              = "/aws/lambda/${var.project_name}-gestion-citas"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = {
    Name = "${var.project_name}-gestion-logs"
  }
}

# ==========================================
# FUNCIONES AWS LAMBDA SERVERLESS
# ==========================================
# 1. Lambda Disponibilidad
resource "aws_lambda_function" "disponibilidad" {
  function_name    = "${var.project_name}-disponibilidad"
  filename         = data.archive_file.lambda_disponibilidad_zip.output_path
  source_code_hash = data.archive_file.lambda_disponibilidad_zip.output_base64sha256
  role             = aws_iam_role.lambda_disponibilidad.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  kms_key_arn      = aws_kms_key.main.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.citas.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_disponibilidad]
}

# 2. Lambda Agendar Cita (Transaccional)
resource "aws_lambda_function" "agendar_cita" {
  function_name    = "${var.project_name}-agendar-cita"
  filename         = data.archive_file.lambda_agendar_zip.output_path
  source_code_hash = data.archive_file.lambda_agendar_zip.output_base64sha256
  role             = aws_iam_role.lambda_agendar.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  kms_key_arn      = aws_kms_key.main.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.citas.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_agendar]
}

# 3. Lambda Gestión y Seguimiento de Citas
resource "aws_lambda_function" "gestion_citas" {
  function_name    = "${var.project_name}-gestion-citas"
  filename         = data.archive_file.lambda_gestion_zip.output_path
  source_code_hash = data.archive_file.lambda_gestion_zip.output_base64sha256
  role             = aws_iam_role.lambda_gestion.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  memory_size      = 256
  timeout          = 10
  kms_key_arn      = aws_kms_key.main.arn

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.citas.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_gestion]
}
