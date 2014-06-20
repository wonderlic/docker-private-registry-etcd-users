# Docker Registry (private)
This uses the `stackbrew/registry` as a base and adds basic auth via
Nginx. Note that you should provide your own SSL

# Usage
To run a private registry,

`docker run -i -t shipyard/docker-private-registry`

# Management
There is a simple management application written in Flask that you can use
to manage registry users.  To access the management application, create a
container from this image and visit `/manage`.

The default username is `admin` with a password of `docker`.  You can change
the password at run via environment variables (see below).

# Environment
* `ADMIN_PASSWORD`: Use a custom admin password (default: docker)
* `REGISTRY_NAME`: Custom name for registry (used when prompted for auth)

# Ports
* 80
* 5000

# Running on S3
To run with Amazon S3 as the backing store, you will need the following environment variables:

* `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID (make sure it has S3 access)
* `AWS_SECRET_KEY`: Your AWS Secret Key
* `S3_BUCKET`: Your S3 bucket to store images
* `SETTINGS_FLAVOR`: This must be set to `prod`
