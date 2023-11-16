import json
import os
import boto3

client = boto3.client('dynamodb')
table=os.environ["DDB_TABLE"]

class DataObject():
    def __init__(self) -> None:
        pass
        
    def return_data(self, x):
        return {
            "statusCode": 200,
            "body":{
                "message": x
            }}
            
    def add_visitor(self, x):
        x = int(x) + 1
        item = {'id':{'S':"Counter"}, "count":{"N": str(x)}}
        data = client.put_item(TableName=table,Item=item)
        return x

    def get_item(self):
        item = {'id':{'S':"Counter"}}
        data = client.get_item(TableName=table,Key=item)
        return data["Item"]["count"]["N"]

    def return_value(self):
            return self.return_data(self.add_visitor(self.get_item()))

dbconnector = DataObject()    

def lambda_handler(event, context):
    print("test23")
    return dbconnector.return_value()

