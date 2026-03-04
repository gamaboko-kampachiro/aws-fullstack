#------------------------------------------------
# creation of bucket

resource "aws_s3_bucket" "app_bucket" {
  bucket = "smart-app-object-storage-12345" # Must be globally unique
  force_destroy = true
  
  tags = {
    Name = "SmartAppBucket"
    Environment = "Dev"
  }
}

#------------------------------------------------
# versioning

# Optional: Force destroy (useful in testing)
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

#------------------------------------------------
# Optional: Enable server-side encryption (SSE-S3)

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}