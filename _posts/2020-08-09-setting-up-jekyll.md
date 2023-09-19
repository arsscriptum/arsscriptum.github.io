---
layout: post
title:  "Jekyll Setup on WSL Running Ubuntu"
summary: "Jekyll Setup on WSL Running Ubuntu"
author: guillaume
date: '2020-08-09'
category: ['powershell','scripts', 'useless']
tags: powershell, scripts, useless
thumbnail: /assets/img/posts/jekyll/main.jpg
keywords: progress, powershell
usemathjax: false
permalink: /blog/powershell-settingup-bundlerjekyll/

---


-------------------

### Overview

I'm poor and cheap. My free options to host a simple blog are scarce, but fortunately, I can do it using [Github Pages](https://pages.github.com/). 
Github Pages is easy to use for static pages. On teh server-side, Github has implemented full of features for blog generation. Unfortunately, seeing your website
before it is commited requires the installation of a bunch of software that are not user-friendly. AKA Jekyll. This is my notes, how I successfully installed it.


### Requirements

This post was written assuming the following software requirements

Windows Environment:
- Windows 10
- [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/about)
- Ubuntu 18.04 LTS [hosted on the Microsoft Store](https://www.microsoft.com/store/productId/9PDXGNCFSCZV)

### Installation REQUIREMENTS


```bash

###############################################################################
# All This Just To Install Ruby
#                  ------------
# i have found the latest distrib version to be 18.x at
# https://github.com/nodesource/distributions/blob/master/deb/setup_18.x
#
# Last tested on 15/10/2022 on WSL Ubuntu 20.04.5
###############################################################################

sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-add-repository ppa:brightbox/ruby-ng
sudo apt-get update

cd $HOME
sudo apt-get update
sudo apt install curl
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install git-core zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs yarn

cd
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
exec $SHELL

git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
exec $SHELL

rbenv install 3.0.1
rbenv global 3.0.1
ruby -v

###############################################################################
# REQUIREMENTS
###############################################################################
sudo apt-get -y install git curl autoconf bison build-essential 
sudo apt-get -y install libssl-dev libyaml-dev libreadline6-dev zlib1g-dev
sudo apt-get -y install libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev
sudo apt-get -y install make gcc gpp build-essential zlib1g zlib1g-dev ruby-dev dh-autoreconf


###############################################################################
# GNU PG
###############################################################################
sudo apt install gnupg2
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add
```

### Installation **Ruby Version Manager RVM**
The installation of Ruby has proven to be problematic, but I managed to successfully install it via the [Ruby Version Manager (RVM)](https://rvm.io/).

The following script show what to do.


```bash

###############################################################################
# RVM VM is a command-line tool which allows you to easily install, manage, 
# and work with multiple ruby environments from interpreters to sets of gems.
###############################################################################
curl -sSL https://get.rvm.io -o rvm.sh
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

cat ./rvm.sh | bash -s stable --rails

source /home/gp/.rvm/scripts/rvm

```

### Installation RUBY

```bash

rvm install "ruby-3.1.2"

```

### Installation [BUNDLER](https://bundler.io/)

```bash

sudo gem update

sudo gem install bundler

bundle install


```

### Installation JEKYLL

Finally we can install Jekyll. Now in the official install guide reference above the command given will install Jekyll v4.0.0. This is incompatible with GitHub pages as referenced in the [GitHub Pages dependencies and versions](https://pages.github.com/versions/). We require Jekyll v3.8.5.

It is simple to specify we want this version ```jekyll --version```

Installation of JEKYLL Gem with: 


```bash

gem install jekyll --version 3.8.5

```

We can also list all installed Gems and compare to the GitHub Pages requried versions by running the command ```gem list```

```bash
gp@DESKTOP-1LEBREA:~$ gem list

*** LOCAL GEMS ***

	abbrev (default: 0.1.0)
	actioncable (7.0.4)
	actionmailbox (7.0.4)
	actionmailer (7.0.4)
	actionpack (7.0.4)
	actiontext (7.0.4)
	actionview (7.0.4)
	activejob (7.0.4)
	activemodel (7.0.4)
	activerecord (7.0.4)
	activestorage (7.0.4)
	activesupport (7.0.4)
	base64 (default: 0.1.0)
	benchmark (default: 0.1.1)
	bigdecimal (default: 3.0.0)
	builder (3.2.4)
	bundler (default: 2.2.3)
	bundler-unload (1.0.2)
	cgi (default: 0.2.0)
	concurrent-ruby (1.1.10)
	crass (1.0.6)
	csv (default: 3.1.9)
	date (default: 3.1.0)
	debug (default: 0.1.0)
	delegate (default: 0.2.0)
	did_you_mean (default: 1.5.0)
	digest (default: 3.0.0)
	drb (default: 2.0.4)
	english (default: 0.7.1)
	erb (default: 2.2.0)
	erubi (1.11.0)
	etc (default: 1.2.0)
	executable-hooks (1.6.1)
	fcntl (default: 1.0.0)
	fiddle (default: 1.0.6)
	fileutils (default: 1.5.0)
	find (default: 0.1.0)
	forwardable (default: 1.3.2)
	gdbm (default: 2.1.0)
	gem-wrappers (1.4.0)
	getoptlong (default: 0.1.1)
	globalid (1.0.0)
	i18n (1.12.0)
	io-console (default: 0.5.6)
	io-nonblock (default: 0.1.0)
	io-wait (default: 0.1.0)
	ipaddr (default: 1.2.2)
	irb (default: 1.3.0)
	json (default: 2.5.1)
	logger (default: 1.4.3)
	loofah (2.19.0)
	mail (2.7.1)
	marcel (1.0.2)
	matrix (default: 0.3.1)
	method_source (1.0.0)
	mini_mime (1.1.2)
	minitest (5.14.2)
	mutex_m (default: 0.1.1)
	net-ftp (default: 0.1.1)
	net-http (default: 0.1.1)
	net-imap (default: 0.1.1)
	net-pop (default: 0.1.1)
	net-protocol (default: 0.1.0)
	net-smtp (default: 0.2.1)
	nio4r (2.5.8)
	nkf (default: 0.1.0)
	nokogiri (1.13.8 x86_64-linux)
	observer (default: 0.1.1)
	open-uri (default: 0.1.0)
	open3 (default: 0.1.1)
	openssl (default: 2.2.0)
	optparse (default: 0.1.0)
	ostruct (default: 0.3.1)
	pathname (default: 0.1.0)
	power_assert (1.2.0)
	pp (default: 0.1.0)
	prettyprint (default: 0.1.0)
	prime (default: 0.1.2)
	pstore (default: 0.1.1)
	psych (default: 3.3.0)
	racc (default: 1.5.1)
	rack (2.2.4)
	rack-test (2.0.2)
	rails (7.0.4)
	rails-dom-testing (2.0.3)
	rails-html-sanitizer (1.4.3)
	railties (7.0.4)
	rake (13.0.3)
	rbs (1.0.0)
	rdoc (default: 6.3.0)
	readline (default: 0.0.2)
	readline-ext (default: 0.1.1)
	reline (default: 0.2.0)
	resolv (default: 0.2.0)
	resolv-replace (default: 0.1.0)
	rexml (3.2.4)
	rinda (default: 0.1.0)
	rss (0.2.9)
	rubygems-bundler (1.4.5)
	rvm (1.11.3.9)
	securerandom (default: 0.1.0)
	set (default: 1.0.1)
	shellwords (default: 0.1.0)
	singleton (default: 0.1.1)
	stringio (default: 3.0.0)
	strscan (default: 3.0.0)
	syslog (default: 0.1.0)
	tempfile (default: 0.1.1)
	test-unit (3.3.7)
	thor (1.2.1)
	time (default: 0.1.0)
	timeout (default: 0.1.1)
	tmpdir (default: 0.1.1)
	tracer (default: 0.1.1)
	tsort (default: 0.1.0)
	typeprof (0.11.0)
	tzinfo (2.0.5)
	un (default: 0.1.0)
	uri (default: 0.10.1)
	weakref (default: 0.1.1)
	websocket-driver (0.7.5)
	websocket-extensions (0.1.5)
	yaml (default: 0.1.1)
	zeitwerk (2.6.1)
	zlib (default: 1.1.0)
```

### Execute local server and test website

Go in the local directory where you cloned your Githu pages project and run this command:

```bash
cd /mnt/c/Users/gp/www/arsscriptum.github.io/
bundle exec jekyll serve --livereload --unpublished --incremental
```


### Full Script on Github

Get the full script [here](https://github.com/arsscriptum/PowerShell.SystemConfigurator/blob/master/Jekyll/RUBY_Install.sh)

### IMPORTANT NOTE

I have observed that windows Subystem for Linux sometimes requires a **restart** when the website is not updated properly in my browser.

To stop and restart WSL do this:

```powershell

function Restart-WSL {
    $MyWsl = (Get-Command 'wsl.exe').Source
    &"$MyWsl" "--shutdown"
}

```