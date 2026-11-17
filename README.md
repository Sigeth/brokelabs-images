# brokelabs-images

Base images for the machines of [BrokeLabs](https://github.com/Sigeth/brokelabs-challenge-template) challenges.

## VM bases (`vm/`)

KubeVirt containerDisks for `vm` machines, built from each distribution's official cloud image:

| Base | Image | Source |
|---|---|---|
| `debian-13` | `ghcr.io/sigeth/brokelabs-images/debian-13:<version>` | Debian genericcloud |
| `ubuntu-26.04` | `ghcr.io/sigeth/brokelabs-images/ubuntu-26.04:<version>` | Ubuntu server cloud image |
| `rocky-10` | `ghcr.io/sigeth/brokelabs-images/rocky-10:<version>` | Rocky Linux GenericCloud (a RHEL rebuild: RHEL itself cannot be redistributed, but a subscriber can build a RHEL base with the same recipe format) |

A base only adds what makes a good default: the QEMU guest agent, NoCloud as the only cloud-init datasource (no probing at boot), and no automatic updates. Users are **not** baked in: the platform creates `student` (UID 1000, passwordless `sudo`) and `brokelabs-checker` through cloud-init when an instance boots.

### The base image contract

The platform depends on this contract only, never on a distribution. Any image meeting it works as a `vm` machine image, so you can add your own base (another distribution, a licensed RHEL, an internal build):

- a KubeVirt **containerDisk**: an OCI image for `linux/amd64` with one qcow2 disk under `/disk/`, owned by UID 107;
- **cloud-init** with the **NoCloud** datasource;
- **sshd** enabled on port 22, accepting public-key logins;
- boots to SSH-ready **without network access**;
- recommended: `qemu-guest-agent`.

### Recipes

Each base is a directory with an `image.yaml` recipe and its scripts:

```yaml
version: 1.0.0            # the tag the image is published under
source:                   # exactly one of url (+ sha256 or sha512) and image
  url: https://.../debian-13-genericcloud-amd64-20261026-2643.qcow2
  sha512: 3ace18e3...
  # image: ghcr.io/sigeth/brokelabs-images/debian-13@sha256:...   (build on a containerDisk)
run: [customize.sh]       # run as root inside the disk, in order, with network access
```

The scripts run offline in the disk image with [`virt-customize`](https://libguestfs.org/virt-customize.1.html); the recipe directory is at `/tmp/recipe` meanwhile. The machine-id is reset so every instance gets its own. Challenges use the same format for their own VM images (`images/<machine>/image.yaml`, usually with `source.image` set to a base).

Build one with [brokelabs-ci](https://github.com/Sigeth/brokelabs-ci) (Dagger):

```sh
dagger -m github.com/Sigeth/brokelabs-ci@v0.4.0 call vm-image --source=vm/debian-13 export --path=debian-13.tar
```

## Container bases (`container/`)

Starting points for the Dockerfiles of `pod` machines (`images/<machine>/Dockerfile` in a challenge):

| Base | Image | Shell |
|---|---|---|
| `alpine-3.24` | `ghcr.io/sigeth/brokelabs-images/alpine-3.24:<version>` | busybox `sh` |
| `debian-13-slim` | `ghcr.io/sigeth/brokelabs-images/debian-13-slim:<version>` | `bash` |

A base adds the `student` user and group (UID and GID 1000, no other groups, home `/home/student`), `LANG=C.UTF-8`, a few login shell defaults, and nothing else: no `sudo`, editors or compilers. It runs as `1000:1000` in `/home/student`, like every pod machine.

It keeps its package manager so challenges can install the tools their tasks need, and ships `drop-package-manager`, which removes it (and itself) as the last build step: nothing is installed at run time. The package database stays, so image scanners still see what is installed.

```dockerfile
FROM ghcr.io/sigeth/brokelabs-images/alpine-3.24:1.0.0@sha256:b5813ffd71c722ba0cab3e5ad68b68668f2f4c137f617e01ad1ac91816a8399e
USER root
RUN apk add --no-cache bash && drop-package-manager
USER 1000:1000
```

Build and test one with [brokelabs-ci](https://github.com/Sigeth/brokelabs-ci) (`container/test.sh` checks the user and `drop-package-manager`):

```sh
dagger -m github.com/Sigeth/brokelabs-ci@v0.4.0 call image --source=container/alpine-3.24 \
  with-user --name=root with-file --path=/test.sh --source=container/test.sh with-exec --args=sh,/test.sh stdout
```

## Releases

Tag `<base>/v<version>` (e.g. `debian-13/v1.0.0`) to publish a base; the version must match its `image.yaml` (VM bases) or the `org.opencontainers.image.version` label of its Dockerfile (container bases).

## License

MIT
