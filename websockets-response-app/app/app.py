import json
import boto3
import os
import websockets
import logging
from botocore.exceptions import ClientError

dynamodb = boto3.client("dynamodb", "eu-west-1")
CONNECTION_ID_TABLE = os.environ["CONNECTION_ID_TABLE"]
COUNTER_TABLE = os.environ["COUNTER_TABLE"]

client = boto3.client("sns", "eu-west-1")
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def check_count_for_sns_topic(event):
    SNS_TOPIC = os.environ["SNS_TOPIC"]
    try:
        for i in event["Records"]:
            num = i["dynamodb"]["NewImage"]["count"]["S"]
            if int(num) % 10 != 0 or int(num) == 0:
                continue
            else:
                logger.info("Sending SNS message")
                client.publish(TopicArn=SNS_TOPIC, Message=f"Visit counter: {num}")
    except KeyError as e:
        logger.exception("Couldn't get count from DynamoDB.")


def get_current_count(event):
    try:
        count = event["Records"][-1]["dynamodb"]["NewImage"]["count"]["S"]
        return count
    except ClientError:
        logger.exception("Couldn't get current count.")


def get_current_connections(connection_id_table):
    try:
        data = connection_id_table.scan(ProjectionExpression="connection_id")
        list_of_connections = [item["connection_id"] for item in data["Items"]]
        logger.info("Found %s active connections.", len(list_of_connections))
        return list_of_connections
    except ClientError:
        logger.exception("Couldn't get current connections.")


def send_counter_to_connections(connections, count):
    WEBSOCKET_ENDPOINT = os.environ["WEBSOCKET_ENDPOINT"]
    api_manager = boto3.client(
        "apigatewaymanagementapi", "eu-west-1",
        endpoint_url=WEBSOCKET_ENDPOINT,
    )
    for connection in connections:
        try:
            api_manager.post_to_connection(
                Data=f"{count}".encode("utf-8"), ConnectionId=connection
            )
            logger.info("Sent count %s to connection %s.", count, connection)
        except ClientError:
            logger.exception(
                "Couldn't send count %s to connection %s.", count, connection
            )


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    connection_id_table = boto3.resource("dynamodb", "eu-west-1").Table(CONNECTION_ID_TABLE)
    response = {"statusCode": 200}

    check_count_for_sns_topic(event)
    count = get_current_count(event)
    current_connections = get_current_connections(connection_id_table)
    send_counter_to_connections(current_connections, count)

    return response
