#!/bin/bash
#set -x

USER=pgajdos
isc="osc -A https://api.suse.de"
osc="osc -A https://api.opensuse.org"
DEVEL_DIST="devel"
DEFAULT_DIST="$DEVEL_DIST"
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
  echo "              - otherwise $DEFAULT_DIST is used for \$dist"
  echo "                and package is saved into $DEFAULT_DIST/\$package"
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
    DIST="$DEFAULT_DIST"  # default DIST
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
echo "Wipe:             [$WIPE]"

# intended to wipe packages from home:$USER:branches:*
# !!! wipe used to behave the same way for openSUSE and SLE versions;
#     I hope it will do also in the future:
#     $CMD rdelete --recursive -m "delete" "$PRJ:$PACKAGE"
#     where $CMD \in {$ibs, $obs} (replaces TYPE) will be enough then
function wipe()
{
  TYPE=$1
  DIST=$2

  if [ $WIPE -eq 1 ]; then
    if [ "$TYPE" == "ibs" ]; then
      echo "Wiping home:$USER:branches:SUSE:$DIST[:GA|[[:Update]:Test]]/$PACKAGE"
      $isc rdelete -m "delete" "home:$USER:branches:SUSE:$DIST:GA" $PACKAGE >/dev/null 2>&1
      $isc rdelete -m "delete" "home:$USER:branches:SUSE:$DIST:Update" $PACKAGE >/dev/null 2>&1
      $isc rdelete -m "delete" "home:$USER:branches:SUSE:$DIST:Update:Test" $PACKAGE >/dev/null 2>&1
    else
      echo "Wiping home:$USER:branches:OBS_Maintained:$PACKAGE/$PACKAGE.openSUSE_$DIST"
#      $osc rdelete -m "delete" "home:$USER:branches:OBS_Maintained:$PACKAGE/$PACKAGE.openSUSE_$DIST >/dev/null 2>&1"
      echo "* This will not work for current osc mbranch. It could be ok when osc mbranch for one distribution package"
      echo "* will be implemented. Then it could be possible to mbranch/remove packages independently. Now it works this way:"
      echo "*   pgajdos@laura:~/pokus> osc mbranch dosfstools"
      echo "*   Project home:pgajdos:branches:OBS_Maintained:dosfstools created."
      echo "*   pgajdos@laura:~/pokus> osc rdelete -m "delete" home:pgajdos:branches:OBS_Maintained:dosfstools/dosfstools.openSUSE_11.4"
      echo "*   pgajdos@laura:~/pokus> osc mbranch dosfstools"
      echo "*   BuildService API error: branch target package already exists: home:pgajdos:branches:OBS_Maintained:dosfstools/dosfstools.openSUSE_11.3"
      echo
      echo 'Invoke manually $osc rdelete --recursive -m "delete" "home:$USER:branches:OBS_Maintained:$PACKAGE'
      echo to remove all packages from home:$USER:branches:OBS_Maintained:$PACKAGE.
    fi
  fi
}

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
      wipe $TYPE $DIST
      COPROJECT="home:$USER:branches:OBS_Maintained:$PACKAGE/$PACKAGE.openSUSE_$DIST"
      echo
      echo "openSUSE:$DIST ($COPROJECT)"
      if [ $OBS_MBRANCHED -eq 0 ]; then
        RESULT=`$osc mbranch $PACKAGE 2>&1`
        if [ $? -ne 0 ]; then
          if [ "`echo $RESULT | grep 'branch target package already exists'`" != "" ]; then
            # no action here
            true
          elif [ "`echo $RESULT | grep 'no packages found'`" != "" ]; then
            echo "ERROR: package not found"
            return # terminate get_package(), but not terminate whole download script
          else
            echo "ERROR: unknown osc MBRANCH message ($RESULT)"
            echo "$0 needs to be fixed to handle it"
            exit 1
          fi
        fi
      fi
      OBS_MBRANCHED=1
      $osc co -c $COPROJECT
      mv "$PACKAGE.openSUSE_$DIST" $PACKAGE
      ;;

    "ibs")
      wipe $TYPE $DIST
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

OBS_MBRANCHED=0
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

