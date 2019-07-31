## What is GC2?

GC2 – an enterprise platform for managing geospatial data, making map visualizations and creating applications. Built on the best open-source and standard-based software.

Please visit the https://github.com/mapcentia/geocloud2 and http://www.mapcentia.com/ for more information.

## The GC2 deployment on AKS

The repository has Docker images to build from in `./docker-images` and Kubernetes configuration files in `./k8s-configurations`. The information below relates to the `k8s-configurations` configuration set.

### Prerequisites

Before installing GC2 in the AKS cluster, ensure that following file shares are created as a part of the Storage account (_Home > Storage accounts > USERNAME - Files_), as these file shares are used by pods for exchanging various data (please see the https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/ for instructions):

- `gc2core-var-www-geocloud2-app-wms-mapcache` (sharing generated files that deal with the WMS generation and caching)

- `gc2core-var-lib-php-sessions` (sharing PHP sessions between containers)

- `gc2core-var-www-geocloud2-app-tmp` (sharing temporary files between containers)

- `vidi-root-vidi-public-tmp` (sharing temporary files between containers)

- `vidi-tmp-sessions` (sharing sessions between containers)

Extract the provided files in any folder on the server with installed `kubectl` and proceed to the installation section.

---

### Preparing the database

#### Using external Postgres cluster

In order to be used with GC2, three databases have to be created in the external cluster: `mapcentia` (storing metadata), `gc2scheduler` (storing data for scheduler), `template_geocloud` (template for all user databases). Please follow steps below to setup databases (the Azure PostgreSQL service was used as an example, the instructions were taken mostly from the Docker configuration file for `mapcentia/postgis` image https://github.com/mapcentia/dockerfiles/blob/master/postgis/entrypoint.sh#L59-L96):

- create the database resource

```
CREATE USER gc2 WITH CREATEROLE CREATEDB PASSWORD 'NEW_PASSWORD';
```

- authorize as the `gc2` user

- create the `template_geocloud` database, create extensions and run migration SQL

```
CREATE DATABASE template_geocloud TEMPLATE template0 ENCODING 'UTF-8';

create extension postgis;
create extension pgcrypto;
create extension pgrouting;
```

Migration SQL: https://raw.githubusercontent.com/mapcentia/dockerfiles/master/postgis/conf/gc2/geometry_columns_join.sql

- create the `mapcentia` database, create extensions and the `users` tables

```
CREATE DATABASE mapcentia;

create extension postgis;
create extension pgcrypto;
create extension pgrouting;

CREATE TABLE users (
    screenname character varying(255),
    pw character varying(255),
    email character varying(255),
    zone character varying,
    parentdb varchar(255),
    created timestamp with time zone DEFAULT ('now'::text)::timestamp(0) with time zone
);
```

- create the `gc2scheduler` database and the `jobs` table

```
CREATE DATABASE gc2scheduler TEMPLATE template0 ENCODING 'UTF-8';

CREATE TABLE jobs (
    id serial PRIMARY KEY,
    name character varying(255),
    url character varying(255),
    cron character varying(255),
    schema character varying(255),
    epsg character varying(255),
    type character varying(255),
    min character varying,
    hour character varying,
    dayofmonth character varying,
    month character varying,
    dayofweek character varying,
    encoding character varying(255),
    lastcheck boolean,
    lasttimestamp timestamp with time zone,
    db character varying(255),
    extra character varying(255)
);
```

- deploy the GC2 on K8s (see instructions below, next steps will need the deployed GC2 installation)

- assuming that GC2 installation is configured with `gc2` user database credentials, the schema creation and migration APIs have to be called

```
GET your-gc2-host.com/api/v2/admin/createschema/mapcentia
GET your-gc2-host.com/api/v2/admin/runmigrations/mapcentia
```

- the Postgres cluster is configured to work with GC2

#### Using Docker images

The Docker images are available for deploying the `postgis` and `pgbouncer`. Please see the https://github.com/sashuk/gc2_aks/tree/master/k8s-configurations/database in order to deploy the database for GC2. However, the schema creation and migration APIs have to be called

```
GET your-gc2-host.com/api/v2/admin/createschema/mapcentia
GET your-gc2-host.com/api/v2/admin/runmigrations/mapcentia
```

---

### Installation

Steps to deploy the GC2 on AKS cluster:

1. Ensure that `kubectl` command is authorized on AKS cluster;

2. Enter Azure storage account name and storage account key in `conf-storage-credentials.yaml` (please see the https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/ for instructions);

3. Install the ingress controller and SSL certificates manager (please follow the https://docs.microsoft.com/en-us/azure/aks/ingress-tls). The installation uses two ingress controllers to provide separate balancing and routing for GC2 and Vidi services. All files, required during installation, are already present in the provided configurations, but hey need to be filled with installation-specific data:

- `email` field in `ingress-ssl/cluster-issuer.yaml`

- all field in `conf-gc2core-env-configmap.yaml` and `conf-vidi-env-configmap.yaml`

- `hosts` and `host` fields filled with GC2 and Vidi installation hostnames (linked with Azure Public IP) in `conf-ingress-rules.yaml`

4. Run `kubectl apply -f .` command to instantiate GC2 pods and services.

---

### Overview of entities

##### Pods (the smallest deployable units of computing that can be created and managed in Kubernetes)

`gc2core` - provides the GC2 API, dashboard and other GC2 services (`alexshumilov/gc2core:develop` image)

`mapcache` - provides the caching for WMS layers  (`mapcentia/mapcache` image)


`vidi` - provides the Vidi application (`mapcentia/vidi` image)

`nginx-ingress-controller` - load balancing, traffic routing

`nginx-ingress-default-backend` - default backend for `nginx-ingress`

##### Services (an abstract way to expose an application running on a set of Pods as a network service)

`gc2core` - 80/TCP port is open, provides access to GC2 API, dashboard and other GC2 services (internal service)

`mapcache` - 5555/TCP port is open, provides map caching (internal service)

`nginx-ingress-controller` - 80/TCP and 443/TCP ports are open (external service)

`nginx-ingress-default-backend` - 80/TCP port is open, handling default routes like `/healthz` that returns 200 and `/` that returns 404 (internal service)

