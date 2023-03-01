#! /bin/bash
screen -dmS etcd bash startetcd.sh
systemctl restart salt-master
systemctl restart salt-api
systemctl restart gosalt
