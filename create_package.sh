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
 # find arduino installation, and setup avr-gcc
 log "looking for avr-gcc from arduino installation"
 program_files=`cygpath "$PROGRAMFILES"`
 program_files_x86="$program_files (x86)"
 for test_dir in "$program_files_x86"/Arduino*/hardware/tools/avr/bin "$HOME/AppData/Local/Arduino"*/packages/arduino/tools/avr-gcc/*/bin
 do
  [[ ! -d $test_dir ]] && continue
  if [[ -e $test_dir/avr-gcc.exe ]]; then
   log "adding directory $test_dir to path env"
   arduino_found="true"
   export PATH="$test_dir:$PATH"
  fi
 done
 [[ $arduino_found != true ]] && log "avr-gcc not found!" && false
 #use local make utility
 export PATH="$curdir\gnuwin32_make:$PATH"
 #use local bc utility
 export PATH="$curdir\gnuwin32_bc:$PATH"
 compress ()
 {
  local base="$1"
  local source="$2"
  local target="$3"
  1>/dev/null pushd "$base"
  "$curdir/zip_util_ps/zip_util.bat" "$source" "$target"
  1>/dev/null popd
  return 0
 }
else
  # find arduino installation, and setup avr-gcc
  log "looking for avr-gcc from arduino installation"
  for test_dir in /usr/bin "$HOME"/arduino-*/hardware/tools/avr/bin "$HOME/.arduino"*/packages/arduino/tools/avr-gcc/*/bin
  do
   [[ ! -d $test_dir ]] && continue
   if [[ -e $test_dir/avr-gcc ]]; then
    log "adding directory $test_dir to path env"
    arduino_found="true"
    export PATH="$test_dir:$PATH"
   fi
  done
  [[ $arduino_found != true ]] && log "avr-gcc not found!" && false
 compress ()
 {
  log "TODO"
  return 1
 }
fi

mkdir -p "$curdir/packages"
package_date=`date -u +%Y.%-m.%-d`
package_name="custom_boards_${package_date}"
package_archive="custom_boards_${package_date}.zip"
index="package_custom_boards_index.json"
temp_dir=`mktemp -d`
log "using temp_directory: $temp_dir"

build_optiboot ()
{
 local freq="$1"
 local baud="$2"
 local targets="$3"
 local target=""
 mkdir -p "$temp_dir/optiboot_build"
 cp "$curdir/src/external/optiboot/"* "$temp_dir/optiboot_build"
 1>/dev/null pushd "$temp_dir/optiboot_build"
 AVR_FREQ=$freq BAUD_RATE=$baud ./makeall $targets
 1>/dev/null popd
 mkdir -p "$temp_dir/$package_name/bootloaders"
 for target in $targets
 do
  mv "$temp_dir/optiboot_build/optiboot_${target}_${freq}_${baud}.hex" "$temp_dir/$package_name/bootloaders"
 done
 rm -rf "$temp_dir/optiboot_build"
}

#create board-definition files at $temp_dir/$package_name
mkdir -p "$temp_dir/$package_name"
dos2unix -q -r -n "$curdir/src/boards.txt" "$temp_dir/$package_name/boards.txt"
dos2unix -q -r -n "$curdir/src/platform.local.txt" "$temp_dir/$package_name/platform.local.txt"
dos2unix -q -r -n "$curdir/src/external/programmers.txt" "$temp_dir/$package_name/programmers.txt"
sed -i "s|program.tool=avrdude|program.tool=avrdude_fuseonly|g" "$temp_dir/$package_name/programmers.txt"
sed -i "s|\(^.*\)\(\.name=.*\)\($\)|\1\2 (with lock setup)\3|" "$temp_dir/$package_name/programmers.txt"
sed -i "s|\(^\)\([^#].*\)\($\)|\1custom_\2\3|" "$temp_dir/$package_name/programmers.txt"
mkdir -p "$temp_dir/$package_name/variants/sanguino"
dos2unix -q -r -n "$curdir/src/external/pins_arduino.h" "$temp_dir/$package_name/variants/sanguino/pins_arduino.h"

#build optiboot for supported platforms
log "building bootloaders"
build_optiboot 20000000L 250000 "atmega328 atmega328p atmega328pb"
build_optiboot 16000000L 250000 "atmega328 atmega328p atmega328pb atmega1284p atmega2560"
build_optiboot 8000000L 19200 "atmega328 atmega328p atmega328pb atmega1284p"
build_optiboot 1000000L 9600 "atmega328 atmega328p atmega328pb"

#compress files
log "creating archive $package_archive"
compress "$temp_dir" "$package_name" "$package_archive"

#calculate sha256 checksum and size
checksum=`sha256sum.exe -b "$temp_dir/$package_archive" | cut -f1 -d" "`
size=`du -b "$temp_dir/$package_archive" | cut -f1`

#create package.json based on package.json.template
dos2unix -q -r -n "$curdir/templates/package.json.template" "$temp_dir/${package_name}.json"
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
dos2unix -q -r "$curdir/$index"

#remove $temp_dir
log "cleaning up temporary directory at $temp_dir"
rm -rf $temp_dir

exit 0
