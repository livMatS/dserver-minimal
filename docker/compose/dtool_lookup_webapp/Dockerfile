FROM node:18-alpine

RUN apk update && apk add --no-cache git

RUN git clone --depth 1 -b 2025-03-13-no-authentication https://github.com/livmats/dtool-lookup-webapp.git /app

WORKDIR /app/dtool-lookup-webapp
COPY compose/dtool_lookup_webapp/build-node-app.sh /build-node-app.sh
RUN chmod 775 /build-node-app.sh
ENTRYPOINT ["/build-node-app.sh"]