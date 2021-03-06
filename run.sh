#!/bin/bash

MASTER_IP=192.168.59.1
SLAVE_IP=(192.168.59.2 192.168.59.3)
INTERFACE=eth1

echo -e "\n"

# delete all containers on all nodes
echo -e "delete all containers on all nodes..."
sudo docker -H tcp://$MASTER_IP:2375 rm -f $(sudo docker -H tcp://$MASTER_IP:2375 ps -aq) > /dev/null
for (( i = 0; i < ${#SLAVE_IP[@]}; i++ )); do
        sudo docker -H tcp://${SLAVE_IP[$i]}:2375 rm -f $(sudo docker -H tcp://${SLAVE_IP[$i]}:2375 ps -aq) > /dev/null
done

echo ""

# start zookeeper container 
echo "start zookeeper container..."
sudo docker -H tcp://$MASTER_IP:2375 run -itd \
                                         --net=host \
                                         --name=zookeeper \
                                         kiwenlau/zookeeper:3.4.8 > /dev/null

# start mesos master container 
echo "start mesos master container..."
sudo docker -H tcp://$MASTER_IP:2375 run -itd \
                                         --net=host \
                                         -e "INTERFACE=$INTERFACE" \
                                         --name=master \
                                         kiwenlau/mesos:0.26.0 start-mesos-master.sh > /dev/null


# start mesos slave container
for (( i = 0; i < ${#SLAVE_IP[@]}; i++ )); do
        echo "start mesos slave$i container..."
        sudo docker -H tcp://${SLAVE_IP[$i]}:2375 run -itd \
                                                      --net=host \
                                                      --pid=host \
                                                      -v /var/run/docker.sock:/var/run/docker.sock \
                                                      -v /sys:/sys \
                                                      -v /tmp/mesos:/tmp/mesos \
                                                      --privileged \
                                                      -e "MASTER_IP=$MASTER_IP" \
                                                      -e "INTERFACE=$INTERFACE" \
                                                      --name=slave$i \
                                                      kiwenlau/mesos:0.26.0 start-mesos-slave.sh > /dev/null
done

                                                      # -v /tmp/mesos:/tmp/mesos \
                                                      # 

# check the status of Mesos/Aurora cluster
echo -e "\nchecking the status of mesos cluster, please wait..."
for (( i = 0; i < 120; i++ )); do
        sleep 2
        mesos_nodes=`sudo docker exec mesos-master curl -s http://$MASTER_IP:5050/state.json | python2.7 -mjson.tool | grep "\"activated_slaves\": ${#SLAVE_IP[@]}.0"`
        if [[ $mesos_nodes ]]; then
                echo -e "\nmesos cluster is running!"
                break
        fi
done

echo -e "\n"

