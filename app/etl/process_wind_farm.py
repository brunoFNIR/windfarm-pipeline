import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import col, to_timestamp, current_timestamp
from pyspark.sql import DataFrame

# Initialize Glue and Spark contexts
# These objects allow Spark to communicate with the AWS Glue environment
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sparkContext = SparkContext()
glueContext = GlueContext(sparkContext)
spark = glueContext.spark_session
job = Job(glueContext)

job.init(args['JOB_NAME'], args)

# First - READ: Extraction from the Data Catalog (Raw Layer)
# The Crawler must have run ate least once to create this table
datasource = glueContext.create_dynamic_frame.from_catalog(
    database = "windfarm_db",
    table_name = "wind_farm_raw"
)

# Second - TRANSFORM: Converting DynamicFrame to Spark DataFrame for complex operations
df: DataFrame = datasource.toDF()

# Third: Data Transformation Logic
# - Cating 'data' (sensor value) to Double for mathematical analysis
# - Converting string timestamps to actual Timestamp types
# - Adding a 'processing_at' column for auditing purposes
transformed_df = (
    df.withColumn("sensor_value", col("data").cast("double"))
    .withColumn("event_timestamp", to_timestamp(col("timestamp")))
    .withColumn("processing_at", current_timestamp())
    .drop("data", "timestamp")
)

# Forth: Loading to Processed S3 (Parquet Format)
# partitionBy for performance and cost optimization
output_path = "s3://wind-farm-processed/data/"

(transformed_df.write
                .mode("overwrite")
                .partitionBy("type")
                .parquet(output_path))

# Comits the job status to the AWS console
job.commit()