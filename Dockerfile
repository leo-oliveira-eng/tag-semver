FROM alpine:3.18

RUN apk add --no-cache git curl jq bash

RUN curl -fsSL https://github.com/cli/cli/releases/latest/download/gh_2.49.0_linux_amd64.tar.gz \
  | tar -xz && \
  mv gh_*/bin/gh /usr/local/bin/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]