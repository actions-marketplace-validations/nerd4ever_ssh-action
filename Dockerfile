FROM alpine:latest
RUN apk update && \
  apk add --no-cache ca-certificates \
  openssh-client \
  sshpass \
  bash
  
RUN ssh-keygen -t rsa -b 4096 -C "docker@nerd4ever.com.br"

COPY LICENSE README.md /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
