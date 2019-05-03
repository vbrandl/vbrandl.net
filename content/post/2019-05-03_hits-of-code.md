+++
title = "Hits-of-Code Badges"
description = "Building a web service for readme badges"
date = "2019-05-03T16:00:00+02:00"
publishdate = "2019-05-03T16:00:00+02:00"
draft = false
categories = ["rust", "programming"]
tags = ["rust", "actic-web", "hits-of-code", "code metric"]
+++

There are few metrics that try to evaluate a codebase. Some give a
glimpse about the code quality like cyclomatic complexity, code
duplication, dependency graphs and the most accurate of all, [WTFs per
minute (WTFs/min)](https://www.osnews.com/story/19266/wtfsm/).  Others
are less well fit to actually evaluate the quality of a code base such
as [souce lines of code
(SLoC)](https://en.wikipedia.org/wiki/Source_lines_of_code). Counting
SLoC might seem like a good metric for the amount of work invested in
a piece of software at first, but when you think about it, things like
refactorings and removal of duplicate code through new abstractions
might reduce the SLoC even if work was invested.

[![WTFs/m](/static/images/wtfm.jpg)](https://www.osnews.com/story/19266/wtfsm/)


## Hits-of-Code

A few years ago, [Yegor Bugayenko](https://www.yegor256.com) proposed
[Hits-of-Code](https://www.yegor256.com/2014/11/14/hits-of-code.html)
as an alternative to SLoC. The idea is to count the changes made to
the codebase over time instead of simply counting the current amount
of lines. By looking at the commit history, you can calculate the
metric and it gives a better overview about the amount of work, that
was invested to implement some project. The score grows with every
commit you make and can never shrink.

While this has nothing to say about the code quality, I think this is
a useful metric, so I decided to implement a small web service to
generate badges for everyone to include in their readme files:
[hitsofcode.com](https://hitsofcode.com).

[![Hits-of-Code](https://hitsofcode.com/github/vbrandl/hoc)](https://hitsofcode.com/view/github/vbrandl/hoc)

Currently only repositories hosted on [GitHub](https://github.com),
[Gitlab](https://gitlab.com) and [BitBucket](https://bitbucket.org)
are supported. The service is implemented in Rust using the
[actix-web](https://actix.rs) framework and deployed as a Docker
container. It is possible to self-host everything using the [Docker
image](https://hub.docker.com/r/vbrandl/hits-of-code) or by building
the [source code](https://github.com/vbrandl/hoc) yourself.

The service simply creates a bare clone of the referenced repository
and parses the output of `git log`. I also implemented a simple
caching mechanism by storing the commit ref of `HEAD` and the HoC
score. Consecutive requests will pull the repository, compare the old
`HEAD` against the new one, if the `HEAD` changed, the HoC between the
old and the new one is calculated and the old score gets added. If
`HEAD` stayed the same, the old score is returned.

I have some ideas for the future, e.g. calculating the metric using a
git library instead of invoking a git binary like in the [reference
implementation](https://github.com/yegor256/hoc/blob/master/lib/hoc/git.rb#L41)
and implement nicer overview pages. But for now the service works
fine and is already used by some repositories.  If you got any feature
requests or bugs to report, just open a [issue on
GitHub](https://github.com/vbrandl/hoc/issues) or [contact me
directly](/contact).


## Final Words

I think HoC is a cool metric and it is a fun project to work on and
improve further but always keep in mind:

> Responsible use of the metrics is just as important as collecting
> them in the first place.
>
> <cite>[Jeff Atwood](https://blog.codinghorror.com/a-visit-from-the-metrics-maid/)</cite>
