FROM golang:1.10

RUN go get gopkg.in/mikefarah/yq.v2 
RUN wget -qO /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod 755 /usr/local/bin/jq
RUN wget -qO /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod 755 /usr/local/bin/kubectl

FROM python:3.7-slim
RUN pip install awscli
COPY --from=0 /usr/local/bin /usr/local/bin
COPY --from=0 /go/bin /usr/local/bin
COPY configure /
COPY make_cluster.sh /
COPY cluster.cf.template /

CMD ["/make_cluster.sh"]
