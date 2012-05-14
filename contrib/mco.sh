#!/bin/bash
#set -x

USER=pgajdos
isc="osc -A https://api.suse.de"
osc="osc -A https://api.opensuse.org"

BRANCH_PROJECT="home:pgajdos:maintenance"

DEVEL_DIST="devel"
OSC_PROJECTS="$DEVEL_DIST 11.4 12.1"
ISC_PROJECTS="SLE-9-SP3 SLE-10-SP3 SLE-11 SLE-11-SP2"
OBS_BRANCHED=0
IBS_BRANCHED=0

ALL_PROJECTS="$OSC_PROJECTS $ISC_PROJECTS"
OSC_DISTDIRS=$OSC_PROJECTS
ISC_DISTDIRS=`echo $ISC_PROJECTS | sed "s:SLE-\|-::g" | tr [A-Z] [a-z]`
ALL_DISTDIRS="$DEVEL_DIST $OSC_DISTDIRS $ISC_DISTDIRS"
ALL_DIST_ARGUMENTS="all obs ibs $ALL_DISTDIRS"

function usage
{
  echo "Usage: $0 \$package [all|ibs|obs|\$dist]"
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
  exit 1
}

# handle arguments
if [ $# -lt 1 -o $# -gt 3 ]; then
  echo "ERROR: Wrong number of arguments ($#)."
  usage
fi

PACKAGE=$1
DIST=""
shift
while (( "$#" )); do
  if [ "`echo $ALL_DIST_ARGUMENTS | grep -i $1`" ]; then
    DIST=`echo $1 | tr [A-Z] [a-z]`
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

# results
echo
echo "Package:          [$PACKAGE]"
echo "Distribution(s):  [$DIST]"

# download package and save in current dir
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
      COPROJECT="$BRANCH_PROJECT:$PACKAGE"
      COPACKAGE=`$osc ls  "$COPROJECT" | grep "_${DIST}_"`
      echo
      echo "openSUSE:$DIST ($COPROJECT/$COPACKAGE)"
      if [ "$COPACKAGE" == "" ]; then
        echo "ERROR: package not found"
        return
      fi
      $osc co -c $COPROJECT $COPACKAGE
      mv $COPACKAGE $PACKAGE
      ;;

    "ibs")
      COPROJECT="$BRANCH_PROJECT:$PACKAGE"
      COPACKAGE=`$isc ls  "$COPROJECT" | grep "_${DIST}_"` # _xx_ needed: SLE-11, SLE-11-SP2
      echo
      echo "SUSE:$DIST ($COPROJECT/$COPACKAGE)"
      if [ "$COPACKAGE" == "" ]; then
        echo "ERROR: package not found"
        return
      fi
      $isc co -c $COPROJECT $COPACKAGE
      mv $COPACKAGE $PACKAGE
      ;;
  esac
  sed -i "s:\(Release.*\).<.*>:\1:" $PACKAGE/$PACKAGE.spec
}

function mbranch()
{
  TYPE=$1
  rm -rf .osc
  PRJ="$BRANCH_PROJECT:$PACKAGE"
  if [ $TYPE == 'obs' ]; then
    if [ $OBS_BRANCHED -eq 0 ]; then
      $osc ls $PRJ > /dev/null
      prjnotexist=$?
      yesno='no'
      if [ $prjnotexist -eq 0 ]; then
        echo "OBS project $PRJ exists yet."
        echo -n "Delete it and branch again? (no will reuse existing project) [yes/NO]: "
        read yesno
        if [ "x$yesno" == "xyes" ]; then
          echo "Deleting OBS project $PRJ."
          $osc rdelete -m 'delete' --recursive "$PRJ" > /dev/null 2>&1
        fi
      fi
      if [ $prjnotexist -eq 1 -o "x$yesno" == "xyes" ]; then
        echo "Branching OBS packages ($PRJ)."
        $osc mbranch $PACKAGE "$PRJ"
      fi
      OBS_BRANCHED=1
      echo
    fi
  elif [ $TYPE == 'ibs' ]; then
    if [ $IBS_BRANCHED -eq 0 ]; then
      $isc ls $PRJ > /dev/null 2>&1
      prjnotexist=$?
      yesno='no'
      if [ $prjnotexist -eq 0 ]; then
        echo "IBS project $PRJ exists yet."
        echo -n "Delete it and branch again? (no will reuse existing project) [yes/NO]: "
        read yesno
        if [ "x$yesno" == "xyes" ]; then
          echo "Deleting IBS project $PRJ."
          $isc rdelete -m 'delete' --recursive "$PRJ" > /dev/null 2>&1
        fi
      fi
      if [ $prjnotexist -eq 1 -o "x$yesno" == "xyes" ]; then
        echo "Branching IBS packages ($PRJ)."
        $isc mbranch $PACKAGE "$PRJ"
      fi
      IBS_BRANCHED=1
      echo
    fi
  fi
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

  mbranch $TYPE
  get_package $d $TYPE

  if [ "$IN_DISTDIR" == "no" ]; then
    cd ..
  fi
done

