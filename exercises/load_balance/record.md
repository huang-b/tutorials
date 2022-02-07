# 实验记录
## 实验命令
启动接收：
```shell
mininet> h2 ./receive.py > logs/h2.log &
mininet> h3 ./receive.py > logs/h3.log &
```

发送命令：
```shell
mininet> h1 ./send.py 10.0.0.1 "P4 is cool"
```