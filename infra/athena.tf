# Athena Workgroup: Manages query execution settings and cost controls
resource "aws_athena_workgroup" "windfarm_workgroup" {
  name = "windfarm-analysis"

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      # Place to store query results
      output_location = "s3://${aws_s3_bucket.artifacts.bucket}/athena-results/"
    }
  }
}