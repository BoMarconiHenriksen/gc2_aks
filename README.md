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

### Installation

Steps to deploy the GC2 on AKS cluster:

1. Ensure that `kubectl` command is authorized on AKS cluster;
2. Enter Azure storage account name and storage account key in `storage-credentials.yaml` (please see the https://zimmergren.net/mount-an-azure-storage-file-share-to-deployments-in-azure-kubernetes-services-aks/ for instructions);
3. Install the ingress controller and SSL certificates manager (please follow the https://docs.microsoft.com/en-us/azure/aks/ingress-tls). The installation uses two ingress controllers in order to provide separate balancing and routing for GC2 and Vidi services. All files, required during installation, are already present in the provided configurations, but hey need to be filled with installation-specific data:

- `email` field in `cluster-issuer.yaml`

- `GC2_HOST` field in `vidi-env-configmap.yaml`

- `hosts` and `host` fields filled with GC2 installation host name (linked with Azure Public IP) in `00-ingress-rules-gc2.yaml`

- `hosts` and `host` fields filled with Vidi installation host name (linked with Azure Public IP) in `00-ingress-rules-vidi.yaml`

- `image` field with the custom `pgbouncer` image name in `pgbouncer-pod.yaml`

4. Run `kubectl apply -f .` command to instantiate GC2 pods and services.

---

### Overview of entities
##### Pods (the smallest deployable units of computing that can be created and managed in Kubernetes)

`gc2core` - provides the GC2 API, dashboard and other GC2 services (`mapcentia/gc2core:develop` image)

`mapcache` - provides the caching for WMS layers  (`mapcentia/mapcache` image)

`pgbouncer` - manages the PostgreSQL cluster connection pooling (installation-specific image)

`vidi` - provides the Vidi application (`mapcentia/vidi` image)

`nginx-ingress-controller` - load balancing, traffic routing

`nginx-ingress-default-backend` - default backend for `nginx-ingress`

##### Services (an abstract way to expose an application running on a set of Pods as a network service)

`gc2core` - 80/TCP port is open, provides access to GC2 API, dashboard and other GC2 services (internal service)

`mapcache` - 5555/TCP port is open, provides map caching (internal service)

`pgbouncer` - 5433/TCP port is open, managing connection to the PostgreSQL cluster (internal service)

`nginx-ingress-controller` - 80/TCP and 443/TCP ports are open (external service)

`nginx-ingress-default-backend` - 80/TCP port is open, handling default routes like `/healthz` that returns 200 and `/` that returns 404 (internal service)

