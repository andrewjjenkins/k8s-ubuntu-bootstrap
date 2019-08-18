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

## License

BSD 3-Clause License

Copyright (c) 2019, Andrew Jenkins
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
