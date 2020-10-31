#!/bin/bash
#
# Restore a backup to $TARGET_PATH

source ./scripts/functions.sh
source ./scripts/borg/config.sh

if [ -z "${DATE}" ]; then
    fail "env var DATE not defined"
fi

if [ -z "${TARGET_PATH}" ]; then
    fail "env var TARGET_PATH not defined"
fi

if [ -z "${BACKUP_REPO_PATH}" ]; then
    fail "env var BACKUP_REPO_PATH not defined"
fi


cd "${TARGET_PATH}" || fail "cd failed"

borg extract \
    --show-rc \
    "${BACKUP_REPO_PATH}::{hostname}-{user}-${DATE}" \
    || fail "borg extract failed"

cd - > /dev/null || fail "cd failed"
