pushd restapi
./restapi.sh
popd
pushd generatesystemd
./podman-generate-systemd.sh
popd
