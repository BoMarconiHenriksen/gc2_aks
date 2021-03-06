#!/bin/bash
set -e

# If container is run without commando, then check if config settings is passed.
if [ $1 == "/usr/bin/supervisord" ]; then
    if [ -n "$GC2_HOST" ]; then
      sed -i "s~GC2_HOST~$GC2_HOST~g" /root/vidi/config/config.js
      echo "
****************************************************
INFO:    GC2 host set to ${GC2_HOST}
****************************************************"
        else
            echo "
****************************************************
WARNING: No GC2 host has been set for Vidi.
         You can set the GC2 host in
         vidi/config/config.js
****************************************************"
    fi

    if [ -n "$GOOGLE_MAPS_API_KEY" ]; then
      sed -i "s~GOOGLE_MAPS_API_KEY~$GOOGLE_MAPS_API_KEY~g" /root/vidi/config/config.js
      echo "
****************************************************
INFO:    Google Maps API key set to ${GOOGLE_MAPS_API_KEY}
****************************************************"
        else
            echo "
****************************************************
WARNING: No Google Maps API key has been set for Vidi.
         You can set the Google Maps API key in
         vidi/config/config.js
****************************************************"
    fi

    if [ -n "$LOCALE" ]; then
            locale=$LOCALE
            echo "
****************************************************
INFO:    Locale set to ${LOCALE}
****************************************************"
        else
            locale=en_US.UTF-8
            echo "
****************************************************
WARNING: No locale has been set for Vidi.
         Setting it to en_US.UTF-8.
         Use "-e locale=your_locale" to set
         it in "docker run".
****************************************************"
    fi
    locale-gen $LOCALE
    dpkg-reconfigure locales
fi

#Run Grunt
cd /root/vidi && grunt production

exec "$@"