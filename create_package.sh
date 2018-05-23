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
  local base="$1"
  local source="$2"
  local target="$3"
  1>/dev/null pushd "$base"
  "$curdir/gnuwin32_zip_util/zip.exe" -q -9 -r -X "$target" "$source"
  1>/dev/null popd
  return 0
 }
else
 compress ()
 {
  log "TODO"
  return 1
 }
fi

mkdir -p "$curdir/packages"
package_date=`date +%Y.%-m.%-d`
package_name="custom_boards_${package_date}"
package_archive="custom_boards_${package_date}.zip"
index="package_custom_boards_index.json"
temp_dir=`mktemp -d`
log "using temp_directory: $temp_dir"

#copy board-definition-templates to $temp_dir
mkdir -p "$temp_dir/$package_name"
cp "$curdir/templates/boards.txt.template" "$temp_dir/$package_name/boards.txt"
cp "$curdir/templates/platform.local.txt.template" "$temp_dir/$package_name/platform.local.txt"

#compress files
log "creating archive $package_archive"
compress "$temp_dir" "$package_name" "$package_archive"

#calculate sha256 checksum and size
checksum=`sha256sum.exe -b "$temp_dir/$package_archive" | cut -f1 -d" "`
size=`du -b "$temp_dir/$package_archive" | cut -f1`

#create package.json based on package.json.template
cp "$curdir/templates/package.json.template" "$temp_dir/${package_name}.json"
sed -i "s|__DATE__|$package_date|g" "$temp_dir/${package_name}.json"
sed -i "s|__ARCHIVE__|$package_archive|g" "$temp_dir/${package_name}.json"
sed -i "s|__SHA256__|$checksum|g" "$temp_dir/${package_name}.json"
sed -i "s|__SIZE__|$size|g" "$temp_dir/${package_name}.json"

#copy archive to $curdir/packages/$package_archive
mv "$temp_dir/$package_archive" "$curdir/packages/$package_archive"
mv "$temp_dir/${package_name}.json" "$curdir/packages/${package_name}.json"

#re-create board-manager definition file at $curdir/$index
first_line="true"
cat "$curdir/templates/header.json.template" > "$curdir/$index"
for entry in "$curdir/packages/"*.json
do
 [[ ! -f "$entry" ]] && break;
 [[ $first_line == true ]] && first_line="false" || echo "," >> "$curdir/$index"
 cat "$entry" >> "$curdir/$index"
done
cat "$curdir/templates/footer.json.template" >> "$curdir/$index"

#remove $temp_dir
log "cleaning up temporary directory at $temp_dir"
rm -rf $temp_dir

exit 0
