#!/bin/bash

h2 ./receive.py > logs/h2.log &
h22 iperf -s -u > logs/h22.log &
h1 ./send.py 10.0.2.2 "P4 is cool" 60 > logs/h1.log &
h11 iperf -c 10.0.2.22 -t 15 -u > logs/h11.log &
