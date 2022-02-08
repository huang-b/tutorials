# 实验记录
## 实验命令
启动接收：
```shell
mininet> h2 ./receive.py > logs/h2.log &
mininet> h22 iperf -s -u > logs/h22.log &
```

启动发送：
```shell
mininet> h1 ./send.py 10.0.2.2 "P4 is cool" 60 > logs/h1.log &
mininet> h11 iperf -c 10.0.2.22 -t 15 -u > logs/h11.log &
```