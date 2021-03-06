FROM debian:stretch
MAINTAINER Martin Høgh<mh@mapcentia.com>

RUN export DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Install packages
RUN apt-get -y update --fix-missing
RUN apt-get -y install wget curl vim git supervisor postgresql-client nodejs default-jre gnupg2 locales libssl1.0-dev libxss-dev

RUN curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh &&\
    bash nodesource_setup.sh &&\
    apt-get install -y nodejs

# Clone Vidi from GitHub
RUN cd  ~ &&\
	git  clone http://github.com/mapcentia/vidi.git --branch master

# Install grunt
RUN cd ~/vidi &&\
    npm install grunt-cli -g --save-dev

# Install packages
RUN cd ~/vidi &&\
	npm install

RUN cd ~/vidi/public/js/lib/bootstrap-material-design &&\
	npm install

#Add config files from Git repo
COPY conf/vidi/config.js /root/vidi/config/config.js
RUN cp ~/vidi/public/js/lib/bootstrap-material-design/less/_variables.less ~/vidi/config/_variables.less

EXPOSE 3000

# Share the source dir
VOLUME  ["/root/vidi"]

# Add entry point
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Add Supervisor config and run the daemon
ADD conf/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]