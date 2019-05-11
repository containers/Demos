## My Weather Demo 

This demo shows how to use the 'stable' buildah image on 
quay.io/buildah to create a container that can show the weather 
of an inputed city.

It requires Buildah 1.8, Podman 1.3 or newer versions.

### Commands

First copy the `Dockerfile.weather` and `weather.py` from this directory
to the machine where Podman or Buildah is installed.

#### Podman

```
podman build -t weather -f Dockerfile.weather .
podman run --tty=true -a=stdin -a=stdout weather
```

#### Buildah

```
buildah bud -t weather -f Dockerfile.weather .
buildah from --name myweather weather
buildah run myweather python3 weather.py
```
