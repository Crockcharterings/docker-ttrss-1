#!/bin/bash

set -e

: "${TTRSS_DB_HOST:="$DB_PORT_5432_TCP_ADDR"}"
: "${TTRSS_DB_USER:="$DB_ENV_POSTGRES_USER"}"
: "${TTRSS_DB_PASS:="$DB_ENV_POSTGRES_PASSWORD"}"
: "${TTRSS_DB_NAME:="ttrss"}"
: "${TTRSS_DB_PORT:="5432"}"
: "${TTRSS_FEED_CRYPT_KEY:=""}"
: "${TTRSS_HOST_URL:="http://localhost/"}"

RESULT=$(PGPASSWORD=$TTRSS_DB_PASS psql -h "$TTRSS_DB_HOST" -U "$TTRSS_DB_USER" -q -c '\dt' "$TTRSS_DB_NAME" | \
    grep "rows" | grep -v "\(0 rows\)") > /dev/null 2>&1

if [[ "$RESULT" == "" ]]; then
    PGPASSWORD=$TTRSS_DB_PASS psql -h "$TTRSS_DB_HOST" -U "$TTRSS_DB_USER" -q -c "CREATE USER $TTRSS_DB_USER"
    PGPASSWORD=$TTRSS_DB_PASS psql -h "$TTRSS_DB_HOST" -U "$TTRSS_DB_USER" -q -c "CREATE DATABASE $TTRSS_DB_NAME"
    PGPASSWORD=$TTRSS_DB_PASS psql -h "$TTRSS_DB_HOST" -U "$TTRSS_DB_USER" -q -c "GRANT ALL PRIVILEGES ON DATABASE $TTRSS_DB_NAME TO $TTRSS_DB_USER"
    PGPASSWORD=$TTRSS_DB_PASS psql -h "$TTRSS_DB_HOST" -U "$TTRSS_DB_USER" -q "$TTRSS_DB_NAME" < /var/www/html/ttrss/schema/ttrss_schema_pgsql.sql
fi

sed -i -e "s/DB_HOST_VALUE/$TTRSS_DB_HOST/" /var/www/html/ttrss/config.php
sed -i -e "s/DB_USER_VALUE/$TTRSS_DB_USER/" /var/www/html/ttrss/config.php
sed -i -e "s/DB_NAME_VALUE/$TTRSS_DB_NAME/" /var/www/html/ttrss/config.php
sed -i -e "s/DB_PASS_VALUE/$TTRSS_DB_PASS/" /var/www/html/ttrss/config.php
sed -i -e "s/DB_PORT_VALUE/$TTRSS_DB_PORT/" /var/www/html/ttrss/config.php
sed -i -e "s/FEED_CRYPT_KEY_VALUE/$TTRSS_FEED_CRYPT_KEY/" /var/www/html/ttrss/config.php
sed -i -e "s#HOST_URL#$TTRSS_HOST_URL#" /var/www/html/ttrss/config.php

echo "define('_SKIP_SELF_URL_PATH_CHECKS', 'skip');" >> /var/www/html/ttrss/config.php

exec "$@"
