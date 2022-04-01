#!/bin/sh
# https://wiki.archlinux.org/title/Advanced_traffic_control
# clients - eth2 router eth1 - server
set -x
tc qdisc del dev eth1 root

##### Classful Qdiscs #####

# This line sets a HTB qdisc on the root of eth1, and it specifies that the class 1:30 is used by default. It sets the name of the root as 1:, for future references.
tc qdisc add dev eth1 root handle 1: htb default 30

# This creates a class called 1:1, which is direct descendant of root (the parent is 1:), this class gets assigned also an HTB qdisc, and then it sets a max rate of 10mbits, with a burst of 15k
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit burst 15k

# The previous class has this branches:

# Class 1:10, which has a rate of 5mbit
# tc class add dev eth1 parent 1:1 classid 1:10 htb rate 5mbit burst 15k

# Class 1:20, which has a rate of 3mbit
# tc class add dev eth1 parent 1:1 classid 1:20 htb rate 3mbit ceil 6mbit burst 15k

# Class 1:30, which has a rate of 1kbit. This one is the default class.
# tc class add dev eth1 parent 1:1 classid 1:30 htb rate 1kbit ceil 6mbit burst 15k

# Martin Devera, author of HTB, then recommends SFQ for beneath these classes:
# tc qdisc add dev eth1 parent 1:10 handle 10: sfq perturb 10
# tc qdisc add dev eth1 parent 1:20 handle 20: sfq perturb 10
# tc qdisc add dev eth1 parent 1:30 handle 30: sfq perturb 10

###### Filters ######

tc filter add dev eth1 protocol ip parent 1: prio 1 matchall flowid 1:1

# This command adds a filter to the qdisc 1: of dev eth1, set the
# priority of the filter to 1, matches packets with a
# destination port 22, and make the class 1:10 process the
# packets that match.
# tc filter add dev eth1 protocol ip parent 1: prio 1 u32 match ip dport 22 0xffff flowid 1:10

# This filter is attached to the qdisc 1: of dev eth1, has a
# priority of 2, and matches the ip address 4.3.2.1 exactly, and
# matches packets with a source port of 80, then makes class
# 1:11 process the packets that match
# tc filter add dev eth1 parent 1: protocol ip prio 2 u32 match ip src 4.3.2.1/32 match ip sport 80 0xffff flowid 1:11
