#!/bin/sh -e
# https://wiki.archlinux.org/title/Advanced_traffic_control
# clients - router - eth1 server
set -x
tc qdisc del dev eth1 root

# Shape all outcoming traffic to 10mbps
tc qdisc add dev eth1 root handle 1: htb default 30
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit burst 15k
tc filter add dev eth1 protocol ip parent 1: prio 1 matchall flowid 1:1
