#!/bin/bash

#You must have $DOCKER_SETUP_USER env var to set up the container's user.

#This script must be run as ROOT, on container start.
# Protip: Use sudo/sudoers to enable calling this easily:
# - In Dockerfile
# echo "${user} ALL=NOPASSWD:SETENV: /app/setup/*" >> /etc/sudoers
# - In entrypoint.sh
# sudo -E /app/setup/setupDockerMount.sh

DOCKER_BIN=/usr/bin/docker
DOCKER_SOCKET=/var/run/docker.sock
DOCKER_GROUP=$(ls -al $DOCKER_SOCKET | awk '{print $4}')
DOCKER_GID=$(ls -aln $DOCKER_SOCKET | awk '{print $4}')
HAS_GROUP=$(getent group $DOCKER_GID)
USER_NOT_IN_GROUP=$(id -nG "jenkins" | grep -qw "$DOCKER_GROUP")
DOCKER_BROKEN=$($DOCKER_BIN 2>&1 | grep -E 'not found|cannot open shared')

#Make sure we're mounted with socket!
if [[ ! -S $DOCKER_SOCKET ]]
then
  echo "Missing: $DOCKER_SOCKET!"
  exit 1
fi

#Make sure we're mounted with binary!
if [[ ! -f $DOCKER_BIN ]]
then
  echo "Missing: $DOCKER_BIN!"
  exit 1
else
  echo "Exists: $DOCKER_BIN"
fi

#Make sure we're mounted with executable!
if [[ ! -x $DOCKER_BIN ]]
then
  echo "Not Executable: $DOCKER_BIN!"
  exit 1
fi

#Test if dynamic linked objects for binary are missing
if [[ ! -z "$DOCKER_BROKEN" ]]
then
  echo "Inoperable: $DOCKER_BIN"
  echo -e "\t\tEnsure all linked objects are volume mounted as well (use: ldd $(which docker))."
  exit 2
fi

#Add Group if missing
if [[ ! $HAS_GROUP ]]
then
  echo "Creating 'docker' group: $DOCKER_GID"
  addgroup --gid $DOCKER_GID docker
fi

#Add User to Group if not already in it
if [[ ! $USER_NOT_IN_GROUP ]]
then
  echo "Adding 'jenkins' to group: $DOCKER_GROUP($DOCKER_GID)"
  echo -e "\tNote: The *name* may not be right, but the GID should be!"
  adduser $DOCKER_USER $DOCKER_GROUP
fi

/usr/sbin/sshd -D