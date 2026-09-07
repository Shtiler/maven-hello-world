FROM eclipse-temurin:8u502-b07-jre-ubi10-minimal@sha256:bf529c982847885d6a3988c0c16c60a910cab0ed25f63580f0cf74af7f07ca84

ARG APPLICATION_VERSION
ARG JAR_FILE
ARG VCS_REF

LABEL org.opencontainers.image.title="maven-hello-world" \
      org.opencontainers.image.description="Hello World Java application" \
      org.opencontainers.image.source="https://github.com/Shtiler/maven-hello-world" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${APPLICATION_VERSION}"

WORKDIR /app

COPY --chown=10001:10001 ${JAR_FILE} application.jar

USER 10001:10001

ENTRYPOINT ["java", "-jar", "/app/application.jar"]
