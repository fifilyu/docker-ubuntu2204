FROM ubuntu:22.04

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

ARG DEBIAN_FRONTEND=noninteractive

####################
# 设置APT
####################
COPY file/etc/apt/sources.list /etc/apt/sources.list

RUN apt-get clean
RUN apt-get update

####################
# 语言支持
####################
RUN apt-get install -y locales
RUN locale-gen "en_US.UTF-8"

####################
# 更新系统软件包
####################
RUN apt-get -y upgrade

####################
# 初始化
####################
RUN apt-get install -y mlocate openssh-server iproute2 curl wget tcpdump vim telnet screen sudo rsync tcpdump openssh-client tar bzip2 xz-utils pwgen aptitude apt-file
# 常用编译环境组件
RUN apt-get install -y gcc make libssl-dev

RUN grep 'set fencs=utf-8,gbk' /etc/vimrc || echo 'set fencs=utf-8,gbk' >>/etc/vim/vimrc

####################
# 设置文件句柄
####################
RUN grep '*               soft   nofile            65535' /etc/security/limits.conf || echo "*               soft   nofile            65535" >>/etc/security/limits.conf
RUN grep '*               hard   nofile            65535' /etc/security/limits.conf || echo "*               hard   nofile            65535" >>/etc/security/limits.conf

####################
# 配置SSH服务
####################
RUN mkdir -p /var/run/sshd

RUN mkdir -p /root/.ssh
RUN touch /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

RUN sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
RUN sed -i "s/#GSSAPICleanupCredentials yes/GSSAPICleanupCredentials no/" /etc/ssh/sshd_config
RUN sed -i "s/#MaxAuthTries 6/MaxAuthTries 10/" /etc/ssh/sshd_config
RUN sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 30/" /etc/ssh/sshd_config
RUN sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 10/" /etc/ssh/sshd_config

####################
# 安装Python3.12
####################
RUN apt-get install -y libssl-dev libffi-dev zlib1g-dev tk-dev libsqlite3-dev libbz2-dev ncurses-dev liblzma-dev uuid-dev libreadline-dev libgdbm-dev libgdbm-compat-dev

###########################
## 安装Python312
###########################
COPY file/usr/local/python-3.12.2/ /usr/local/python-3.12.2/
WORKDIR /usr/local
RUN test -L python3 || ln -s python-3.12.2 python3

ARG py_bin_dir=/usr/local/python3/bin
RUN echo "export PATH=${py_bin_dir}:\${PATH}" >/etc/profile.d/python3.sh

WORKDIR ${py_bin_dir}
RUN test -L pip312 || ln -v -s pip3 pip312
RUN test -L python312 || ln -v -s python3 python312

RUN ./pip312 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN ./pip312 install --root-user-action=ignore -U pip

####################
# 安装常用编辑工具
####################
RUN ./pip312 install --root-user-action=ignore -U yq toml-cli

COPY file/usr/local/bin/jq /usr/local/bin/jq
RUN chmod 755 /usr/local/bin/jq

RUN apt-get install -y xmlstarlet crudini

####################
# BASH设置
####################
RUN echo "alias ll='ls -l --color=auto --group-directories-first'" >>/root/.bashrc

####################
# Locale设置
####################
RUN locale-gen en_US.utf8
RUN update-locale LANG=en_US.utf8

####################
# 清理
####################
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22
