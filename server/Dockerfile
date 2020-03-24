############################################################
# Dockerfile to build borgbackup server images
# Based on Debian
############################################################
FROM debian:buster-slim

# Volume for SSH-Host-Keys
VOLUME /sshkeys

# Volume for borg repositories
VOLUME /backup

# Volume for authorized_keys exchange from init
VOLUME /home/borg

RUN export DEBIAN_FRONTEND=noninteractive && \
		apt-get update && \
		apt-get -y --no-install-recommends install \
		borgbackup openssh-server iputils-ping && \
		apt-get clean && \
		useradd -s /bin/bash -m -U borg && \
		mkdir /home/borg/.ssh && \
		chmod 700 /home/borg/.ssh && \
		touch /home/borg/.ssh/authorized_keys && \
		chown -R borg:borg /home/borg /backup && \
		mkdir /run/sshd && \
		rm -f /etc/ssh/ssh_host*key* && \
		rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY ./entrypoint.sh /entrypoint.sh
COPY ./sshd_config /etc/ssh/sshd_config

USER borg
EXPOSE 2222

ENTRYPOINT /entrypoint.sh
