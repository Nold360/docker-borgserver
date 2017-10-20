############################################################
# Dockerfile to build borgbackup server images
# Based on Debian
############################################################
FROM debian:latest

# Volume for SSH-Keys
VOLUME /sshkeys

# Volume for borg repositories
VOLUME /backup

RUN apt-get update && apt-get -y install borgbackup openssh-server
RUN useradd -s /bin/bash -m borg
RUN mkdir /home/borg/.ssh && chmod 700 /home/borg/.ssh && chown borg: /home/borg/.ssh
RUN mkdir /run/sshd

COPY ./data/run.sh /run.sh
COPY ./data/sshd_config /etc/ssh/sshd_config

CMD /bin/bash /run.sh

# Default SSH-Port for clients
EXPOSE 22
