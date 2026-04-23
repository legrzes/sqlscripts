#!/bin/bash
#
# keycloak_find_user.sh - script for searching string in tables user_attribute, user_entity
# print someinfo about user
# Used for batch cheking users in keycloak db.
#

WDIR=tmp
LOGF=$WDIR/keycloak_find_user.log

STXT=$1
PSQL="psql -t -A -d keycloak"

mkdir -p $WDIR

LOG () {
        DTTM=`date +"%Y%m%d.%H%M%S"`
        echo $DTTM $0 $@
        echo $DTTM $0 $@ >> $LOGF
}
if [[ ! "$STXT" =~ ^[[:alnum:].@_-]+$ ]]; then

        LOG ERR "Niepoprawny parametr" $STXT
    exit 1
fi

IDS=$($PSQL  <<ENDSQL |sort -u
SELECT user_id FROM user_attribute
WHERE lower(value)=lower('$STXT');
SELECT id FROM user_entity WHERE lower(email)=lower('$STXT') or lower(first_name)=lower('$STXT') or lower(last_name)=lower('$STXT') or lower(username)=lower('$STXT')
ENDSQL
)
LOG dbg znalazlem=$IDS

for id in $IDS ; do
        # main data
        INF1=$($PSQL  <<ENDSQL
        SELECT username, first_name, last_name,email FROM user_entity
        WHERE id='$id';
ENDSQL
)
        # last activity
        INF_L=$($PSQL  <<ENDSQL| tr '|' ' ' | tr "\n" ";"
        SELECT to_char(to_timestamp(event_time/1000),'YYYY-MM-DD'), type FROM event_entity
        WHERE user_id='$id'  and type like 'LOGIN%'
        ORDER by event_time desc LIMIT 3;
ENDSQL
)
        # attributies
        INF_A=$($PSQL  <<ENDSQL
        SELECT name,'=',value ,';' FROM user_attribute
        WHERE user_id='$id';
ENDSQL
)
        INF_A=`echo $INF_A |tr -d '|'`
        echo REKORD "$STXT|$id|$INF1|$INF_A|$INF_L"

done
