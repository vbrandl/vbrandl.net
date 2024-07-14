FROM klakegg/hugo:alpine as build
# FROM klakegg/hugo:0.56.3-alpine as build
WORKDIR /usr/src/build
COPY ./ ./
RUN apk --no-cache add --update make
RUN hugo && \
    make -C public/ -f ../Makefile
  # find ./ -type f \( \
  #   -name "*.html" \
  #   -o -name "*.js" \
  #   -o -name "*.css" \
  #   -o -name "*.xml" \
  #   -o -name "*.json" \
  #   -o -name "*.txt" \
  #   -o -name "*.png" \
  #   -o -name "*.ico" \
  #   -o -name "*.svg" \
  #   -not -name "*.gz" \) \
  #   -exec gzip -v -k -9 "{}" \;


# Stage: Run

FROM caddy
# FROM nginx:alpine
# RUN rm /usr/share/nginx/html/*
COPY Caddyfile /etc/caddy/Caddyfile
COPY ./.well-known/ /data/.well-known
COPY --from=build /usr/src/build/public /data
EXPOSE 80
