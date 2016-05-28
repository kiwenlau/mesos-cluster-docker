#!/bin/bash

MASTER_IP=192.168.59.1
SLAVE_IP=(192.168.59.2 192.168.59.3)
INTERFACE=eth1

# delete all containers on all nodes
echo -e "\n\ndelete all containers on all nodes"
sudo docker -H tcp://$MASTER_IP:4000 rm -f $(sudo docker -H tcp://$MASTER_IP:4000 ps -aq) > /dev/null
for (( i = 0; i < ${#SLAVE_IP[@]}; i++ )); do
        sudo docker -H tcp://${SLAVE_IP[$i]}:4000 rm -f $(sudo docker -H tcp://${SLAVE_IP[$i]}:4000 ps -aq) > /dev/null
done

echo -e "\n"

# start mesos master container 
echo "start master container..."
sudo docker -H tcp://$MASTER_IP:4000 run --net=host \
                                         -itd \
                                         --name=mesos-master \
                                         -e "INTERFACE=$INTERFACE" \
                                         kiwenlau/mesos:0.26.0 supervisord --configuration=/etc/supervisor/conf.d/mesos-master.conf > /dev/null


# start mesos slave container
for (( i = 0; i < ${#SLAVE_IP[@]}; i++ )); do
        echo "start slave$i container..."
        sudo docker -H tcp://${SLAVE_IP[$i]}:4000 run --pid=host \
                                                      -v /var/run/docker.sock:/var/run/docker.sock \
                                                      --net=host \
                                                      -e "INTERFACE=$INTERFACE" \
                                                      -itd \
                                                      --privileged \
                                                      --name=mesos-slave$i \
                                                      -e "MASTER_IP=$MASTER_IP" \
                                                      kiwenlau/mesos:0.26.0 supervisord --configuration=/etc/supervisor/conf.d/mesos-slave.conf > /dev/null
done


# check the status of Mesos/Aurora cluster
echo -e "\nchecking the status of Mesos cluster, please wait..."
for (( i = 0; i < 120; i++ )); do
        mesos_nodes=`sudo docker exec mesos-master curl -s http://$MASTER_IP:5050/state.json | python2.7 -mjson.tool | grep "\"activated_slaves\": ${#SLAVE_IP[@]}.0"`
        if [[ $mesos_nodes ]]; then
                echo -e "\nMesos is running"
                break
        fi
        sleep 1
done

echo ""

