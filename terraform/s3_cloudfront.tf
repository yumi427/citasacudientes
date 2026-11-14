# Bucket S3 Privado para el Frontend (PWA)
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "${var.project_name}-frontend-"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-frontend-bucket"
  }
}

# Bloqueo total de acceso público en S3
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cifrado en reposo con AWS KMS (SSE-KMS)
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.main.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Versionado del bucket para control de despliegues
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Origin Access Control (OAC) para comunicación cifrada CloudFront -> S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-oac-${var.environment}"
  description                       = "OAC para acceso exclusivo desde CloudFront hacia S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribución CDN CloudFront con terminación SSL/TLS 1.3
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN de CitasAcudientes para clientes móviles"
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    # Redirección forzosa HTTP a HTTPS (TLS en tránsito)
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Soporte para SPA (Single Page Application) móvil
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  tags = {
    Name = "${var.project_name}-cdn-${var.environment}"
  }
}

# Política de Bucket S3: Acceso exclusivo a CloudFront (OAC) y Denegación de HTTP no seguro
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Permitir lectura solo a la distribución CloudFront
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      },
      # Denegar cualquier comunicación que no use HTTPS (Cifrado en tránsito)
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
