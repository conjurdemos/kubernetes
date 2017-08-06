FROM ubuntu:trusty

ENV CONJUR_CLI_PKG=conjur_5.4.0-1_amd64.deb 
COPY ${CONJUR_CLI_PKG} .
RUN dpkg -i ${CONJUR_CLI_PKG} 

RUN apt-get update && apt-get install -y curl
RUN apt-get update && apt-get install -y jq
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN sudo mv ./kubectl /usr/local/bin/kubectl

# On container startup: wait forever for interrupt signal
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
