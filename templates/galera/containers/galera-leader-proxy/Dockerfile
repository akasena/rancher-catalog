FROM alpine:latest

RUN apk add --update bash socat && rm -rf /var/cache/apk/*
ADD ./run.sh /

entrypoint ["/run.sh"]
