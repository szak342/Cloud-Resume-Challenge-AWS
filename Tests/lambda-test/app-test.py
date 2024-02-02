import boto3
import pytest
from pytest import MonkeyPatch
import moto
import os
import sys
import json


path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../') + 'sam-app/app/')
sys.path.append(path)

origin_header = "www.krzysztofszadkowski.com"

MonkeyPatch().setenv("DDB_TABLE", "test_table")
MonkeyPatch().setenv("AWS_ACCESS_KEY_ID", "testing")
MonkeyPatch().setenv("AWS_SECRET_ACCESS_KEY", "testing")
MonkeyPatch().setenv("ALLOWED_SITES","https://krzysztofszadkowski.com,https://www.krzysztofszadkowski.com")

from app import *

RETURN_DATA = {"statusCode": 200, 
               "body":json.dumps({ "message": 1}), 
               "headers": {
                    "Access-Control-Allow-Origin" : origin_header
                },
                "isBase64Encoded": False}

@moto.mock_dynamodb
def test_lambda_handler():
    table_name = "test_table"
    dynamodb = boto3.resource('dynamodb', 'eu-west-1')

    table = dynamodb.create_table(
        TableName=table_name,
        KeySchema=[{'AttributeName': 'id', 'KeyType': 'HASH'}],
        AttributeDefinitions=[{'AttributeName': 'id','AttributeType': 'S'}],
        ProvisionedThroughput={'ReadCapacityUnits': 5, 'WriteCapacityUnits': 5}
    )

    item = {"id": "Counter","count": 0}
    table.put_item(Item=item)
    
    assert return_data(add_visitor(get_item()), origin_header) == RETURN_DATA
