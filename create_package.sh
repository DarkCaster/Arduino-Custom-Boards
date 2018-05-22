#!/bin/bash

curdir="$( cd "$( dirname "$0" )" && pwd )"

log () {
 echo "[ $@ ]"
}

error() {
 local source="$1"
 local line="$2"
 local ec="$3"
 echo "*** command at $source:$line failed with error code $ec"
 [[ ! -z $temp_dir ]] && echo "cleaning up temporary directory at $temp_dir" && rm -rf "$temp_dir"
 exit $ec
}

trap 'error ${BASH_SOURCE} ${LINENO} $?' ERR

if [[ ! -z $MSYSTEM ]]; then
 log "running on msys"
 compress ()
 {
  log "TODO"
  return 1
 }
else
 compress ()
 {
  log "TODO"
  return 1
 }
fi

mkdir -p "$curdir/packages"
package_date=`date +%Y.%m.%d`
package_name="custom_boards_$package_date"
temp_dir=`mktemp -d`
log "using temp_directory: $temp_dir"

### TODO: copy board-definition-templates to $temp_dir
### TODO: create final board-definition files
### TODO: compress files
### TODO: copy archive to $curdir/packages/$package_name.zip
### TODO: create new json definition at $curdir/packages
### TODO: re-create board-manager definition file at $curdir/custom-packages.json

### remove $temp_dir
log "cleaning up temporary directory at $temp_dir"
rm -rf $temp_dir

exit 0
