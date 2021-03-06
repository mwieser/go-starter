# go-starter

`go-starter` is an opinionated [golang](https://golang.org/) backend development template by [allaboutapps](https://allaboutapps.at/).

## Table of Contents

- [go-starter](#go-starter)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Usage](#usage)
    - [Requirements](#requirements)
    - [Quickstart](#quickstart)
    - [Set project module name](#set-project-module-name)
    - [Typical commands](#typical-commands)
    - [Running locally](#running-locally)
    - [`./docker-helper.sh`](#docker-helpersh)
    - [PostgreSQL](#postgresql)
    - [SwaggerUI](#swaggerui)
  - [Additional resources](#additional-resources)
  - [Contributing](#contributing)
  - [Maintainers](#maintainers)
  - [License](#license)

## Features

- Full local golang service development environment using [Docker Compose](https://docs.docker.com/compose/install/) and [VSCode devcontainers](https://code.visualstudio.com/docs/remote/containers) that just works with Linux, MacOS and Windows.
- Adheres to the project layout defined in [golang-standard/project-layout](https://github.com/golang-standards/project-layout).
- Provides database migration ([sql-migrate](https://github.com/rubenv/sql-migrate)) and models generation ([SQLBoiler](https://github.com/volatiletech/sqlboiler)) workflows for [PostgreSQL](https://www.postgresql.org/) databases.
- Integrates [IntegreSQL](https://github.com/allaboutapps/integresql) for fast, concurrent and isolated integration testing with real PostgreSQL databases.
- Autoinstalls our recommended VSCode extensions for golang development.
- Integrates [go-swagger](https://github.com/go-swagger/go-swagger) for compile-time generation of `swagger.yml`, structs and request/response validation functions.
- Integrates [MailHog](https://github.com/mailhog/MailHog) for easy SMTP-based email testing.
- Integrates [SwaggerUI](https://github.com/swagger-api/swagger-ui) for live-previewing your Swagger v2 schema.
- Integrates [pgFormatter](https://github.com/darold/pgFormatter) and [vscode-pgFormatter](https://marketplace.visualstudio.com/items?itemName=bradymholt.pgformatter) for SQL formatting.
- Comes with fully implemented `auth` package, an OAuth2 RESTful JSON API ready to be extended according to your requirements.
- Implements [OAuth 2.0 Bearer Tokens](https://tools.ietf.org/html/rfc6750) and password authentication using [argon2id](https://godoc.org/github.com/alexedwards/argon2id) hashes.
- Comes with a tested mock and [FCM](https://firebase.google.com/docs/cloud-messaging) provider for sending push notifications and storing push tokens.
- CLI layer provided by [spf13/cobra](https://github.com/spf13/cobra). It's exceptionally easy to add additional subcommands.
- Parallel jobs optimized `Makefile` and various convenience scripts (see all targets and description with `make help`). A full rebuild via `make build` only takes seconds.
- Multi-staged `Dockerfile` (`development` -> `builder` -> `builder-app` -> `app`).

## Usage

### Requirements

Requires the following local setup for development:

- [Docker CE](https://docs.docker.com/install/) (19.03 or above)
- [Docker Compose](https://docs.docker.com/compose/install/) (1.25 or above)
- [VSCode Extension: Remote - Containers](https://code.visualstudio.com/docs/remote/containers) (`ms-vscode-remote.remote-containers`)

The project makes use of the [Remote - Containers extension](https://code.visualstudio.com/docs/remote/containers) provided by [Visual Studio Code](https://code.visualstudio.com/). A local installation of the Go toolchain is *no longer* required when using this setup. Please refer to the above official installation guide how this works for your host OS.

### Quickstart

> GitHub: Click on **[Use this template](https://github.com/allaboutapps/go-starter/generate)** to create your own project.   
> Contributions and others: You will need to fork this repository.

```bash
# Easily start the docker-compose dev environment through our helper
./docker-helper.sh --up

# You should be inside the 'service' docker container with a bash shell.
# development@XXXXXXXXX:/app$

# You may also work in VSCode's integrated terminal after connecting via CMD+SHIFT+P "Remote-Containers: Reopen in Container"

# Print all available make targets
make help
```

### Set project module name

After your `git clone` you may do the following:

```bash
# Change the go project module name and create a new README
make set-module-name
# internal: allaboutapps.dev/<GIT_PROJECT>/<GIT_REPO>
# others: github.com/<USER>/<PROJECT>

# Finally move our license file away and create a new README.md for your project
mv README.md README-go-starter.md
mv LICENSE LICENSE-go-starter
make get-module-name > README.md
```

### Typical commands

Other useful commands while developing your service:

```bash
# Print all available make targets
make help

# Shortcut for make init, make build, make info and make test
make all

# Init install/cache dependencies and install tools to bin
make init

# Rebuild only after changes to files (generate, format, build, lint)
make

# Execute all tests
make test
```

### Running locally

To finally run the service locally you may:

```bash
# Migrate up the database
sql-migrate up

# Seed the database (if you have any fixtures defined in `/internal/data/fixtures.go`)
app db seed

# Start the locally-built server
app server

# Now available at http://127.0.0.1:8080
``` 

### `./docker-helper.sh`

Our `docker-helper.sh` script does its best to assist our `docker-compose`-based local dev workflow: 

```bash
# ---

# $local

# you may attach to the development container through multiple shells, it's always the same command
./docker-helper.sh --up

# if you ever need to halt the docker-compose env (without deleting your projects' images & volumes)
./docker-helper.sh --halt

# if you ever change something in the Dockerfile and require a rebuild of the service image only
./docker-helper.sh --rebuild

# if you ever need to wipe ALL docker traces (will delete your projects' images & volumes)
./docker-helper.sh --destroy
```

### PostgreSQL

A PostgreSQL database is automatically started and exposed on `localhost:5432`.

Feel free to connect with your preferred database client from your host maschine for debugging purposes or just issue `psql` within our development container.

### SwaggerUI

A Swagger-UI container was automatically started through our `docker-compose.yml` and is exposed on Port `8081`. Please visit [http://localhost:8081](http://localhost:8081/) to access it (it does not require a running `app server`).

Regarding [Visual Studio Code](https://code.visualstudio.com/): Always develop *inside* the running `development` docker container, by attaching to this container.

Run CMD+SHIFT+P `Go: Install/Update Tools` after starting vscode to autoinstall all golang vscode dependencies, then **reload your window**.

## Additional resources

* [Wiki](https://github.com/allaboutapps/go-starter/wiki)
* [FAQ](https://github.com/allaboutapps/go-starter/wiki/FAQ)
* [Random Training Material](https://github.com/allaboutapps/go-starter/wiki/Random-training-material)

## Contributing

Pull requests are welcome. For major changes, please [open an issue](https://github.com/allaboutapps/go-starter/issues/new) first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## Maintainers

- [Michael Farkas - @farkmi](https://github.com/farkmi)
- [Nick Müller - @MorpheusXAUT](https://github.com/MorpheusXAUT)
- [Mario Ranftl - @majodev](https://github.com/majodev)
- [Manuel Wieser - @mwieser](https://github.com/mwieser)

## License

[MIT](LICENSE) © 2020 aaa – all about apps GmbH | Michael Farkas | Nick Müller | Mario Ranftl | Manuel Wieser and the "go-starter" project contributors
