# 实验记录
## 实验命令
启动接收：
```shell
mininet> h1 ./receive.py > logs/recv.log &
```

启动发送：
```shell
mininet> h1 ./send.py > logs/send.log &
```

启动负载：
* 文档中推荐的负载如下，这个流一共经过3跳，但因为探测包路径的原因，`s2->h4`的带宽没有被探测到，所以只能看到前两跳的带宽。
```shell
mininet> iperf h1 h4 
```
* 虽然`s1->h1`的带宽被探测到了，但测试流量主要是从`h1->s1->s3/s4->s2->h4`，反向流量并不大。
* 所以，结合探测路径，建议使用如下负载，可以看到三跳端口的流量。
```shell
mininet> iperf h4 h1 
```