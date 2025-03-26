FROM node:18-alpine

RUN apk update && apk add --no-cache git

# from node:18 Dockerfile, https://github.com/nodejs/docker-node/blob/4c8c98eaf121d6d1002a85d055d07aa91e2c9914/18/buster/Dockerfile

RUN git clone --depth 1 -b 2025-03-13-no-authentication https://github.com/livmats/dtool-lookup-webapp.git /app

#RUN git clone --depth 1 https://github.com/jic-dtool/dtool-lookup-webapp.git /app
#WORKDIR /app
#RUN git checkout origin/2025-03-13-no-authentication

WORKDIR /app/dtool-lookup-webapp
COPY compose/dtool_lookup_webapp/build-node-app.sh /build-node-app.sh
RUN chmod 775 /build-node-app.sh
ENTRYPOINT ["/build-node-app.sh"]