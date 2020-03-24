# Borgserver Init-Container, simply replace entrypoiny and install git
#FROM nold360/borgserver:latest
FROM borg:git

USER root
RUN export DEBIAN_FRONTEND=noninteractive && \
		apt-get update && \
		apt-get -y --no-install-recommends install \
		git ca-certificates && \
		apt-get clean && \
		rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

COPY ./entrypoint.sh /entrypoint.sh
