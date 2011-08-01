#!/bin/bash
#set -x

USER=pgajdos
isc="osc -A https://api.suse.de"
osc="osc -A https://api.opensuse.org"

OSC_PROJECTS="11.3 11.4"
ISC_PROJECTS="SLE-9-SP4 SLE-10-SP3 SLE-10-SP4 SLE-11-SP1 SLE-11-SP2"
ALL_PROJECTS="$OSC_PROJECTS $ISC_PROJECTS"
PACKAGE=$1
DIST=$2
DEFAULT_DIST="devel"
WIPE=$3


function usage
{
  echo "Usage: $0 \$package [devel|all|ibs|obs|\$dist [wipe]]"
  echo ""
  echo "       \$dist: $ALL_PROJECTS sles9"
  echo "              when no second argument is supplied, $DEFAULT_DIST is used"
  echo "       wipe:  when specified, home:$USER:branches:*"
  echo "              will be erased before osc branch;"
  echo "              for devel and sles9 doesn't make sense (noop)"
  exit 1
}


if [ "$PACKAGE" == "" ]; then
  echo "Package not specified."
  usage
fi

if [ "$DIST" == "" ]; then
  DIST="$DEFAULT_DIST"
fi

if [ "$WIPE" != "" -a "$WIPE" != "wipe" ]; then
  echo "Third argument must be wipe."
  usage
fi

# package from devel project

if [ "$DIST" == "all" -o "$DIST" == "devel" ]; then
  DEVEL_PRJ=`$osc meta pkg openSUSE:Factory $PACKAGE | grep "<devel" | sed "s:.*project=\"*::" | sed "s:\".*::"`
  if [ "$DEVEL_PRJ" == "" ]; then
    echo "Devel project of package $PACKAGE couldn't be figured out."
  else
    echo ""
    echo "devel project: $DEVEL_PRJ"
    if [ ! -e devel ]; then
      mkdir devel;
    fi
    cd devel
    rm -rf $PACKAGE
    $osc co -c $DEVEL_PRJ $PACKAGE
    cd ..
    if [ "$DIST" == "devel" ]; then
      exit 0  # we are done here
    fi
  fi
fi

# packages from obs

if [ "$DIST" == "all" -o "$DIST" == "obs" ]; then
  for i in $OSC_PROJECTS; do
    echo ""
    echo "openSUSE $i"
    if [ ! -e $i ]; then
      mkdir $i;
    fi
    cd $i
    rm -rf $PACKAGE
    if [ "$WIPE" == "wipe" ]; then
      $osc rdelete "home:$USER:branches:openSUSE:$i" $PACKAGE >/dev/null 2>&1
      $osc rdelete "home:$USER:branches:openSUSE:$i:Update" $PACKAGE >/dev/null 2>&1
      $osc rdelete "home:$USER:branches:openSUSE:$i:Update:Test" $PACKAGE >/dev/null 2>&1
    fi
    COPROJECT=`$osc branch -m "maintanence update" "openSUSE:$i" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
    if [ "$COPROJECT" == "" ]; then
      echo "package not found"
      cd ..
      continue
    fi
    $osc co -c $COPROJECT
    sed -i "s:\(Release.*\).<.*>:\1:" $PACKAGE/$PACKAGE.spec
    cd ..
  done
  if [ "$DIST" == "obs" ]; then
    exit 0  # we are done here
  fi
fi 

# packages from ibs and sles9

if [ "$DIST" == "all" -o "$DIST" == "ibs" ]; then
  for i in $ISC_PROJECTS; do
    DIR=`echo $i | sed "s:SLE-\|-::g" | tr [A-Z] [a-z]`
    echo ""
    echo "SUSE $DIR"
    if [ ! -e $DIR ]; then
      mkdir $DIR;
    fi
    cd $DIR
    rm -rf $PACKAGE
    if [ "$WIPE" == "wipe" ]; then
      $isc rdelete "home:$USER:branches:SUSE:$i:GA" $PACKAGE >/dev/null 2>&1
      $isc rdelete "home:$USER:branches:SUSE:$i:Update" $PACKAGE >/dev/null 2>&1
      $isc rdelete "home:$USER:branches:SUSE:$i:Update:Test" $PACKAGE >/dev/null 2>&1
    fi
    COPROJECT=`$isc branch -m "maintanence update" "SUSE:$i:GA" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
    if [ "$COPROJECT" == "" ]; then
      echo "package not found"
      cd ..
      continue
    fi
    $isc co -c $COPROJECT
    sed -i "s:\(Release.*\).<.*>:\1:" $PACKAGE/$PACKAGE.spec
    cd ..
  done

  if [ "$DIST" == "ibs" ]; then
    exit 0  # we are done here
  fi
fi

if [ $DIST == "all" ]; then
  exit 0  # we are done here
fi

# particular distribution check out

BS=""
if [ "`echo $OSC_PROJECTS | grep $DIST`" != "" ]; then
  BS="obs"
elif [ "`echo $ISC_PROJECTS | grep $DIST`" != "" ]; then
  BS="ibs"
else
  echo "$DIST distribution wasn't found."
  usage
fi
DIR=`echo $DIST | sed "s:SLE-\|-::g" | tr [A-Z] [a-z]`
if [ ! -e $DIR ]; then
  mkdir $DIR;
fi
cd $DIR
rm -rf $PACKAGE
if [ "$BS" == ibs ]; then
  if [ "$WIPE" == "wipe" ]; then
    $isc rdelete "home:$USER:branches:SUSE:$DIST:GA" $PACKAGE >/dev/null 2>&1
    $isc rdelete "home:$USER:branches:SUSE:$DIST:Update" $PACKAGE >/dev/null 2>&1
    $isc rdelete "home:$USER:branches:SUSE:$DIST:Update:Test" $PACKAGE >/dev/null 2>&1
  fi
  COPROJECT=`$isc branch -m "maintanence update" "SUSE:$DIST:GA" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
  if [ "$COPROJECT" == "" ]; then
    echo "package not found"
    exit 1
  fi
  $isc co -c $COPROJECT 
else
  if [ "$WIPE" == "wipe" ]; then
    $osc rdelete "home:$USER:branches:openSUSE:$DIST" $PACKAGE >/dev/null 2>&1
    $osc rdelete "home:$USER:branches:openSUSE:$DIST:Update" $PACKAGE >/dev/null 2>&1
    $osc rdelete "home:$USER:branches:openSUSE:$DIST:Update:Test" $PACKAGE >/dev/null 2>&1
  fi
  COPROJECT=`$osc branch -m "maintanence update" "openSUSE:$DIST" $PACKAGE 2>&1 | grep "home:$USER:branches" | sed "s/.*\(home.*\)/\1/"`
  if [ "$COPROJECT" == "" ]; then
    echo "package not found"
    exit 1
  fi
  $osc co -c $COPROJECT
fi
sed -i "s:\(Release.*\).<.*>:\1:" $PACKAGE/$PACKAGE.spec
cd ..


