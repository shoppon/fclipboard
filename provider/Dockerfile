FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list /etc/apt/sources.list && \
	rm -Rf /var/lib/apt/lists/* && \
	apt-get update

RUN apt-get -y install wget python3 python3-pip

# for quicker build
COPY requirements.txt /opt/fclipboard/requirements.txt
RUN pip install -r /opt/fclipboard/requirements.txt -i http://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com

COPY . /opt/fclipboard/

CMD ["/bin/bash"]
