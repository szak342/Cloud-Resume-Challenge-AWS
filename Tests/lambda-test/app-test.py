import boto3
import pytest
from pytest import MonkeyPatch
import moto
import os
import sys


path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../') + 'sam-app/app/')
sys.path.append(path)

MonkeyPatch().setenv("DDB_TABLE", "test_table")

from app import *

RETURN_DATA = {"statusCode": 200, "body":{ "message": 1}}

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
    
    assert return_data(add_visitor(get_item())) == RETURN_DATA
