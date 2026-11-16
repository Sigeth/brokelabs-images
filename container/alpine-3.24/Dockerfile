# opslab container base: Alpine 3.24 with the student user (D28) and nothing
# else (busybox provides the shell and the usual tools). Published as
# ghcr.io/sigeth/opslab-images/alpine-3.24:<version>.
FROM docker.io/library/alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf
LABEL org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/Sigeth/opslab-images" \
      org.opencontainers.image.licenses="MIT"
COPY --chmod=0755 drop-package-manager /usr/local/sbin/drop-package-manager
COPY --chmod=0644 profile.sh /etc/profile.d/00-base.sh
RUN addgroup -g 1000 student \
 && adduser -D -u 1000 -G student -h /home/student -s /bin/sh student
ENV LANG=C.UTF-8
# Pod machines always run as 1000:1000; challenges switch to root (USER root)
# only to install their tools, then come back.
USER 1000:1000
WORKDIR /home/student
CMD ["sh", "-l"]
