FROM crystallang/crystal:1.11.2-alpine

# install packages required to run the tests
RUN apk add --no-cache bash jq coreutils

WORKDIR /opt/test-runner
COPY . .

ENV CRYSTAL_CACHE_DIR=/tmp/.cache/.crystal

RUN ./bin/build.sh

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
