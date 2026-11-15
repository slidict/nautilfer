FROM ruby:4.0-bookworm

WORKDIR /app

# compose passes UID=${UID}, which is empty on hosts that do not export it, so the
# build has to produce the account anyway. The previous `[ "$UID" -ne "" ]` was a
# numeric test against an empty string: it errored, took the else branch, and
# skipped useradd even when a UID *was* supplied.
ARG UID=1000

RUN apt-get update -qq && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*
COPY . .
RUN bundle install

# Everything above needs root. Create the account last, hand it /app and the gem
# path so `bundle install` still works at runtime, and only then stop being root.
RUN useradd --create-home --uid "$UID" user \
 && chown -R user:user /app "${GEM_HOME:-/usr/local/bundle}"
USER user
