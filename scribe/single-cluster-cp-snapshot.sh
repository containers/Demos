#!/usr/bin/env sh

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
bright=$(tput setaf 14)
yellow=$(tput setaf 11)
red=$(tput setaf 196)
reset=$(tput sgr0)

# commands
read_bright() {
  read -p "${bold}${bright}$1${reset}"
}
echo_bright() {
  echo "${bold}${bright}$1${reset}"
}

# headings
read_yellow() {
  read -p "${bold}${yellow}$1${reset}"
}

# headings
read_red() {
  read -p "${bold}${red}$1${reset}"
}

intro() {
  read_yellow "Single Cluster, CopyMethod = 'Snapshot'"
  echo ""
  read_bright "--> kubectl create ns source"
  kubectl create ns source
  echo ""
  read_bright "--> kubectl create ns dest"
  kubectl create ns dest
  echo ""
  clear
}

cleanup() {
  read_yellow "Removing replication"
  read_bright "--> kubectl scribe remove-replication"
  kubectl scribe remove-replication
  echo ""
  read_bright "--> kubectl get pvc -n dest"
  kubectl get pvc -n dest
  echo ""
  read_yellow "kubectl get pvc -n source"
  kubectl get pvc -n source
  echo ""
  read_bright "--> kubectl delete ns dest --force --grace-period=0"
  kubectl delete ns/dest
  echo ""
  read_bright "--> kubectl delete ns source --force --grace-period=0"
  kubectl delete ns/source
  echo ""
}

trap cleanup EXIT

create_source_application() {
  read_yellow "Create Source Application"
  read_bright "--> kubectl -n source apply -f examples/source-database/"
  kubectl -n source apply -f examples/source-database/
  echo ""
  read_bright "--> clear"
  clear
}

create_destination_application() {
  read_yellow "Create Destination Application"
  read_bright "--> kubectl -n dest apply -f examples/destination-database/mysql-service.yaml"
  kubectl -n dest apply -f examples/destination-database/mysql-service.yaml
  echo ""
  read_bright "--> kubectl -n dest apply -f examples/destination-database/mysql-secret.yaml"
  kubectl -n dest apply -f examples/destination-database/mysql-secret.yaml
  echo ""
  read_bright "--> kubectl -n dest apply -f examples/destination-database/mysql-deployment.yaml"
  kubectl -n dest apply -f examples/destination-database/mysql-deployment.yaml
  echo ""
  read_bright "--> clear"
  clear
}

show_config() {
  read_yellow "Scribe Config"
  read_bright "--> cat config.yaml"
  cat config.yaml
  echo ""
  read_bright "--> clear"
  clear
}

modify_source_db() {
  read_yellow "Modify Source Database"
  read_yellow "mysql -u root -p\$MYSQL_ROOT_PASSWORD"
  read_bright "--> kubectl exec --stdin --tty -n source `kubectl get pods -n source | grep mysql | awk '{print $1}'` -- /bin/bash"
  echo ""
  read_bright "--> clear"
  clear
}

verify_sync() {
  read_yellow "Verify Synced Database"
  read_yellow "mysql -u root -p\$MYSQL_ROOT_PASSWORD"
  read_bright "--> kubectl exec --stdin --tty -n dest `kubectl get pods -n dest | grep mysql | awk '{print $1}'` -- /bin/bash"
  echo ""
  read_bright "--> clear"
  clear
}

full_replication() {
  read_yellow "--> Start Replication: Create a ReplicationSource and ReplicationDestination"
  read_bright "--> kubectl scribe start-replication"
  kubectl scribe start-replication
  echo ""
  read_bright "--> kubectl get replicationsource -n source"
  kubectl get replicationsource -n source
  echo ""
  read_bright "--> kubectl get replicationdestination -n dest"
  kubectl get replicationdestination -n dest
  echo ""
  read_bright "--> clear"
  clear
  read_bright "--> kubectl scribe set-replication"
  kubectl scribe set-replication
  watch oc get replicationsource/source-source -n source -o yaml
  echo ""
  read_bright "--> kubectl edit deployment/mysql -n dest"
  kubectl edit deployment/mysql -n dest
  watch oc get pods -n dest
  echo ""
} 

set_replication() {
  read_yellow "--> Set and Pause Replication: Create Destination PVC From Latest Snapshot Image"
  read_bright "--> kubectl scribe set-replication"
  kubectl scribe set-replication
  echo ""
  read_bright "--> kubectl edit deployment/mysql -n dest"
  kubectl edit deployment/mysql -n dest
  watch oc get pods -n dest
  echo ""
} 

continue_replication() {
  read_yellow "--> Continue a Scribe Replication"
  read_bright "--> kubectl scribe continue-replication"
  kubectl scribe continue-replication
  read_bright "--> watch oc scribe get replicationsource -n source"
  watch oc get replicationsource -n source
  echo ""
}

intro
read_bright "--> next"
create_source_application
read_bright "--> next"
create_destination_application
read_bright "--> next"
modify_source_db
read_bright "--> next"
show_config
read_bright "--> next"
full_replication
read_bright "--> next"
verify_sync
read_bright "--> next"
continue_replication
read_bright "--> next"
set_replication
read_bright "--> next"
cleanup
