FROM alpine:3.21

RUN apk add --no-cache git curl jq bash

RUN curl -fsSL https://github.com/cli/cli/releases/download/v2.69.0/gh_2.69.0_linux_amd64.tar.gz \
  | tar -xz && \
  mv gh_*/bin/gh /usr/local/bin/

WORKDIR /action

COPY entrypoint.sh /action/entrypoint.sh
COPY lib /action/lib
RUN chmod +x /action/entrypoint.sh

CMD ["bash", "/action/entrypoint.sh"]
