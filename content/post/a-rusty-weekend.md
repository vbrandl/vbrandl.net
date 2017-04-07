+++
date = "2017-04-07T12:19:43+02:00"
publishdate = "2017-04-07T12:19:43+02:00"
title = "A Rusty Weekend"
categories = ["programming", "rust"]
draft = true
description = "My first steps with the Rust programming language"
tags = ["rust","skeleton"]

+++
## The Rust Language

Since reading about Mozilla's new programming language [Rust](https://www.rust-lang.org/) I was eager to give it a try. Rust is a really new language and the first stable version was released in 2015.
Almost C like performance without memory corruption vulnerabilities, no race conditions and so forth thanks to a number of very interesting design concepts
and no garbage collector or any other kind of runtime overhead made that language sound really awesome.

In Rust all safety checks are done in compile time. The compiler translates into the [LLVM](https://en.wikipedia.org/wiki/LLVM) meta language which then takes care 
of the optimization and compilation into machine code for the target architecture. Rust libraries provide a [FFI](https://en.wikipedia.org/wiki/Foreign_function_interface) 
so they can be used from almost every other language. Due to it's safety features and the lack of performance overhead, Rust also aims to be a system programming language and there are 
some really awesome projects, e.g. the [Redox operating system](https://www.redox-os.org/) which implements a microkernel architecture and has some really great design ideas (have a look at it!).
Also Mozilla started implementing a new, parallel browser engine called [Servo](https://servo.org/) which is more than 3 times faster than Gecko, the current engine used in Firefox[^servo]. 
The MP4 parser in Firefox is already implemented in Rust an there is more to come. [Here](https://www.rust-lang.org/en-US/friends.html) is a more complete list of Rust code that runs on production systems.

Rust also has a own package manager/build management tool called [cargo](https://github.com/rust-lang/cargo) that makes working with libraries really easy. 
Libraries in the Rust ecosystem are hosted on [crates.io](https://crates.io/) and you just need to reference them in the cargo configuration and they will be downloaded and included in the build.

## New Projects

Last weekend i started my first project to get in contact with Rust, called [skeleton](https://github.com/ntzwrk/skeleton/), which aims to be a language independent project management tool. When starting a new project, e.g. using 
Gradle for build management, one initializes the structure using `gradle init` but in most cases that's not the only thing to do. You might want to initialize a git repository for the project, maybe copy a license file 
and download a gitignore file. Skeleton aims to automate these steps using some simple configuration files which allow the user to execute commands, create folders, touch files, include other skeleton configurations 
or download a gitignore file from [gitignore.io](https://gitignore.io) by a given list of languages, IDEs, ... to ignore. So `skeleton --lang=java init` might initialize a Gradle project, copy your license file, touch your 
README.md, initialize a git repository and download a gitignore file for [Java, Gradle and IntelliJ](https://www.gitignore.io/api/java%2Cgradle%2Cintellij).

## Conclusion

The design of Rust makes you think different about your code, e.g. by default every variable in Rust is immutable. If you want a mutable variable you have to explicitly mark it as such. When passing a variable as a parameter to 
a function you can't simply reuse after the function returns as long as you don't explicitly borrow the variable for the time of the function call. All these features can also make you think different when writing C code 
and probably producing better code. I really think Rust is worth looking at when implementing performance critical parts of a project. Also when looking for a new language to learn it is a good idea. 
Even for people coming from scripting languages who aren't familiar with the edit-compile-run cycle of compiled languages it is really easy thanks to cargo. 
Write your code, maybe add some dependencies and simply run `cargo test` for your tests or `cargo run` to execute the program.


[^servo]: http://events.linuxfoundation.org/sites/events/files/slides/LinuxConEU2014.pdf
