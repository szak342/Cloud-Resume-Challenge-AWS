import json
import boto3
import os

SNS_TOPIC = os.environ["SNS_TOPIC"]
client = boto3.client("sns")


def lambda_handler(event, context):
    try:
        for i in event["Records"]:
            print(i)
            num = i["dynamodb"]["NewImage"]["count"]["N"]
            if int(num) % 10 == 0:
                print(num)
                response = client.publish(
                    TopicArn=SNS_TOPIC, Message=f"Visit counter: {num}"
                )
                return response
    except KeyError as e:
        print(e)
