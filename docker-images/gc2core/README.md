## Launching the image in Docker (Kubernetes)

The image database connection data is empty, so all parameters have to be provided via enrionment variables. If the image is run in Docker, then variables can be passed as

```
sudo docker run -d -e GC2_PASSWORD=pw -e GC2_HOST=host -e GC2_DATABASE=database -e GC2_USER=user -e GC2_PORT=port -e GC2_PASSWORD=password -e GC2_BOUNCER=true alexshumilov/gc2core:latest
```

In case of Kubernetes, please provide the ConfigMap with proper keys.