apiurl="https://api.opensuse.org"
osc="osc -A $apiurl"
sleeptime="30m"
baseproject="openSUSE:Factory"

function usage
{
  echo "Usage: $0 prj pkg new_prj [new_package]"
  echo "       moves or renames prj/pkg to new_prj/new_pkg"
  echo "       and if prj is devel project for prj in factory"
  echo "       performs appropriate actions"
}

# wait until request state is accepted, declined or revoked
function rqwait
{
  rqstate=""
  while [ -z "$rqstate" ]; do
    echo `date` checking for request state
    rqstate=`$osc rq show --brief $rqno | grep "State\:\(accepted\|declined\|revoked\)" | sed 's/.*State\:\([a-z]*\).*/\1/'`
    sleep "$sleeptime"
  done
}

function diff_changes
{
  $osc cat $prj $pkg $pkg.changes > $pkg.changes.a
  $osc cat $new_prj $new_pkg $new_pkg.changes > $new_pkg.changes.b
  diff=`diff -u "$pkg.changes.a" "$new_pkg.changes.b"`
  rm $pkg.changes.a $new_pkg.changes.b
}

prj=$1
pkg=$2
new_prj=$3
new_pkg=$4

if [ -z "$prj" -o -z "$pkg" -o -z "$new_prj" ]; then
  usage
  exit 1
fi

if [ -z "$new_pkg" ]; then
  new_pkg=$pkg;
fi

message="Moving $prj/$pkg to $new_prj/$new_pkg."

echo "[[ === $message ==="

$osc ls $prj/$pkg > /dev/null
if [ $? -eq 1 ]; then
  echo "[[ ERROR: $prj/$pkg doesn't exist."
  exit 1
fi

echo "[[[[ Copying $prj/$pkg $new_prj/$new_pkg".

# copying package (if not exist yet)
$osc ls "$new_prj/$new_pkg" >/dev/null 2>&1
if [ $? -eq 1 ]; then
  if [ $pkg == $new_pkg ]; then
    # package move: copy with _link
    $osc copypac -m "$message" "$prj/$pkg" "$new_prj/$new_pkg" > /dev/null
  else
    # package rename: copy without _link
    $osc copypac -e -m "$message" "$prj/$pkg" "$new_prj/$new_pkg" > /dev/null
  fi
  if [ $? -ne 0 ]; then
    echo "[[[[ ERROR: Command $osc copypac -m \"$message\" $prj/$pkg $new_prj/$new_pkg failed."
    exit 2
  fi

  # package rename: modify package sources
  if [ "$pkg" != $new_pkg ]; then
    echo "[[[[[[ Making neccessary changes to package sources."

    echo "[[[[[[[[ Checkouting package into ./$new_pkg."
    $osc co -c $new_prj $new_pkg 
    if [ $? -ne 0 ]; then 
      echo "[[[[[[[[ ERROR: Command $osc co -c $new_prj $new_pkg failed."
      exit 2
    fi

    pushd $new_pkg

    echo "[[[[[[[[ Renaming source files from $pkg* to $new_pkg*."
    mmv "$pkg*" "$new_pkg#1"
    if [ $? -ne 0 ]; then
      echo "[[[[[[[[ ERROR: Command mmv \"$pkg*\" \"$new_pkg#1\" failed."
      echo "[[[[[[[[ HINT:  If you don't have mmv installed, please run zypper in mmv (very useful tool)."
      exit 2
    fi 

    echo "[[[[[[[[ Making some basic $new_pkg.spec file changes."
    sed -i "s,^\(Name:[ \t]*\)$pkg,\1$new_pkg," instlux.spec    
    sed -i "s,^\(Patch[0-9]*:[ \t]*\)$pkg,\1$new_pkg," instlux.spec
    
    echo "[[[[[[[[ Check in package into $new_prj/$new_pkg."
    $osc ar
    $osc ci -m "$message"
    if [ $? -ne 0 ]; then 
      echo "[[[[[[[[ ERROR: Command $osc ci -m \"$message\" failed."
      exit 2
    fi

    popd

    echo "[[[[[[[[ WARNING: Package was submitted with some changes in spec file."
    echo "[[[[[[[[          Before continue, please check if package is building ok and make"
    echo "[[[[[[[[          other needed changes eventually."
    echo "[[[[[[[[          Then you can continue with yes."
    echo "[[[[[[[[ SEE: `pwd`/$new_pkg"
    echo -n "[[[[[[ Package is building fine and we can continue? [yes/NO]: "

    read yesno

    rm -r $new_pkg

    if [ $yesno != "yes" ]; then
      echo "[[[[[[ Aborting."
      exit 0
    fi
  fi
