FROM pivotalservices/pks-kubectl

RUN mkdir -p /opt/resource
COPY assets/* /opt/resource/
