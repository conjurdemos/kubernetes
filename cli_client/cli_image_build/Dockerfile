FROM ubuntu:trusty

ENV CONJUR_CLI_PKG=conjur_5.4.0-1_amd64.deb 
COPY ${CONJUR_CLI_PKG} .
RUN dpkg -i ${CONJUR_CLI_PKG} 

RUN sudo apt-get update && apt-get install -y curl
RUN sudo apt-get install -y jq
RUN sudo apt-get install -y apt-transport-https
RUN sudo apt-get install -y ca-certificates
RUN sudo apt-get install -y software-properties-common
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN sudo mv ./kubectl /usr/local/bin/kubectl
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN sudo apt-key fingerprint 0EBFCD88
RUN sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
RUN sudo apt-get update && apt-get install -y docker-ce
# On container startup: wait forever for interrupt signal
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
