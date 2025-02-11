FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        git \
        curl \
        unzip \
        xz-utils \
        libglu1-mesa \
        sudo \
        procps \
        ca-certificates && \
        update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

RUN useradd -m -s /bin/bash dev && \
    echo "dev:dev" | chpasswd && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

EXPOSE 22
EXPOSE 80

WORKDIR /home/dev

CMD ["/usr/sbin/sshd", "-D"]
