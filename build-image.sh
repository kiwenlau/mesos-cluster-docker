#!/bin/bash

sudo docker rm -f $(sudo docker ps -aq)

echo -e "\nbuild docker mesos image\n"
sudo docker build -f mesos/Dockerfile -t kiwenlau/mesos:0.26.0 ./mesos

echo ""


