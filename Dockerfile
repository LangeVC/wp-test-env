# Dockerfile for wp-test-env
# Builds a self-contained Docker image that bundles the compose environment
# and setup scripts — ready to run via `docker run`.

FROM alpine:3.23

LABEL org.opencontainers.image.title="wp-test-env"
LABEL org.opencontainers.image.description="WordPress Testing Environment — Docker Compose stack with one-click setup"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Copy everything needed for the environment
COPY docker-compose.yml /env/
COPY docker/              /env/docker/
COPY config/              /env/config/
COPY scripts/             /env/scripts/
COPY tests/               /env/tests/
COPY plugins/             /env/plugins/
COPY themes/              /env/themes/
COPY .env.example         /env/.env.example
COPY README.md            /env/
COPY LICENSE              /env/

WORKDIR /env

CMD ["sh", "-c", "cat README.md && echo '' && echo 'Run: docker compose -f /env/docker-compose.yml up -d && /env/scripts/setup.sh'"]
