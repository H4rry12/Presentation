#!/bin/bash

SYNC_FUNCTION_PID=-1
SERVER_PID=-1
CHROMIUM_PID=-1

# trap ctrl-c function and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
	echo "Exiting ***"
	kill $SYNC_FUNCTION_PID
	kill $SERVER_PID
	kill $CHROMIUM_PID
	exit 0
}

if [ $# -eq 0 ]; then
	echo "Usage: "$0" [OPTION]..."
	echo
	echo "Options"
	echo -e " -l, --local \t Mistni adresar, do ktereho se zkopiruje vzdaleny obsah."
	echo -e " -r, --remote \t Vzdaleny adresar, se kterym se bude synchronizovat."
	echo -e " -u, --user \t Uzivatel pro zabezpecene pripojeni."
	echo -e " -p, --passwd \t Heslo zabezpeceneho pripojeni."
	echo -e " -h, --host \t Adresa vzdaleneho zarizeni."
	exit 0
fi

while [ "$#" -ne 0 ]; do
	case $1 in
	-l|--local)
		shift
		LOCAL=$1
		;;
	-r|--remote)
		shift
		REMOTE=$1
		;;
	-u|--user)
		shift
		USER=$1
		;;
	-p|--passwd)
		shift
		PASS=$1
		;;
	-h|--host)
		shift
		HOST=$1
		;;
	esac
	shift
done

# Nastaveni a vytvoreni lokalniho adresare
if [ -z $LOCAL ]; then
	LOCAL=$PWD"/data"
fi

if [ ! -d $LOCAL ]; then
	mkdir -p $LOCAL
fi

sync_funcion() {
	while [ true ]; do
		echo "Directory synchronization..."
		sshpass -p $PASS rsync -av -e ssh $USER"@"$HOST":"$REMOTE $LOCAL
		sleep 60
	done
}

chromix-too-server &
SERVER_PID=$!

sleep 2

sync_funcion &
SYNC_FUNCTION_PID=$!

sleep 2

chromium-browser --disable-translate --incognito --kiosk 2> /dev/null &
CHROMIUM_PID=$!

sleep 5

TAB_TO_CLOSE=2

while true; do
	for FILE in $LOCAL/*; do
		if [ -f "$FILE" ]; then
		
			ACTION="file://"
			URL="$FILE"
			
			# Test jestli soubor nema priponu *.desktop a vyhledani adresy URL=
			FILE_NAME=${FILE##*/}
			FILE_TYPE=${FILE_NAME##*.}
			if [ $FILE_TYPE == "desktop" ]; then
				while read LINE; do
					if [ "${LINE%%=*}" == "URL" ]; then
						URL="${LINE##*=}"
						ACTION=""
					fi
				done < "$FILE"
			fi
			
			OPENED_TAB=$(chromix-too open $ACTION"$URL")
			
			sleep 5
			
			chromix-too rm $TAB_TO_CLOSE
			TAB_TO_CLOSE="${OPENED_TAB%%\ *}"
			
			sleep 25
			
		else
			sleep 1
		fi
	done
done

echo "End..."

kill $SYNC_FUNCTION_PID
kill $SERVER_PID
kill $CHROMIUM_PID

exit 0

