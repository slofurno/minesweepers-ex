FROM elixir:1.4.1-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends jq dnsutils build-essential \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app

COPY . /app
WORKDIR /app

ENV MIX_ENV="prod"

RUN make mine_nif.so

RUN dig -t ANY hex.pm > /dev/null \
&& mix local.hex --force \
&& mix local.rebar --force \
&& mix deps.get \
&& mix compile \
&& make mine_nif.so

CMD ["mix", "run", "--no-halt"]
