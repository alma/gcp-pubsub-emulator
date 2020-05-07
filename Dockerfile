# The Pub/Sub emulator requires Java 8
FROM	java:jre-alpine

ENV	CLOUDSDK_CORE_DISABLE_PROMPTS 1
ENV	DATA_DIR "/pubsub-data"
ENV	HOST_PORT 8085

RUN	apk add --no-cache curl bash python

# Install Google Cloud SDK
RUN	curl https://sdk.cloud.google.com | bash

# Install the Pub/Sub emulator
RUN	/root/google-cloud-sdk/bin/gcloud config set disable_usage_reporting true && \
	/root/google-cloud-sdk/bin/gcloud components install -q pubsub-emulator beta

# Create the directory to store Pub/Sub data
RUN 	mkdir -p "${DATA_DIR}"

# Expose the default emulator port
EXPOSE	8085

ADD start_emulator.sh /
RUN	chmod +x /start_emulator.sh

CMD ["/start_emulator.sh"]