else
  echo "[[[[ WARNING: $new_prj/$new_pkg exists yet, not copying."

  diff_changes
  echo "[[[[ CHANGES: "
  if [ -z "$diff" ]; then
    echo "No changes."
  else
    echo "$diff"
  fi
  echo -n "[[[[ Continue? [yes/NO]: "

  read yesno
  if [ "$yesno" != "yes" ]; then
    echo "[[[[ Aborting."
    exit 0;
  fi
fi

# check, if $prj is devel project for $pkg in $baseproject
develproject=`$osc develproject $baseproject $pkg`
if [ "$develproject" == "$prj" ]; then
  
  echo "[[[[ Performing $baseproject submissions ($prj is devel project for $pkg in $baseproject)."

  # check if this is package rename
  if [ "$pkg" != "$new_pkg" ]; then

    echo "[[[[[[ Submitting $new_prj/$new_pkg to $baseproject (hint: pkg != new_pkg)."
    rqno=`yes | $osc sr -m "$message" "$new_prj" "$new_pkg" "$baseproject" 2>&1 | grep "request id" | sed 's:.*request id \([0-9]\+\).*:\1:g'`
    if [ -z "$rqno" ]; then
      echo "[[[[[[ ERROR: Command $osc sr -m \"$message\" $new_prj $new_pkg $baseproject failed."
      exit 2
    fi

    echo "[[[[[[ Created submit request $rqno."
    rqwait

    echo "[[[[[[ Submit request was $rqstate."

    if [ "$rqstate" != "accepted" ]; then
      echo "--------------------------------------------"
       $osc rq show $rqno
      exit 1
    fi

    echo "[[[[[[ Package $new_pkg is in $baseproject."
    echo "[[[[[[ Deleting $baseproject/$pkg."

    rqno=`$osc dr -m "$message" "$baseproject/$pkg"`
    if [ -z "$rqno" ]; then
      echo "[[[[[[ ERROR: Command $osc dr -m \"$message\" $baseproject/$pkg failed."
      exit 2
    fi

    echo "[[[[[[ Created delete request $rqno."
    rqwait
 
    echo "[[[[[[ Delete request was $rqstate."

    if [ "$rqstate" != "accepted" ]; then
      echo "--------------------------------------------"
      $osc rq show $rqno
      exit 1;
    fi

    echo "[[[[[[ Package $pkg was deleted from $baseproject."

  else # not package name

    echo "[[[[[[ Changing devel project from $prj/$pkg to $new_prj/$pkg (hint: pkg == new_pkg)."      
   
    rqno=`$osc cr -m "$message" "$baseproject" "$pkg" "$new_prj"`
    if [ -z "$rqno" ]; then
      echo "[[[[[[ ERROR: Command $osc cr -m \"$message\" $baseproject $pkg $new_prj failed."
      exit 2
    fi

    echo "[[[[[[ Created change devel request $rqno."
    rqwait

    echo "[[[[[[ Change devel request was $rqstate."

    if [ "$rqstate" != "accepted" ]; then
      echo "--------------------------------------------"
      $osc rq show $rqno
      exit 1;
    fi

    echo "[[[[[[ Devel project of $baseproject/$pkg is now $new_prj."

  fi

fi

# double check that $new_prj/$new_pkg exists and is the same

echo "[[[[ Removing $prj/$pkg"

$osc ls "$new_prj/$new_pkg" > /dev/null
if [ $? -ne 0 ]; then
  echo "[[[[ ERROR: Doublechecked: Package $new_prj/$new_pkg doesn't exist, not removing (it shouldn't happen)."
  exit 1
fi

# see changes before pkg removal
diff_changes

# remove only if there are no other changes
if [ ! -z "$diff" ]; then
  echo "[[[[ WARNING: $prj/$pkg and $new_prj/$new_pkg are different, not removing."
  echo "[[[[          $prj/$pkg could have been modified in the meantime. Changes:"
  echo "$diff"
fi

echo -n "[[[[ Really remove $prj/$pkg? (yes/NO): "
read yesno
if [ "$yesno" != "yes" ]; then
  echo "[[[[ Aborting."
  exit 0
fi

$osc rdelete -m "$message" "$prj/$pkg"
if [ $? -ne 0 ]; then
  echo "[[[[ ERROR: Command $osc rdelete -m \"$message\" $prj/$pkg failed."
  exit 2
fi

echo "[[ Finished."

exit 0

