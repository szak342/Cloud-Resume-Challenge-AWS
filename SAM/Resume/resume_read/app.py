import json
import boto3

client = boto3.client('dynamodb')
table='resume-ResumeTable-1Q1PSLSXHEWAT'
COUNTER = False

class DataObject():
    def __init__(self) -> None:
        self.COUNTER = False
        pass
        
    def return_data(self):
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "hello world2"
            })}

    def create_new_counter(self):
        item = {'id':{'S':"Counter"}, "count":{"N", "1"}}
        data = client.put_item(TableName=table,Item=item)

    def add_visitor(self, x):
        x = int(x) + 1
        item = {'id':{'S':"Counter"}, "count":{"N", str(int(x) + 1)}}
        data = client.put_item(TableName=table,Item=item)

    def get_item(self):
        item = {'id':{'S':"Counter"}}
        data = client.get_item(TableName=table,Key=item)
        return data["Item"]["count"]["N"]

    def check_if_counter_exist(self):
        try:
            x = self.get_item()
            COUNTER = True
        except:
            self.create_new_counter(self)

dbconnector = DataObject()    

def lambda_handler(event, context):
    dbconnector.check_if_counter_exist()
    return dbconnector.return_data()
