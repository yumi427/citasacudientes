output "cloudfront_domain_name" {
  description = "Dominio público seguro (HTTPS) de la aplicación móvil PWA"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "ID de la distribución de CloudFront"
  value       = aws_cloudfront_distribution.cdn.id
}

output "s3_frontend_bucket_name" {
  description = "Nombre del bucket S3 privado (Frontend)"
  value       = aws_s3_bucket.frontend.id
}

output "api_gateway_endpoint" {
  description = "URL base del API Gateway REST (HTTPS)"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "dynamodb_table_name" {
  description = "Nombre de la tabla DynamoDB (Single-Table)"
  value       = aws_dynamodb_table.citas.name
}

output "kms_key_arn" {
  description = "ARN de la clave AWS KMS usada para cifrado en reposo"
  value       = aws_kms_key.main.arn
}

output "kms_key_alias" {
  description = "Alias de la clave AWS KMS"
  value       = aws_kms_alias.main.name
}
