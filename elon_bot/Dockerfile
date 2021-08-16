FROM mikaak/elixir:1.11-alpine as builder

WORKDIR /home

# Add mix files
COPY ./config/* ./config/
COPY ./mix.exs ./

ENV HEX_HTTP_CONCURRENCY=4 \
    HEX_HTTP_TIMEOUT=500 \
    MIX_ENV=prod \
    NODE_ENV=production \
    PORT=4000

RUN mix do deps.get, compile

COPY ./lib ./lib

# Install Deps and Release
RUN rm -rf deps/*/.git && mix release

FROM mikaak/alpine-release:latest

WORKDIR /root
COPY --from=builder /home/_build/prod/elon_bot-0.1.0.tar.gz ./
RUN ["tar", "xzf", "elon_bot-0.1.0.tar.gz"]

ENV PORT=4000

EXPOSE 4000

ENTRYPOINT ["/root/bin/elon_bot"]
CMD ["start"]
