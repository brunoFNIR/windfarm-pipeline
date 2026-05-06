# S3 bucket Raw
resource "aws_s3_bucket" "raw" {
  bucket = "${var.project_name}-raw"
}

# S3 bucket Curated
resource "aws_s3_bucket" "processed" {
  bucket = "${var.project_name}-processed"
}

# S3 bucket artifacts and scripts
resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.project_name}-artifacts"
}

# Kinesis Stream
resource "aws_kinesis_stream" "stream" {
  name = "wind-farm-stream"
  shard_count = 1
}