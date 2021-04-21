#!/usr/bin/env sh

# Setting up some colors for helping read the demo output.
# Comment out any of the below to turn off that color.
bold=$(tput bold)
bright=$(tput setaf 14)
yellow=$(tput setaf 11)
red=$(tput setaf 196)
reset=$(tput sgr0)
sourceuser="default/api-sotest1-group-b-devcluster-openshift-com:6443/newton"
destuser="default/api-sotest2-group-b-devcluster-openshift-com:6443/einstein"

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
  read_yellow "Across Clusters, CopyMethod = 'Snapshot'"
  echo ""
  read_bright "--> kubectl --context "${sourceuser}" create ns source"
  kubectl --context "${sourceuser}" create ns source
  echo ""
  read_bright "--> kubectl --context "${destuser}" create ns dest"
  kubectl --context "${destuser}" create ns dest
  echo ""
  read_bright "--> kubectl config get-contexts"
  kubectl config get-contexts
  echo ""
  read_bright "--> echo /"/${KUBECONFIG}/""
  echo "${KUBECONFIG}"
  echo ""
  clear
}

cleanup() {
  clear
  read_yellow "Removing replication"
  read_bright "--> kubectl scribe remove-replication"
  kubectl scribe remove-replication
  echo ""
  read_bright "--> kubectl --context "${destuser}" get pvc -n dest"
  kubectl --context "${destuser}" get pvc -n dest
  echo ""
  read_yellow "kubectl --context "${sourceuser}" get pvc -n source"
  kubectl --context "${sourceuser}" get pvc -n source
  echo ""
  read_bright "--> kubectl --context "${destuser}" delete ns dest --force --grace-period=0"
  kubectl --context "${destuser}" delete ns/dest
  echo ""
  read_bright "--> kubectl --context "${sourceuser}" delete ns source --force --grace-period=0"
  kubectl --context "${sourceuser}" delete ns/source
  echo ""
}

trap cleanup EXIT

create_source_application() {
  read_yellow "Create Source Application"
  read_bright "--> kubectl --context "${sourceuser}" -n source apply -f examples/source-database/"
  kubectl --context "${sourceuser}" -n source apply -f examples/source-database/
  echo ""
  read_bright "--> clear"
  clear
}

create_destination_application() {
  read_yellow "Create Destination Application"
  read_bright "--> kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-service.yaml"
  kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-service.yaml
  echo ""
  read_bright "--> kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-secret.yaml"
  kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-secret.yaml
  echo ""
  read_bright "--> kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-deployment.yaml"
  kubectl --context "${destuser}" -n dest apply -f examples/destination-database/mysql-deployment.yaml
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
  read_bright "--> kubectl --context "${sourceuser}" exec --stdin --tty -n source `kubectl --context "${sourceuser}" get pods -n source | grep mysql | awk '{print $1}'` -- /bin/bash"
  echo ""
  read_bright "--> clear"
  clear
}

verify_sync() {
  read_yellow "Verify Synced Database"
  read_yellow "mysql -u root -p\$MYSQL_ROOT_PASSWORD"
  read_bright "--> kubectl --context "${destuser}" exec --stdin --tty -n dest `kubectl --context "${destuser}" get pods -n dest | grep mysql | awk '{print $1}'` -- /bin/bash"
  echo ""
  read_bright "--> clear"
  clear
}

full_replication() {
  read_yellow "--> Start Replication: Create a ReplicationSource and ReplicationDestination"
  read_bright "--> kubectl scribe start-replication"
  kubectl scribe start-replication
  echo ""
  read_bright "--> kubectl --context "${sourceuser}" get replicationsource -n source"
  kubectl --context "${sourceuser}" get replicationsource -n source
  echo ""
  read_bright "--> kubectl --context "${destuser}" get replicationdestination -n dest"
  kubectl --context "${destuser}" get replicationdestination -n dest
  echo ""
  read_bright "--> clear"
  clear
  read_bright "--> kubectl scribe set-replication"
  kubectl scribe set-replication
  read_bright "--> watch kubectl get replicationsource/source-source -n source --context "${sourceuser}" -o yaml"
  watch kubectl get replicationsource/source-source -n source --context "${sourceuser}" -o yaml
  echo ""
  read_bright "--> kubectl --context "${destuser}" edit deployment/mysql -n dest"
  kubectl --context "${destuser}" edit deployment/mysql -n dest
  watch kubectl get pods -n dest --context "${destuser}"
  echo ""
} 

set_replication() {
  read_yellow "--> Set and Pause Replication: Create Destination PVC From Latest Snapshot Image"
  read_bright "--> kubectl scribe set-replication"
  kubectl scribe set-replication
  echo ""
  read_bright "--> kubectl --context "${destuser}" edit deployment/mysql -n dest"
  kubectl --context "${destuser}" edit deployment/mysql -n dest
  watch kubectl --context "${destuser}" get pods -n dest
  echo ""
} 

continue_replication() {
  read_yellow "--> Continue a Scribe Replication"
  read_bright "--> kubectl scribe continue-replication"
  kubectl scribe continue-replication
  read_bright "--> watch kubectl --context "${sourceuser}" get replicationsource -n source"
  watch kubectl --context "${sourceuser}" get replicationsource -n source
  echo ""
}

intro
read_bright "--> next"
show_config
read_bright "--> next"
create_source_application
read_bright "--> next"
create_destination_application
read_bright "--> next"
modify_source_db
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
