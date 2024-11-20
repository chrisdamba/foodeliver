from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, month, hour, dayofmonth, col, year, udf


@udf
def string_decode(s, encoding='utf-8'):
    if s:
        return (s.encode('latin1')  # To bytes, required by 'unicode-escape'
                .decode('unicode-escape')  # Perform the actual octal-escaping decode
                .encode('latin1')  # 1:1 mapping back to bytes
                .decode(encoding)  # Decode original encoding
                .strip('\"'))

    else:
        return s


def create_or_get_spark_session(app_name, master="yarn"):
    """
    Creates or gets a Spark Session

    Parameters:
        app_name : str
            Pass the name of your app
        master : str
            Choosing the Spark master, yarn is the default
    Returns:
        spark: SparkSession
    """
    spark = (SparkSession
             .builder
             .appName(app_name)
             .master(master)
             .config("spark.sql.streaming.schemaInference", "true")
             .config("spark.sql.shuffle.partitions", "1")
             .config("spark.default.parallelism", "1")
             .config("spark.streaming.stopGracefullyOnShutdown", "true")
             .config("spark.executor.memory", "4g")
             .config("spark.driver.memory", "4g")
             .getOrCreate())

    return spark


def create_kafka_read_stream(spark, kafka_address, kafka_port, topic, starting_offset="latest"):
    """
    Creates a kafka read stream

    Parameters:
        spark : SparkSession
            A SparkSession object
        kafka_address: str
            Host address of the kafka bootstrap server
        kafka_port: str
            Port of the kafka bootstrap server
        topic : str
            Name of the kafka topic
        starting_offset: str
            Starting offset configuration, "earliest" by default 
    Returns:
        read_stream: DataStreamReader
    """
    # kafka_bootstrap_servers = "localhost:9092"
    kafka_bootstrap_servers = f"{kafka_address}:{kafka_port}"
    try:
        read_stream = (spark
                       .readStream
                       .format("kafka")
                       .option("kafka.bootstrap.servers", kafka_bootstrap_servers)
                       .option("subscribe", topic)
                       .option("startingOffsets", starting_offset)
                       .option("failOnDataLoss", "false")
                       .load())
        return read_stream
    except Exception as e:
        print(f"Error creating Kafka read stream for topic {topic}: {str(e)}")
        return None


def process_stream(stream, stream_schema):
    """
    Process stream to fetch on value from the kafka message.
    convert ts to timestamp format and produce year, month, day,
    hour columns
    Parameters:
        stream : DataStreamReader
            The data stream reader for your stream
        stream_schema : DataStreamSchema
            The data stream schema
    Returns:
        stream : DataStreamReader
            The data stream reader for your stream
    """

    # read only value from the incoming message and convert the contents
    # inside to the passed schema
    stream = (stream
              .selectExpr("CAST(value AS STRING)")
              .select(
        from_json(col("value"), stream_schema).alias(
            "data")
    )
              .select("data.*")
              )

    # Add month, day, hour to split the data into separate directories
    stream = (stream
              .withColumn("year", year(col("timestamp")))
              .withColumn("month", month(col("timestamp")))
              .withColumn("hour", hour(col("timestamp")))
              .withColumn("day", dayofmonth(col("timestamp")))
              )
    # Add show to see incoming rows
    stream.writeStream.outputMode("append").format("console").start()
    return stream


def create_file_write_stream(stream, storage_path, checkpoint_path, trigger="1 minute", output_mode="append",
                             file_format="parquet"):
    """
    Write the stream back to a file store

    Parameters:
        stream : DataStreamReader
            The data stream reader for your stream
        file_format : str
            parquet, csv, orc etc
        storage_path : str
            The file output path
        checkpoint_path : str
            The checkpoint location for spark
        trigger : str
            The trigger interval
        output_mode : str
            append, complete, update
    """

    write_stream = (stream
                    .writeStream
                    .format(file_format)
                    .partitionBy("month", "day", "hour")
                    .option("path", storage_path)
                    .option("checkpointLocation", checkpoint_path)
                    .trigger(processingTime=trigger)
                    .outputMode(output_mode)
                    .withWatermark("timestamp", "10 minutes"))

    return write_stream


def write_batch(batch_df, file_path):
    batch_df.write.mode("append").parquet(file_path)
