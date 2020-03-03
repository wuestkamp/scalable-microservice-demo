from lib.kafka import Kafka
import json
import logging
from datetime import datetime
import uuid as uuid_lib
import sys
import pymongo
import os
logging.basicConfig(stream=sys.stdout, level=logging.INFO)


topic_user_create = 'user-create'
topic_user_create_response = 'user-create-response'
topic_user_approve = 'user-approve'
topic_user_approve_response = 'user-approve-response'
kafka = Kafka('user-service', [topic_user_create, topic_user_approve_response], [topic_user_approve, topic_user_approve_response])

mongodb_connection_string = os.environ['MONGODB_CONNECTION_STRING']
mongodb_client = pymongo.MongoClient(mongodb_connection_string)
mongodb_database = mongodb_client["user_service"]
mongodb_collection = mongodb_database["user"]


def user_create(msg):
    logging.info(f'creating user for msg:{msg}')

    user = msg['data']
    user['createdAt'] = str(datetime.now())
    user['uuid'] = str(uuid_lib.uuid4())
    user['approved'] = 'pending'

    result = mongodb_collection.insert_one(user.copy())
    logging.info(f'MongoDB insert: {result.inserted_id}')

    msg['data'] = user

    kafka.create_message(topic_user_approve, msg)
    logging.info(f'send user approval for msg:{msg}')


def user_approve(msg):
    logging.info(f'approving user for msg:{msg}')

    user = msg['data']

    user_mongo = user.copy()
    mongodb_collection.replace_one(
        {'uuid': user_mongo['uuid']},
        user_mongo
    )
    logging.info(f'MongoDB user updated')

    msg['data'] = user

    if user['approved'] == 'true':
        msg['response']['state'] = 'completed'
    elif user['approved'] == 'false':
        msg['response']['state'] = 'failed'
        msg['response']['error'] = 'approval failed'

    kafka.create_message(topic_user_create_response, msg)
    logging.info(f'updated user for msg:{msg}')


def new_message_listener(msg):
    topic = msg.topic()
    data = json.loads(msg.value())
    if topic == topic_user_create:
        user_create(data)
    elif topic == topic_user_approve_response:
        user_approve(data)


kafka.subscribe(new_message_listener, 'kafka_new_message')
