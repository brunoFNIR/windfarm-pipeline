# IAM Role fir Kinesis Data Firehose execution
resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

  # Trust policy allowing Firehose sevice to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })
}

# Policy defining Firehose access to S3 and Kinesis Streams
resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Permission to deliver ingested data into the new raw S3 bucket 
        Effect = "Allow"
        Action = [
            "s3:PutObject",
            "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.raw.arn}/*"
    },
    {
        # Permission to read streaming records from the source Kinesis Stream
        Effect = "Allow"
        Action = [
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream",
            "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.stream.arn
    }
    ]
  })
}

# Delivery Stream to move data from Kinesis Stream to S3 Raw Bucket
resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name = "wind-farm-firehose"
  destination = "extended_s3"

  # Source configuration: Links to the Kinesis Data Stream
  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
    role_arn = aws_iam_role.firehose_role.arn
  }

  # Destination configuration: Targets the raw S3 bucket
  extended_s3_configuration{
    role_arn = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw.arn
  }
}
