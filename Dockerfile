FROM ruby:4.0-bookworm

WORKDIR /app

# compose passes UID=${UID:-1000}, so the account exists even when the host shell
# exports nothing. The previous `[ "$UID" -ne "" ]` was a numeric test against an
# empty string: it errored, took the else branch, and skipped useradd even when a
# UID *was* supplied, while the `if` swallowed the non-zero status.
# A uid below 1000 collides with a Debian system account and useradd fails the
# build. That is deliberate — silently running as `daemon` would be worse.
ARG UID=1000

RUN apt-get update -qq && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

# Create the account before anything is copied in, so /app and the gem path are
# handed over while they are still empty; a chown after the copy would duplicate
# the whole source tree and gem tree into another layer. The official ruby image
# installs gems into a root-owned /usr/local/bundle, and a dev container that
# cannot add a dependency would be worse than the problem being fixed.
RUN useradd --create-home --uid "$UID" user \
 && chown -R user:user /app "${GEM_HOME:-/usr/local/bundle}"

# Everything above needed root; nothing below does.
USER user
COPY --chown=user:user . .
RUN bundle install
