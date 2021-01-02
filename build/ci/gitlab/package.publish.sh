#!/usr/bin/env sh

which curl

if [ -z "${CI_API_V4_URL}" ]; then CI_API_V4_URL="https://gitlab.com/api/v4"; fi
if [ -z "${CI_SERVER_URL}" ]; then CI_SERVER_URL="https://gitlab.com"; fi
if [ -z "${CI_PROJECT_ID}" ]; then echo "CI_PROJECT_ID is empty" && exit 1; fi
if [ -z "${CI_JOB_TOKEN}" ]; then echo "CI_JOB_TOKEN is empty" && exit 1; fi
RELEASE_VERSION="$1"
if [ -z "${RELEASE_VERSION}" ]; then echo "undefined release version" && exit 1; fi

pkg_ver=$(echo ${RELEASE_VERSION} | sed -r 's/[^0-9.]//g')
if [ -z "${pkg_ver}" ]; then echo "invalid package version" && exit 1; fi

curl --header "JOB-TOKEN: ${CI_JOB_TOKEN}" --upload-file release-${RELEASE_VERSION}.zip \
    ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/generic/release/${pkg_ver}/goproject-${RELEASE_VERSION}.zip
