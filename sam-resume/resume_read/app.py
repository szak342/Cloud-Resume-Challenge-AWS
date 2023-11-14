import json
import boto3

client = boto3.client('dynamodb')
table='resume-ResumeTable-1W6TYC4BQGRJU'

class DataObject():
    def __init__(self) -> None:
        self.COUNTER = False
        pass
        
    def return_data(self, x):
        return {
            "statusCode": 200,
            "body":{
                "message": x
            }}

    def create_new_counter(self):
        item = {'id':{'S':"Counter"}, "count":{"N": "1"}}
        data = client.put_item(TableName=table,Item=item)

    def add_visitor(self, x):
        x = int(x) + 1
        item = {'id':{'S':"Counter"}, "count":{"N": str(x)}}
        data = client.put_item(TableName=table,Item=item)
        return x

    def get_item(self):
        item = {'id':{'S':"Counter"}}
        data = client.get_item(TableName=table,Key=item)
        return data["Item"]["count"]["N"]

    def check_if_counter_exist(self):
        try:
            return self.return_data(self.add_visitor(self.get_item()))
            #self.COUNTER = True
        except:
            print("creating counter")
            self.create_new_counter()
            return self.return_data("1")

dbconnector = DataObject()    

def lambda_handler(event, context):
    return dbconnector.check_if_counter_exist()
