# gcp-pubsub-emulator

Run GCP Pub/Sub emulator in a Docker container for development and testing purposes

## Usage

Retrieve the latest version of the Docker image:

```shell
$ docker pull "getalma/gcp-pubsub-emulator:latest"
```

Run the Docker container, by making it reachable through port `8085`:

```shell
$ docker run \
	--rm --tty --interactive \
	--publish "8085:8085" \
	--name "pubsub_emulator" \
	"getalma/gcp-pubsub-emulator:latest"
```

or using `docker-compose`:

```shell
$ cat docker-compose.yml
version: "3"

services:
  pubsub-emulator:
    image: getalma/gcp-pubsub-emulator:latest

  some-service:
    build: .
    environment:
      - PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
    depends_on:
      - pubsub-emulator

$ docker-compose up "some-service"
Creating pubsub-emulator_1 ... done
Creating some-service_1 ... done
Attaching to some-service_1
...
```

You can, now, use the emulator to develop and test your application.

## Run an application against the emulator

First install the Google Cloud Pub/sub client library (in a virtualenv on inside a Docker container):

```shell
$ pip install --upgrade google-cloud-pubsub
```

Then, set the environment variable that will allow your code to run on the emulator, instead of trying to connect to Google Cloud Pub/Sub:

```shell
export PUBSUB_EMULATOR_HOST=localhost:8085
```

After this, you can use the client library to create topics and subscriptions, publish and receive messages.

Start by importing the client library and creating the needed publisher and subscriber

```shell
$ ipython
Python 3.8.2 (default, Apr 23 2020, 14:22:33) 
Type 'copyright', 'credits' or 'license' for more information
IPython 7.14.0 -- An enhanced Interactive Python. Type '?' for help.

In [1]: from google.cloud import pubsub_v1 
   ...:  
   ...: PROJECT_ID="some_project" 
   ...: TOPIC="some_topic"       
   ...: SUBSCRIPTION="I_want_messages"  
   ...:  
   ...: publisher = pubsub_v1.PublisherClient() 
   ...: subscriber = pubsub_v1.SubscriberClient() 
   ...:  
   ...: subscription_path = subscriber.subscription_path(PROJECT_ID, SUBSCRIPTION) 
   ...: topic_path = publisher.topic_path(PROJECT_ID, TOPIC) 
   ...:                                                                     
```                        

Create a topic and a subscription:

```shell
In [2]: publisher.create_topic(topic_path)                                                           
Out[2]: name: "projects/some_project/topics/some_topic"

In [3]: subscriber.create_subscription(subscription_path, topic_path) 
   ...:                                                                                              
Out[3]: 
name: "projects/some_project/subscriptions/I_want_messages"
topic: "projects/some_project/topics/some_topic"
push_config {
}
ack_deadline_seconds: 10
message_retention_duration {
  seconds: 604800
}
```

Try to `pull` some messages from the subscription. There are none (if you do not use `return_immediately=True`, the `pull` function will wait until it receives a messages or it reaches a timeout of several seconds)

```shell
In [4]: response = subscriber.pull(subscription_path, max_messages=5, return_immediately=True) 
   ...:                                                                                              

In [5]: for msg in response.received_messages: 
   ...:     print("Received message:", msg.message.data) 
   ...:                                                                      
```

Publish a message:
```shell
In [6]: publisher.publish(topic_path, b'My first message!', spam='eggs') 
   ...:                                                                                              
Out[6]: <google.cloud.pubsub_v1.publisher.futures.Future at 0x7f75acee6610>
```

And pull if from the subscription:
```shell
In [7]: response = subscriber.pull(subscription_path, max_messages=5, return_immediately=True) 
   ...:  
   ...: for msg in response.received_messages: 
   ...:     print("Received message:", msg.message.data) 
   ...:                                                                                              
Received message: b'My first message!'

In [8]: response                                                                                     
Out[8]: 
received_messages {
  ack_id: "projects/some_project/subscriptions/I_want_messages:1"
  message {
    data: "My first message!"
    attributes {
      key: "spam"
      value: "eggs"
    }
    message_id: "1"
    publish_time {
      seconds: 1588873495
    }
  }
}
```

