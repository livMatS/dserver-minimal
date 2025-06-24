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
