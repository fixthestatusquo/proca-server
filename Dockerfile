# --- Builder --------------------------------------------

FROM hexpm/elixir:1.18.4-erlang-27.3.4-alpine-3.21.3 AS builder

ENV MIX_ENV=prod \
    LANG=C.UTF-8

RUN apk add --no-cache build-base git nodejs npm

RUN mix local.hex --force && \
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
RUN mix phx.digest
RUN mix release

# --- APP ----------------------------------------------

FROM alpine:3.21 AS app

ENV LANG=C.UTF-8
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/app/prod/rel/proca/bin
ENV LOGS_DIR=/app/log

RUN apk add --no-cache openssl ncurses-libs libstdc++ libgcc

RUN adduser -D -h /app app

WORKDIR /app

COPY --from=builder /app/_build .

COPY rel/bin/setup ./prod/rel/proca/bin/setup

COPY .iex.exs ./.iex.exs

RUN mkdir ./prod/rel/proca/tmp && chmod 0777 ./prod/rel/proca/tmp \
    && chmod +x ./prod/rel/proca/bin/setup \
    && find . -type f -a -perm /u=x -exec chmod +x {} \;

USER app

CMD ["sh", "-c", "setup && exec proca start"]
