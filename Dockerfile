############################################################
# Dockerfile to build borgbackup server images
# Based on Debian
############################################################
FROM debian:buster-slim

# Volume for SSH-Keys
VOLUME /sshkeys

# Volume for borg repositories
VOLUME /backup

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get -y --no-install-recommends install \
		borgbackup openssh-server && apt-get clean && \
		useradd -s /bin/bash -m borg && \
		mkdir /home/borg/.ssh && \
		chmod 700 /home/borg/.ssh && \
		chown borg: /home/borg/.ssh && \
		mkdir /run/sshd && \
		rm -f /etc/ssh/ssh_host*key* && \
		rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY ./data/run.sh /run.sh
COPY ./data/sshd_config /etc/ssh/sshd_config

ENTRYPOINT /run.sh

# Default SSH-Port for clients
EXPOSE 22
