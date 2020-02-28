# rubyfarm-bisect

This tool allows you to do "git bisect" MRI revisions easily.
Instead of compiling each revision locally, it uses ["rubylang/rubyfarm" repository](https://hub.docker.com/r/rubylang/rubyfarm/tags/) in DockerHub, which contains all MRI revisions since r57410 that were successfully built.

By using rubyfarm-bisect, you don't have to worry about:

* Compilation failure ("exit 125").  rubyfarm-bisect handles it.
* The range of bisect.  rubyfarm-bisect has a good default.
* The order of good and bad commits.  rubyfarm-bisect automatically detects the order.

## How to setup

You need to install rubyfarm-bisect.

```
$ gem install rubyfarm-bisect
```

You also need to be able to use "docker" command without "sudo".

```
$ docker run --rm -t rubylang/rubyfarm:r60001 ruby -v
Unable to find image 'rubylang/rubyfarm:r60001' locally
r60001: Pulling from rubylang/rubyfarm

  *snip*

Status: Downloaded newer image for rubylang/rubyfarm:r60001
ruby 2.5.0dev (2017-09-23 trunk 60001) [x86_64-linux]
```

## How to use

The simplest way:

```
$ rubyfarm-bisect ruby -e '<your test code>'
```

which assumes that `<your test code>` runs successfully at r57410, and fails at "trunk".

### `-g`/`-b`: specify a good/bad commit range

You can specify good and bad commits for git bisect:

```
$ rubyfarm-bisect -g 7c1b30a6 -b trunk ruby -e '<your test code>'
```

`-g` is a good commit, and `-b` is a bad commit.
The arguments must be a SVN revision (e.g., "r60000"), or a commit hash of [git.ruby-lang.org/ruby.git](https://git.ruby-lang.org/ruby.git) (e.g., 7c1b30a6).

You don't have to worry about which is good and bad:

* rubyfarm-bisect first checks if the good commit is an ancestor of the bad one.  If not, it swaps the good and bad ones.
* rubyfarm-bisect then checks if the test passes at the good (older) commit.  If it does not pass the test, it works as a "reversed" mode; it tries to find the first "good" commit.

### `-u`: specify a git url

This tool clones [the git repository of ruby](https://git.ruby-lang.org/ruby.git) into temporary directory, which takes some minutes.
To make it fast, you can use your local repository:

```
$ git clone https://git.ruby-lang.org/ruby /path/to/local/git/repo
$ rubyfarm-bisect -u /path/to/local/git/repo ruby -e '<your test code>'
```

### `-t`: use `test.rb`

If you want to pass a test script instead of a command-line argument, use:

```
$ vim test.rb # create and save your test.rb
$ rubyfarm-bisect -t
```

which mounts `test.rb` in the current directory to `/root/test.rb` in the docker container.

### `-m`: specify a path to be mounted to `/root`

If you want to pass not only a test script but also some data files, you can specify a directory to be mounted to `/root`:

```
$ rubyfarm-bisect -m /path/to/dir ruby /root/test.rb
```

Your `/path/to/dir` must contains `test.rb`.  Note that the directory is mounted in read-only mode.

## Example

Consider that you encounter a bug of trunk:

```
$ ruby -rripper -e 'Ripper.slice("foo", "ident")'
Traceback (most recent call last):
	8: from -e:1:in `<main>'
	7: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:156:in `slice'
	6: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:163:in `token_match'
	5: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:163:in `new'
	4: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:181:in `initialize'
	3: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:202:in `compile'
	2: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:202:in `scan'
	1: from /opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:205:in `block in compile'
/opt/ruby/lib/ruby/2.5.0/ripper/lexer.rb:205:in `concat': can't modify frozen String (RuntimeError)

```

You can find the regression by using rubyfarm-bisect:

```
$ rubyfarm-bisect ruby -rripper -e 'Ripper.slice("foo", "ident")'

  *snip*

e3300dce829955390b5099c013ab4452a74ffd20 is the first bad commit
commit e3300dce829955390b5099c013ab4452a74ffd20
Author: kazu <kazu@b2dd03c8-39d4-4d8f-98ff-823fe69b080e>
Date:   Sun Feb 5 07:54:32 2017 +0000

    {ext,test}/ripper: Specify frozen_string_literal: true.
    
    git-svn-id: svn+ssh://ci.ruby-lang.org/ruby/trunk@57538 b2dd03c8-39d4-4d8f-98ff-823fe69b080e

:040000 040000 7092727b90c406b5672852457099250bc0a8f62e 5ad04f3dce97452d18b6c72850ac69f6b34014bc M	ext
:040000 040000 83300d1a837029ed91f9675b2de984dcce2fe735 e679db1ae68baac0825f0fde89e3dd743781dd26 M	test
bisect run success
```

```
$ rubyfarm-bisect -g r57410 -b r60000 -u /path/to/ruby.git/ ruby -rripper -e 'Ripper.slice("foo", "ident")'
```

```
$ cat test.rb
require "ripper"
Ripper.slice("foo", "ident")

$ rubyfarm-bisect -t
```
