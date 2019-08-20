#!/usr/bin/env sh 

read -p "Using SELinux with container runtimes "
echo ""

read -p "--> dnf install udica podman setools-console "
echo ""
sudo dnf install udica podman setools-console -y
echo ""

read -p "--> getenforce"
echo ""
getenforce
echo ""

read -p "--> podman run -v /home:/home:rw -v /var/spool:/var/spool:ro -p 21:21 -d fedora sleep 1h"
echo ""
sudo podman run -v /home:/home:rw -v /var/spool:/var/spool:ro -p 21:21 -d fedora sleep 1h
echo ""

read -p "--> podman top -l label"
echo ""
sudo podman top -l label
echo ""

echo "--> sesearch -A -s container_t -t home_root_t -c dir -p read"
echo ""
sesearch -A -s container_t -t home_root_t -c dir -p read
echo ""

echo "--> sesearch -A -s container_t -t var_spool_t -c dir -p read"
echo ""
sesearch -A -s container_t -t var_spool_t -c dir -p read
echo ""


echo "--> sesearch -A -s container_t -t port_type -c tcp_socket"
echo ""
sesearch -A -s container_t -t port_type -c tcp_socket
echo ""

read -p "--> podman ps"
echo ""
sudo podman ps
echo ""

read -p "--> podman inspect -l | udica  my_container
"
echo ""
sudo podman inspect -l | sudo udica  my_container
echo ""

echo "--> semodule -i my_container.cil /usr/share/udica/templates/{base_container.cil,net_container.cil,home_container.cil}"
echo ""
sudo semodule -i my_container.cil /usr/share/udica/templates/{base_container.cil,net_container.cil,home_container.cil}
echo ""

read -p "--> podman stop -l"
echo ""
sudo podman stop -l
echo ""

read -p "--> podman run --security-opt label=type:my_container.process -v /home:/home:rw -v /var/spool:/var/spool:ro -p 21:21 -d fedora sleep 1h"
echo ""
sudo podman run --security-opt label=type:my_container.process -v /home:/home:rw -v /var/spool:/var/spool:ro -p 21:21 -d fedora sleep 1h
echo ""

read -p "--> podman top -l label"
echo ""
sudo podman top -l label
echo ""

echo "--> sesearch -A -s my_container.process -t home_root_t -c dir -p read"
echo ""
sesearch -A -s my_container.process  -t home_root_t -c dir -p read
echo ""

echo  "--> sesearch -A -s my_container.process -t var_spool_t -c dir -p read"
echo ""
sesearch -A -s my_container.process -t var_spool_t -c dir -p read
echo ""


echo "--> sesearch -A -s my_container.process -t port_type -c tcp_socket"
echo ""
sesearch -A -s my_container.process -t port_type -c tcp_socket
echo ""

echo "--> cleanup"
echo ""
sudo podman stop -l
sudo semodule -r my_container base_container net_container home_container &> /dev/null
echo ""

echo "Enf of Demo."
