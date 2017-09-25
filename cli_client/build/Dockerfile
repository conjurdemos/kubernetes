FROM ubuntu:16.04

RUN apt-get update && apt-get install -y curl

RUN curl -o conjur.deb -L https://github.com/conjurinc/cli-ruby/releases/download/v5.4.0/conjur_5.4.0-1_amd64.deb \
  && dpkg -i conjur.deb \
  && rm conjur.deb

RUN apt-get install -y vim
RUN apt-get install -y jq
RUN apt-get install -y apt-transport-https
RUN apt-get install -y ca-certificates
RUN apt-get install -y software-properties-common
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x ./kubectl
RUN mv ./kubectl /usr/local/bin/kubectl
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
RUN curl -Lo summon.tar.gz https://github.com/cyberark/summon/releases/download/v0.6.5/summon-linux-amd64.tar.gz && tar xvf summon.tar.gz && mv summon /usr/local/bin

# On container startup: wait forever for interrupt signal
CMD exec /bin/bash -c "trap : TERM INT; sleep infinity & wait"
