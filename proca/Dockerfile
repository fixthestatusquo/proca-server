# --- Builder --------------------------------------------

FROM elixir AS builder

ENV MIX_ENV=prod \
    LANG=C.UTF-8

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -  && \
    apt-get install -y nodejs 

RUN mix local.hex --force  && \
    mix local.rebar --force

RUN mkdir /app
WORKDIR /app

COPY config ./config
COPY assets ./assets
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get
RUN mix deps.compile
RUN npm install --prefix ./assets && npm run deploy --prefix ./assets
RUN mix phx.digest
RUN mix release

# --- APP ----------------------------------------------

FROM debian:buster AS app

ENV LANG=C.UTF-8
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/app/prod/rel/proca/bin
ENV DEBIAN_FRONTEND=noninteractive
ENV LOGS_DIR=/app/log

# Install openssl

RUN apt-get update && apt-get install -y openssl libtinfo6

# Copy over the build artifact from the previous step and create a non root user

RUN useradd --home-dir /app app

WORKDIR /app

COPY --from=builder /app/_build .

COPY rel/bin/setup ./prod/rel/proca/bin/setup

COPY .iex.exs ./.iex.exs

RUN mkdir ./prod/rel/proca/tmp && chmod 0777 ./prod/rel/proca/tmp \
    && chmod +x ./prod/rel/proca/bin/setup \
    && find . -type f -a -perm /u=x -exec chmod +x {} \;

USER app

CMD ["sh", "-c", "setup && exec proca start"]
