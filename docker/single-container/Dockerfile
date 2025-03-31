FROM nginx:1.27.4-bookworm

# from node:18 Dockerfile, https://github.com/nodejs/docker-node/blob/4c8c98eaf121d6d1002a85d055d07aa91e2c9914/18/buster/Dockerfile
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 18.11.0
ENV FLASK_APP=dservercore

RUN apt-get --yes update && \
    apt-get --no-install-recommends --yes install gpg && \
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor && \
   echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list && \
    apt-get --yes update && \
    apt-get --no-install-recommends --yes install mongodb-org && \
    apt-get --no-install-recommends --yes install \
        git dirmngr gpg-agent xz-utils supervisor \
        gcc libc6-dev libpq-dev postgresql postgresql-client

        

RUN apt-get --yes update && apt-get --no-install-recommends --yes install python3 python3-pip python3-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    pip install --break-system-packages -U pip  && \
    pip install --break-system-packages gunicorn psycopg2 setuptools_scm && \
    pip install --break-system-packages git+https://github.com/jic-dtool/dservercore.git@2025-02-27-dependency-fixes && \
    pip install --break-system-packages dserver-search-plugin-mongo && \
    pip install --break-system-packages dserver-retrieve-plugin-mongo && \
    pip install --break-system-packages dtool-cli dtool-info dtool-create dtool-s3 && \
    pip install --break-system-packages dserver-direct-mongo-plugin && \
    pip install --break-system-packages dserver-dependency-graph-plugin && \
    pip install --break-system-packages dserver-notification-plugin && \
    rm -rf /root/.cache/pip && \
    apt-get remove --purge --autoremove -y gcc && \
    rm -rf /var/lib/apt/lists/*


RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    141F07595B7B3FFE74309A937405533BE57C7D57 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    61FC681DFB92A079F1685E77973F295594EC4689 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
  ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version

ENV YARN_VERSION 1.22.19

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  # smoke test
  && yarn --version

#
# Checkout web GUI
#
RUN git clone --depth 1 -b 2025-03-13-no-authentication https://github.com/livmats/dtool-lookup-webapp.git /app


COPY dtool.json /home/dserver/.config/dtool/

COPY docker-entrypoint.d/50-prepare-dserver.sh /docker-entrypoint.d/50-prepare-dserver.sh
RUN chmod +x /docker-entrypoint.d/50-prepare-dserver.sh

# RUN mkdir /keys && chown dservercore /keys

COPY dtool_lookup_webapp.env /app/dtool-lookup-webapp/.env

WORKDIR /app/dtool-lookup-webapp
RUN npm install
RUN npm run build

RUN mkdir -p /data/db
RUN chown mongodb:mongodb /data/db

COPY wsgi.py /dserver/wsgi.py
COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setze die Umgebungsvariablen aus der Compose-Datei
ENV SQLALCHEMY_DATABASE_URI=postgresql://postgres@localhost:5432/dtool \
    SEARCH_MONGO_URI=mongodb://localhost:27017/ \
    SEARCH_MONGO_DB=dtool_info \
    SEARCH_MONGO_COLLECTION=datasets \
    RETRIEVE_MONGO_URI=mongodb://localhost:27017/ \
    RETRIEVE_MONGO_DB=dtool_info \
    RETRIEVE_MONGO_COLLECTION=datasets \
    MONGO_URI=mongodb://localhost:27017/ \
    MONGO_DB=dtool_info \
    MONGO_COLLECTION=metadata \
    JWT_PUBLIC_KEY_FILE=/keys/jwt_key.pub \
    JWT_PRIVATE_KEY_FILE=/keys/jwt_key \
    DISABLE_JWT_AUTHORISATION=True \
    DEFAULT_USER=test-user \
    DUMP_HTTP_REQUESTS=True \
    LOGLEVEL=DEBUG \
    MONGO_DATA_DIR=/data/db \
    POSTGRES_PORT=5432 \
    POSTGRES_DB=dtool \
    POSTGRES_USER=postgres \
    POSTGRES_PASSWORD="" \
    SCRIPT_NAME=/lookup \
    API_SPEC_OPTIONS='{ \
      "x-internal-id": "2", \
      "servers": [ \
        { \
        "url": "http://localhost:8888/lookup", \
        "description": "dserver" \
        } \
      ] \
    }'

# Exponiere den Port
EXPOSE 5000
EXPOSE 8080
EXPOSE 8888

CMD ["/usr/bin/supervisord", "-n"]
# Starte den Dienst (dies muss individuell an deine App angepasst werden)
# CMD ["python3", "app.py"]