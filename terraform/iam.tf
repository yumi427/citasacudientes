# Política base para asumir rol de Lambda
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# ==========================================
# 1. ROL Y POLÍTICA: AGENDAR CITA (TRANSACCIONAL)
# ==========================================
resource "aws_iam_role" "lambda_agendar" {
  name               = "${var.project_name}-lambda-agendar-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_agendar_policy" {
  name = "${var.project_name}-lambda-agendar-policy"
  role = aws_iam_role.lambda_agendar.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTransactionalWrite"
        Effect = "Allow"
        Action = [
          "dynamodb:TransactWriteItems",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.citas.arn,
          "${aws_dynamodb_table.citas.arn}/index/*"
        ]
      },
      {
        Sid    = "KMSDecryptAndGenerate"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-agendar-cita:*"
      }
    ]
  })
}

# ==========================================
# 2. ROL Y POLÍTICA: DISPONIBILIDAD
# ==========================================
resource "aws_iam_role" "lambda_disponibilidad" {
  name               = "${var.project_name}-lambda-disponibilidad-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_disponibilidad_policy" {
  name = "${var.project_name}-lambda-disponibilidad-policy"
  role = aws_iam_role.lambda_disponibilidad.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBDisponibilidadAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:PutItem",
          "dynamodb:GetItem"
        ]
        Resource = aws_dynamodb_table.citas.arn
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-disponibilidad:*"
      }
    ]
  })
}

# ==========================================
# 3. ROL Y POLÍTICA: GESTIÓN DE CITAS
# ==========================================
resource "aws_iam_role" "lambda_gestion" {
  name               = "${var.project_name}-lambda-gestion-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_gestion_policy" {
  name = "${var.project_name}-lambda-gestion-policy"
  role = aws_iam_role.lambda_gestion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBGestionAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.citas.arn,
          "${aws_dynamodb_table.citas.arn}/index/*"
        ]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.main.arn
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-gestion-citas:*"
      }
    ]
  })
}
