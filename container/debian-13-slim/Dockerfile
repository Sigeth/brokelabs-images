# opslab container base: Debian 13 (trixie) slim with the student user (D28)
# and nothing else (bash and coreutils come with Debian). Published as
# ghcr.io/sigeth/opslab-images/debian-13-slim:<version>.
FROM docker.io/library/debian:13-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
LABEL org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/Sigeth/opslab-images" \
      org.opencontainers.image.licenses="MIT"
COPY --chmod=0755 drop-package-manager /usr/local/sbin/drop-package-manager
# The home directory gets Debian's default .profile and .bashrc (/etc/skel).
RUN groupadd -g 1000 student \
 && useradd -m -u 1000 -g student -d /home/student -s /bin/bash student
ENV LANG=C.UTF-8
# Pod machines always run as 1000:1000; challenges switch to root (USER root)
# only to install their tools, then come back.
USER 1000:1000
WORKDIR /home/student
CMD ["bash", "-l"]
