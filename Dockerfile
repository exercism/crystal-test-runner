FROM crystallang/crystal:1.22.1-alpine

# install packages required to run the tests
RUN apk add --no-cache bash jq coreutils

WORKDIR /opt/test-runner
COPY . .

ENV CRYSTAL_CACHE_DIR=/tmp/.cache/.crystal

RUN ./bin/build.sh

# Fill the compiler's cache, so runs reuse the standard library's object files
RUN ./bin/warm-up.sh

ENTRYPOINT ["/opt/test-runner/bin/run.sh"]
