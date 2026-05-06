# AWS Glue Catalog Database to store metadata tables
resource "aws_glue_catalog_database" "windfarm_db" {
  name = "windfarm_db"
}

# IAM Role for AWS Glue service execution
resource "aws_iam_role" "glue_role" {
  name = "glue-role"

  # Trust policy allowing Glue service to assume this role
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

# Inline policy defining specific permissions for the Glue Job
resource "aws_iam_role_policy" "glue_policy" {
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to read raw data from the raw layer
        Effect = "Allow"
        Action = [
            "s3:GetObject",
            "s3:ListBucket"
        ]
        Resource = [
            aws_s3_bucket.raw.arn,
            "${aws_s3_bucket.raw.arn}/*"
        ]
      },
      {
        # Permission to retrieve PySpark scripts and write execution logs
        Effect = "Allow"
        Action = [
            "s3:GetObject",
            "s3:PutObject"
        ]
        Resource = ["${aws_s3_bucket.artifacts.arn}/*"]
      },
      {
        # Permission to persist trasnformed Parquet data into the processed layer
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.processed.arn}/*"]
      }
    ]
  })
}

# Crawler to automatically infer schema from raw S3 files and populate the Data CAtalog
resource "aws_glue_crawler" "crawler" {
  name = "windfarm-crawler"
  role = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.windfarm_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/"
  }
}

# Upload the local PySpark ETL Script to the S3 artifacts bucket
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.artifacts.bucket
  key = "scripts/process_wind_farm.py"
  source = "../app/etl/process_wind_farm.py"
  etag = filemdhash("../app/etl/process_wind_farm.py") # Triggres update if local file changes
}

# Defines the Glue Spark Job for data transformation
resource "aws_glue_job" "wind_farm_process" {
  name = "wind-farm-data-processing"
  role_arn = aws_iam_role.glue_role.arn
  glue_version = "4.0"

  worker_type = "G.1X"
  number_of_workers = 2

  command {
    name = "glueetl" 
    script_location = "s3://${aws_s3_bucket.artifacts.bucket}/${aws_s3_object.glue_script.key}"
    python_version = "3"
  }

  # Runtime arguments for logging and monitoring
  default_arguments = {
    "--job-language" = "python"
    "--continuous-log-logGroup" = "/aws-glue/jobs/${var.project_name}"
    "--spark-event-logs-path" = "s3://${aws_s3_bucket.artifacts.bucket}/spark-logs"
    "--enable-continuous-cloudwatch-log" = "true"
  }
}