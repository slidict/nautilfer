FROM ruby:4.0-bookworm

WORKDIR /app

ARG UID

RUN if [ "$UID" -ne "" ] ; then \
      useradd user -d /app -u $UID; \
    fi

RUN apt-get update -qq && apt-get install -y git
COPY . .
RUN bundle install
