# MapCentia GC2core

A complete platform for managing geospatial data, making map visualisations and creating applications. Built on the best open source and standard based software.

This image is for a decoupled setup of GC2. Its depends on PostGIS and Elasticsearch. If you just want to test GC2, take a look at our stand-alone gc2 image.

The image comes with MapServer 7.0.0 and support for ECW imagery.

This following setup is for use together with our custom PostGIS image. 

## How to use this image
You need PostGIS and optional Elasticsearch and Geoserver running. Check out our PostGIS, Elasticsearch and Geoserver images. The latter is only necessary if you want printing.

Start by copying config files out from the image, so they can be stored on the host for easy editing and persistence.

    sudo docker run \
        --rm -i \
        -v ~/apache2:/tmp mapcentia/gc2core cp /etc/apache2/sites-enabled /tmp -R
    
    sudo docker run \
        --rm -i \
        -v ~:/tmp mapcentia/gc2core cp /etc/php5/fpm /tmp -R
    
    sudo docker run \
        --rm -i \
        -v ~/gc2:/tmp mapcentia/gc2core cp /var/www/geocloud2/app/conf /tmp -R
        
    sudo docker run \
        --rm -i \
        -v ~/gc2:/tmp mapcentia/gc2core cp /var/www/geocloud2/app/tmp /tmp -R
        
    sudo chmod 777 ~/gc2/tmp -R
        

The GC2_PASSWORD is the password for the PostGreSQL user "gc2" (See the README for our PostGIS image).

Leave -e TIMEZONE="..." to default to UTC.

    sudo docker run \
        --name gc2core \
        --restart=always \
        --link postgis:postgis \
        --link elasticsearch:elasticsearch \
        --link geoserver:geoserver \
        -v ~/apache2/ssl:/etc/apache2/ssl \
        -v ~/apache2/sites-enabled:/etc/apache2/sites-enabled/ \
        -v ~/fpm:/etc/php5/fpm/ \
        -v ~/gc2/conf:/var/www/geocloud2/app/conf \
        -v ~/gc2/tmp:/var/www/geocloud2/app/tmp \
        -v ~/gc2/mapcache:/var/www/geocloud2/app/wms/mapcache \
        -e GC2_PASSWORD=xxxxxx \
        -e TIMEZONE="Europe/Copenhagen" \
        -p 80:80 -p 443:443 -p 9000:9000\
        -d -t \
        mapcentia/gc2core
        

If you are using SSL you can strip the password phrase from the key. 

    /path/to/openssl rsa -in /path/to/originalkeywithpass.key -out /path/to/newkeywithnopass.key
    
### Optional
Start a node.js deamon to keep the Elasticsearch indices up to date.

    sudo docker run \
            --name elasticsearch_river \
            -e PGPASSWORD=xxxxxx \
            --link gc2core:gc2core \
            --link postgis:postgis \
            --volumes-from gc2core \
            -d -t mapcentia/gc2core \
            nodejs /var/www/geocloud2/app/scripts/pg2es.js [database] --host postgis --user gc2 --es-host gc2core --key [API key]


Start a node.js deamon to keep the Ckan up to date.

    sudo docker run \
            --name ckan_river \
            -e PGPASSWORD=xxxxxx \
            --link gc2core:gc2core \
            --link postgis:postgis \
            --volumes-from gc2core \
            -d -t mapcentia/gc2core \
            nodejs /var/www/geocloud2/app/scripts/meta2ckan.js [database] --host postgis --user gc2 --ckan-host gc2core --key [API key]
    

Update source and run database migrations.

    sudo docker run \
        --rm \
        --volumes-from=gc2core \
        --link postgis:postgis \
        -t -i mapcentia/gc2core grunt --gruntfile /var/www/geocloud2/Gruntfile.js production
        
    sudo docker run \
        --rm \
        --volumes-from=gc2core \
        --link postgis:postgis \
        -t -i mapcentia/gc2core grunt --gruntfile /var/www/geocloud2/Gruntfile.js migration
        
![MapCentia](https://geocloud.mapcentia.com/assets/images/MapCentia_geocloud_200.png)

[www.mapcentia.com/en/geocloud](http://www.mapcentia.com/en/geocloud/)





