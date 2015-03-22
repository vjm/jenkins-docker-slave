FROM ubuntu:14.04
MAINTAINER Vince Montalbano <vince.montalbano@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install JDK 7 (latest edition)
RUN apt-get update && apt-get install -y openjdk-7-jdk

RUN apt-get update && apt-get -y upgrade && apt-get install -y git wget curl openssh-server autoconf make zlibc zlib1g zlib1g-dev openssl libssl-dev libreadline-dev libgdbm-dev libreadline6-dev libncurses5-dev libpq-dev libffi-dev libmysqlclient-dev g++

RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.1

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
    && apt-get install -y bison libffi-dev libgdbm-dev ruby \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/src/ruby \
    && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
        | tar -xjC /usr/src/ruby --strip-components=1 \
    && cd /usr/src/ruby \
    && autoconf \
    && ./configure --disable-install-doc \
    && make -j"$(nproc)" \
    && make install \
    && apt-get purge -y --auto-remove bison libgdbm-dev ruby \
    && rm -r /usr/src/ruby

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

RUN gem install bundler \
    && bundle config --global path "$GEM_HOME" \
    && bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME

# Add user jenkins to the image
RUN adduser --quiet jenkins
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins" | chpasswd
RUN echo 'jenkins ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "/home/jenkins/.gemrc" 

RUN (curl -sL https://deb.nodesource.com/setup | bash -) && apt-get update && apt-get install -y npm nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/* && ln -s /usr/bin/nodejs /usr/bin/node

RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]