CONTRIBUTING

<!-- vim-markdown-toc GFM -->

* [Forking PPI](#forking-ppi)
* [Sending Pull Requests](#sending-pull-requests)

<!-- vim-markdown-toc -->

# Forking PPI

`script/perlimports` is a fatpacked script, which includes a fork of `PPI`. You should probably have the fork available if your're going to be editing or testing this particular script.

```
git submodule init
git submodule update
```

Now, if you'd like to update the fatpacked `perlimports`, just run the following script:

```
./author/fatpack.sh
```

The entire purpose of the fatpacking is for the one bit of forked code, rather
than making a portable binary, so I don't have plans currently to pack any
other modules into `script/perlimports`.

# Sending Pull Requests

The internals are still in a state of flux, so if you're proposing an invasive
change, please get in touch with me first by opening a GitHub issue. That way
we can co-ordinate and make sure valuable time isn't wasted on code which later
can't be merged without a lot of work.
