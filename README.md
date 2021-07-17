# mydev

This repository holds the scripts I use to do local MySQL and MySQL cluster
development. It is tailored fairly tightly to my own workflows, but should be
adaptable for others to use as well. There are some fairly hacky implementations
and rough edges, but the code mostly works (for the use cases I've tested). Use
it at your own peril and contribute at your own leisure.

**n.b.** if you are bold enough to use this project, note that it is intended
for development usage only and should never be used in a production
environment!


# Installation

Installation is fairly straightforward:

```
$ git clone https://github.com/burnison/mydev $HOME/.mydev
$ echo '. $HOME/.mydev/mydev.sh' >> ~/.zshrc
$ echo '. $HOME/.mydev/mydev.sh' >> ~/.bashrc
```

After this, re-source your shell or start a new one.


# Example usage

1. To start, you'll need to add a "source" repository. Choose either Percona
   Server or MySQL Server:
   ```
   $ mydev sources-add percona
   ```
   This will check-out the Percona Server source tree into the `sources` directory.
   The clone will take a long time.

1. Next, you will need to create a new build:
   ```
   $ mydev builds-list-all
     ...
     percona-server-5.6  (origin/5.6)
     percona-server-5.7  (origin/5.7)
     ...

   $ mydev builds-add percona-server 5.7

   $ mydev builds-recompile percona-server-5.7
   ```
   This will create a Git worktree of the Percona Server 5.7 release in the
   `builds` directory and compile it.

1. With a build added and compiled, you can create instances with `instance-create`:
   ```
   $ mydev instance-create --no-shutdown percona-server-5.7 5701
   $ mydev instance-create --replica-of 5701 --logical --no-shutdown percona-server-5.7 5702
   $ mydev instance-create --replica-of 5701 --logical percona-server-5.7 5703
   $ mydev instance-create --replica-of 5702 --logical percona-server-5.7 5704
   ```
   If you have `xtrabackup` on your `PATH`, you may skip the `--logical` flag when
   creating replicas.

1. You can view the state of the existing cluster with `instance-status`:
   ```
   $ mydev instance-status
   5701    running
   5702    running
   5703    stopped
   5704    stopped
   ```

1. Next, you can start-up instances with `instance-start`, optionally using `lldb`.
   ```
   $ mydev instance-start 5703 &
   $ echo $!
   279637

   $ mydev instance-start --debug 5704
   (lldb) target create "mysqld"
   Current executable set to 'mysqld' (x86_64).
   (lldb) settings set -- target.run-args  "--defaults-file=$HOME/.mydev/instances/5704/my.cnf" "--debug=o,/dev/stdout"
   (lldb)
   ```
   Note that all instances start with the `--gdb` flag.

1. Finally, you can run queries against the nodes with `instance-connect`:
   ```
   $ mydev instance-connect 5703 -e 'select @@port'
   +--------+
   | @@port |
   +--------+
   |  35703 |
   +--------+

   $ mydev instance-connect 5703
   mysql>
   ```

1. When you're all done, you can stop an instance with `instance-stop`:
   ```
   $ mydev instance-stop 5704
   ```

# Other commands

There are a number of other useful commands, and you can find them using
`--help`. For example,

```
$ mydev --help
usage: mydev command [args]

commands:
    builds-add            add a new build
    builds-list           show installed builds
    builds-list-all       show all possible builds
    builds-recompile      recompile a build
    builds-switch         change shim paths to that of a build

    instance-connect      connect to a specific instance
    instance-create       create a new instance
    instance-list         list all installed instances
    instance-logs         shows the logs of an instance using $PAGER
    instance-start        start an instance
    instance-status       shows the status of an instance
    instance-stop         stop an instance
    instance-switch       changes shim paths to that of an instance

    sources-add           add a new source
    sources-list          list all installed sources
```

and


```
$ mydev instance-create --help
usage: mydev instance-create [-r source-instance-id [--logical]] [--no-shutdown] build instance-id

options
    -r|--replica-of INSTANCE  creates a new replica from this host using a physical restore
    --logical                 used with -r to crate an instance from a logical restore
    --no-shutdown             prevent the new instance from shutting down

    build                     the MySQL build to use
    instance                  the unique instance number

example: mydev instance-create --replica-of 5701 --logical percona-server-5.7 5702
```



# Attributions

The design of this project is influenced by [asdf-vm](https://github.com/asdf-vm/asdf).
I have no affiliation with asdf-vm, but I think it's a pretty great tool.
