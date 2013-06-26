#!/bin/bash
# Description: Scan files and add Apache 2.0 license

rootpath=$1
excludes=$2

if [ ! -e "$rootpath" ];
then
    echo Usage: $0 repo_path [ excludes.txt ]
    echo
    echo export AUTHOR=\"Company\" and execute
    echo Put file or directory names to be excluded in excludes.txt
    exit 1
fi

if [ ! -f "$excludes" ];
then
    excludes=/tmp/excludes
fi

echo "\.git" >> $excludes
echo "\.svn" >> $excludes

if [ -z "$AUTHOR" ];
then
    AUTHOR="Sarath Lakshman"
fi

YEAR="$(date +%Y)"

# Python, shell style
read -d '' license1 <<EOF

# 	Copyright $YEAR $AUTHOR
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

EOF

# C,C++, Go style
read -d '' license2 <<EOF
/*
 *	 Copyright $YEAR $AUTHOR
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

EOF

get_file_type () {
	desc=`file $1`
	if x=$1 && [[ "{${x##*.}" = "go" ]];
    then
        echo go
	elif [[ "$desc" =~ "python" ]];
	then
		echo python
	elif [[ "$desc" =~ "shell script" ]];
	then
		echo shell
	elif [[ "$desc" =~ "C++ program" ]];
	then
		echo cpp
	elif [[ "$desc" =~ "c program" ]];
	then
		echo c
	else
		echo unknown
	fi
}

has_license () {
	found=`cat $1 | head -n 100 | grep -i -e "copyright"`
	if [[ -z "$found" ]];
	then
		echo no
	else
		echo yes
	fi
}

update_license () {
	copyright=`cat $1 | head -n 100 | grep -i -e "copyright"`
	me=`echo "$copyright" | grep "$AUTHOR"`
	if [[ -z "$me" ]];
	then
		echo "Found, $copyright"
		echo Please add license manually for $1
		echo
	fi
}

add_license () {
	if [[ "$2" = "python" || "$2" = "shell" ]];
	then
		insert_at_line=$(awk '{ if (!match($0, "^#")) { print NR; exit }}' $1)
		head -n $(( $insert_at_line - 1 )) $1 > /tmp/tmp.$$.tmp
		if [ "$insert_at_line" -ne 1 ];
        then
            echo >> /tmp/tmp.$$.tmp
        fi
		echo "$license1" >> /tmp/tmp.$$.tmp
		tail -n "+$insert_at_line" $1 >> /tmp/tmp.$$.tmp
	elif [[ "$2" != "unknown" ]];
	then
		insert_at_line=$(awk '{ if (!match($0, "^/")) { print NR; exit }}' $1)
		head -n $(( $insert_at_line - 1 )) $1 > /tmp/tmp.$$.tmp
		if [ "$insert_at_line" -ne 1 ];
        then
            echo >> /tmp/tmp.$$.tmp
        fi
		echo "$license2" >> /tmp/tmp.$$.tmp
		tail -n "+$insert_at_line" $1 >> /tmp/tmp.$$.tmp
	else
		return
	fi

	mv /tmp/tmp.$$.tmp $1
}


find $rootpath -type f > /tmp/tmp.$$.files.1
grep -v -f $excludes /tmp/tmp.$$.files.1 > /tmp/tmp.$$.files

for f in `cat /tmp/tmp.$$.files`;
do
    echo "Processing $f"
    hl=$(has_license $f)
	if [[ "$hl" = "yes" ]];
	then
		update_license $f $(get_file_type $f)
	else
		add_license $f $(get_file_type $f)
	fi

done

rm -f /tmp/$$.files*

