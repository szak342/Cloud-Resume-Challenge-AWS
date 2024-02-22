import boto3
import pytest
from pytest import MonkeyPatch
from moto import mock_aws
import os
import sys
import unittest

path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../") + "websockets-response-app/app/"
)
sys.path.append(path)

MonkeyPatch().setenv("CONNECTION_ID_TABLE", "id_table")
MonkeyPatch().setenv("COUNTER_TABLE", "counter_table")
MonkeyPatch().setenv("ALLOWED_ORIGINS", "https://testsite.com")
MonkeyPatch().setenv("ALLOWED_HOST", "allowedhost.com")
MonkeyPatch().setenv("DDB_TABLE", "test_table")
MonkeyPatch().setenv("AWS_ACCESS_KEY_ID", "testing")
MonkeyPatch().setenv("AWS_SECRET_ACCESS_KEY", "testing")
MonkeyPatch().setenv("AWS_REGION", "eu-west-1")



test_event_true = {
    "Records": [
        {
            "eventID": "2344b7e50c70682bd1c086dd2d6ec521",
            "eventName": "MODIFY",
            "eventVersion": "1.1",
            "eventSource": "aws:dynamodb",
            "awsRegion": "eu-west-1",
            "dynamodb": {
                "ApproximateCreationDateTime": 1708353416,
                "Keys": {"id": {"S": "Counter"}},
                "NewImage": {"count": {"S": "19"}, "id": {"S": "Counter"}},
                "SequenceNumber": "10465800000000027286039278",
                "SizeBytes": 25,
                "StreamViewType": "NEW_IMAGE",
            },
            "eventSourceARN": "arn:aws:dynamodb:eu-west-1:428690775959:table/resume-table/stream/2024-02-17T07:44:14.010",
        }
    ]
}

test_event = {
    "Records": [
        {
            "eventID": "2344b7e50c70682bd1c086dd2d6ec521",
            "eventName": "MODIFY",
            "eventVersion": "1.1",
            "eventSource": "aws:dynamodb",
            "awsRegion": "eu-west-1",
            "dynamodb": {
                "ApproximateCreationDateTime": 1708353416,
                "Keys": {"id": {"S": "Counter"}},
                "NewImage": {"count": {"S": "19"}, "id": {"S": "Counter"}},
                "SequenceNumber": "10465800000000027286039278",
                "SizeBytes": 25,
                "StreamViewType": "NEW_IMAGE",
            },
            "eventSourceARN": "arn:aws:dynamodb:eu-west-1:428690775959:table/resume-table/stream/2024-02-17T07:44:14.010",
        }
    ]
}

from app import *

@mock_aws
class MockTest(unittest.TestCase):
    def setUp(self):
        # Setting up SNS topic
        sns = boto3.client("sns", "eu-west-1")
        sns.create_topic(Name="test_topic")
        response = sns.list_topics()
        self.topic_arn = response["Topics"][0]["TopicArn"]
        MonkeyPatch().setenv("SNS_TOPIC", self.topic_arn)

        # Setting up DynamoDB tables
        dynamodb = boto3.resource("dynamodb", "eu-west-1")
        self.counter_table = dynamodb.create_table(
            TableName=COUNTER_TABLE,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        self.id_table = dynamodb.create_table(
            TableName=CONNECTION_ID_TABLE,
            KeySchema=[{"AttributeName": "connection_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "connection_id", "AttributeType": "S"}
            ],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        self.counter_table.put_item(Item={"id": "Counter", "count": 2})
        self.id_table.put_item(Item={"connection_id": "mockconnectionid"})
        self.id_table.put_item(Item={"connection_id": "mockconnectionid2"})

        # Setting up apigatewayv2
        api = boto3.client("apigatewayv2", "eu-west-1")
        response = api.create_api(
            Name="test_api",
            ProtocolType="WEBSOCKET",
            RouteSelectionExpression="$request.body.action",
        )

        response_stage = api.create_stage(
            ApiId=response["ApiId"], StageName="test_stage"
        )
        
        MonkeyPatch().setenv(
            "WEBSOCKET_ENDPOINT",
            f"https://{response['ApiId']}.execute-api.eu-west-1.amazonaws.com/{response_stage['StageName']}",
        )

    def test_check_count_for_sns_topic(self):
        check_count_for_sns_topic(test_event)

    def test_current_count(self):
        assert get_current_count(test_event) == "19"

    def test_current_connections(self):
        assert get_current_connections(self.id_table) == [
            "mockconnectionid",
            "mockconnectionid2",
        ]

    def test_lambda_handler(self):
        assert lambda_handler(test_event, "") == {"statusCode": 200}

