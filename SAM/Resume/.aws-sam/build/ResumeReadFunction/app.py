import json
import boto3

client = boto3.client('dynamodb')
table='resume-ResumeTable-1Q1PSLSXHEWAT'
COUNTER = False

class DataObject():
    def __init__(self) -> None:
        pass
        
    def return_data():
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "hello world2"
            })}

    def create_new_counter():
        item = {'id':{'S':"Counter"}, "count":{"N", "1"}}
        data = client.put_item(TableName=table,Item=data)



    def add_visitor(x):
        x = int(x) + 1
        item = {'id':{'S':"Counter"}, "count":{"N", str(int(x) + 1)}}
        data = client.put_item(TableName=table,Item=data)

    def check_if_counter_exist():
        print("test")
        if COUNTER == False:
            try:
                item = {'id':{'S':"Counter"}}
                data = client.get_item(TableName=table,Key=item)
                COUNTER = True
                #print(data["Item"]["count"]["N"])
            except:
                data = client.put_item(TableName=table,Item=data)

dbconnector = DataObject()    

def lambda_handler(event, context):
    dbconnector.check_if_counter_exist()
    return dbconnector.return_data()
