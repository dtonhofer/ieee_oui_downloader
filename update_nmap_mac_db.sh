#!/bin/bash

# ============
# Downloads latest Organizationally Unique Identifier (OUI) list from
# ieee.org in format suitable for use in nmap-mac-prefixes file.
#
# This is a modified version of Alain Kelder's original script at
#
# http://giantdorks.org/alain/script-to-update-nmap-mac-prefixes-with-latest-entries-from-the-ieee-oui-database/
#
# (License of original script is uncertain ....
#  So the License of this script is uncertain.)
#
# The script creates a temporary directory under /tmp and 
# downloads the IEEE OUI file into it. If there is a problem
# with processing, start the script again with the name of the
# temporary directory on the command line, and the already
# downloaded OUI file will be used -- no new download will be
# attempted.
#
# The script does not clean up after itself, you will have to
# destroy the temporary directory by yourself!
#
# 2018-10-27: The script passes ShellCheck
# =============

set -o nounset

nmp="nmap-mac-prefixes"
src="/usr/share/nmap/$nmp"
oui="oui.txt"
url="http://standards-oui.ieee.org/oui/$oui"

# ----- 
# The original author likes logging

LogThis()
{
   local level=${1:-''}
   local msg=${2:-''}
   echo "$(date "+%F %T") $(basename "$0"): $level: $msg" 
}

# ----- 
# End message to be printed from the temp directory
 
UpdateNotice()
{
   cat << EOF
 
   Processing complete.
 
   Updated file saved as '$(pwd)/$nmp'. It contains $missing OUI
   entries missing from the original '$src'.
 
   You should manually review the updated version, if satisfied,
   replace the original '$src'.

   Try 

   diff --side-by-side "$src" "$(pwd)/$nmp" | less

   If you run this script again as 

   $(basename "$0") "$(pwd)"

   an already-downloaded '$oui' file in '$(pwd)' will be used and no new
   download will be attempted.
 
   Here are line counts from the original and updated versions:
 
EOF
}

# -----
 
LineCounts()
{
   wc -l "$src" "$(pwd)/$nmp" | sed '/total$/d'
}

# -----
# Directly from http://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
# (For a string-processing toolkit like bash to not have trim...)

trim() {
   local var="$*"
   var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
   var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
   echo -n "$var"
}
 
# ---- BEGIN ----

if [[ ! -f $src ]]; then
  LogThis ERROR "Required nmap source file '$src' not found, I quit." 
  exit 1 
fi

if [[ ! -x "$(type -P combine)" ]]; then
  LogThis ERROR "Looks like program 'combine(1)' is not available"
  LogThis ERROR "Get it with e.g. 'apt-get install moreutils', 'dnf install moreutils' etc."
  exit 1
fi

# ... did the user pass the name of a temporary working directory?
# if yes, use that, otherwise create a new one

if [[ -n ${1:-''} ]]; then
   tmpdir=$1   
else
   # ... create temporary working directory, then cd to it
   # Using "--tmpdir", the directory will be created in "/tmp" (presumably)
   tmpdir=$(mktemp --tmpdir -d nmap_oui_processing.XXXXXX) || {
      LogThis ERROR "Could not create temporary directory, I quit."
      exit 1
   }
fi

# ... cd to the given or newly created directory

cd "$tmpdir" || {
   LogThis ERROR "Could not cd to temporary directory '$tmpdir', I quit."
   exit 1
}

LogThis INFO "Working in directory '$(pwd)'"

# ... if $oui file  already exist, do nothing, otherwise download

if [[ ! -f $oui ]]; then
   LogThis INFO "Downloading '$oui' from '$url'"
   curl --verbose --fail --output "$oui" "$url" || {
      LogThis ERROR "Could not properly retrieve '$url' (curl error $?, see curl man page), I quit."
      exit 1
   }
fi

# ... it must be there now

if [[ ! -f $oui ]]; then
  LogThis ERROR "'$(oui)' is missing"
  exit 1
fi

# ... processing!!

new_ones_raw_1=raw_1
new_ones_raw_2=raw_2
new_ones=new_lines_from_downloaded_file
old_ones=old_lines_from_existing_file
missing_ones=missing_lines_found_in_downloaded_file

/bin/cp "$src" "$nmp" || {
  LogThis ERROR "Could not copy existing '$src' to '$(pwd)'. I quit!"
  exit 1
}

# save values from oui.txt in format used by nmap-mac-prefixes

LogThis INFO "Extracting values from '$oui'..."
grep "(base 16)" "$oui" | sed -r 's/( |\t)+/ /g;s/\(base 16\) //;s/^ //;' > "$new_ones_raw_1"
 
# if Org value is empty, set it to "Private"

LogThis INFO "Replacing empty Org with 'Private'..."
awk '{if ($2=="") $2="Private"; print}' "$new_ones_raw_1" > "$new_ones_raw_2"

# extract just the OUI for comparison

LogThis INFO "Generating files for comparison..."
awk '{print$1}' "$new_ones_raw_2" > "$new_ones"
awk '$1!="#" {print$1}' "$nmp" > "$old_ones"
 
# generate a list of OUI present in oui.txt but missing in nmap-mac-prefixes
combine "$new_ones" not "$old_ones" > "$missing_ones"
 
missing=$(wc -l < "$missing_ones")
 
if [[ $missing -eq 0 ]]; then
   echo
   echo INFO "Local '$nmp' is up to date, nothing to do."
else
   echo -e "\n# Appended from $url on $(date)" >> "$nmp"
   sed -i '/^$/d' "$nmp"
   # Append missing OUI to nmap-mac-prefixes
   LogThis INFO "Appending missing OUI to '$(pwd)/$nmp'..."
   while read -r id; do
      add=$(grep "$id" "$new_ones_raw_2")
      add=$(trim "$add")
      echo "$add" >> "$nmp"
   done < "$missing_ones"
   UpdateNotice
   LineCounts
fi
 

