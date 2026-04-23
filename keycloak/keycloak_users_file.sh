#!/bin/bash
#
#


FLIN=$1

echo > $FLIN.results.txt
cnt=0
while IFS= read -r line; do
    echo "Text read from file: $line"
    cnt=$(($cnt + 1))
    stxt=`echo "$line" |tr " " "|" |cut -f 1`
    echo $cnt stxt=$stxt
    res=$(./keycloak_find_user.sh "$stxt" |grep "^REKORD" | tr "\n" "\t")

    echo "$cnt  $line   $res" >> $FLIN.results.txt
done < $FLIN
