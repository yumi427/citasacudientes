# Tabla DynamoDB Single-Table con Cifrado KMS y Facturación On-Demand (Sin Streams)
resource "aws_dynamodb_table" "citas" {
  name         = "CitasAcudientesTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  # Atributos Clave Primaria
  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  # Atributos GSI1: Historial por Acudiente ordenado por fecha
  attribute {
    name = "GSI1_PK"
    type = "S"
  }

  attribute {
    name = "GSI1_SK"
    type = "S"
  }

  # Atributos GSI2: Consultas por Estado y Monitoreo Institucional
  attribute {
    name = "GSI2_PK"
    type = "S"
  }

  attribute {
    name = "GSI2_SK"
    type = "S"
  }

  # GSI1: Consulta cronológica de citas por Acudiente
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1_PK"
    range_key       = "GSI1_SK"
    projection_type = "ALL"
  }

  # GSI2: Monitoreo de citas por Estado (SOLICITADA, CONFIRMADA, etc.)
  global_secondary_index {
    name            = "GSI2"
    hash_key        = "GSI2_PK"
    range_key       = "GSI2_SK"
    projection_type = "ALL"
  }

  # Cifrado en reposo con AWS KMS (Customer Managed Key)
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  # Recuperación en un punto del tiempo (Point-in-Time Recovery)
  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "CitasAcudientesTable"
  }
}
