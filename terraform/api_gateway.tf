# ==========================================
# AMAZON API GATEWAY (HTTP API SÍNCRONO)
# ==========================================
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-api-${var.environment}"
  protocol_type = "HTTP"
  description   = "API REST Serverless para CitasAcudientes (PWA Móvil)"

  cors_configuration {
    allow_origins = [
      "https://${aws_cloudfront_distribution.cdn.domain_name}",
      "http://localhost:3000",
      "http://localhost:5173"
    ]
    allow_methods = ["GET", "POST", "PATCH", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key"]
    max_age       = 3600
  }

  tags = {
    Name = "${var.project_name}-http-api"
  }
}

# Logs de Acceso de API Gateway
resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = aws_kms_key.main.arn
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# ==========================================
# INTEGRACIONES CON AWS LAMBDA (PROXY)
# ==========================================
resource "aws_apigatewayv2_integration" "disponibilidad" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.disponibilidad.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "agendar" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.agendar_cita.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "gestion" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.gestion_citas.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# ==========================================
# RUTAS DE LA API
# ==========================================
# 1. Disponibilidad Docente
resource "aws_apigatewayv2_route" "get_disponibilidad" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /disponibilidad"
  target    = "integrations/${aws_apigatewayv2_integration.disponibilidad.id}"
}

resource "aws_apigatewayv2_route" "post_disponibilidad" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /disponibilidad"
  target    = "integrations/${aws_apigatewayv2_integration.disponibilidad.id}"
}

# 2. Agendar Cita (Acudiente)
resource "aws_apigatewayv2_route" "post_citas" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /citas"
  target    = "integrations/${aws_apigatewayv2_integration.agendar.id}"
}

# 3. Gestión y Seguimiento de Citas
resource "aws_apigatewayv2_route" "get_citas" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /citas"
  target    = "integrations/${aws_apigatewayv2_integration.gestion.id}"
}

resource "aws_apigatewayv2_route" "get_cita_by_id" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /citas/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.gestion.id}"
}

resource "aws_apigatewayv2_route" "patch_cita_by_id" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "PATCH /citas/{id}"
  target    = "integrations/${aws_apigatewayv2_integration.gestion.id}"
}

# ==========================================
# PERMISOS PARA INVOCAR LAMBDAS
# ==========================================
resource "aws_lambda_permission" "api_disponibilidad" {
  statement_id  = "AllowAPIGatewayInvokeDisponibilidad"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disponibilidad.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_agendar" {
  statement_id  = "AllowAPIGatewayInvokeAgendar"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.agendar_cita.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_gestion" {
  statement_id  = "AllowAPIGatewayInvokeGestion"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.gestion_citas.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
