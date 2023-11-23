import boto3
import pytest
import moto
import os

class LambdaDynamoDBClass:
    def __init__(self, lambda_dynamodb_resource):
        self.resource = lambda_dynamodb_resource["resource"]
        self.table_name = lambda_dynamodb_resource["table_name"]
        self.table = self.resource.Table(self.table_name)


@moto.mock_dynamodb
class TestSampleLambda(TestCase):
    def setUp(self) -> None:
        dynamodb = boto3.resource("dynamodb", region_name="eu-west-1")
        dynamodb.create_table(
            TableName = self.test_ddb_table_name,
            AttributeDefinitions = [{"AttributeName": "id", 
                                     "AttributeType": "S"}],
            BillingMode = 'PAY_PER_REQUEST')
        
        mocked_dynamodb_resource = resource("dynamodb")
        mocked_dynamodb_resource = { "resource" : resource('dynamodb'),
                                     "table_name" : self.test_ddb_table_name  }
        self.mocked_dynamodb_class = LambdaDynamoDBClass(mocked_dynamodb_resource)

    def test_create_letter_in_s3(self) -> None:
    
        self.mocked_dynamodb_class.table.put_item(Item={"PK":"D#UnitTestDoc",
                                                        "data":"Unit Test Doc Corpi"})
        self.mocked_dynamodb_class.table.put_item(Item={"PK":"C#UnitTestCust",
                                                        "data":"Unit Test Customer"})