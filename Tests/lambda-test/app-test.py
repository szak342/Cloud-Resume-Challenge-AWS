import boto3
import pytest
import moto
import os
from dotenv import load_dotenv
import sys

sys.path.append('app/app/')

load_dotenv()

print(sys.path)
from app import *

RETURN_DATA = {"statusCode": 200, "body":{ "message": 1}}

@pytest.fixture(scope="session", autouse=True)
def set_env():
    os.environ["DDB_TABLE"] = "test_table"


@moto.mock_dynamodb
def test_lambda_handler():
    
    os.environ["DDB_TABLE"] = "test_table"

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
