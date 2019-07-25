## What is GC2?

GC2 – an enterprise platform for managing geospatial data, making map visualizations and creating applications. Built on the best open source and standard based software.

Please visit the https://github.com/mapcentia/geocloud2 and http://www.mapcentia.com/ for more information.

## The GC2 deployment on AKS

The repository contains Docker images to build from in `./docker-images` and Kubernetes configuration files in `./k8s-configurations`. The information below relates to the `k8s-configurations` configuration set.

### Prerequisities

Before installing GC2 in the AKS cluster, ensure that following file shares are created as a part of the Storage account (_Home > Storage accounts > USERNAME - Files_), as these file shares are used by pods for exchanging various data (please see the https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/ for instructions):

- `gc2core-var-www-geocloud2-app-wms-mapcache` (sharing generated files that deal with the WMS generation and caching)

- `gc2core-var-lib-php-sessions` (sharing PHP sessions between containers)

- `gc2core-var-www-geocloud2-app-tmp` (sharing temporary files between containers)

- `vidi-root-vidi-public-tmp` (sharing temporary files between containers)

- `vidi-tmp-sessions` (sharing sessions between containers)

Extract the provided files in any folder on the server with installed `kubectl` and proceed to the installation section.

---

### Preparing the database

To begin with, two databases have to be created in the PostgreSQL cluster:

https://github.com/mapcentia/dockerfiles/blob/master/postgis/entrypoint.sh#L67-L96

To ease installation and migrations in a cluster environment, the "Admin" API was added to GC2 develop branch. So after deployment with connection to a existing PostGIS database, call:

/api/v2/admin/createschema/[your_database]

This will create the "settings" schema in the database. This should only be run once. 
/api/v2/admin/runmigrations/[your_database]

This will run the latest migrations in the database. This will only affect the settings schema in the database.

---
### Installation

Steps to deploy the GC2 on AKS cluster:

1. Ensure that `kubectl` command is authorized on AKS cluster;
2. Enter Azure storage account name and storage account key in `conf-storage-credentials.yaml` (please see the https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/ for instructions);
3. Install the ingress controller and SSL certificates manager (please follow the https://docs.microsoft.com/en-us/azure/aks/ingress-tls). The installation uses two ingress controllers in order to provide separate balancing and routing for GC2 and Vidi services. All files, required during installation, are already present in the provided configurations, but hey need to be filled with installation-specific data:

- `email` field in `ingress-ssl/cluster-issuer.yaml`

- all field in `conf-gc2core-env-configmap.yaml` and `conf-vidi-env-configmap.yaml`

- `hosts` and `host` fields filled with GC2 and Vidi installation host names (linked with Azure Public IP) in `conf-ingress-rules.yaml`

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
