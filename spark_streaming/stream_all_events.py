# Run the script using the following command
# spark-submit \
#   --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.1.2 \
# stream_all_events.py

import os
from streaming_functions import *
from schema import schema

KAFKA_ADDRESS = os.getenv("KAFKA_ADDRESS", "localhost")
KAFKA_PORT = os.getenv("KAFKA_PORT", "9092")
ORDER_PLACED_EVENTS_TOPIC = "order_placed_events"
ORDER_PREPARATION_EVENTS_TOPIC = "order_preparation_events"
ORDER_READY_EVENTS_TOPIC = "order_ready_events"
DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC = "delivery_partner_assignment_events"
ORDER_PICKUP_EVENTS_TOPIC = "order_pickup_events"
PARTNER_LOCATION_EVENTS_TOPIC = "partner_location_events"
ORDER_IN_TRANSIT_EVENTS_TOPIC = "order_in_transit_events"
DELIVERY_STATUS_CHECK_EVENTS_TOPIC = "delivery_status_check_events"
ORDER_DELIVERY_EVENTS_TOPIC = "order_delivery_events"
ORDER_CANCELLATION_EVENTS_TOPIC = "order_cancellation_events"
USER_BEHAVIOUR_EVENTS_TOPIC = "user_behaviour_events"
RESTAURANT_STATUS_EVENTS_TOPIC = "restaurant_status_events"
REVIEW_EVENTS_TOPIC = "review_events"

S3_BUCKET = os.getenv("S3_BUCKET", 'foodeliver')
OUTPUT_PATH = os.getenv("OUTPUT_PATH", f"s3a://{S3_BUCKET}/events")
CHECKPOINT_PATH = os.getenv("CHECKPOINT_PATH", f"s3a://{S3_BUCKET}/checkpoints")


# initialize a spark session
spark = create_or_get_spark_session('Foodatasim Stream')
spark.streams.resetTerminated()

# create Kafka read streams
order_placed_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_PLACED_EVENTS_TOPIC)
order_preparation_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_PREPARATION_EVENTS_TOPIC)
order_ready_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_READY_EVENTS_TOPIC)
delivery_partner_assignment_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT,
                                                              DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC)
order_pickup_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_PICKUP_EVENTS_TOPIC)
partner_location_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, PARTNER_LOCATION_EVENTS_TOPIC)
order_in_transit_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_IN_TRANSIT_EVENTS_TOPIC)
delivery_status_check_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT,
                                                        DELIVERY_STATUS_CHECK_EVENTS_TOPIC)
order_delivery_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_DELIVERY_EVENTS_TOPIC)
order_cancellation_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, ORDER_CANCELLATION_EVENTS_TOPIC)
user_behaviour_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, USER_BEHAVIOUR_EVENTS_TOPIC)
restaurant_status_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, RESTAURANT_STATUS_EVENTS_TOPIC)
review_events = create_kafka_read_stream(spark, KAFKA_ADDRESS, KAFKA_PORT, REVIEW_EVENTS_TOPIC)

# process streams
order_placed_events = process_stream(
    order_placed_events, schema[ORDER_PLACED_EVENTS_TOPIC], ORDER_PLACED_EVENTS_TOPIC)
order_preparation_events = process_stream(
    order_preparation_events, schema[ORDER_PREPARATION_EVENTS_TOPIC], ORDER_PREPARATION_EVENTS_TOPIC)
order_ready_events = process_stream(
    order_ready_events, schema[ORDER_READY_EVENTS_TOPIC], ORDER_READY_EVENTS_TOPIC)
delivery_partner_assignment_events = process_stream(
    delivery_partner_assignment_events, schema[DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC], DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC)
order_pickup_events = process_stream(
    order_pickup_events, schema[ORDER_PICKUP_EVENTS_TOPIC], ORDER_PICKUP_EVENTS_TOPIC)
partner_location_events = process_stream(
    partner_location_events, schema[PARTNER_LOCATION_EVENTS_TOPIC], PARTNER_LOCATION_EVENTS_TOPIC)
order_in_transit_events = process_stream(
    order_in_transit_events, schema[ORDER_IN_TRANSIT_EVENTS_TOPIC], ORDER_IN_TRANSIT_EVENTS_TOPIC)
delivery_status_check_events = process_stream(
    delivery_status_check_events, schema[DELIVERY_STATUS_CHECK_EVENTS_TOPIC], DELIVERY_STATUS_CHECK_EVENTS_TOPIC)
