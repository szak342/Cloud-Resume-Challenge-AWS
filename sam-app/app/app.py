import os
import boto3

client = boto3.client('dynamodb', 'eu-west-1')
table=os.environ["DDB_TABLE"]

def return_data(x):
    return {
        "statusCode": 200,
        "body":{
            "message": x
        }}
            
def add_visitor(x):
    x = int(x) + 1
    item = {'id':{'S':"Counter"}, "count":{"N": str(x)}}
    data = client.put_item(TableName=table,Item=item)
    return x

def get_item():
    item = {'id':{'S':"Counter"}}
    data = client.get_item(TableName=table,Key=item)
    return data["Item"]["count"]["N"]


def lambda_handler(event, context):
    return return_data(add_visitor(get_item()))

print("test")

