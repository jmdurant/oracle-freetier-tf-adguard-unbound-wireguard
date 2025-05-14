#!/bin/bash
HOST=$(hostname -f)
DATE=$(date +"%d%m%Y-%H%M%S")
LOGFILE="/tmp/wg_openemr_${HOST}_${DATE}.log"

function os_actions() {
    echo "starting os pre-requisites..." | tee -a $LOGFILE
    sudo apt-get update &&
        sudo apt-get install -yqq \
            ca-certificates \
            curl \
            gnupg \
            lsb-release \
            git \
            unzip \
            apt-transport-https \
            software-properties-common | tee -a $LOGFILE

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker and Compose plugin
    sudo apt-get install -yqq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin | tee -a $LOGFILE
}

function docker_actions() {
    # Bring up root-level compose if present
    if [[ -f /home/ubuntu/docker-compose.yml ]]; then
        echo "Bringing up services in /home/ubuntu" | tee -a $LOGFILE
        cd /home/ubuntu && sudo docker compose up -d | tee -a $LOGFILE
    fi
    # Bring up OpenEMR
    if [[ -f /home/ubuntu/openemr/docker-compose.yml ]]; then
        echo "Bringing up services in /home/ubuntu/openemr" | tee -a $LOGFILE
        cd /home/ubuntu/openemr && sudo docker compose up -d | tee -a $LOGFILE
    fi
    # Bring up Telehealth
    if [[ -f /home/ubuntu/telehealth/docker-compose.yml ]]; then
        echo "Bringing up services in /home/ubuntu/telehealth" | tee -a $LOGFILE
        cd /home/ubuntu/telehealth && sudo docker compose up -d | tee -a $LOGFILE
    fi
    # Bring up Jitsi
    if [[ -f /home/ubuntu/jitsi-docker/docker-compose.yml ]]; then
        echo "Bringing up services in /home/ubuntu/jitsi-docker" | tee -a $LOGFILE
        cd /home/ubuntu/jitsi-docker && sudo docker compose up -d | tee -a $LOGFILE
    fi
}

os_actions
docker_actions 