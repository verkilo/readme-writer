FROM ruby:latest
LABEL maintainer="Ben Wilson <ben@merovex.com>"

ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes

RUN apt-get update -q \
    && apt-get install -qy \
      locales

RUN rm -rf /var/lib/apt/lists/*
RUN mkdir -p ./cache

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN gem install liquid

COPY compile.rb /compile.rb
COPY README.liquid /README.liquid

ENTRYPOINT ["/compile.rb"]
