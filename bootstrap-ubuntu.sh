#!/bin/bash
set -euo pipefail

RAM=8192 #MB
VCPUS=8
BRIDGE=""
if ifconfig br0 2>/dev/null >/dev/null; then
  BRIDGE="br0"
  echo "Using bridge $BRIDGE"
fi
BASESPEC="arch=amd64 release=bionic label=release"


NAME=${1:-foobar}
FULLNAME=ubuntu-k8s-${NAME}
HOST=${FULLNAME}.local
SSHPUBKEY=${SSHPUBKEY:-${HOME}/.ssh/id_rsa.pub}

if ! dpkg -l uvtool > /dev/null; then
  echo "Need uvtool installed:"
  echo "  sudo apt-get install uvtool"
  exit 1
fi

if ! [ -f "$SSHPUBKEY" ]; then
  echo "SSHPUBKEY $SSHPUBKEY not found."
  echo "  Need an SSH keypair (\$SSHPUBKEY).  If you don't have one try:"
  echo "    ssh-keygen"
  exit 1
fi

#sudo uvt-simplestreams-libvirt sync $BASESPEC

ssh-keygen -R ${FULLNAME}.local || true
CMD="uvt-kvm create \
  --memory $RAM --cpu $VCPUS \
  --run-script-once ubuntu-guest-runonce.sh \
  --ssh-public-key-file $SSHPUBKEY \
"

if [ -n "$BRIDGE" ]; then
  CMD="$CMD --bridge $BRIDGE"
fi

CMD="$CMD $FULLNAME $BASESPEC"
echo "Defining KVM guest..."
echo "$CMD"
eval "$CMD"

virsh autostart ${FULLNAME}

echo "Attempting to SSH to ${HOST}, may take a few attempts..."
COMPLETE=""
while [ -z "$COMPLETE" ]; do
  sleep 5
  ssh -oStrictHostKeyChecking=no ubuntu@${HOST} "tail -F /var/log/ubuntu-guest-runonce.log" && COMPLETE="yes" || true
done
