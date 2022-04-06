#!/bin/bash

killall iperf3

base_port=5200

num_servers=$1
shift
iperf_options="$*"

for i in $(seq 1 $num_servers); do
	server_port=$(($base_port+$i));
	iperf3 -s -p $server_port $iperf_options &
done
