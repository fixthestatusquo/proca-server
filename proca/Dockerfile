# --- Build 
FROM elixir AS builder

ENV MIX_ENV=prod \
    LANG=C.UTF-8


RUN mix local.hex --force  && \
    mix local.rebar --force


RUN mkdir /app
WORKDIR /app

COPY config ./config
COPY lib ./lib
COPY priv ./priv
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get
RUN mix deps.compile
RUN mix phx.digest
RUN mix release

# --- APP
FROM debian:buster AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apt-get update && apt-get install -y openssl libtinfo6

# Copy over the build artifact from the previous step and create a non root user
RUN useradd --create-home app
WORKDIR /home/app
COPY --from=builder /app/_build .
RUN chown -R app: ./prod
USER app

CMD ["./prod/rel/proca/bin/proca", "start"]
