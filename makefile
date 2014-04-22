NODEJS_VERSION := v0.10.26
export SHELL=/bin/bash -l
VARNISH_DAEMON := /usr/local/sbin/varnishd
VARNISH_VERSION := 3.0.3

test:
	nvm use $(NODEJS_VERSION) && ./run_tests.sh

install: base nvm varnish
	nvm install $(NODEJS_VERSION)
	nvm use $(NODEJS_VERSION) && npm install
	echo "Instalacion exitosa!"
	
nvm:
	curl https://raw.github.com/creationix/nvm/master/install.sh | sh
	
varnish:
	($(VARNISH_DAEMON) -V 2>&1 | grep $(VARNISH_VERSION)) || (cd /tmp/ && wget http://repo.varnish-cache.org/source/varnish-$(VARNISH_VERSION).tar.gz && tar xvf varnish-$(VARNISH_VERSION).tar.gz && cd /tmp/varnish-$(VARNISH_VERSION) && sudo sh autogen.sh && sudo sh configure && sudo make && sudo make install)
	
update:
	sudo apt-get update

base: update
	sudo apt-get install autotools-dev automake libtool autoconf libncurses5-dev xsltproc groff-base libpcre3-dev pkg-config g++ -y -f

.PHONY: test
