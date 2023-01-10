
process_tar() {
  cd $WORK_DIR

  setenforce 0

  cd rke2
  chmod +x install.sh
  PATH=$PATH:$WORK_DIR/bin ./install.sh
  cd ..




  echo "Starting RKE2 Server service.  This will take a few minutes."
  systemctl start rke2-server

  #Configure kubectl

  cat >> ~/.bashrc <<EOF
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=$PATH:/var/lib/rancher/rke2/bin:/usr/local/bin
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
export KU_NS=default
alias ku="kubectl -n \\\$KU_NS"
EOF
  source ~/.bashrc


}

if [ "$(id -u)" -ne 0 ] ; then printf '\xE2\x98\xA0'; echo "Must be run as root. Exiting.";  exit 1 ; fi

WORK_DIR=/tmp
mkdir -p $WORK_DIR/bin
cat $0 | tail -2 | head -1 | tr -d '\n' | base64 -d > $WORK_DIR/bin/tar
export PATH=$PATH:$WORK_DIR/bin
chmod +x $WORK_DIR/bin/tar

cat $0 | tail -1 | tr -d '\n' | base64 -d > $WORK_DIR/payload.tgz
tar -zvxf $WORK_DIR/payload.tgz -C $WORK_DIR

mkdir -p /var/lib/rancher/rke2/server/manifests/
mkdir -p /var/lib/rancher/rke2/agent/images/
cp $WORK_DIR/manifests/*.yaml /var/lib/rancher/rke2/server/manifests/
cp $WORK_DIR/registry/*.tar /var/lib/rancher/rke2/agent/images/
cp $WORK_DIR/rke2_configuration.yaml /etc/rancher/rke2/config.yaml

# perform actions with the extracted content
process_tar



exit 0
