from pyspark.sql.types import (IntegerType,
                               StringType,
                               DoubleType,
                               StructField,
                               StructType,
                               LongType,
                               BooleanType, TimestampType, FloatType)

schema = {
    'order_placed_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("userId", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("itemIds", StringType(), True),
        StructField("totalAmount", FloatType(), True),
        StructField("status", StringType(), True),
        StructField("orderPlacedAt", TimestampType(), True)
    ]),
    'order_preparation_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("prepStartTime", TimestampType(), True)
    ]),
    'order_ready_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("pickupTime", TimestampType(), True)
    ]),
    'delivery_partner_assignment_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("estimatedPickupTime", TimestampType(), True)
    ]),
    'order_pickup_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("pickupTime", TimestampType(), True),
        StructField("estimatedDeliveryTime", TimestampType(), True)
    ]),
    'partner_location_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("partnerId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("newLocation", StructType([
            StructField("lat", FloatType(), True),
            StructField("lon", FloatType(), True)
        ]), True),
        StructField("currentOrder", StringType(), True),
        StructField("status", StringType(), True),
        StructField("updateTime", TimestampType(), True),
        StructField("speed", FloatType(), True)
    ]),
    'order_in_transit_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("customerId", StringType(), True),
        StructField("currentLocation", StructType([
            StructField("lat", FloatType(), True),
            StructField("lon", FloatType(), True)
        ]), True),
        StructField("estimatedDeliveryTime", TimestampType(), True),
        StructField("pickupTime", TimestampType(), True),
        StructField("status", StringType(), True)
    ]),
    'delivery_status_check_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("userId", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("estimatedDeliveryTime", TimestampType(), True),
        StructField("current_location", StructType([
            StructField("lat", FloatType(), True),
            StructField("lon", FloatType(), True)
        ]), True),
        StructField("nextCheckTime", TimestampType(), True)
    ]),
    'order_delivery_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("userId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("estimatedDeliveryTime", TimestampType(), True),
        StructField("actualDeliveryTime", TimestampType(), True)
    ]),
    'order_cancellation_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("userId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("status", StringType(), True),
        StructField("cancellationTime", TimestampType(), True)
    ]),
    'user_behaviour_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("userId", StringType(), True),
        StructField("orderFrequency", FloatType(), True),
        StructField("lastOrderTime", TimestampType(), True)
    ]),
    'restaurant_status_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("capacity", IntegerType(), True),
        StructField("prepTime", FloatType(), True)
    ]),
    'review_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("reviewId", StringType(), True),
        StructField("orderId", StringType(), True),
        StructField("customerId", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerId", StringType(), True),
        StructField("foodRating", FloatType(), True),
        StructField("deliveryRating", FloatType(), True),
        StructField("overallRating", FloatType(), True),
        StructField("comment", StringType(), True),
        StructField("createdAt", TimestampType(), True),
        StructField("orderTotal", FloatType(), True),
        StructField("deliveryTime", IntegerType(), True)
    ]),
}
