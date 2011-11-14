#!/bin/bash
#set -x

USER=pgajdos
isc="osc -A https://api.suse.de"
osc="osc -A https://api.opensuse.org"
DEVEL_DIST="devel"
OSC_PROJECTS="$DEVEL_DIST 11.3 11.4 12.1"
ISC_PROJECTS="SLE-9-SP4 SLE-10-SP3 SLE-10-SP4 SLE-11-SP1 SLE-11-SP2"

ALL_PROJECTS="$OSC_PROJECTS $ISC_PROJECTS"
OSC_DISTDIRS=$OSC_PROJECTS
ISC_DISTDIRS=`echo $ISC_PROJECTS | sed "s:SLE-\|-::g" | tr [A-Z] [a-z]`
ALL_DISTDIRS="$DEVEL_DIST $OSC_DISTDIRS $ISC_DISTDIRS"
ALL_DIST_ARGUMENTS="all obs ibs $ALL_DISTDIRS"

function usage
{
  echo "Usage: $0 \$package [all|ibs|obs|\$dist] [wipe]"
  echo ""
  echo "       \$dist: $ALL_DISTDIRS"
  echo "              package is saved into \$dist/\$package;"
  echo "              when no second argument is supplied: "
  echo "              - when you are in some of dist subdirectory"
  echo "                ($ALL_DISTDIRS) "
  echo "                name of this subdirectory is used for \$dist"
  echo "                and package is saved into ./\$package;"
  echo "              - otherwise $DEVEL_DIST is used for \$dist"
  echo "                and therefore package is saved into $DEVEL_DIST/\$package"
  echo "       wipe:  when specified, home:$USER:branches:*"
  echo "              will be erased before osc branch;"
  echo "              for $DEVEL_DIST doesn't make sense (noop)"
  exit 1
}

# handle arguments
if [ $# -lt 1 -o $# -gt 3 ]; then
  echo "ERROR: Wrong number of arguments ($#)."
  usage
fi

PACKAGE=$1
DIST=""
WIPE=0
shift
while (( "$#" )); do
  if [ "`echo $ALL_DIST_ARGUMENTS | grep -i $1`" ]; then
    DIST=`echo $1 | tr [A-Z] [a-z]`
  elif [ "$1" == wipe ]; then
    WIPE=1
  else
    echo "ERROR: Wrong argument ($1)."
    usage
  fi
  shift
done

# DIST
IN_DISTDIR="no"

if [ "$DIST" == "" ]; then
  CURDIR=`echo $PWD | sed "s:^.*/::"`
  if [ "`echo $ALL_DISTDIRS | grep $CURDIR`" != "" ]; then
    DIST="$CURDIR"
    IN_DISTDIR="yes"
  else
    DIST="$DEVEL_DIST"  # default DIST
  fi
fi

# 11sp1 --> SLE-11-SP1, etc.
if [ "`echo $ISC_DISTDIRS | grep $DIST`" != "" ]; then
  DIST=`echo $DIST | tr [a-z] [A-Z] | sed "s:\(^[0-9]\+\):SLE-\1-:" | sed "s:-$::"`
fi

DIST=`echo $DIST | sed "s:all:$ALL_PROJECTS:" | sed "s:ibs:$ISC_PROJECTS:" | sed "s:obs:$OSC_PROJECTS:"`

echo "Package:          [$PACKAGE]"
echo "Distribution(s):  [$DIST]"
echo "Wipe:             [$WIPE]"

function wipe()
{
  CMD=$1
  PRJ=$2

  if [ $WIPE -eq 1 ]; then
    echo "Wiping $PRJ[[:Update]:Test]/$PACKAGE"
    $CMD rdelete -m "delete" "$PRJ" $PACKAGE >/dev/null 2>&1
    $CMD rdelete -m "delete" "$PRJ:Update" $PACKAGE >/dev/null 2>&1
    $CMD rdelete -m "delete" "$PRJ:Update:Test" $PACKAGE >/dev/null 2>&1
  fi
}

function get_package()
{
  DIST=$1
  TYPE=$2

  if [ -e $PACKAGE ]; then
    echo "Removing $DIST/$PACKAGE directory"
    rm -rf $PACKAGE
  fi 

  case $TYPE in  

    "devel")
      COPROJECT=`$osc meta pkg openSUSE:Factory $PACKAGE | grep "<devel" | sed "s:.*project=\"*::" | sed "s:\".*::"`
      echo
      echo "devel project ($COPROJECT)"
      if [ "$COPROJECT" == "" ]; then
        echo "ERROR: Devel project of package $PACKAGE couldn't be figured out, package not downloaded."
        echo "       Check if $PACKAGE lies in openSUSE:Factory."
      fi
      $osc co -c $COPROJECT $PACKAGE
      ;;

    "obs")
      wipe "$osc" "home:$USER:branches:openSUSE:$DIST"
      COPROJECT=`$osc branch -m "maintanence update" "openSUSE:$DIST" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
      echo
      echo "openSUSE:$DIST ($COPROJECT)"
      if [ "$COPROJECT" == "" ]; then
        echo "ERROR: package not found"
        return
      fi
      $osc co -c $COPROJECT
      ;;

    "ibs")
      wipe "$isc" "home:$USER:branches:SUSE:$DIST"
      COPROJECT=`$isc branch -m "maintanence update" "SUSE:$DIST:GA" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
      echo
      echo "SUSE:$DIST ($COPROJECT)"
      if [ "$COPROJECT" == "" ]; then
        echo "ERROR: package not found"
        return
      fi
      $isc co -c $COPROJECT
      ;;
  esac
  sed -i "s:\(Release.*\).<.*>:\1:" $PACKAGE/$PACKAGE.spec
}


for d in $DIST; do
  if [ "$d" == "$DEVEL_DIST" ]; then
    TYPE="devel"
  elif [ "`echo $OSC_PROJECTS | grep $d`" ]; then
    TYPE="obs"
  elif [ "`echo $ISC_PROJECTS | grep $d`" ]; then
    TYPE="ibs"
  fi

  echo
  if [ "$IN_DISTDIR" == "no" ]; then
    DISTDIR=`echo $d | sed "s:SLE-\|-::g" | tr [A-Z] [a-z]`
    if [ ! -e $DISTDIR ]; then
      echo "Creating $DISTDIR directory"
      mkdir $DISTDIR;
    fi
    cd $DISTDIR
  fi

  get_package $d $TYPE

  if [ "$IN_DISTDIR" == "no" ]; then
    cd ..
  fi
done

