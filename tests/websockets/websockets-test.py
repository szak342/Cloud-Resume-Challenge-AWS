import boto3
import pytest
from pytest import MonkeyPatch
from moto import mock_aws
import os
import sys

path = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../../") + "websockets-app/app/"
)
sys.path.append(path)

MonkeyPatch().setenv("CONNECTION_ID_TABLE", "id_table")
MonkeyPatch().setenv("COUNTER_TABLE", "counter_table")
MonkeyPatch().setenv("ALLOWED_ORIGINS", "https://testsite.com")
MonkeyPatch().setenv("ALLOWED_HOST", "allowedhost.com")
MonkeyPatch().setenv("DDB_TABLE", "test_table")
MonkeyPatch().setenv("AWS_ACCESS_KEY_ID", "testing")
MonkeyPatch().setenv("AWS_SECRET_ACCESS_KEY", "testing")

from app import *

request_connect_true = {
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        "Accept-Language": "en-US,en;q=0.5",
        "Cache-Control": "no-cache",
        "Host": "allowedhost.com",
        "Origin": "https://testsite.com",
        "Pragma": "no-cache",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "websocket",
        "Sec-Fetch-Site": "cross-site",
        "Sec-WebSocket-Extensions": "permessage-deflate",
        "Sec-WebSocket-Key": "DM+9PqsQtaZrN+IMZbWTzg==",
        "Sec-WebSocket-Version": "13",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
        "X-Amzn-Trace-Id": "Root=1-65d2ff2e-718990494fd688f062bf1571",
        "X-Forwarded-For": "185.69.197.15",
        "X-Forwarded-Port": "443",
        "X-Forwarded-Proto": "https",
    },
    "multiValueHeaders": {
        "Accept": ["*/*"],
        "Accept-Encoding": ["gzip, deflate, br"],
        "Accept-Language": ["en-US,en;q=0.5"],
        "Cache-Control": ["no-cache"],
        "Host": ["allowedhost.com"],
        "Origin": ["https://testsite.com"],
        "Pragma": ["no-cache"],
        "Sec-Fetch-Dest": ["empty"],
        "Sec-Fetch-Mode": ["websocket"],
        "Sec-Fetch-Site": ["cross-site"],
        "Sec-WebSocket-Extensions": ["permessage-deflate"],
        "Sec-WebSocket-Key": ["DM+9PqsQtaZrN+IMZbWTzg=="],
        "Sec-WebSocket-Version": ["13"],
        "User-Agent": [
            "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0"
        ],
        "X-Amzn-Trace-Id": ["Root=1-65d2ff2e-718990494fd688f062bf1571"],
        "X-Forwarded-For": ["185.69.197.15"],
        "X-Forwarded-Port": ["443"],
        "X-Forwarded-Proto": ["https"],
    },
    "requestContext": {
        "routeKey": "$connect",
        "eventType": "CONNECT",
        "extendedRequestId": "TXzPWFkkjoEF92g=",
        "requestTime": "19/Feb/2024:07:11:42 +0000",
        "messageDirection": "IN",
        "stage": "develop",
        "connectedAt": 1708326702789,
        "requestTimeEpoch": 1708326702790,
        "identity": {
            "userAgent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
            "sourceIp": "185.69.197.15",
        },
        "requestId": "TXzPWFkkjoEF92g=",
        "domainName": "allowedhost.com",
        "connectionId": "TXzPWdnOjoECGjA=",
        "apiId": "nn27okk1we",
    },
    "isBase64Encoded": False,
}

