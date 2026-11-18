# BrokeLabs workstation for Kubernetes challenges: the machine a student's
# terminal lands on, next to a vcluster machine (kubeconfigFor). The platform
# mounts the kubeconfig and sets KUBECONFIG. Built on the Alpine base (the
# student user, D28); kubectl follows Alpine's package (1.36, within the
# supported skew of the virtual clusters). Published as
# ghcr.io/sigeth/brokelabs-images/workstation-k8s:<version>.
FROM ghcr.io/sigeth/brokelabs-images/alpine-3.24:1.0.1@sha256:0bda9e219fda6e893138c802fd05ddf396357371b4563429852ecbc8d4d4f7d6
LABEL org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/Sigeth/brokelabs-images" \
      org.opencontainers.image.licenses="MIT"
USER root
# The package manager stays (challenges add their tools, then run
# drop-package-manager), like in the bases.
RUN apk add --no-cache \
      bash bash-completion less curl openssl jq yq-go vim nano \
      kubectl kubectl-bash-completion helm helm-bash-completion \
 && sed -i 's#^student:\(.*\):/bin/sh$#student:\1:/bin/bash#' /etc/passwd \
 && kubectl version --client >/dev/null && helm version >/dev/null
COPY --chmod=0644 kubernetes.sh /etc/profile.d/10-kubernetes.sh
USER 1000:1000
WORKDIR /home/student
CMD ["bash", "-l"]
