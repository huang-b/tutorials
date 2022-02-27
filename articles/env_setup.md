最近学习了P4语言（一种应用在可编程交换机上的编程语言）的官方教程[P4tutorials](https://github.com/p4lang/tutorials)，这个教程由一系列实验组成，每个实验都是用P4语言实现特定的网络功能，涉及经典的三层转发、贴近应用的负载均衡、较为前沿的带内遥测等多个主题，引导实验者在动手过程中感受P4语言的特性，非常推荐有兴趣的读者动手学习。

本来计划学习之后写一写实验总结，但每个实验都有非常详细的引导，几乎是手把手教学，再多说就算剧透了，所以这篇文章就只说实验环境的搭建，实验内容还是大家亲自去感受。这篇文章主要介绍我搭建实验环境的过程，教程本身提供了实验用的虚拟机，但我的实验电脑上没有虚拟机软件，不过正好装了Docker，所以就试着构建一个实验用的Docker镜像。

## 镜像构建
实验环境其实比较简单，主体就是p4c和mininet，再加上一些网络工具。

__基础镜像__

使用Docker搭建环境的好处是可以借助Dockerhub找到现成的[p4c镜像](https://hub.docker.com/r/p4lang/p4c)，在此基础上完成其他软件安装即可。

__构建镜像__

[mininet](https://github.com/mininet/mininet)源码附带了安装脚本，所以我是直接下载源码安装的。我在实验电脑上的工作目录如下：
```
工作目录
+-- Dockerfile
+-- start.sh
+-- mininet/
+-- tutorials/
```

其中，`tutorials`目录里是下载的教程源码；`start.sh`是启动容器的脚本，这一步用不到；`mininet`目录里是下载的mininet源码，放在这里是为了构建镜像时能够复制到镜像内部；`Dockerfile`用于构建镜像，其完整内容如下：
```Dockerfile
# 基础镜像
FROM p4lang/p4c:stable
# 安装编译需要的软件
RUN apt-get update -y && apt-get --yes --force-yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install sudo build-essential iputils-ping
# 把mininet源码复制到镜像内
ADD mininet /home/mininet
# 从源码安装mininet
RUN PYTHON=python3 /home/mininet/util/install.sh -a
# 安装辅助工具
RUN pip3 install psutil
```

在工作目录下，使用如下命令构建镜像：
```shell
docker build -t myrepo/p4tutorials .
```
> 输入命令不要漏掉最后的 `.` ，表示在当前目录构建镜像，其实在哪个目录构建都可以，只要那个目录底下有Dockerfile和mininet源码就可以。

__启动容器__

仍然在工作目录下，启动镜像时把教程目录挂载到容器内，对应的命令如下（start.sh里就是这个命令）：
```
docker run --rm --privileged -v ~/Program/p4tutorials/tutorials:/home/p4tutorials -it p4lang/p4tutorials bash
```
容器启动以后，我们下载的教程源码就在`/home/p4tutorials`目录下，进入这个目录就可以开始实验。

## 多窗口操作
教程里的各个实验基本都是通过收发报文来验证正确性的，所以需要多窗口操作，各个窗口分别在不同节点上启动发送进程和接收进程。因为教程预设是在有图形界面的虚拟机里进行实验，所以多窗口都是通过在mininet命令行里执行xterm来打开的，但是Docker容器里没办法打开xterm，所以需要想其他办法完成实验。

### mininet内多窗口
大部分实验是在mininet模拟器的命令行里启动多窗口，比如qos实验，需要在节点h1和h2上各开一个xterm窗口，在h1运行send.py，在h2运行receive.py。在Docker实验环境里，启动mininet以后虽然不能打开多个窗口，但是mininet本身可以模拟在不同节点上执行命令，只要在命令前加上节点名即可，比如`h1 ping h2`就是在h1上执行ping命令，目标主机是h2。在此基础上，就可以利用后台进程来完成实验。具体操作如下：
```shell
# 在h2上启动接收进程并转入后台执行，进程输出重定向到指定日志文件
mininet> h2 ./receive.py > logs/h2.log &
# 在h1上启动发送进程，因为发送进程要接收键盘输入，所以保留在前台
mininet> h1 ./send.py 10.0.2.2
```
因为容器里面的实验目录是从宿主机（也就是做实验的电脑）上映射过来的，所以在宿主机文件系统里就能查看h2.log，这样就可以一边在Docker容器里操作发送脚本发包，一边在宿主机上查看接收脚本的输出。


### mininet外多窗口
教程里的`p4runtime`实验比较特别，别的实验都是在启动mininet实例以后再打开多窗口，而这个实验是要在启动mininet之前就在虚拟机里打开两个窗口，其中一个运行mininet实例并验证网络联通性，另外一个用于运行`mycontroller.py`，负责往虚拟交换机中注入表项以及读取计数器。这个实验用前后台进程的方法做起来比较困难（前后台进程可以切换，但似乎mininet命令行不支持相关命令），不过多窗口是在启动mininet之前打开的，不受限于mininet命令行其实灵活很多。我选择的办法是在容器内启动ssh服务端，然后从宿主机ssh登陆到容器内，这样就可打开多个独立窗口完成实验。

这个方案需要修改`start.sh`，最终内容如下：
```
#!/bin/bash
pub_key=`cat ~/.ssh/id_rsa.pub`

docker run --rm --privileged -p 10022:22 -v ~/Program/p4tutorials/tutorials:/home/p4tutorials -it p4lang/p4tutorials bash -c "mkdir -p /root/.ssh && echo \"$pub_key\" >> /root/.ssh/authorized_keys && /etc/init.d/ssh start && bash"
```

对`start.sh`的修改主要解决两个问题：
* __宿主机与容器的网络联通性__：Docker容器默认是运行在虚拟网络上的，与宿主机网络并不连通（不在一个网络命名空间），这个问题可以通过指定[容器与宿主机共用网络](https://docs.docker.com/network/network-tutorial-host/)或者端口映射的方法来解决，这里推荐端口映射的方式，也就是上面命令中的 `-p 10022:22` 参数，作用是把容器的22端口映射为宿主机的10022端口，这样配置以后，在宿主机运行 `ssh root@localhost -p 10022` 就可以登陆到容器内。
* __ssh免密登陆__：为了方便，我希望从宿主机登陆容器的时候无需输入密码，具体做法是在启动时把宿主机上我的公钥（即`~/.ssh/id_rsa.pub`的内容）复制到容器内的可信密钥配置（即`/root/.ssh/authorized_keys`）里。配置以后我在宿主机上的用户就可以免密登陆为容器里的root用户。

## 写在后面
再次推荐感兴趣的读者亲身体验一下[P4tutorials](https://github.com/p4lang/tutorials)。本文记录的是用Docker搭建教程实验环境的过程，以及在Docker环境下对实验操作的一些调整，我自己完成的实验放在了[github](https://github.com/huang-b/tutorials)上，具体的实验代码无需参考，每个实验都有个solution目录，里面是教程设计者给的实现方案，更有参考价值；在一些需要多窗口操作的实验目录下我放了个`record.md`文件，记录了通过后台进程的方式完成实验用到的命令，有需要的读者可以参考。
