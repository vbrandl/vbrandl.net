+++
date = "2018-07-15T17:00:00+02:00"
publishdate = "2018-07-15T17:00:00+02:00"
title = "BIND9 API"
description = ""
draft = true
categories = ["rust", "letsencrypt", "dns"]
tags = ["rust", "actix-web"]

+++

I manage most of my domains using my own nameservers, running BIND9 on
two Debian VPS located in Italy (master) and France (slave). Until
now, I've been changing the DNS records by SSHing into the machine and
editing the zonefile by hand. This worked fine since I rarely needed
to change any DNS records. Then earlier this year, [LetsEncrypt][0]
put the ACME v2 endpoint into production which allows users to issue
wildcard certificates using the DNS challenge. This put me into a
situation where I needed to create, update and delete DNS records
automatically.

<!-- more -->

While the LetsEncrypt HTTP challenge requires the user to make the
challenge flag available via HTTP under
`http://www.example.com/.well-known/acme-challenge`. This way, the
ACME endpoint can only verify ownership over a specific subdomain
(`www.example.com` in this case). The DNS challenge looks for the flag
in the TXT record `_acme-challenge.example.com`. This allows the ACME
endpoint to validate ownership over the whole domain and it is
possible to issue a wildcard certificate for `*.example.com`.

Since DNS setups vary depending on the domain provider or used DNS
server, certbot can use manual auth and cleanup hooks, that receive
the domain name and challenge flag via the environment variables
`$CERTBOT_DOMAIN` and `$CERTBOT_VALIDATION` respectively.

Once the challenge mechanism was understood, I needed a way to
programmatically create and delete records on my BIND9 server. I
decided to implement I REST-like webservice to run on the same machine
as BIND9 and modify records using the `nsupdate` command.

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
reverse proxy like nginx to encrypt the requests using TLS or as I am
doing it, make the server listen on a private IP address inside an
encrypted VLAN ([tinc][1] in my case).

For the implementation of the API and the client, I chose to use Rust
with the [actix-web][2] framework for the server and [reqwest][3] to
make HTTP requests on the client side. While I have already worked
with other Rust web frameworks, namely [Rocket][4] for my Bachelor
thesis but it depends on the nightly branch of the compiler and is a
pain to maintain over a longer period of time. Also actix-web is
_really_ fast[^actix-performance].

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

After placing the client somewhere in `$PATH` and putting the certbot
hooks on the machine that should issue the certificates, I can invoke
certbot like followed:

```
certbot certonly -n --agree-tos --server \
https://acme-v02.api.letsencrypt.org/directory --preferred-challenges=dns-01 \
--manual --manual-auth-hook /usr/lib/letsencrypt-bind9/certbot-bind9-auth \
--manual-cleanup-hook /usr/lib/letsencrypt-bind9/certbot-bind9-cleanup \
--manual-public-ip-logging-ok -d example.com -d '*.example.com'
```


[0]: https://letsencrypt.org/
[1]: https://www.tinc-vpn.org/
[2]: https://github.com/actix/actix-web/
[3]: https://github.com/seanmonstar/reqwest/
[4]: https://github.com/SergioBenitez/Rocket/
[5]: https://github.com/kegato/letsencrypt-inwx/
[6]: https://github.com/vbrandl/bind9-api#server

[^actix-performance]: https://www.techempower.com/benchmarks/#section=data-r16&hw=ph&test=plaintext

>  vim: set filetype=markdown ts=4 sw=4 tw=70 noet :
