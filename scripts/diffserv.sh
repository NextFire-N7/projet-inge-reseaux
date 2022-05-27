#!/bin/sh
# https://wiki.archlinux.org/title/Advanced_traffic_control
# clients - router - eth1 server
set -x

### Queuing ###

tc qdisc del dev eth1 root

## Hierarchical Token Bucket (HTB) ##

# This line sets a HTB qdisc on the root of eth1, and it specifies that the class 1:30 is used by default. It sets the name of the root as 1:, for future references.
tc qdisc add dev eth1 root handle 1: htb default 30

# This creates a class called 1:1, which is direct descendant of root (the parent is 1:), this class gets assigned also an HTB qdisc, and then it sets a max rate of 10mbits, with a burst of 15k
tc class add dev eth1 parent 1: classid 1:1 htb rate 10mbit burst 15k

# The previous class has this branches:

# Class 1:10, which has a rate of 8mbit // Expedited Forwarding
tc class add dev eth1 parent 1:1 classid 1:10 htb rate 8mbit burst 15k prio 1

# Class 1:20, which has a rate of 1mbit // Assured Forwarding
tc class add dev eth1 parent 1:1 classid 1:20 htb rate 1mbit ceil 10mbit burst 15k prio 2

# Class 1:30, which has a rate of 1kbit. This one is the default class. // Best effort
tc class add dev eth1 parent 1:1 classid 1:30 htb rate 1kbit ceil 10mbit burst 15k prio 3

### Filters ###

## Using tc only ##

tc filter add dev eth1 protocol ip parent 1: prio 1 u32 match ip sport 5201 0xffff flowid 1:10
tc filter add dev eth1 protocol ip parent 1: prio 1 u32 match ip sport 5202 0xffff flowid 1:20
tc filter add dev eth1 protocol ip parent 1: prio 1 u32 match ip sport 5203 0xffff flowid 1:30
