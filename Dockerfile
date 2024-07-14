FROM klakegg/hugo:0.56.3-alpine as build
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

FROM nginx:alpine
RUN rm /usr/share/nginx/html/*
COPY --from=build /usr/src/build/public /usr/share/nginx/html/
COPY ./.well-known/ /usr/share/nginx/html/.well-known
EXPOSE 80
