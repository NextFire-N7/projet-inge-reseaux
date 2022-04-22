#!/bin/sh
# https://wiki.archlinux.org/title/Advanced_traffic_control
# clients - eth2 router eth1 - server
set -x
tc qdisc del dev eth1 root

MAX_BANDWIDTH=10000 #kbit

EF_RATIO=0.1 # Of the total bandwidth
AF_RATIO=0.5 # Of the remain bandwidth

function calc(){
    echo "scale=10;x=($1);scale=0;x/1" | bc
}

##### Classful Qdiscs #####

# This line sets a HTB qdisc on the root of eth1, and it specifies that the class 1:30 is used by default. It sets the name of the root as 1:, for future references.
tc qdisc add dev eth1 root handle 1: htb default 30

# This creates a class called 1:1, which is direct descendant of root (the parent is 1:), this class gets assigned also an HTB qdisc, and then it sets a max rate of 10mbits, with a burst of 15k
tc class add dev eth1 parent 1: classid 1:1 htb rate ${MAX_BANDWIDTH}kbit ceil ${MAX_BANDWIDTH}kbit burst 15k

# The previous class has this branches:

# EXPEDITED FORWARDING : High-Priority class (eg. Voice) 1:10, which has a **fixed** rate of 1mbit
EF_BANDWIDTH="$(calc "${EF_RATIO}*${MAX_BANDWIDTH}")"
tc class add dev eth1 parent 1:1 classid 1:10 htb rate ${EF_BANDWIDTH}kbit ceil ${EF_BANDWIDTH}kbit burst 15k

# ASSURED FORWARDING : Priority class for higher-than-normal priority trafics (eg. Video, ssh sessions, dedicated flow to peculiar entities, ...) 1:20
# The rate of this class could be dynamic : buyings from entities to get better contraints on their trafic, etc..
# It has been (arbitrarily) set to half the remaining bandwidth here.
AF_BANDWIDTH="$(calc "(1-${EF_RATIO})*${AF_RATIO}*${MAX_BANDWIDTH}")"
tc class add dev eth1 parent 1:1 classid 1:20 htb rate ${AF_BANDWIDTH}kbit ceil ${AF_BANDWIDTH}kbit burst 15k

# BEST EFFORT : Low-Priority class for the rest of the trafic. No contraints and it is the default class.
BE_MAX_BANDWIDTH="$(calc "${MAX_BANDWIDTH}-${EF_BANDWIDTH}-${AF_BANDWIDTH}")"
tc class add dev eth1 parent 1:1 classid 1:30 htb rate 1kbit ceil ${BE_MAX_BANDWIDTH}kbit burst 15k

# Martin Devera, author of HTB, then recommends SFQ for beneath these classes:
# tc qdisc add dev eth1 parent 1:10 handle 10: sfq perturb 10
# tc qdisc add dev eth1 parent 1:20 handle 20: sfq perturb 10
# tc qdisc add dev eth1 parent 1:30 handle 30: sfq perturb 10

# According to one ressource, we can set up a "dsmask" qdisc:
tc qdisc add dev eth1 parent 1:10 handle 10: dsmask indices 1 set_tc_index
tc qdisc add dev eth1 parent 1:20 handle 20: dsmask indices 2 set_tc_index
tc qdisc add dev eth1 parent 1:30 handle 20: dsmask indices 5 set_tc_index


###### Filters ######
# Filters assign packets to a class based on a (combination of) parameter(s) such as: transport protocol, application protocol, ip adress of sender, ...

# Shape all outcoming traffic to 10mbps
# This is not useful because all trafic gets affected to the class 1:30 by default
#tc filter add dev eth1 protocol ip parent 1: prio 1 matchall flowid 1:1

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

tc filter add dev eth1 parent 1: protocol ip prio 1 handle 1 fw flowid 1:10
tc filter add dev eth1 parent 1: protocol ip prio 1 handle 2 fw flowid 1:20
tc filter add dev eth1 parent 1: protocol ip prio 1 handle 5 fw flowid 1:30



###### IPTABLE RULES ######

#TODO:

###### RESSOURCES ######

# https://wiki.archlinux.org/title/advanced_traffic_control#Using_tc_+_iptables
# https://hal.archives-ouvertes.fr/hal-00470674/file/Utilisation_de_l_outil_TC_pour_la_configuration_de_classes_de_service_DiffServ.pdf