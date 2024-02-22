import json
import boto3
import os
import logging
from botocore.exceptions import ClientError

dynamodb = boto3.client("dynamodb", "eu-west-1")
CONNECTION_ID_TABLE = os.environ["CONNECTION_ID_TABLE"]
COUNTER_TABLE = os.environ["COUNTER_TABLE"]
ALLOWED_ORIGINS = os.environ["ALLOWED_ORIGINS"].split(",")
ALLOWED_HOST = os.environ["ALLOWED_HOST"]

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def check_host(event):
    if event["headers"]["Host"] == ALLOWED_HOST:
        logger.info("Host header is valid.")
        return True
    else:
        logger.info("Host header is invalid.")
        return False
        

def check_origin(event):
    if "headers" in event and "Origin" in event["headers"]:
        origin_header = event["headers"]["Origin"]
        if origin_header in ALLOWED_ORIGINS:
            logger.info("Origin header is valid.")
            return True
        else:
            logger.info("Origin header is invalid.")
            return False
    else:
        logger.info("Origin header is invalid.")
        return False

def connect(user_name, connection_id_table, counter_table, connection_id):
    response = 200
    try:
        connection_id_table.put_item(
            Item={"connection_id": connection_id, "user_name": user_name}
        )
        logger.info("Added connection %s for user %s.", connection_id, user_name)
    except ClientError:
        logger.exception(
            "Couldn't add connection %s for user %s.", connection_id, user_name
        )
        response = 503
    try:
        item_response = counter_table.get_item(Key={"id": "Counter"})
        counter = int(item_response["Item"]["count"]) + 1
        counter_table.put_item(Item={"id": "Counter", "count": str(counter)})
        logger.info("Updated counter to %s.", counter)
    except ClientError:
        logger.exception("Couldn't update counter.")
        response = 503

    return response


def disconnect(table, connection_id):
    status_code = 200
    try:
        table.delete_item(Key={"connection_id": connection_id})
        logger.info("Disconnected connection %s.", connection_id)
    except ClientError:
        logger.exception("Couldn't disconnect connection %s.", connection_id)
        status_code = 503
    return status_code


def lambda_handler(event, context):
    route_key = event["requestContext"]["routeKey"]
    connection_id = event["requestContext"]["connectionId"]
    logger.info("Received request: %s.", event)


    if (
        CONNECTION_ID_TABLE is None
        or COUNTER_TABLE is None
        or route_key is None
        or connection_id is None
    ):
        return {"statusCode": 400}

    connection_id_table = boto3.resource("dynamodb", "eu-west-1").Table(CONNECTION_ID_TABLE)
    counter_table = boto3.resource("dynamodb", "eu-west-1").Table(COUNTER_TABLE)
    logger.info("Request: %s, use table %s.", route_key, connection_id_table.name)
    response = {"statusCode": 200}

    if route_key == "$connect":
        if check_origin(event):
            user_name = event.get("queryStringParameters", {"name": "guest"}).get("name")
            response["statusCode"] = connect(
                user_name, connection_id_table, counter_table, connection_id
            )
        else:
            response["statusCode"] = 403
    elif route_key == "$disconnect":
        if check_host(event):
            response["statusCode"] = disconnect(connection_id_table, connection_id)
        else:
            response["statusCode"] = 403
    else:
        response["statusCode"] = 404
    
    return response
