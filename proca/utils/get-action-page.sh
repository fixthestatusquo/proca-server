#!/bin/bash

set -u
set -e 
NAME=""
URL="https://api.proca.app/api"
FILE=""
CHOWN=""
SCRIPT=$(readlink -f $0)
ARGV="$@"
CRONTAB=""

show_help()
{
    cat >&2 <<"END"
Proca Widget data fetcher.
Usage:
  $0 -n widget_name [optional arguments]

optional arguments:
  -u https://api.proca.app/api   - alternative url for Proca API
  -o /var/www/html/widget-1.json - file to write the widget data into (should be served by http server)
  -w                             - set ownership to www-data (server user)
  -c                             - add this command to crontab
END

}



while getopts "u:n:o:wc" OPTION; do
    case $OPTION in
        n)
            NAME=$OPTARG
            ;;
        u)
            URL=$OPTARG
            ;;
        o)
            FILE="$OPTARG"
            ;;
        w)
            CHOWN=yes
            ;;
        c)
            CRONTAB=yes
            ;;
        *)
            echo "Incorrect options provided"
            show_help
            exit 1
            ;;
    esac
done

if [ "$NAME" = "" ]; then
    show_help
    exit 1
fi


QUERY="{actionPage(name:\"$NAME\"){config,locale,journey,name,campaign{title,name,externalId,stats{actionCount{actionType,count},supporterCount},org{title}}}}"

if [ -n "$FILE" ]; then
    touch "$FILE"
    chmod 0644 "$FILE"

    if [ -n "$CHOWN" ]; then
        FILEUID=$(id -u www-data || 0)
        FILEGID=$(id -g www-data || 0)
        chown $FILEUID:$FILEGID "$FILE" || echo "File will have owner: $(id -u):$(id -g)"
    fi

    OUTPUT="-o $FILE"
else
    OUTPUT=""
fi

CURL=$(which curl || echo '')
if [ -n "$CURL" ]; then
    curl -s -G --data-urlencode "query=$QUERY" $OUTPUT $URL
else
    echo "Install curl"
fi

crontab_installed()
{
    crontab -l 2>/dev/null | grep "$SCRIPT" || echo "no"
}

if [ "$CRONTAB" = "yes" -a -n "$FILE" ]; then
    if [ "$(crontab_installed)" = "no" ]; then
        (crontab -l 2>/dev/null; echo "* * * * * $SCRIPT -n $NAME -o $FILE ${CHOWN:+-w}") | crontab -
        echo "Job installed to run every minute"
    else
        echo "This script seems to be installed, remove it and try again (use crontab -e)"
    fi
    echo "Your crontab:"
    crontab -l

fi
