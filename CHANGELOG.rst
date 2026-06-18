CHANGELOG
=========

This project uses `semantic versioning <http://semver.org/>`_.
This change log uses principles from `keep a changelog <http://keepachangelog.com/>`_.

[unpublished]
-------------

Added
^^^^^

- Single-container app wrapping dserver, web app, and some CLI and Python lookup API packages

Changed
^^^^^^^

- Container `docker/dserver_devel` uses local file system as base URI, not s3 endpoint anymore
- Container composition `dserver/devel.yml` does not use minio s3 service and ldap authentication anymore, but has authentication disabled
- Single-container image rebuilt as a multi-stage build: the web GUI (now
  tracking ``jic-dtool/dtool-lookup-webapp`` together with its ``dserver-client-js``
  dependency) is compiled in a throwaway Node stage and served as a static
  bundle by nginx; the runtime image is ``python:3.12-slim`` and no longer ships
  the Node/Yarn toolchain
- Single-container installs the dserver core and plugins as well as the dtool
  stack (``dtoolcore``, ``dtool-cli``, ``dtool-info``, ``dtool-create``,
  ``dtool-s3``, ``dtool-lookup-api``, ``dtool-lookup-client``) from the default
  branches of their GitHub repositories via ``requirements.txt``; transitive
  Flask-stack dependencies are capped (``Flask``/``Werkzeug``/``marshmallow``)
  to keep the resolution coherent
- Single-container bootstrap (``prepare-dserver.sh``) waits for the databases,
  generates migrations only on first boot and otherwise applies them
  (``flask db upgrade``), and is idempotent on restart
- Container publication workflow now builds multi-arch images
  (``linux/amd64,linux/arm64``), uses the GitHub Actions build cache, and pushes
  to the registry given by the ``registry`` input (previously misnamed, so login
  silently fell back to Docker Hub)

[0.3.0]
-------

Changed
^^^^^^^

- Pinned ``dservercore`` dependency to >= 0.21.0.
- Pinned ``dserver_devel`` base image to Python 3.12

[0.2.0]
-------

Changed
^^^^^^^

- Core dependency on ``dservercore``.
