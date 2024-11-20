from pyspark.sql.types import (IntegerType,
                               StringType,
                               DoubleType,
                               StructField,
                               StructType,
                               LongType,
                               BooleanType, TimestampType, FloatType)

location_schema = StructType([
   StructField("lat", DoubleType(), True),
   StructField("lon", DoubleType(), True)
])

schema = {
    'user_created_events': StructType([
       StructField("id", StringType(), False),
       StructField("timestamp", TimestampType(), True),
       StructField("name", StringType(), True),
       StructField("email", StringType(), True),
       StructField("joinDate", LongType(), True),
       StructField("location", location_schema, True),
       StructField("preferences", StringType(), True),
       StructField("dietRestrictions", StringType(), True),
       StructField("orderFrequency", DoubleType(), True)
    ]),
    'restaurant_created_events': StructType([
       StructField("id", StringType(), False),
       StructField("timestamp", TimestampType(), True),
       StructField("host", StringType(), True),
       StructField("name", StringType(), True),
       StructField("currency", IntegerType(), True),
       StructField("phone", StringType(), True),
       StructField("town", StringType(), True),
       StructField("slugName", StringType(), True),
       StructField("websiteLogoUrl", StringType(), True),
       StructField("offline", StringType(), True),
       StructField("location", location_schema, True),
       StructField("cuisines", StringType(), True),
       StructField("rating", DoubleType(), True),
       StructField("totalRatings", DoubleType(), True),
       StructField("prepTime", DoubleType(), True),
       StructField("minPrepTime", DoubleType(), True),
       StructField("avgPrepTime", DoubleType(), True),
       StructField("pickupEfficiency", DoubleType(), True),
       StructField("menuItemIds", StringType(), True),
       StructField("capacity", IntegerType(), True)
    ]),
    'delivery_partner_created_events': StructType([
       StructField("id", StringType(), False),
       StructField("timestamp", TimestampType(), True),
       StructField("name", StringType(), True),
       StructField("joinDate", LongType(), True),
       StructField("rating", DoubleType(), True),
       StructField("totalRatings", DoubleType(), True),
       StructField("experienceScore", DoubleType(), True),
       StructField("speed", DoubleType(), True),
       StructField("avgSpeed", DoubleType(), True),
       StructField("currentOrderID", StringType(), True),
       StructField("currentLocation", location_schema, True),
       StructField("status", StringType(), True)
    ]),
    'menu_item_created_events': StructType([
       StructField("id", StringType(), False),
       StructField("timestamp", TimestampType(), True),
       StructField("restaurantID", StringType(), True),
       StructField("name", StringType(), True),
       StructField("description", StringType(), True),
       StructField("price", DoubleType(), True),
       StructField("prepTime", DoubleType(), True),
       StructField("category", StringType(), True),
       StructField("type", StringType(), True),
       StructField("popularity", DoubleType(), True),
       StructField("prepComplexity", DoubleType(), True),
       StructField("ingredients", StringType(), True),
       StructField("isDiscountEligible", BooleanType(), True)
    ]),
    'order_placed_events': StructType([
        StructField("timestamp", TimestampType(), True),
        StructField("eventType", StringType(), True),
        StructField("orderId", StringType(), False),
        StructField("itemIds", StringType(), True),
        StructField("totalAmount", DoubleType(), True),
        StructField("orderPlacedAt", LongType(), True),
        StructField("customerId", StringType(), True),
        StructField("restaurantId", StringType(), True),
        StructField("deliveryPartnerID", StringType(), True),
        StructField("deliveryCost", DoubleType(), True),
        StructField("paymentMethod", StringType(), True),
        StructField("deliveryAddress", location_schema, True),
        StructField("reviewGenerated", BooleanType(), True)
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
