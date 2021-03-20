#!/bin/bash

# Cambio a directorio con los playbooks
SOURCE="${BASH_SOURCE[0]}"
cd `dirname $SOURCE`

# nfs
#ansible-playbook -i hosts -l nfs install-k8snfs.yaml
#[ $? -ne 0 ] && exit 1

# master
ansible-playbook -i hosts -l master install-k8smaster.yaml
[ $? -ne 0 ] && exit 2

# sdn
ansible-playbook -i hosts -l master install-k8sSDN.yaml
[ $? -ne 0 ] && exit 3

# Lectura de comando para join de worker
KUBEADMJOIN=$(cat out/kubeadm_CNI_init.out | sed 's,kubeadm,/usr/bin/kubeadm,g' | sed 's/\\//g' | tail -2)

# Generación de fichero de variables para workers
echo '---' > group_vars/k8sworker.yaml
echo >> group_vars/k8sworker.yaml
echo '# Esta variable se actualiza dinámicamente desde el script k8s_install.sh, no es necesario modificarla' >> group_vars/k8sworker.yaml
echo "kubeadmjoin: '$KUBEADMJOIN'" >> group_vars/k8sworker.yaml

# workers
ansible-playbook -i hosts -l workers install-k8sworker.yaml
[ $? -ne 0 ] && exit 4

# ingress
ansible-playbook -i hosts -l master install-k8singress.yaml
[ $? -ne 0 ] && exit 5

# deploy apps
ansible-playbook -i hosts -l master k8sdeploy.yaml
[ $? -ne 0 ] && exit 6

echo "-----------------------------------------------------------------------------------"
echo "Finalizada la instalación de cluster k8s vanilla." 
echo "Puede tardar un tiempo en levantar los pods."
echo "-----------------------------------------------------------------------------------"
echo
