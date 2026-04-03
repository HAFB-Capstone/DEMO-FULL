FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openjdk-8-jdk \
        python3 \
        python3-pip \
        python3-venv \
        nmap \
        netcat-openbsd \
        curl \
        wget \
        git \
        maven \
        unzip \
        net-tools \
        iproute2 \
        iputils-ping \
        procps \
        psmisc \
        coreutils \
        ca-certificates \
        bash \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/mbechler/marshalsec.git /tools/marshalsec \
    && cd /tools/marshalsec \
    && mvn clean package -DskipTests -q

RUN wget "https://web.archive.org/web/20211210224333/https://github.com/feihong-cs/JNDIExploit/releases/download/v1.2/JNDIExploit.v1.2.zip" \
      -O /tmp/JNDIExploit.v1.2.zip \
    && unzip /tmp/JNDIExploit.v1.2.zip -d /tools/jndi/ \
    && rm /tmp/JNDIExploit.v1.2.zip

WORKDIR /app

COPY requirements.txt /app/requirements.txt
COPY tools/ /app/tools/
COPY config/ /app/config/

RUN python3 -m venv /opt/rt-log4j-venv \
    && /opt/rt-log4j-venv/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/rt-log4j-venv/bin/pip install --no-cache-dir -r /app/requirements.txt

ENV PATH="/opt/rt-log4j-venv/bin:${PATH}"

RUN ln -s /tools/marshalsec /root/marshalsec \
    && mkdir -p /root/tools \
    && ln -s /tools/jndi /root/tools/jndi

CMD ["/bin/bash"]
