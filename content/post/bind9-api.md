+++
date = "2018-07-15T21:45:00+02:00"
publishdate = "2018-07-15T21:45:00+02:00"
title = "BIND9 API"
description = ""
draft = true
categories = ["rust", "letsencrypt", "dns"]
tags = ["rust", "actix-web"]

+++

I manage most of my domains using my own nameservers, running
[BIND9][18] on two Debian VPS located in Italy (master) and France
(slave). Until now, I've been changing the DNS records by SSHing into
the machine and editing the zonefile by hand. This worked fine since I
rarely needed to change any DNS records. Then earlier this year,
[LetsEncrypt][0] put the ACME v2 endpoint into production which allows
users to obtain wildcard certificates using the DNS challenge. This
put me into a situation where I needed to create, update and delete
DNS records automatically.

<!-- more -->

The LetsEncrypt HTTP challenge requires the user to make the challenge
flag available via HTTP under
`http://www.example.com/.well-known/acme-challenge`. This way, the
ACME endpoint can only verify ownership over a specific subdomain
(`www.example.com` in this case). The DNS challenge looks for the flag
in the TXT record `_acme-challenge.example.com`. This allows the ACME
endpoint to validate ownership over the whole domain and it is
possible to issue a wildcard certificate for `*.example.com`.

Since DNS setups vary depending on the domain provider or used DNS
server, [certbot][10] can use manual auth and cleanup hooks, that receive
the domain name and challenge flag via the environment variables
`$CERTBOT_DOMAIN` and `$CERTBOT_VALIDATION` respectively.

Once the challenge mechanism was understood, I needed a way to
programmatically create and delete records on my BIND9 server. I
decided to implement a REST-like webservice to run on the same machine
as BIND9 and modify records using the [`nsupdate` command][7].

The REST API offers two methods:

```
POST /record
X-Api-Token: <api-token>

{
    "name": "_acme-challenge.example.com",
    "value": "<challenge flag>",
    "record": "TXT",
    "ttl": 1337
}
```

```
DELETE /record
X-Api-Token: <api-token>

{
    "name": "_acme-challenge.example.com",
    "record": "TXT"
}
```

The `X-Api-Token` header contains the SHA256-HMAC over the request
body using a pre-shared secret to prevent unauthenticated use of the
API but this still does not protect against replay attacks. If an
attacker managed to intercept an request to the API, (s)he would be
able to resend the same request to the server and re-execute the
command. To prevent this, the API server has to be placed behind a
reverse proxy like [nginx][11] to encrypt the requests using TLS or as I am
doing it, make the server listen on a private IP address inside an
encrypted VLAN ([tinc][1] in my case).

Once the body was verified using the pre-shared secret `nsupdate` is
invoked and the following update or delete scripts are passed via
stdin:

```
server 127.0.0.1
update add _acme-challenge.example.com 1337 TXT <challenge flag>
send
```

```
server 127.0.0.1
update delete _acme-challenge.example.com TXT
send
```

For the implementation of the API and the client, I chose to use Rust
with the [actix-web][2] framework for the server and [reqwest][3] to
make HTTP requests on the client side. The implementation along with
installation instructions can be found [on Github][8] or [my Gitea
instance][9]. I have already worked with the [Rocket][4] web framework
for my Bachelor thesis but it depends on the nightly branch of the
compiler and is a pain to maintain over a longer period of time due to
breaking changes in the nightly compiler. Also actix-web is _really_
fast[^actix-performance]. Further crates that were used and should be
mentioned include [ring][12] for cryptographic operations, [serde][13]
for (de)serialization of data and [proptest][14] to verify some
properties of my code (e.g.  `verify_signature(key, msg, sign(key,
msg))` must be true for every input of `key` and `msg`). Rust made it
easy to exchange data between the client and the server in a typesafe
manner and actix-web offers an well designed API to build fast web
applications. While actix-web lacks the incredible ergonomics of
Rocket (it's not bad, just not as good as Rocket), I prioritize using
the stable compiler branch over API ergonomics.

The client itself is independent of the way, certbot works and the
integration into the workflow is archived by bash scripts inspired by
[these INWX certbot hooks][5].

For the server to work, a DNS key has to be generated as described in
[the repository][6] to be able to modify the records using `nsupdate`.
I start the API server using a systemd service:

```
[Unit]
Description=BIND9 API

[Service]
Type=onshot
ExecStart=/usr/local/bin/bind9-api -k /etc/bind/dnskey -h 10.0.1.101 -t <api secret>
ExecStop=pkill bind9-api

[Install]
WantedBy=multi-user.target
```

The client is configured using the configuration file
`/etc/bind9apiclient.toml` that contains the API URL and secret.

```
# API server host
host = "http://127.0.0.1:8080"
# API secret
secret = "topsecret"
```

The final binaries, I use in production are compiled using the
[`ekidd/rust-musl-builder` Docker image][16] to build completely
static binaries by linking against the [musl libc][17] (Linking
against the default glibc target, produces dynamically linked binaries
that depend to the systems glibc and OpenSSL version).

After placing the client somewhere in `$PATH` and putting the certbot
hooks on the machine that should obtain the certificates, I can invoke
certbot like followed:

```
certbot certonly -n --agree-tos --server \
https://acme-v02.api.letsencrypt.org/directory --preferred-challenges=dns-01 \
--manual --manual-auth-hook /usr/lib/letsencrypt-bind9/certbot-bind9-auth \
--manual-cleanup-hook /usr/lib/letsencrypt-bind9/certbot-bind9-cleanup \
--manual-public-ip-logging-ok -d example.com -d '*.example.com'
```

I already obtained a wildcard certificate for my domain
[oldsql.cc][15], even if I'm using only a single subdomain, to test my
code. Obtaining the certificate worked fine, and I guess renewal won't
pose any problems either.

[0]: https://letsencrypt.org/
[1]: https://www.tinc-vpn.org/
[2]: https://actix.rs/
[3]: https://github.com/seanmonstar/reqwest/
[4]: https://rocket.rs/
[5]: https://github.com/kegato/letsencrypt-inwx/
[6]: https://github.com/vbrandl/bind9-api#server
[7]: https://linux.die.net/man/8/nsupdate
[8]: https://github.com/vbrandl/bind9-api
[9]: https://git.vbrandl.net/vbrandl/bind9-api
[10]: https://certbot.eff.org/
[11]: https://nginx.org/
[12]: https://crates.io/crates/ring
[13]: https://crates.io/crates/serde
[14]: https://crates.io/crates/proptest
[15]: https://oldsql.cc
[16]: https://hub.docker.com/r/ekidd/rust-musl-builder/
[17]: https://www.musl-libc.org/
[18]: https://www.isc.org/downloads/bind/

[^actix-performance]: https://www.techempower.com/benchmarks/#section=data-r16&hw=ph&test=plaintext
