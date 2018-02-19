# Bits Service

![logo](docs/bits_logo_horizontal.svg)

The bits-service is an extraction from existing functionality of the [cloud controller](https://github.com/cloudfoundry/cloud_controller_ng). It encapsulates all "bits operations" into its own, separately scalable service. All bits operations comprise buildpacks, droplets, app_stashes, packages and the buildpack_cache.

[The API](http://cloudfoundry-incubator.github.io/bits-service/) is a work in progress and will most likely change.

## Supported Backends:

* S3
* Local filesystem
* WebDAV

# Development

The CI config is in the [bits-service-ci](https://github.com/cloudfoundry-incubator/bits-service-ci) repo.
