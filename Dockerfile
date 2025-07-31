FROM floryn90/hugo:0.148.2 AS build-stage

ARG hugobuildargs
ENV HUGO_BUILD_ARGS=${hugobuildargs}

USER root
WORKDIR /app
ADD . .

RUN hugo ${HUGO_BUILD_ARGS}

FROM nginx:1.29-alpine

COPY --from=build-stage /app/public/ /usr/share/nginx/html
