resource "aws_iam_role" "firehose_role" {
  name = "firehose-role"

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

resource "aws_iam_role_policy" "firehose_policy" {
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = [
            "s3:PutObject",
            "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.raw.arn}/*"
    },
    {
        Effect = "Allow"
        Action = [
            "kinesis:GetRecords",
            "kinesis:GetShardIterator",
            "kinesis:DescribeStream",
            "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.stream.arn
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  name = "wind-farm-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.stream.arn
    role_arn = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration{
    role_arn = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.raw.arn
  }
}
