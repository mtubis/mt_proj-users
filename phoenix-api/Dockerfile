FROM hexpm/elixir:1.17.3-erlang-27.2.2-debian-bookworm-20250203

WORKDIR /app

RUN apt-get update \
  && apt-get install -y build-essential git ca-certificates curl \
  && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=dev

# cache deps
COPY mix.exs mix.lock ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get

# reszta projektu
COPY . .

EXPOSE 4000

CMD ["sh", "-lc", "mix ecto.create && mix ecto.migrate && mix phx.server"]
