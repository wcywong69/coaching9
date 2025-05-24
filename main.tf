resource "aws_s3_bucket" "static_bucket" {
  bucket        = "wongs3.sctp-sandbox.com"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket                  = aws_s3_bucket.static_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.static_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        # Sid       = "AllowPublicRead",
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com"
}

resource "aws_route53_record" "wongs3" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "wongs3" # Bucket prefix before sctp-sandbox.com
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.website.website_domain
    zone_id                = aws_s3_bucket.static_bucket.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "null_resource" "upload_static_site" {
    provisioner "local-exec" {
        # command = "aws s3 sync ${path.module}/../coaching9_24May25_static_web s3://${aws_s3_bucket.static_bucket.id} --acl public-read"
        command = "aws s3 sync ${path.module}/../coaching9_24May25_static_web s3://${aws_s3_bucket.static_bucket.id}"
        }
        
        depends_on = [
            aws_s3_bucket.static_bucket
            ]
}
