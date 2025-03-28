FROM python:3.12-slim-bullseye

RUN adduser --disabled-password --gecos '' dserver

COPY --chown=dserver . /app

WORKDIR /app

ENV FLASK_APP=dservercore

RUN apt-get --yes update && \
    apt-get --no-install-recommends --yes install gcc libc6-dev libpq-dev git curl && \
    pip install -U pip  && \
    pip install gunicorn  psycopg2 setuptools_scm && \
    pip install --break-system-packages . && \
    pip install dtool-cli dtool-info dtool-create dtool-s3 && \
    pip install dserver-direct-mongo-plugin && \
    pip install dserver-dependency-graph-plugin && \
    pip install dserver-notification-plugin && \
    rm -rf /root/.cache/pip && \
    apt-get remove --purge --autoremove -y gcc && \
    rm -rf /var/lib/apt/lists/*


COPY docker/dserver_devel/dtool.json /home/dserver/.config/dtool/

COPY docker/dserver_devel/boot.sh  /
RUN chmod +x /boot.sh

RUN mkdir /keys && chown dserver /keys

USER dserver
EXPOSE 5000
ENTRYPOINT ["/boot.sh"]
