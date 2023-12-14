import os
import boto3
import json


client = boto3.client('dynamodb', 'eu-west-1')
table=os.environ["DDB_TABLE"]
allowed_origins = os.environ["ALLOWED_SITES"].split(",")
print(allowed_origins)


def return_data(x, origin_header):
    return {
        "statusCode": 200,
        "body":json.dumps({"message": x})
            ,
        "headers": {
                    "Access-Control-Allow-Origin" : origin_header
                },
        "isBase64Encoded": False
        }
    
            
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
    #return return_data(add_visitor(get_item()), event)
    if 'headers' in event and 'origin' in event['headers']:
        origin_header = event['headers']['origin']
        if origin_header in allowed_origins:
            return return_data(add_visitor(get_item()), origin_header)
                
        else:
            return {
                'statusCode': 403,
                'body': json.dumps('Access denied. Invalid origin.')
                }
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Bad Request. Origin header not found.')
        }