order_delivery_events = process_stream(
    order_delivery_events, schema[ORDER_DELIVERY_EVENTS_TOPIC], ORDER_DELIVERY_EVENTS_TOPIC)
order_cancellation_events = process_stream(
    order_cancellation_events, schema[ORDER_CANCELLATION_EVENTS_TOPIC], ORDER_CANCELLATION_EVENTS_TOPIC)
user_behaviour_events = process_stream(
    user_behaviour_events, schema[USER_BEHAVIOUR_EVENTS_TOPIC], USER_BEHAVIOUR_EVENTS_TOPIC)
restaurant_status_events = process_stream(
    restaurant_status_events, schema[RESTAURANT_STATUS_EVENTS_TOPIC], RESTAURANT_STATUS_EVENTS_TOPIC)
review_events = process_stream(
    review_events, schema[REVIEW_EVENTS_TOPIC], REVIEW_EVENTS_TOPIC)


# write a file to storage every 2 minutes in parquet format
order_placed_events_writer = create_file_write_stream(order_placed_events, f"{OUTPUT_PATH}/{ORDER_PLACED_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_PLACED_EVENTS_TOPIC}")
order_preparation_events_writer = create_file_write_stream(order_preparation_events, f"{OUTPUT_PATH}/{ORDER_PREPARATION_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_PREPARATION_EVENTS_TOPIC}")
order_ready_events_writer = create_file_write_stream(order_ready_events, f"{OUTPUT_PATH}/{ORDER_READY_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_READY_EVENTS_TOPIC}")
delivery_partner_assignment_events_writer = create_file_write_stream(delivery_partner_assignment_events, f"{OUTPUT_PATH}/{DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{DELIVERY_PARTNER_ASSIGNMENT_EVENTS_TOPIC}"
                                        )
order_pickup_events_writer = create_file_write_stream(order_pickup_events, f"{OUTPUT_PATH}/{ORDER_PICKUP_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_PICKUP_EVENTS_TOPIC}")
partner_location_events_writer = create_file_write_stream(partner_location_events, f"{OUTPUT_PATH}/{PARTNER_LOCATION_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{PARTNER_LOCATION_EVENTS_TOPIC}")
order_in_transit_events_writer = create_file_write_stream(order_in_transit_events, f"{OUTPUT_PATH}/{ORDER_IN_TRANSIT_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_IN_TRANSIT_EVENTS_TOPIC}")
delivery_status_check_events_writer = create_file_write_stream(delivery_status_check_events, f"{OUTPUT_PATH}/{DELIVERY_STATUS_CHECK_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{DELIVERY_STATUS_CHECK_EVENTS_TOPIC}"
                                                        )
order_delivery_events_writer = create_file_write_stream(order_delivery_events, f"{OUTPUT_PATH}/{ORDER_DELIVERY_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_DELIVERY_EVENTS_TOPIC}")
order_cancellation_events_writer = create_file_write_stream(order_cancellation_events, f"{OUTPUT_PATH}/{ORDER_CANCELLATION_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{ORDER_CANCELLATION_EVENTS_TOPIC}")
user_behaviour_events_writer = create_file_write_stream(user_behaviour_events, f"{OUTPUT_PATH}/{USER_BEHAVIOUR_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{USER_BEHAVIOUR_EVENTS_TOPIC}")
restaurant_status_events_writer = create_file_write_stream(restaurant_status_events, f"{OUTPUT_PATH}/{RESTAURANT_STATUS_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{RESTAURANT_STATUS_EVENTS_TOPIC}")
review_events_writer = create_file_write_stream(review_events, f"{OUTPUT_PATH}/{REVIEW_EVENTS_TOPIC}", f"{CHECKPOINT_PATH}/{REVIEW_EVENTS_TOPIC}")

order_placed_events_writer.start()
order_preparation_events_writer.start()
order_ready_events_writer.start()
delivery_partner_assignment_events_writer.start()
order_pickup_events_writer.start()
partner_location_events_writer.start()
order_in_transit_events_writer.start()
delivery_status_check_events_writer.start()
order_delivery_events_writer.start()
order_cancellation_events_writer.start()
user_behaviour_events_writer.start()
restaurant_status_events_writer.start()
review_events_writer.start()

spark.streams.awaitAnyTermination()
