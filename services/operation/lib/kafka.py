from confluent_kafka import Producer, Consumer
from confluent_kafka.admin import AdminClient, NewTopic
import json
import os
import threading
import logging
import sys
from pubsub import pub

logging.basicConfig(stream=sys.stdout, level=logging.INFO)

bootstrap_servers = os.environ['KAFKA_BOOTSTRAP_SERVERS']
sasl_username = os.environ['KAFKA_SASL_USERNAME']
sasl_password = os.environ['KAFKA_SASL_PASSWORD']


class Kafka:
    __p = None
    __c = None
    __a = None
    __poll_thread = None
    __topics_consume = []
    __topics_create = []
    __messages = {}

    def __init__(self, group_id, topics_consume, topics_create=None):
        self.__topics_consume = topics_consume
        self.__topics_create = topics_create

        self.__p = Producer({
            'bootstrap.servers': bootstrap_servers,
            'sasl.mechanisms': 'PLAIN',
            'security.protocol': 'SASL_SSL',
            'sasl.username': sasl_username,
            'sasl.password': sasl_password,
        })

        self.__c = Consumer({
            'bootstrap.servers': bootstrap_servers,
            'sasl.mechanisms': 'PLAIN',
            'security.protocol': 'SASL_SSL',
            'sasl.username': sasl_username,
            'sasl.password': sasl_password,
            'group.id': group_id,
            'auto.offset.reset': 'earliest'
        })

        self.__a = AdminClient({
            'bootstrap.servers': bootstrap_servers,
            'sasl.mechanisms': 'PLAIN',
            'security.protocol': 'SASL_SSL',
            'sasl.username': sasl_username,
            'sasl.password': sasl_password,
            'group.id': group_id,
            'auto.offset.reset': 'earliest'
        })

        if topics_create:
            self.__create_topics(topics_create)

        self.__poll_thread = threading.Thread(target=self.__thread_consume)
        self.__poll_thread.start()
        self.subscribe(self.__new_message_listener, 'kafka_new_message')

    @staticmethod
    def subscribe(listener, topic_name):
        pub.subscribe(listener, topic_name)

    def create_message(self, topic, value):
        """
        create a new Kafka message
        """
        logging.info(f'Producing record: {value}')
        self.__p.produce(topic, value=json.dumps(value), on_delivery=self.__create_message_acked)
        self.__p.poll(0)
        self.__p.flush()

    def __create_topics(self, topics):
        """ Create topics """
        new_topics = [NewTopic(topic, num_partitions=6, replication_factor=3) for topic in topics]
        # Call create_topics to asynchronously create topics, a dict
        # of <topic,future> is returned.
        fs = self.__a.create_topics(new_topics)

        # Wait for operation to finish.
        # Timeouts are preferably controlled by passing request_timeout=15.0
        # to the create_topics() call.
        # All futures will finish at the same time.
        for topic, f in fs.items():
            try:
                f.result()  # The result itself is None
                print("Topic {} created".format(topic))
            except Exception as e:
                print("Failed to create topic {}: {}".format(topic, e))

    def __thread_consume(self):
        """
        endless loop polling Kafka for new messages
        """
        self.__c.subscribe(self.__topics_consume)
        try:
            while True:
                msg = self.__c.poll(0.1)
                if msg is None:
                    # logging.info('poll')
                    continue
                elif msg.error():
                    logging.error('error: {}'.format(msg.error()))
                    continue
                else:
                    pub.sendMessage('kafka_new_message', msg=msg)
        except KeyboardInterrupt:
            self.__c.close()
        return None

    def __new_message_listener(self, msg):
        topic = msg.topic()
        data = json.loads(msg.value())
        logging.info(f'Consumed record with topic:{topic} data:{data}')
        uuid = data['uuid']
        messages_key = f'{topic}_{uuid}'
        if messages_key in self.__messages and self.__messages[messages_key] == 'awaiting':
            self.__messages[messages_key] = data

    @staticmethod
    def __create_message_acked(err, msg):
        if err is not None:
            logging.error('Failed to deliver message: {}'.format(err))
        else:
            logging.info('Produced record to topic {} partition [{}] @ offset {}'.format(msg.topic(), msg.partition(),
                                                                   msg.offset()))
