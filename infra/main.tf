# S3 RAW
resource "aws_s3_bucket" "raw" {
  bucket = "wind-farm-raw"
}

# Kinesis Stream
resource "aws_kinesis_stream" "stream" {
  name = "wind-farm-stream"
  shard_count = 1
}