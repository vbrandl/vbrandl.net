+++
date = "2018-07-20T13:30:00+02:00"
publishdate = "2018-07-20T13:30:00+02:00"
title = "Deploying a Hugo website using Gitea and DroneCI"
description = "Building a continuous delivery pipeline for static websites generated with Hugo"
draft = true
categories = ["Continuous Delivery", "Hugo"]
tags = ["Hugo", "DevOps", "Gitea", "DroneCI"]
toc = true

+++

This blog is created using the [Hugo][0] static site generator. I used
to deploy new posts using a bare git repository on the target server
and a `post-receive` hook to build the posts and copy them to the
public web server directory. I followed [this tutorial][1] by Digital
Ocean. This worked well enough but, to deploy the blog, I always
needed to push to a separate git remote. Also I had to set up SSH
access to the server and the new git remote if I wanted to write posts
on another machine. I decided, a better setup was needed.

<!-- more -->

## Goal

The goal of the new pipeline should be to automatically build and
deploy the blog when commit is made to the repository:

```
+-------------------+    +------------+    +------------------+
| Git commit & push | -> | Hugo build | -> | Deploy to server |
+-------------------+    +------------+    +------------------+
```

## Setup

A few weeks ago, I setup [DroneCI][2] aside my [Gitea][3] instance.
There is a [great plugin for DroneCI][4] to build Hugo websites.
Deploying the generated pages can be done using the [SCP][5] or
[rsync][6] plugins. I decided to use rsync since it would be able to
execute a custom script after copying the files over to the target
machine (which might come in handy in the future).

Drone build pipelines are made up of several steps, where the changes
made on the repository in each step are persisted to the next step. So
when the first step (actually it is the second step since the first is
cloning the repository but this is an implicit step) builds the Hugo
website, the build output in the `public/` directory will still exist
in the following step, so I can use the created files and copy them to
the target server in the second step. At this point my DroneCI
configuration looked like this:

```yaml
pipeline:
  build:
    image: cbrgm/drone-hugo:latest
    validate: true
    url: https://www.vbrandl.net

  deploy:
    image: drillster/drone-rsync
    hosts: [ "vbrandl.net" ]
    target: /var/www/vbrandl.net
    source: public/*
    user: hugo
    secrets: [ rsync_key ]
```

The SSH key for the user `hugo` on the target server was added as a
secret to the repository so I was able to use rsync.

Due to Drones modular approach for build pipelines, it is trivial to
deploy the blog to other targets. There are plugins to deploy to [AWS
S3][11], use [FTP(S)][12] for uploading and many others. Only the
`deploy` step in the pipeline needs to be replaced.

## Improving the Pipeline

### Ahead-of-Time Compression

To take the load of compressing requested files from my web server, I
use the [`gzip_static` module][7] of nginx. The compression is done
using the following `Makefile`:

```Makefile
.PHONY: default clean

TARGETS = $(shell find . -type f -name '*.html')
TARGETS += $(shell find . -type f -name '*.asc')
TARGETS += $(shell find . -type f -name '*.css')
TARGETS += $(shell find . -type f -name '*.js')
TARGETS += $(shell find . -type f -name '*.txt')
TARGETS += $(shell find . -type f -name '*.xml')
TARGETS += $(shell find . -type f -name '*.svg')
TARGETS_GZ = $(patsubst %, %.gz, $(TARGETS))

CC=gzip
CFLAGS=-k -f -9

default: $(TARGETS_GZ)

%.gz : %
	$(CC) $(CFLAGS) $<

clean:
	rm -f $(TARGETS_GZ)
```

This way, when `index.html` is requested and the client requests a
compressed file, nginx will look if `index.html.gz` exists and if it
does, that file will be served, so the web server does not need to
compress the file on the fly. I implemented another step in my build
pipeline between the build and the deploy step, that uses the [Alpine
Linux base image][8], installs `make` and executes the `Makefile`.

```yaml
pipeline:
  build:
    image: cbrgm/drone-hugo:latest
    validate: true
    url: https://www.vbrandl.net

  compress:
    image: alpine:latest
    commands:
      - apk --no-cache update
      - apk add make
      - make -C public/ -f ../Makefile

  deploy:
    image: drillster/drone-rsync
    hosts: [ "vbrandl.net" ]
    target: /var/www/vbrandl.net
    source: public/*
    user: hugo
    secrets: [ rsync_key ]
```

### Multiple Environments

At this point I thought it would be fun to implement a staging area
for the blog to test unreleased drafts and get feedback on them,
without releasing them on the main blog. The staging area should be
based of the `develop` branch of the blog and publish every post (draft,
expired and future posts). On my server I created a new directory for
the staging area and let [staging.vbrandl.net][9] point there.

I made use of [conditional step execution][10] in Drone pipelines to
change the build and deploy steps depending on the branch:

```yaml
pipeline:
  build-dev:
    image: cbrgm/drone-hugo:latest
    buildDrafts: true
    buildFuture: true
    buildExpired: true
    validate: true
    url: https://staging.vbrandl.net
    when:
      branch: develop

  build-prod:
    image: cbrgm/drone-hugo:latest
    buildDrafts: false
    buildFuture: false
    buildExpired: false
    validate: true
    url: https://www.vbrandl.net
    when:
      branch: master

  compress:
    image: alpine:latest
    commands:
      - apk --no-cache update
      - apk add make
      - make -C public/ -f ../Makefile

  deploy-dev:
    image: drillster/drone-rsync
    hosts: [ "vbrandl.net" ]
    target: /var/www/staging.vbrandl.net
    source: public/*
    user: hugo
    secrets: [ rsync_key ]
    when:
      branch: develop

  deploy-prod:
    image: drillster/drone-rsync
    hosts: [ "vbrandl.net" ]
    target: /var/www/vbrandl.net
    source: public/*
    user: hugo
    secrets: [ rsync_key ]
    when:
      branch: master
```

Now my blog is automatically deployed once I merge new posts into the
`master` branch, and while using a separate staging area for my little
blog might be considered to be overkill, it was pretty fun to
implement a proper deployment pipeline.

The final pipeline looks like this:

```
+----------+   +-----------------+   +----------------+   +----------------+
| Git push | > | Hugo build $ENV | > | Compress files | > | Deploy to $ENV |
+----------+   +-----------------+   +----------------+   +----------------+
```


[0]: https://gohugo.io/
[1]: https://www.digitalocean.com/community/tutorials/how-to-deploy-a-hugo-site-to-production-with-git-hooks-on-ubuntu-14-04
[2]: https://drone.io/
[3]: https://gitea.io/
[4]: http://plugins.drone.io/cbrgm/drone-hugo/
[5]: http://plugins.drone.io/appleboy/drone-scp/
[6]: http://plugins.drone.io/drillster/drone-rsync/
[7]: http://nginx.org/en/docs/http/ngx_http_gzip_static_module.html
[8]: https://hub.docker.com/_/alpine/
[9]: https://staging.vbrandl.net/
[10]: http://docs.drone.io/pipelines/
[11]: http://plugins.drone.io/drone-plugins/drone-s3/
[12]: http://plugins.drone.io/christophschlosser/drone-ftps/
