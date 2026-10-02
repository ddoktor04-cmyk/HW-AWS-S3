---
name: aws-s3
description: S3 bucket configuration. Use when creating storage buckets, setting up lifecycle policies, configuring versioning, or managing bucket policies.
metadata:
  author: cmd521
  version: "1.0"
---

# AWS S3 Storage

## When to Use

- Creating storage buckets
- Storing static assets
- Setting up lifecycle policies
- Configuring versioning
- Managing bucket policies

## Bucket Naming Conventions

- **Globally unique** across all AWS accounts
- **Lowercase letters, numbers, hyphens** only
- **3-63 characters** long
- **Format**: `{project}-{environment}-{purpose}`

```
myapp-prod-assets
myapp-staging-backups
myapp-dev-logs
```

## Basic S3 Bucket

```hcl
resource "aws_s3_bucket" "main" {
  bucket = "${var.project}-${var.environment}-assets"

  tags = {
    Name        = "${var.project}-${var.environment}-assets"
    Environment = var.environment
  }
}
```

## Block Public Access (Always Enable)

```hcl
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## Versioning

```hcl
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

## Server-Side Encryption

### SSE-S3 (AES-256)

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### SSE-KMS

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
  }
}
```

## Lifecycle Rules

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
```

## Bucket Policy

```hcl
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.main.arn,
          "${aws_s3_bucket.main.arn}/*"
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
```

## CORS Configuration

```hcl
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://example.com"]
    max_age_seconds = 3000
  }
}
```

## Environment Differences

| Aspect | Dev | Staging | Prod |
|--------|-----|---------|------|
| Versioning | Suspended | Enabled | Enabled |
| Lifecycle | 30 days → delete | 30 → IA → Glacier | 30 → IA → Glacier |
| Encryption | SSE-S3 | SSE-S3 | SSE-KMS |
| Force destroy | true | false | false |

## Gotchas

1. **Naming**: Cannot change bucket name after creation
2. **Region**: Cannot change region after creation
3. **Force Destroy**: Use `force_destroy = true` only for dev
4. **Versioning**: Once enabled, can only suspend (not disable)
5. **Access Logging**: Enable for audit purposes
6. **Requester Pays**: For buckets shared with other accounts

## See Also

- [assets/s3.tf.example](assets/s3.tf.example) for complete example
