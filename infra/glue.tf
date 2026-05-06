resource "aws_glue_catalog_database" "windfarm_db" {
  name = "windfarm_db"
}

resource "aws_iam_role" "glue_role" {
  name = "glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "glue_policy" {
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = [
            "s3:GetObject",
            "s3:ListBucket"
        ]
        Resource = [
            aws_s3_bucket.raw.arn,
            "${aws_s3_bucket.raw.arn}/*"
        ]
    }]
  })
}

resource "aws_glue_crawler" "crawler" {
  name = "windfarm-crawler"
  role = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.windfarm_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/"
  }
}