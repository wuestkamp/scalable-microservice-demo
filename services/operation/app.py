from flask import Flask
from flask_cors import CORS
from flask import request, Response
import json
import uuid as uuid_lib
from lib.kafka import Kafka
import logging
import pymongo
import sys
import os
logging.basicConfig(stream=sys.stdout, level=logging.INFO)

app = Flask(__name__)
CORS(app)

topic_user_create = 'user-create'
topic_user_create_response = 'user-create-response'
kafka = Kafka('operation-service', [topic_user_create_response], [topic_user_create, topic_user_create_response])

allowed_operations = [topic_user_create]

mongodb_connection_string = os.environ['MONGODB_CONNECTION_STRING']
mongodb_client = pymongo.MongoClient(mongodb_connection_string)
mongodb_database = mongodb_client["operation_service"]
mongodb_collection = mongodb_database["operation"]


@app.route('/operation/create/<operation_name>', methods=['POST'])
def action_operation_create(operation_name):
    uuid = uuid_lib.uuid4()
    content = request.json
    msg = {
        'uuid': f'{uuid}',
        'type': operation_name,
        'state': 'pending',
        'data': content,
        'response': {
            'state': 'pending'
        }
    }
    if operation_name in allowed_operations:
        kafka.create_message(operation_name, msg)
    else:
        msg['state'] = 'failed'
        msg['error'] = 'operation not allowed'

    result = mongodb_collection.insert_one(msg.copy())
    logging.info(f'MongoDB insert: {result.inserted_id}')

    return Response(json.dumps(msg))


@app.route('/operation/get/<uuid>', methods=['GET'])
def action_operation_get(uuid):
    result = mongodb_collection.find_one({'uuid': uuid})
    if result and '_id' in result:
        del result['_id']
        logging.info(f'MongoDB find: {result}')

        return Response(json.dumps(result))
    else:
        return Response(json.dumps({}))


def update_operation_response(msg):
    if msg['response']['state'] == 'completed':
        msg['state'] = 'completed'
    else:
        msg['state'] = 'failed'
        msg['error'] = msg['response']['error']
    msg_mongo = msg.copy()
    mongodb_collection.replace_one(
        {'uuid': msg_mongo['uuid']},
        msg_mongo
    )
    logging.info(f'MongoDB update done')


def new_message_listener(msg):
    topic = msg.topic()
    data = json.loads(msg.value())
    if topic == topic_user_create_response:
        update_operation_response(data)


kafka.subscribe(new_message_listener, 'kafka_new_message')


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', use_reloader=False)
