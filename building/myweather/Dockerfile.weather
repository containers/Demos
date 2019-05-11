FROM quay.io/buildah/stable
RUN yum install -y python3 python-pip
RUN pip3 install requests
COPY weather.py /
CMD  python3 weather.py
