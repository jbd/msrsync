# msrsync: maximize your rsync bandwidth usage

`msrsync` (multi-stream rsync) is a python wrapper around `rsync`.

It will split the transfer in multiple buckets while the source is scanned and will hopefully help maximizing the usage of the available bandwidth by running a configurable number of `rsync` processes in parallel. The main limitation is it does not handle remote source or target directory, they must be locally accessible (local disk, nfs/cifs/other mountpoint).

Quick example:

```bash
$ msrsync -p 4 /source /destination
```

This will copy /source directory in the /destination directory (same behaviour as `rsync` regarding the slash handling) using 4 `rsync` processes (using `"-a --numeric-ids"` as default option. Could be override with `--rsync` option). `msrsync` will split the files and directory list into bucket of 1G or 1000 files maximum (see `--size` and `--files` options) before feeding them to each `rsync` process in parallel using the `--files-from` option. As long as the source and the destination can cope with the parallel I/O (think big boring "enterprise grade" NAS), it should be faster than a single `rsync`.

> `msrsync` shares the same spirit as [fpart](https://github.com/martymac/fpart) (and its [fpsync](https://github.com/martymac/fpart/blob/master/tools/fpsync) associated tool) by Ganaël Laplanche or [parsync](http://moo.nac.uci.edu/~hjm/parsync/) by Harry Mangalam. Those are two fantastic much more complete tools used in the field to do real work. Please check them out, they might be what you're looking for.

## Motivation

Why write `msrsync` if tools like [fpart](https://github.com/martymac/fpart) and [parsync](http://moo.nac.uci.edu/~hjm/parsync/) exist ? While reasonnable, their dependencies can be a point of friction given the constraints we can have on a given system. When you're lucky, you can use your package manager ([fpart](https://github.com/martymac/fpart) seems to be well supported among various GNU/Linux and FreeBSD distribution: [FreeBSD](http://www.freshports.org/sysutils/fpart), [Debian](http://packages.debian.org/fpart), [Ubuntu](http://packages.ubuntu.com/fpart), [Archlinux](https://aur.archlinux.org/packages/fpart/), [OBS](https://build.opensuse.org/package/show/home:mgoppold/fpart)) to deal with the requirements but more often than not, I found myself struggling with the sad state of the machine I'm working with.

That's why the only dependencies of msrsync are [python](https://www.python.org/) >=2.6 and [rsync](https://rsync.samba.org/). What python 2.6 ? I'm aiming RHEL6 like distribution as a minimum requirement here, so I'm stuck with python 2.6. I miss some cool features, but that's part of the project.

## Requirements

[python](python) >= 2.6 and [rsync](https://rsync.samba.org/)

## Installation

`msrsync` is a single python file, you just have to download it. Or if you prefer, you can clone the repository and use the provided Makefile:

```bash
$ wget https://raw.githubusercontent.com/jbd/msrsync/master/msrsync && chmod +x msrsync
```
or
```bash
$ git clone https://github.com/jbd/msrsync && cd msrsync && sudo make install
```

## Usage

```
$ msrsync --help
usage: msrsync [options] [--rsync "rsync-options-string"] SRCDIR [SRCDIR2...] DESTDIR
   or: msrsync --selftest

msrsync options:
    -p, --processes ...   number of rsync processes to use [1]
    -f, --files ...       limit buckets to <files> files number [1000]
    -s, --size ...        limit partitions to BYTES size (1024 suffixes: K, M, G, T, P, E, Z, Y) [1G]
    -b, --buckets ...     where to put the buckets files (default: auto temporary directory)
    -k, --keep            do not remove buckets directory at the end
    -j, --show            show bucket directory

rsync options:
    -r, --rsync ...       MUST be last option. rsync options as a quoted string ["-a --numeric-ids"]. The "--from0" option will ALWAYS be added, no matter what. Be aware that this will affect all rsync `from/filter files if you want to use them. See rsync(1) manpage for
                            details.

self-test options:
    -t, --selftest        run the integrated unit and functional tests
    -e, --bench           run benchmarks
    -g, --benchshm        run benchmarks in /dev/shm
```

If you want to use specific options for the rsync processes, use the `--rsync` option:

```bash
$ msrsync -p4 --rsync "-a --numeric-ids --inplace" source destination
```

## Performance

You can launch a benchmark using the `--bench` option or `make test`. It is only for testing purpose. They are comparing the performance between vanilla `rsync` and `msrsync` using multiple options. Since I'm just creating a huge fake file tree with empty files, you won't see any `msrsync` benefits here, unless you're trying with many many files. They need to be run as root since I'm dropping disk cache between run.

```
$ sudo make bench # or sudo msrsync --bench
Benchmarks with 100000 entries (95% of files):
rsync -a --numeric-ids took 14.05 seconds (speedup x1)
msrsync --processes 1 --files 1000 --size 1G took 18.58 seconds (speedup x0.76)
msrsync --processes 2 --files 1000 --size 1G took 10.61 seconds (speedup x1.32)
msrsync --processes 4 --files 1000 --size 1G took 6.60 seconds (speedup x2.13)
msrsync --processes 8 --files 1000 --size 1G took 6.58 seconds (speedup x2.14)
msrsync --processes 16 --files 1000 --size 1G took 6.66 seconds (speedup x2.11)
```

Please test on real data instead =). There is also a `--benchshm` option that will perform the benchmark in `/dev/shm`.

## Notes

- The `rsync` processes are always run with the `--files-from` and `--from0`, no matter what. `--from0` option affects `--exclude-from`, `--include-from`, `--files-from`, and any merged files specified in a `--filter` rule.

- This may seem obvious but if the source or the destination of the copy cannot handle parallel I/O well, you won't see any benefits (quite the opposite in fact) using `msrsync`. 

## Development

I'm targeting python 2.6 without external dependencies besides rsync. The provided Makefile is just an helper around the embedded testing and coverage.py:

```
$ make help
Please use `make <target>' where <target> is one of
  clean         => clean all generated files
  cov           => coverage report using /usr/bin/python-coverage (use COVERAGE env to change that)
  covhtml       => coverage html report
  man           => build manpage
  test          => run embedded tests
  install       => install msrsync in /usr/bin (use DESTDIR env to change that)
  lint          => run pylint
  bench         => run benchmarks (linux only. Need root to drop buffer cache between run)
  benchshm      => run benchmarks using /dev/shm (linux only. Need root to drop buffer cache between run)

```
There is an integrated test suite (`--selftest` option, or `make test`). Since I'm using unittest from python 2.6 library, I cannot capture the output of the tests (buffer parameter from TestResult object appeared in 2.7).

```
$ make test # or msrsync --selftest
test_get_human_size (__main__.TestHelpers)
convert bytes to human readable string ... ok
test_get_human_size2 (__main__.TestHelpers)
convert bytes to human readable string ... ok
test_human_size (__main__.TestHelpers)
convert human readable size to bytes ... ok
...
test simple msrsync synchronisation ... ok
test_msrsync_cli_2_processes (__main__.TestSyncCLI)
test simple msrsync synchronisation ... ok
test_msrsync_cli_4_processes (__main__.TestSyncCLI)
test simple msrsync synchronisation ... ok
test_msrsync_cli_8_processes (__main__.TestSyncCLI)
test simple msrsync synchronisation ... ok
test_simple_msrsync_cli (__main__.TestSyncCLI)
test simple msrsync synchronisation ... ok
test_simple_rsync (__main__.TestSyncCLI)
test simple rsync synchronisation ... ok

----------------------------------------------------------------------
Ran 29 tests in 3.320s

OK
```
