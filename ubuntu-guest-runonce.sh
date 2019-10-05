#!/bin/bash
set -euxo pipefail

LOGFILE=/var/log/ubuntu-guest-runonce.log
USER=ubuntu
GROUP=ubuntu
USERHOME=/home/$USER
echo "Starting k8s bootstrap at `date`" >> $LOGFILE

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update

apt-get install --yes \
  avahi-daemon \
  docker.io \
  kubelet kubeadm kubectl \

apt-mark hold kubelet kubeadm kubectl

echo "apt-get complete" >> $LOGFILE

kubeadm config images pull

echo "kubeadm config images pull complete" >> $LOGFILE

kubeadm init \
  --pod-network-cidr 10.244.0.0/16 \
  --service-cidr 10.96.0.0/16

echo "kubeadm init complete" >> $LOGFILE

mkdir -p $USERHOME/.kube
cp -i /etc/kubernetes/admin.conf $USERHOME/.kube/config
chown -R $USER:$GROUP $USERHOME/.kube
export KUBECONFIG=$USERHOME/.kube/config

kubectl taint nodes --all node-role.kubernetes.io/master-

echo "kubectl taint nodes (to schedule on master) complete" >> $LOGFILE

sysctl -w net.bridge.bridge-nf-call-iptables=1

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/b99442c989cf41551d2604f4eecc223329dbd553/Documentation/kube-flannel.yml

echo "kubectl install of flannel complete" >> $LOGFILE

# If you're running a one-node cluster, no sense in multiple CoreDNS pods.
kubectl patch deployment -n kube-system coredns --patch '{"spec": {"replicas": 1}}'

echo "kubectl patch coredns complete" >> $LOGFILE

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml

kubectl patch service -n kubernetes-dashboard kubernetes-dashboard --patch \
  '{"spec": { "type": "NodePort", "ports": [ { "nodePort": 30443, "port": 443, "protocol": "TCP", "targetPort": 8443 } ] } }'

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF

echo "Dashboard installation complete" >> $LOGFILE

TOKEN=`kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep admin-user | awk "{print \\$1}") -o jsonpath='{.data.token}' | base64 -d`
MYIP=`hostname -I | awk "{print \\$1}"`

INFOSTRING="To log in to dashboard, go to:
   https://$MYIP:30443
Choose the token login, and provide this token:
$TOKEN
"
echo "$INFOSTRING" >> $LOGFILE
cat > /etc/update-motd.d/85-kubernetes-login <<EOF
#!/bin/sh
echo "$INFOSTRING"
EOF
chmod a+x /etc/update-motd.d/85-kubernetes-login

echo "You can safely CTRL-C now.  To tear down, run:
  sudo uvt-kvm destroy $HOSTNAME
" >> $LOGFILE


