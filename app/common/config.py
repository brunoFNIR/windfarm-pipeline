import os
from dotenv import load_dotenv

load_dotenv()

AWS_REGION = os.getenv("AWS_REGION")
STREAM_NAME= os.getenv("STREAM_NAME")