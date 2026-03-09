FROM maven:3.8.8-eclipse-temurin-8 AS builder

ARG KK_VERSION=4.4.0
ARG KK_GIT_REPO=https://gitee.com/kekingcn/file-online-preview.git
ARG KK_GIT_REF=v${KK_VERSION}
WORKDIR /build

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends git ca-certificates; \
	rm -rf /var/lib/apt/lists/*

RUN set -eux; \
	git clone --depth 1 --branch "$KK_GIT_REF" "$KK_GIT_REPO" .

RUN set -eux; \
    mvn -q -DskipTests package; \
    ls -lah server/target; \
    test -f server/target/kkFileView-${KK_VERSION}.tar.gz


FROM keking/kkfileview:4.1.0

ARG KK_VERSION=4.4.0

COPY --from=builder /build/server/target/kkFileView-${KK_VERSION}.tar.gz /tmp/kkfileview.tar.gz

RUN set -eux; \
    tar -xzf /tmp/kkfileview.tar.gz -C /opt/; \
    rm -f /tmp/kkfileview.tar.gz

ENV KKFILEVIEW_BIN_FOLDER=/opt/kkFileView-4.4.0/bin

ENTRYPOINT ["java","-Dfile.encoding=UTF-8","-Dspring.config.location=/opt/kkFileView-4.4.0/config/application.properties","-jar","/opt/kkFileView-4.4.0/bin/kkFileView-4.4.0.jar"]
