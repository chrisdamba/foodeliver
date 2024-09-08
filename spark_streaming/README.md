# Food Delivery Data Ingestion

This project contains a PySpark streaming job that ingests data from various Kafka topics related to a food delivery platform and saves the data as Parquet files in S3.

## Project Structure

```
spark_streaming/
│
├── schema.py
├── stream_all_events.py
├── streaming_functions.py
└── README.md
```

## Setup

1. Ensure you have PySpark installed and configured.
2. Set up Kafka and create the necessary topics.
3. Configure your S3 bucket and ensure your Spark environment has the necessary permissions to write to S3.

## Environment Variables

The following environment variables should be set:

- `KAFKA_ADDRESS`: The address of your Kafka bootstrap server (default: "localhost")
- `KAFKA_PORT`: The port of your Kafka bootstrap server (default: "9092")
- `S3_BUCKET`: The S3 bucket name (default: 'foodeliver')
- `OUTPUT_PATH`: The S3 path where the Parquet files will be saved (default: "s3a://foodeliver/events/")
- `CHECKPOINT_PATH`: The S3 path for storing Spark streaming checkpoints (default: "s3a://foodeliver/checkpoints/")

## Running the Job

To run the job, execute the following command:

```
spark-submit \
  --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 \
stream_all_events.py
```

## Data Flow

1. The job creates a Spark session and configures it for streaming.
2. It then creates Kafka read streams for each event type.
3. Each stream is processed and the data is parsed according to a defined schema.
4. The processed data is then written as Parquet files to the specified S3 location.

## Event Types

The job processes the following event types:

1. Order Placed Events
2. Order Preparation Events
3. Order Ready Events
4. Delivery Partner Assignment Events
5. Order Pickup Events
6. Partner Location Events
7. Order In Transit Events
8. Delivery Status Check Events
9. Order Delivery Events
10. Order Cancellation Events