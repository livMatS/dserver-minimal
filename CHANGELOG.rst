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
- Fixed the ``containers`` build-test: the ``dserver_devel`` image failed to
  build because ``setuptools_scm`` ran git against ``/app`` (owned by the
  ``dserver`` user) as root and git rejected it as "dubious ownership"; mark
  ``/app`` a safe directory and check out full history/tags (``fetch-depth: 0``)
- CI workflows modernized: ``containers.yml`` uses ``docker/metadata-action``
  (renamed from the deprecated ``crazy-max/ghaction-docker-meta``) and the
  GitHub Actions build cache; ``publish-python-package.yml`` publishes via PyPI
  Trusted Publishing (OIDC) instead of long-lived tokens and builds on Python
  3.12 (was end-of-life 3.8); least-privilege ``permissions`` blocks added; the
  JOSS ``paper`` workflow only runs on ``paper/`` changes; Dependabot now also
  tracks Docker base images

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
