FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

#
# Clean the system, update, upgrade, and autoremove
#
RUN apt-get autoremove --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get autoremove --yes

#
# Install core and build essentials
#
RUN apt-get install --yes build-essential

SHELL ["/bin/bash", "-c"]

#
# Unset DEBIAN_FRONTEND
#
ENV DEBIAN_FRONTEND=

#
# Set default command
#
CMD ["bash"]

