# Scripts for building / testing packages built via Build Service

These scripts reduce to a one-line command the process of building
rpms (e.g. from git) and then distributing them to a host (typically a
VM) which is being used for testing.

For example,

    build-dist-rpms -l -r external-smt -t 192.168.124.10 -p pacific \
        ~/SUSE/IBS/branches/Devel/Cloud/2.0/Staging/crowbar

does the following:

1.  Invokes `build-rpms` to build an rpm:

    1.  Invokes a helper to find the location of the git working tree
        on the local system which contains source corresponding to
        the package in the given directory.  This helper is a trivial
        shell script which every developer can tweak to match their
        own `$HOME` layout.

    2.  Rewrites the `url` parameter in the `_service` file to point
        to that local git repository (that's the `-l` option).

    3.  Rewrites the `revision` parameter in the `_service` file to
        be `external-smt`.

    4.  Runs `osc service disabledrun`.

    5.  Restores the `_service` file to how it was before the above
        tweaks.

    6.  Runs `osc build` with suitable parameters.

2.  Invokes `dist-rpms` script to install that rpm on `192.168.124.10`
    via `rsync`, `ssh`, and `zypper`.

    In the example above, the `-p pacific` option even allows
    installation of an rpm via a proxy host, which is really useful
    when the host you are hacking on (e.g. your laptop) is different
    to the one (e.g. workstation) on which you are running your test
    VMs.

# Installation

First download and install to somewhere on `$PATH`, e.g.

    git clone https://github.com/openSUSE/pack-tools.git
    cp pack-tools/contrib/BS-pkg-testing/* ~/bin
    mv ~/bin/source-dir-for.sample ~/bin/source-dir-for

Now adjust the config script to where you've checked out your OBS / IBS
packages and the corresponding `git` repositories:

    vim ~/bin/source-dir-for

Try building a package from local source and installing it into
your test VM with a single command! e.g.

    build-dist-rpms -d -t 192.168.124.10 ~/Devel/Cloud/2.0/Staging/crowbar

If you want to use a particular git branch, use the `-r` option:

    build-dist-rpms -r mybranch -t 192.168.124.10 ~/Devel/Cloud/2.0/Staging/crowbar

# References

These scripts were originally announced here:

* http://mailman.suse.de/mlarch/SuSE/cloud-devel/2013/cloud-devel.2013.08/msg00029.html
* http://mailman.suse.de/mlarch/SuSE/cloud-devel/2013/cloud-devel.2013.08/msg00331.html

