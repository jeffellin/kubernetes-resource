FROM pivotalservices/pks-kubectl
ENV VERSION=2.12.1
ENV BASE_URL="https://storage.googleapis.com/kubernetes-helm"
ENV TAR_FILE="helm-v${VERSION}-linux-amd64.tar.gz"
RUN curl -L ${BASE_URL}/${TAR_FILE} |tar xvz && \
    mv linux-amd64/helm /usr/bin/helm && \
    chmod +x /usr/bin/helm && \
    rm -rf linux-amd64  
RUN helm init --client-only && helm plugin install https://github.com/chartmuseum/helm-push
RUN mkdir -p /opt/resource
COPY assets/* /opt/resource/
