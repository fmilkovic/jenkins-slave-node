# This Dockerfile is used to build an image containing an node jenkins slave

FROM node:4.8.5
MAINTAINER Filip Milkovic <filip@devzion.xyz>

# Add backports
RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list

# Upgrade and Install packages
RUN apt-get update && apt-get -y upgrade && apt-get install -y git openssh-server maven git wget xz-utils build-essential python && apt-get -t jessie-backports install -y openjdk-8-jdk

RUN npm install -g npm@3

# Prepare container for ssh
RUN mkdir /var/run/sshd && adduser --quiet jenkins && echo "jenkins:jenkins" | chpasswd

ADD start.sh .

ENV CI=true
EXPOSE 22

ENTRYPOINT ["./start.sh"]