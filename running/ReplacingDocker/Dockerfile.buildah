FROM fedora

RUN dnf -y install buildah; dnf -y clean all
ENTRYPOINT ["/usr/bin/buildah"]
WORKDIR /root
