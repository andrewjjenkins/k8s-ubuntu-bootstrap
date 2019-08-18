# k8s-bootstrap

This is a way to bootstrap a kubernetes cluster using libvirt VMs.  There may be
easier ways to do this.  If you have:

- 1 or more Ubuntu hosts
- Want to run vanilla Kubernetes, but in a VM so you can throw it away
- Want your Kubernetes cluster to be "bridged" so you can directly access
  NodePorts like you were in the cloud
- Want to use flannel as your CNI

then this might be for you.  This depends on "uvtool" which is tooling for
Ubuntu that lets Ubuntu start VMs as if they were in a cloud like AWS.  uvtool
takes care of getting the right image and upon boot, loading the right SSH
public key and running a setup script (as if you had provided it in the
userdata in AWS).  We run a bunch of kubeadm and kubectl commands in that init
script to create a one-node kubernetes cluster.

Here's example output:

    Attempting to SSH to ubuntu-k8s-foobar.local, may take a few attempts...
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    ssh: Could not resolve hostname ubuntu-k8s-foobar.local: Name or service not known
    Warning: Permanently added 'ubuntu-k8s-foobar.local,192.168.7.99' (ECDSA) to the list of known hosts.
    Starting k8s bootstrap at Sun Aug 18 05:41:11 UTC 2019
    apt-get complete
    kubeadm config images pull complete
    kubeadm init complete
    kubectl taint nodes (to schedule on master) complete
    kubectl install of flannel complete
    kubectl patch coredns complete
    Dashboard installation complete
    To log in to dashboard, go to:
       https://192.168.7.99:30443
    Choose the token login, and provide this token:
    eyJhbGciOiJSUzI1NiIs....

    You can safely CTRL-C now.  To tear down, run:
      sudo uvt-kvm destroy ubuntu-k8s-foobar

You can use the one-node cluster or you can also use kubeadm to join additional
nodes.  It installs the kubernetes dashboard by default.
