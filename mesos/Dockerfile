FROM ubuntu:14.04

MAINTAINER kiwenlau <kiwenlau@gmail.com>

# 设置时区
RUN sudo echo "Asia/Tokyo" > /etc/timezone && \
    sudo dpkg-reconfigure -f noninteractive tzdata

WORKDIR /root

RUN apt-get update && apt-get install -y supervisor wget vim nfs-common moreutils curl  

# install docker
RUN wget -qO- https://get.docker.com/ | sh

# Install Java 8 from Oracle's PPA
RUN  sudo apt-get install -y software-properties-common && \
     sudo add-apt-repository ppa:webupd8team/java && \
     echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
     sudo apt-get update -y && \
     sudo apt-get install -y oracle-java8-installer oracle-java8-set-default

# install mesos 0.26.0
RUN sudo apt-get install -y software-properties-common && \
    sudo add-apt-repository ppa:openjdk-r/ppa -y && \
    sudo apt-get update && \
    sudo apt-get install -y software-properties-common wget libsvn1 libcurl3

RUN wget -c http://downloads.mesosphere.io/master/ubuntu/14.04/mesos_0.26.0-0.2.145.ubuntu1404_amd64.deb && \
    sudo dpkg -i mesos_0.26.0-0.2.145.ubuntu1404_amd64.deb && \
    rm mesos_0.26.0-0.2.145.ubuntu1404_amd64.deb 

ADD mesos-master.conf /etc/supervisor/conf.d/mesos-master.conf
ADD mesos-slave.conf /etc/supervisor/conf.d/mesos-slave.conf

# Install ZooKeeper
RUN sudo apt-get install -y zookeeperd

# sudo docker build -t kiwenlau/mesos-aurora .

