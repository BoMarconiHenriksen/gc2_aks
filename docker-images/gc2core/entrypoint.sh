#!/bin/bash
set -e

# If container is run without commando, then check if pgsql pw for gc2 is passed.
if [ $1 == "/usr/bin/supervisord" ]; then
    # Host
    if [ -n "$GC2_HOST" ]; then
      sed -i "s/POSTGISHOST_CONFIGURATION/$GC2_HOST/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL host set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL host has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi

    # Database
    if [ -n "$GC2_DATABASE" ]; then
      sed -i "s/POSTGISDB_CONFIGURATION/$GC2_DATABASE/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL database set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL database has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi

    # User
    if [ -n "$GC2_USER" ]; then
      sed -i "s/POSTGISUSER_CONFIGURATION/$GC2_USER/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL user set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL user has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi

    # Port
    if [ -n "$GC2_PORT" ]; then
      sed -i "s/POSTGISPORT_CONFIGURATION/$GC2_PORT/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL port set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL port has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi

    # Password
    if [ -n "$GC2_PASSWORD" ]; then
      sed -i "s/POSTGISPW_CONFIGURATION/$GC2_PASSWORD/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL password set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL password has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi

    # Password
    if [ -n "$GC2_BOUNCER" ]; then
      sed -i "s/PGBOUNCER_CONFIGURATION/$GC2_BOUNCER/g" /var/www/geocloud2/app/conf/Connection.php
      echo "
*************************************************************
Info:    PostgreSQL pgbouncer set in
         geocloud2/app/conf/Connection.php
*************************************************************"
    else
      echo "
*************************************************************
WARNING: No PostgreSQL pgbouncer has been set for the GC2 user.
         You set this in geocloud2/app/conf/Connection.php
*************************************************************"
    fi
fi

# Rebuilding the dashboard to provide configuration from ConfigMap
mkdir -p /dashboardtmp &&\
cd /dashboardtmp &&\
git clone http://github.com/mapcentia/dashboard.git &&\
cd /dashboardtmp/dashboard &&\
npm install &&\
cp ./app/config.js.sample ./app/config.js

# Dashboard "vidiUrl" setting
if [ -n "$GC2_HOST" ]; then
    sed -i "s/VIDI_URL_CONFIGURATION/$VIDI_URL/g" /dashboardtmp/dashboard/app/config.js
    echo "
*************************************************************
Info:    Vidi URL was set
*************************************************************"
else
    echo "
*************************************************************
WARNING: No Vidi URL has been set
*************************************************************"
fi

cd /dashboardtmp/dashboard &&\
cp ./.env.production ./.env &&\
npm run build && cp -R ./build/* /var/www/geocloud2/public/dashboard/ &&\
rm -R /dashboardtmp

chown www-data:www-data /var/www/geocloud2/app/tmp/ &&\
chown www-data:www-data /var/www/geocloud2/app/wms/mapfiles/ &&\
chown www-data:www-data /var/www/geocloud2/app/wms/mapcache/ &&\
chown www-data:www-data /var/www/geocloud2/app/wms/files/ &&\
chown www-data:www-data /var/www/geocloud2/app/wms/qgsfiles/ &&\
chown www-data:www-data /var/www/geocloud2/public/logs/

# Set time zone if passed
if [ -n "$TIMEZONE" ]; then
    echo $TIMEZONE | tee /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata
fi
exec "$@"