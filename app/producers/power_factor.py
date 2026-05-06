import boto3
import json
import time
from random import uniform
from datetime import datetime

from app.common.config import *

client = boto3.client(
    'kinesis',
    region_name=AWS_REGION
)

id_counter = 0

while True:
  id_counter += 1
  data = uniform(0.7,1)
  record = {
      'id': str(id),
      'data': str(data),
      'type': 'powerfactor',
      'timestamp': str(datetime.now())
  }

  client.put_record(
      StreamName=STREAM_NAME,
      Data=json.dumps(record),
      PartitionKey=record['type'])
  
  print("Sent: ", record)

  time.sleep(10)