# 实验记录
## 实验命令
启动接收：
```shell
mininet> h2 ./receive.py > logs/h2.log &
```

启动发送：
```shell
mininet> h1 ./send.py --p=UDP --des=10.0.2.2 --m="P4 is cool" --dur=30 &
mininet> h1 ./send.py --p=TCP --des=10.0.2.2 --m="P4 is cool" --dur=30 &
```