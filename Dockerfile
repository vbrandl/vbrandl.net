FROM klakegg/hugo:alpine as build
WORKDIR /usr/src/build
COPY ./ ./
RUN apk --no-cache add --update make
RUN hugo && \
    make -C public/ -f ../Makefile

FROM caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY ./.well-known/ /data/.well-known
COPY --from=build /usr/src/build/public /data
