# Quark Reference

Reference generated with [jazzy](https://github.com/realm/jazzy). Hosted by [GitHub Pages](https://pages.github.com). Inspired by Jesse Squire's [awesome post](http://www.jessesquires.com/swift-documentation/) about documentation.

## Setup

The `gh-pages` branch includes the `master` branch as a [git submodule](http://git-scm.com/book/en/v2/Git-Tools-Submodules) in order to generate docs.

````bash
git clone https://github.com/QuarkX/Quark.git Reference
cd Reference
git checkout gh-pages
git submodule update --init
````

## Generate

````bash
./generate.sh
````

## Preview

````bash
open index.html -a Safari
````

## Publish

````bash
./publish.sh
````

## View

http://reference.quark.zewo.io
