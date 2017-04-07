+++
date = "2017-04-07T14:05:00+02:00"
publishdate = "2017-04-07T14:05:00+02:00"
title = "A Rusty Weekend"
categories = ["programming", "rust"]
draft = true
description = "My first steps with the Rust programming language"
tags = ["rust","skeleton"]

+++
## The Rust Language

Since reading about Mozilla's new programming language [Rust][0] I was eager to give it a try. Rust is a really new language and the first stable version was released in 2015.
Almost C like performance without memory corruption vulnerabilities, no race conditions and so forth thanks to a number of very interesting design concepts
and no garbage collector or any other kind of runtime overhead made that language sound really awesome.

In Rust all safety checks are done in compile time. The compiler translates into the [LLVM][1] meta language which then takes care 
of the optimization and compilation into machine code for the target architecture. Rust libraries provide a [FFI][2] 
so they can be used from almost every other language. Due to it's safety features and the lack of performance overhead, Rust also aims to be a system programming language and there are 
some really awesome projects, e.g. the [Redox operating system][3] which implements a microkernel architecture and has some really great design ideas (have a look at it!).
Also Mozilla started implementing a new, parallel browser engine called [Servo][4] which is more than 3 times faster than Gecko, the current engine used in Firefox[^servo]. 
The MP4 parser in Firefox is already implemented in Rust and there is more to come. [Here][5] is a more complete list of Rust code that runs on production systems.

Rust also has its own package manager/build management tool called [cargo][6] that makes working with libraries really easy. 
Libraries in the Rust ecosystem are hosted on [crates.io][7] and you just need to reference them in the cargo configuration and they will be downloaded and included in the build.

## New Projects

Last weekend I started my first project to get in contact with Rust, called [skeleton][8], which aims to be a language independent project management tool. When starting a new project, e.g. using 
Gradle for build management, one initializes the structure using `gradle init` but in most cases that's not the only thing to do. You might want to initialize a git repository for the project, maybe copy a license file 
and download a gitignore file. Skeleton aims to automate these steps using some simple configuration files which allow the user to execute commands, create folders, touch files, include other skeleton configurations 
or download a gitignore file from [gitignore.io][9] by a given list of languages, IDEs, ... to ignore. So `skeleton --lang=java init` might initialize a Gradle project, copy your license file, touch your 
README.md, initialize a git repository and download a gitignore file for [Java, Gradle and IntelliJ][10].

## Conclusion

The design of Rust makes you think different about your code, e.g. by default every variable in Rust is immutable. If you want a mutable variable you have to explicitly mark it as such. When passing a variable as a parameter to 
a function you can't simply reuse it after the function returns, as long as you don't explicitly borrow the variable for the time of the function call. All these features can also make you think different when writing C code 
and probably help producing better code. I really think Rust is worth looking at especially when implementing performance critical parts of a project. Also when looking for a new language to learn it is a good idea. 
Even for people coming from scripting languages who aren't familiar with the edit-compile-run cycle of compiled languages it is really easy thanks to cargo. 
Write your code, maybe add some dependencies and simply run `cargo test` for your tests or `cargo run` to execute the program. To get started I can recommend the official documentation [The Book][11] or have a look at some 
examples on [Rust by Example][12].


[^servo]: http://events.linuxfoundation.org/sites/events/files/slides/LinuxConEU2014.pdf

[0]: https://www.rust-lang.org/
[1]: https://en.wikipedia.org/wiki/LLVM
[2]: https://en.wikipedia.org/wiki/Foreign_function_interface
[3]: https://www.redox-os.org/
[4]: https://servo.org/
[5]: https://www.rust-lang.org/en-US/friends.html
[6]: https://github.com/rust-lang/cargo
[7]: https://crates.io/
[8]: https://github.com/ntzwrk/skeleton/
[9]: https://gitignore.io
[10]: https://www.gitignore.io/api/java%2Cgradle%2Cintellij
[11]: https://doc.rust-lang.org/book/
[12]: http://rustbyexample.com/
