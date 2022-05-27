#!/bin/sh
# https://wiki.archlinux.org/title/Advanced_traffic_control
# clients - eth2 router eth1 - server
set -x
tc qdisc del dev eth2 root

# Shape all outcoming traffic to 10mbps
tc qdisc add dev eth2 root handle 1: htb
tc class add dev eth2 parent 1: classid 1:1 htb rate 10mbit burst 15k
tc filter add dev eth2 protocol ip parent 1: prio 1 matchall flowid 1:1
