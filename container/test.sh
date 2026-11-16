#!/bin/sh
# Checks a container base (run as root in the image, by CI): the student user
# (D28) and drop-package-manager, which removes the package manager but keeps
# its database.
set -eu
fail() { echo "FAIL: $*" >&2; exit 1; }

[ "$(id -u student)" = 1000 ] || fail "student is not UID 1000"
[ "$(id -g student)" = 1000 ] || fail "student's group is not GID 1000"
[ "$(id -Gn student)" = student ] || fail "student has extra groups: $(id -Gn student)"
[ "$(stat -c %u:%g /home/student)" = 1000:1000 ] || fail "/home/student is not owned by student"
! command -v sudo >/dev/null || fail "sudo is installed"

if command -v apk >/dev/null; then manager=apk db=/lib/apk/db/installed
else manager=apt-get db=/var/lib/dpkg/status; fi
drop-package-manager
hash -r # forget the paths looked up before
! command -v "$manager" >/dev/null || fail "$manager is still installed"
! command -v drop-package-manager >/dev/null || fail "drop-package-manager did not remove itself"
[ -s "$db" ] || fail "the package database $db is gone"
echo ok
