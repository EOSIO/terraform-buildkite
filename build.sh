#!/usr/bin/env bash
set -ex
IFS=$' \n\t'

rm -rf dist

export PROVIDER_VERSION="0.0.5"
export DISTDIR="$PWD/dist"
export WORKDIR="$PWD"

export GOX_MAIN_TEMPLATE="$DISTDIR/{{.OS}}/terraform-provider-buildkite_v${PROVIDER_VERSION}"
export GOX_ARCH="amd64"
export GOX_OS=${*:-"linux darwin"}

# We'll use gox to cross-compile
go get github.com/mitchellh/gox
# We just assume the cross toolchains are already installed, since on Debian
# there are deb packages for those.

# Build the provider
gox -arch="$GOX_ARCH" -os="$GOX_OS" -output="$GOX_MAIN_TEMPLATE" github.com/$(git remote show origin -n | grep h.URL | sed 's/.*://;s/\/.*//;s/.git$//')/terraform-buildkite

# ZZZZZZZZZZZZZZZZZZZZIPPIT
echo "--- Build done"
for os in $GOX_OS; do
    for arch in $GOX_ARCH; do
        echo "--- Zipping $os/$arch"
        cd "$DISTDIR/$os"
        zip ../terraform-provider-buildkite-v"${PROVIDER_VERSION}"-"$os"-"$arch".zip ./*
    done
done
echo "--- DING! Fries are done"
cd "$DISTDIR"
openssl dgst -r -sha256 ./*.zip > sha256s.txt
exit 0
