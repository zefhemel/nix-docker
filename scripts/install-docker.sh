#!/bin/sh

# disable apt frontend to prevent
# any troublesome questions
export DEBIAN_FRONTEND=noninteractive

which docker || apt-get install -y docker.io
