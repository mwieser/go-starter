### -----------------------
# --- Stage: development
# --- https://hub.docker.com/_/golang
# --- https://github.com/microsoft/vscode-remote-try-go/blob/master/.devcontainer/Dockerfile
### -----------------------
FROM golang:1.15.0 AS development

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# https://github.com/go-modules-by-example/index/blob/master/010_tools/README.md#walk-through
ENV GOBIN /app/bin
ENV PATH $GOBIN:$PATH

# Our Makefile / env fully supports parallel job execution
ENV MAKEFLAGS "-j 8 --no-print-directory"

# postgresql-support: Add the official postgres repo to install the matching postgresql-client tools of your stack
# https://wiki.postgresql.org/wiki/Apt
# run lsb_release -c inside the container to pick the proper repository flavor
# e.g. stretch=>stretch-pgdg, buster=>buster-pgdg
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" \
    | tee /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add -

# Install required system dependencies
RUN apt-get update \
    && apt-get install -y \
    #
    # Mandadory minimal linux packages
    # Installed at development stage and app stage
    # Do not forget to add mandadory linux packages to the final app Dockerfile stage below!
    # 
    # -- START MANDADORY --
    ca-certificates \
    # --- END MANDADORY ---
    # 
    # Development specific packages
    # Only installed at development stage and NOT available in the final Docker stage
    # based upon
    # https://github.com/microsoft/vscode-remote-try-go/blob/master/.devcontainer/Dockerfile
    # https://raw.githubusercontent.com/microsoft/vscode-dev-containers/master/script-library/common-debian.sh
    #
    # -- START DEVELOPMENT --
    apt-utils \
    dialog \
    openssh-client \
    less \
    iproute2 \
    procps \
    lsb-release \
    locales \
    sudo \
    bash-completion \
    bsdmainutils \
    postgresql-client-12 \
    # --- END DEVELOPMENT ---
    # 
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# env/vscode support: LANG must be supported, requires installing the locale package first
# https://github.com/Microsoft/vscode/issues/58015
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

# sql pgFormatter: Install the same version of pg_formatter as used in your editors, as of 2020-04 thats v4.3
# requires perl to be installed
# https://github.com/bradymholt/vscode-pgFormatter/commits/master
# https://github.com/darold/pgFormatter/releases
RUN mkdir -p /tmp/pgFormatter \
    && cd /tmp/pgFormatter \
    && wget https://github.com/darold/pgFormatter/archive/v4.3.tar.gz \
    && tar xzf v4.3.tar.gz \
    && cd pgFormatter-4.3 \
    && perl Makefile.PL \
    && make && make install \
    && rm -rf /tmp/pgFormatter 

# go gotestsum: (this package should NOT be installed via go get)
# https://github.com/gotestyourself/gotestsum/releases
RUN mkdir -p /tmp/gotestsum \
    && cd /tmp/gotestsum \
    && wget https://github.com/gotestyourself/gotestsum/releases/download/v0.5.2/gotestsum_0.5.2_linux_amd64.tar.gz \
    && tar xzf gotestsum_0.5.2_linux_amd64.tar.gz \
    && cp gotestsum /usr/local/bin/gotestsum \
    && rm -rf /tmp/gotestsum 

# go linting: (this package should NOT be installed via go get)
# https://github.com/golangci/golangci-lint#binary
# https://github.com/golangci/golangci-lint/releases
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \
    | sh -s -- -b $(go env GOPATH)/bin v1.30.0

# go swagger: (this package should NOT be installed via go get) 
# https://github.com/go-swagger/go-swagger/releases
RUN curl -o /usr/local/bin/swagger -L'#' \
    "https://github.com/go-swagger/go-swagger/releases/download/v0.25.0/swagger_linux_amd64" \
    && chmod +x /usr/local/bin/swagger

# linux permissions / vscode support: Add user to avoid linux file permission issues
# Detail: Inside the container, any mounted files/folders will have the exact same permissions
# as outside the container - including the owner user ID (UID) and group ID (GID). 
# Because of this, your container user will either need to have the same UID or be in a group with the same GID.
# The actual name of the user / group does not matter. The first user on a machine typically gets a UID of 1000,
# so most containers use this as the ID of the user to try to avoid this problem.
# 2020-04: docker-compose does not support passing id -u / id -g as part of its config, therefore we assume uid 1000
# https://code.visualstudio.com/docs/remote/containers-advanced#_adding-a-nonroot-user-to-your-dev-container
# https://code.visualstudio.com/docs/remote/containers-advanced#_creating-a-nonroot-user
ARG USERNAME=development
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# vscode support: cached extensions install directory
# https://code.visualstudio.com/docs/remote/containers-advanced#_avoiding-extension-reinstalls-on-container-rebuild
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders

# linux permissions / vscode support: chown $GOPATH so $USERNAME can directly work with it
# Note that this should be the final step after installing all build deps 
RUN mkdir -p /$GOPATH/pkg && chown -R $USERNAME /$GOPATH

### -----------------------
# --- Stage: builder
### -----------------------

FROM development as builder
WORKDIR /app
COPY Makefile /app/Makefile
COPY go.mod /app/go.mod
COPY go.sum /app/go.sum
RUN make modules
COPY tools.go /app/tools.go
RUN make tools
COPY . /app/

### -----------------------
# --- Stage: builder-app
### -----------------------

FROM builder as builder-app
RUN make go-build

### -----------------------
# --- Stage: app
### -----------------------

FROM debian:buster-slim as app

RUN apt-get update \
    && apt-get install -y \
    #
    # Mandadory minimal linux packages
    # Installed at development stage and app stage
    # Do not forget to add mandadory linux packages to the base development Dockerfile stage above!
    #
    # -- START MANDADORY --
    ca-certificates \
    # --- END MANDADORY ---
    #
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder-app /app/bin/app /app/bin/sql-migrate /app/
COPY --from=builder-app /app/dbconfig.yml /app/
COPY --from=builder-app /app/api/swagger.yml /app/api/
COPY --from=builder-app /app/assets /app/assets/
COPY --from=builder-app /app/migrations /app/migrations/
COPY --from=builder-app /app/web /app/web/

WORKDIR /app

CMD [ "/bin/sh", "-c", "/app/sql-migrate up && /app/app server" ]