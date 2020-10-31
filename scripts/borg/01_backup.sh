#!/bin/bash
#
# Create a backup from a source directory
# Forces the backup timestamp to be set to to $DATE

source ./scripts/functions.sh
source ./scripts/borg/config.sh

if [ -z "${DATE}" ]; then
    fail "env var DATE not defined"
fi

if [ -z "${SOURCE_PATH}" ]; then
    fail "env var SOURCE_PATH not defined"
fi

if [ -z "${BACKUP_REPO_PATH}" ]; then
    fail "env var BACKUP_REPO_PATH not defined"
fi


# We want relative paths inside the backup, so we have to cd into $SOURCE_PATH first
cd "${SOURCE_PATH}" || fail "cd failed"

borg create \
    --one-file-system \
    --stats \
    --show-rc \
    --timestamp "${DATE::-1}" \
    "${BACKUP_REPO_PATH}::{hostname}-{user}-${DATE}" \
    . \
    || fail "borg create failed"

cd - > /dev/null || fail "cd failed"
