data "aws_caller_identity" "current" {}

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
            "s3:PutObject",
            "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
          ]
      },
      {
        # Permission to persist trasnformed Parquet data into the processed layer
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:DeleteObject"
          ]
        Resource = [
          aws_s3_bucket.processed.arn,
          "${aws_s3_bucket.processed.arn}/*"
          ]
      },
      {
        # Permission to access Data Catalog
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetDatabases",
          "glue:GetTable",
          "glue:GetTables",
          "glue:GetPartition",
          "glue:GetPartitions",
          "glue:BatchGetPartition",
          "glue:BatchCreatePartition",
          "glue:CreateTable",
          "glue:UpdateTable"
        ]
        Resource = [
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/default",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:database/${aws_glue_catalog_database.windfarm_db.name}",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.windfarm_db.name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws-glue/crawlers*",
          "arn:aws:logs:*:*:log-group:/aws-glue/jobs*"
        ]
      }
    ]
  })
}

# Crawler to automatically infer schema from raw S3 files and populate the Data CAtalog
resource "aws_glue_crawler" "raw_crawler" {
  name = "windfarm-raw-crawler"
  role = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.windfarm_db.name

  s3_target {
    path = "s3://${aws_s3_bucket.raw.bucket}/"
  }
}

# Crawler for the Processed layer
resource "aws_glue_crawler" "processed_crawler" {
  name = "windfarm-processed-crawler"
  role = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.windfarm_db.name

  # Points to the processed data bucket
  s3_target {
    path = "s3://${aws_s3_bucket.processed.bucket}/data/"
  }
}

# Upload the local PySpark ETL Script to the S3 artifacts bucket
resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.artifacts.bucket
  key = "scripts/process_wind_farm.py"
  source = "../app/etl/process_wind_farm.py"
  etag = filemd5("../app/etl/process_wind_farm.py") # Triggres update if local file changes
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

# --- ETL Pipeline Orchestration: Managing dependencies between Spark Job and Processed Crawler ---

# Workflow: Logical container for the entire ETL process
resource "aws_glue_workflow" "windfarm_workflow" {
  name = "wind-farm-etl-workflow"
}

# Trigger to start the Raw Crawler
resource "aws_glue_trigger" "start_raw_crawler_trigger" {
  name = "1-start-raw-crawler"
  type = "ON_DEMAND"
  workflow_name = aws_glue_workflow.windfarm_workflow.name

  actions {
    crawler_name = aws_glue_crawler.raw_crawler.name
  }
}

# Trigger to start the Spark Job AFTER Raw Crawler finishes
resource "aws_glue_trigger" "start_spark_job_trigger" {
  name = "2-start-spark-after-raw"
  type = "CONDITIONAL" 
  workflow_name = aws_glue_workflow.windfarm_workflow.name

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.raw_crawler.name
      crawl_state = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.wind_farm_process.name
  }
}

# Trigger to start the Processed Crawler AFTER the Spark Job finishes
resource "aws_glue_trigger" "start_processed_crawler_trigger" {
  name = "start-processed-crawler-trigger"
  type = "CONDITIONAL" # starts only when a condition is met
  workflow_name = aws_glue_workflow.windfarm_workflow.name

  predicate {
    conditions {
      job_name = aws_glue_job.wind_farm_process.name
      state = "SUCCEEDED" # only runs if Spark Job succeeds
    }
  }

  actions {
    crawler_name = aws_glue_crawler.processed_crawler.name
  }
}