# Development setup

For development, it will be helpful to run `dserver` itself uncontainerized.
The folder `devel` contains helper components to
set up a simple development setup. To run a meaningful `dserver` instance,
underlying services like databases and storage infrastructure are necessary.
For the development setup described here, they can be provided with

```bash
docker compose -f docker/env.yml up -d
```

We will install all pythonic components of `dserver` in a virtual environment.

Create and activate virtual environment with

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
````

The container environment provides a PostgreSQL instance. For dserver to talk
with PostgreSQL seamlessly, please install

```bash
sudo apt install libpq-dev
pip install gunicorn psycopg2
```

on Ubuntu.

The container environment also provides an S3 server for testing. For allowing
dserver to ingest datasets from an S3 bucket,

```bash
pip install dtool-s3
```

`dtool.json` provides a minimal configuration
for a lookup server launched as described in the following. Place it at
`${HOME}/.config/dtool/dtool.json` with

```bash
cp devel/dtool.json ~/.config/dtool/dtool.json
```

The script ``devel/create_test_data.sh`` showcases the creation
of two datasets by means of the `dtool` command line interface (CLI).

To make the `dtool` CLI available, run

```bash
pip install dtool-cli dtool-info dtool-create 
```

Now, run `create_test_data.sh` to create test data sets
and copies them to a test s3 bucket.

For installing dserver by help of this meta package `dserver-minimal`,
run 

```bash
pip install dserver-minimal
```

Alternatively, install `dserver`'s core as well as search and retrieve plugins 
individually, e.g.

```bash
pip install dtool-lookup-server
pip install dserver-search-plugin-mongo
pip install dserver-retrieve-plugin-mongo
```

For an extended setup with support for direct mongo queries to the server,
dependency graph queries, and ingestion of datasets on S3 notifications,
also install

```bash
pip install dserver-direct-mongo-plugin
pip install dserver-dependency-graph-plugin
pip install dserver-notification-plugin
```

For development purposes, you might want to install these core components and
plugins listed above in editable mode from local copies of the repositories, i.e.

```bash
git clone https://github.com/jic-dtool/dtool-lookup-server.git
cd dtool-lookup-server
pip install -e .
```

for `dtool-lookup-server`, and in similar fashion for the plugins.

`env.rc` provides a default flask app configuration
in form of environment variables. Inspect and modify as needed, and export
them to your current shell environment with

```bash
source devel/env.rc
```

Prepare dserver with

```bash
bash devel/init.sh
 ```

to initilize databases, apply database migrations, create the single user
`test-user`, register the base URI `s3://test-bucket`, and grant permissions.

Eventually, run

```bash
bash devel/run.sh
```

to launch dserver with `gunicorn` on `localhost:5000`.

In case of a successful launch, http://localhost:5000/doc/swagger 
should expose the REST API documentation.

The route `/config/versions` is accessible without authentication and
authorization and should list all installed server-side plugins with
their versions.

For testing other routes that require authorization, retrieve a JWT token
for `test-user` with

```bash
curl --insecure -H "Content-Type: application/json" \
   -X POST -d '{"username": "test-user", "password": "test-password" }' \
   http://localhost:5001/token
```