#!/bin/bash
#
# Initialize a borg backup repository

source ./scripts/functions.sh
source ./scripts/borg/config.sh

# Print borg version for traceability
borg --version

borg init \
    --encryption=none \
    --show-rc \
    "${BACKUP_REPO_PATH}" \
    || fail "borg init failed"
