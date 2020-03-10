FROM alpine:latest

RUN apk add --update bash curl jq && rm -rf /var/cache/apk/*

ADD ./run ./start_galera /

# Confd
ADD ./conf.d /etc/confd/conf.d
ADD ./templates /etc/confd/templates

ADD https://github.com/rancher/confd/releases/download/0.11.0-dev-rancher/confd-0.11.0-dev-rancher-linux-amd64 /confd
RUN chmod +x /confd

ADD https://github.com/rancher/giddyup/releases/download/v0.11.0/giddyup /giddyup
RUN chmod +x /giddyup

entrypoint ["/run"]
