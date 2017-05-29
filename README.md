Myrmex development environment image
===

This repository contains the Dockerfile used for the automated build of the image `myrmex/dev`.

This image is useful to set up a development environment to work on Lager or Lager plugins.

The default user is `myrmex`.

A *hack* allows to run a container using the user `myrmex` with a specified UID.
This aims to simplify the management of permissions when the UID of the user that runs a container is different than 1000.

```bash
# Run containers normally if you do not have to manage host/container permissions
docker run myrmex/dev <command>

# Run the container as root with a  HOST_UID environment variable to override the UID in the container
# The command will be executed as the user "myrmex"
docker run -u root --env HOST_UID=`id -u` myrmex/dev <command>

# If the host GID differs from the UID, it is possible to set it
# Otherwise, it will be considered that HOST_GID = HOST_UID
docker run -u root --env HOST_UID=`id -u` --env HOST_GID=`id -g` myrmex/dev <command>
```
