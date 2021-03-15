-----
content-type: "page"
title: "About"
-----
{@ _defs_.md || 0 @}

**min** is a concatenative, fully-homoiconic, functional, interpreted programming language. 

This basically means that:

* It is based on a somewhat obscure and slightly unintuitive programming paradigm, think of [Forth](http://www.forth.org/), [Factor](http://factorcode.org/) and [Joy](http://www.kevinalbrecht.com/code/joy-mirror/) but with parentheses for an extra [Lisp](https://common-lisp.net/)y flavor.
* Programs written in min are actually written using *quotations*, i.e. lists.
* It comes with map, filter, find, map-reduce, and loads of other functional goodies. See the {#link-module||seq#} for more.
* It is probably slower than the average production-ready programming language.

## Why?

Because creating a programming language is something that every programmer needs to do, at some point in life. And also because there are way too few [concatenative](http://concatenative.org/wiki/view/Front%20Page) programming language out there -- so people are likely to be _less_ pissed off than if I made a yet another Lisp instead.

I always wanted to build a minimalist language, but that could also be used for real work and provided a standard library for common tasks and functionalities like regular expression support, cryptography, execution of external programs, shell-like operators, and keywords to work with files, and more.

Additionally, I wanted it to be fully self-contained, cross-platform, and small. Not stupidly small, but I feel it's a good compromise compared to the alternatives out there, considering that you only need _one file_ to run any min program.

 I also created a static site generator called [HastySite](https://github.com/h3rald/hastysite), which also powers <https://min-lang.org>. HastySite internally uses min as the language to write the [rules](https://github.com/h3rald/min/blob/master/site/rules.min) to process the source files of the site, and also all its [scripts](https://github.com/h3rald/min/tree/master/site/scripts).

Finally, I think more and more people should get to know concatenative programming languages, because [concatenative programming matters](http://evincarofautumn.blogspot.it/2012/02/why-concatenative-programming-matters.html).

## How?

min is developed entirely in [Nim](https://nim-lang.org) -- the name is (almost) entirely a coincidence. I wanted to call it _minim_ but then shortened it for more... minimalism.

min's parser started off as a fork of Nim's JSON parser -- adapted to process a concatenative programming language with less primitive types than JSON. It is interpreted in the traditional sense: no bytecode, no JIT, just plain read, parse, and run. 

## Who?

min was created and implemented by [Fabio Cevasco](https://h3rald.com), with contributions by [Peter Munch-Ellingsen](https://peterme.net), [Yanis Zafirópulos](https://github.com/drkameleon), and [baykus871](https://github.com/baykus871).

Special thanks to [mwgkgk](https://github.com/mwgkgk) for contributing to the design of native dictionaries.

## When?

min source code [repository](https://github.com/h3rald/min) was created on November 8^th 2014. This only means that I've been very slowly developing something that was actually made public at the end of July 2017.
