FROM openjdk:16-jdk-alpine3.12

WORKDIR /app
COPY . /app

RUN apk add --no-cache bash wget git

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