request_connect_false = {
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        "Accept-Language": "en-US,en;q=0.5",
        "Cache-Control": "no-cache",
        "Host": "notallowedhost.com",
        "Origin": "https://falsetestsite.com",
        "Pragma": "no-cache",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "websocket",
        "Sec-Fetch-Site": "cross-site",
        "Sec-WebSocket-Extensions": "permessage-deflate",
        "Sec-WebSocket-Key": "DM+9PqsQtaZrN+IMZbWTzg==",
        "Sec-WebSocket-Version": "13",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
        "X-Amzn-Trace-Id": "Root=1-65d2ff2e-718990494fd688f062bf1571",
        "X-Forwarded-For": "185.69.197.15",
        "X-Forwarded-Port": "443",
        "X-Forwarded-Proto": "https",
    },
    "multiValueHeaders": {
        "Accept": ["*/*"],
        "Accept-Encoding": ["gzip, deflate, br"],
        "Accept-Language": ["en-US,en;q=0.5"],
        "Cache-Control": ["no-cache"],
        "Host": ["notallowedhost.com"],
        "Origin": ["https://falsetestsite.com"],
        "Pragma": ["no-cache"],
        "Sec-Fetch-Dest": ["empty"],
        "Sec-Fetch-Mode": ["websocket"],
        "Sec-Fetch-Site": ["cross-site"],
        "Sec-WebSocket-Extensions": ["permessage-deflate"],
        "Sec-WebSocket-Key": ["DM+9PqsQtaZrN+IMZbWTzg=="],
        "Sec-WebSocket-Version": ["13"],
        "User-Agent": [
            "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0"
        ],
        "X-Amzn-Trace-Id": ["Root=1-65d2ff2e-718990494fd688f062bf1571"],
        "X-Forwarded-For": ["185.69.197.15"],
        "X-Forwarded-Port": ["443"],
        "X-Forwarded-Proto": ["https"],
    },
    "requestContext": {
        "routeKey": "$connect",
        "eventType": "CONNECT",
        "extendedRequestId": "TXzPWFkkjoEF92g=",
        "requestTime": "19/Feb/2024:07:11:42 +0000",
        "messageDirection": "IN",
        "stage": "develop",
        "connectedAt": 1708326702789,
        "requestTimeEpoch": 1708326702790,
        "identity": {
            "userAgent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
            "sourceIp": "185.69.197.15",
        },
        "requestId": "TXzPWFkkjoEF92g=",
        "domainName": "notallowedhost.com",
        "connectionId": "TXzPWdnOjoECGjA=",
        "apiId": "nn27okk1we",
    },
    "isBase64Encoded": False,
}

request_disconnect_true = {
    "headers": {
        "Host": "allowedhost.com",
        "x-api-key": "",
        "X-Forwarded-For": "",
        "x-restapi": "",
    },
    "multiValueHeaders": {
        "Host": ["allowedhost.com"],
        "x-api-key": [""],
        "X-Forwarded-For": [""],
        "x-restapi": [""],
    },
    "requestContext": {
        "routeKey": "$disconnect",
        "disconnectStatusCode": 1001,
        "eventType": "DISCONNECT",
        "extendedRequestId": "TX0tuFp2joEF5Zw=",
        "requestTime": "19/Feb/2024:07:21:46 +0000",
        "messageDirection": "IN",
        "disconnectReason": "Going away",
        "stage": "develop",
        "connectedAt": 1708326702789,
        "requestTimeEpoch": 1708327306706,
        "identity": {
            "userAgent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
            "sourceIp": "185.69.197.15",
        },
        "requestId": "TX0tuFp2joEF5Zw=",
        "domainName": "allowedhost.com",
        "connectionId": "TXzPWdnOjoECGjA=",
        "apiId": "nn27okk1we",
    },
    "isBase64Encoded": False,
}

request_disconnect_false = {
    "headers": {
        "Host": "falseallowedhost.com",
        "x-api-key": "",
        "X-Forwarded-For": "",
        "x-restapi": "",
    },
    "multiValueHeaders": {
        "Host": ["falseallowedhost.com"],
        "x-api-key": [""],
        "X-Forwarded-For": [""],
        "x-restapi": [""],
    },
    "requestContext": {
        "routeKey": "$disconnect",
        "disconnectStatusCode": 1001,
        "eventType": "DISCONNECT",
        "extendedRequestId": "TX0tuFp2joEF5Zw=",
        "requestTime": "19/Feb/2024:07:21:46 +0000",
        "messageDirection": "IN",
        "disconnectReason": "Going away",
        "stage": "develop",
        "connectedAt": 1708326702789,
        "requestTimeEpoch": 1708327306706,
        "identity": {
            "userAgent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
            "sourceIp": "185.69.197.15",
        },
        "requestId": "TX0tuFp2joEF5Zw=",
        "domainName": "falseallowedhost.com",
        "connectionId": "TXzPWdnOjoECGjA=",
        "apiId": "nn27okk1we",
    },
    "isBase64Encoded": False,
}

