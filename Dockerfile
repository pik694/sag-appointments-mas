FROM elixir:1.9.2

# copy sources
COPY ./mix.exs ./
COPY ./mix.lock ./
COPY ./config ./config
COPY ./lib ./lib
COPY ./Makefile ./

# install dependencies
RUN make init

# build
RUN make build


ENTRYPOINT [ "/bin/sh", "-c"]
