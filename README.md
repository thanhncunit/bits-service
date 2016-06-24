# Bits Service

The bits-service is an extraction from existing functionality of the [cloud controller](https://github.com/cloudfoundry/cloud_controller_ng). It encapsulates all "bits operations" into its own, separately scalable service. All bits operations comprise buildpacks, droplets, app_stashes, packages and the buildpack_cache. 

## API

**The API is a work in progress and will most likely change.**

```
POST /buildpacks
GET /buildpacks/:guid
DELETE /buildpacks/:guid
```

```
POST /droplets
GET /droplets/:guid
DELETE /droplets/:guid
```

```
POST /app_stash/entries
POST /app_stash/matches
POST /app_stash/bundles
```

```
POST /packages
GET /packages/:guid
DELETE /packages/:guid
```

## Supported Backends: 

Currently, only local filesystem and S3 are supported.

# Development

The CI config is in the [bits-service-ci](https://github.com/cloudfoundry-incubator/bits-service-ci) repo.

## Documentation

The sequence charts in `docs/` were generated with [websequencediagrams](https://www.websequencediagrams.com/) and can be regenerated with `rake docs/create-app.png` etc.