request_connect_wrong_routeKey = {
    "headers": {
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate, br",
        "Accept-Language": "en-US,en;q=0.5",
        "Cache-Control": "no-cache",
        "Host": "allowedhost.com",
        "Origin": "https://testsite.com",
        "Pragma": "no-cache",
        "Sec-Fetch-Dest": "empty",
        "Sec-Fetch-Mode": "websocket",
        "Sec-Fetch-Site": "cross-site",
        "Sec-WebSocket-Extensions": "permessage-deflate",
        "Sec-WebSocket-Key": "DM+9PqsQtaZrN+IMZbWTzg==",
        "Sec-WebSocket-Version": "13",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
        "X-Amzn-Trace-Id": "Root=1-65d2ff2e-718990494fd688f062bf1571",
        "X-Forwarded-For": "185.69.197.15",
        "X-Forwarded-Port": "443",
        "X-Forwarded-Proto": "https",
    },
    "multiValueHeaders": {
        "Accept": ["*/*"],
        "Accept-Encoding": ["gzip, deflate, br"],
        "Accept-Language": ["en-US,en;q=0.5"],
        "Cache-Control": ["no-cache"],
        "Host": ["allowedhost.com"],
        "Origin": ["https://testsite.com"],
        "Pragma": ["no-cache"],
        "Sec-Fetch-Dest": ["empty"],
        "Sec-Fetch-Mode": ["websocket"],
        "Sec-Fetch-Site": ["cross-site"],
        "Sec-WebSocket-Extensions": ["permessage-deflate"],
        "Sec-WebSocket-Key": ["DM+9PqsQtaZrN+IMZbWTzg=="],
        "Sec-WebSocket-Version": ["13"],
        "User-Agent": [
            "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0"
        ],
        "X-Amzn-Trace-Id": ["Root=1-65d2ff2e-718990494fd688f062bf1571"],
        "X-Forwarded-For": ["185.69.197.15"],
        "X-Forwarded-Port": ["443"],
        "X-Forwarded-Proto": ["https"],
    },
    "requestContext": {
        "routeKey": "$image",
        "eventType": "CONNECT",
        "extendedRequestId": "TXzPWFkkjoEF92g=",
        "requestTime": "19/Feb/2024:07:11:42 +0000",
        "messageDirection": "IN",
        "stage": "develop",
        "connectedAt": 1708326702789,
        "requestTimeEpoch": 1708326702790,
        "identity": {
            "userAgent": "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0",
            "sourceIp": "185.69.197.15",
        },
        "requestId": "TXzPWFkkjoEF92g=",
        "domainName": "allowedhost.com",
        "connectionId": "TXzPWdnOjoECGjA=",
        "apiId": "nn27okk1we",
    },
    "isBase64Encoded": False,
}


import unittest


@mock_aws
class MockTest(unittest.TestCase):
    def setUp(self):
        dynamodb = boto3.resource("dynamodb", "eu-west-1")
        self.counter_table = dynamodb.create_table(
            TableName=COUNTER_TABLE,
            KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
            AttributeDefinitions=[{"AttributeName": "id", "AttributeType": "S"}],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        self.id_table = dynamodb.create_table(
            TableName=CONNECTION_ID_TABLE,
            KeySchema=[{"AttributeName": "connection_id", "KeyType": "HASH"}],
            AttributeDefinitions=[
                {"AttributeName": "connection_id", "AttributeType": "S"}
            ],
            ProvisionedThroughput={"ReadCapacityUnits": 5, "WriteCapacityUnits": 5},
        )
        self.counter_table.put_item(Item={"id": "Counter", "count": 0})

    def test_origin(self):
        assert check_origin(request_connect_true) == True
        assert check_origin(request_connect_false) == False

    def test_host(self):
        assert check_host(request_disconnect_true) == True
        assert check_host(request_disconnect_false) == False

    def test_connect(self):
        assert (
            connect("guest", self.id_table, self.counter_table, "mockconnectionid")
            == 200
        )

    def test_disconnect(self):
        assert disconnect(self.id_table, "mockconnectionid") == 200

    def test_lambda_handler(self):
        assert lambda_handler(request_connect_true, "") == {"statusCode": 200}
        assert lambda_handler(request_connect_false, "") == {"statusCode": 403}
        assert lambda_handler(request_disconnect_true, "") == {"statusCode": 200}
        assert lambda_handler(request_disconnect_false, "") == {"statusCode": 403}
        assert lambda_handler(request_connect_wrong_routeKey, "") == {"statusCode": 404}
