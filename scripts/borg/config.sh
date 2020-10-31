#!/bin/bash
#
# Configuration for borg using env vars

export BACKUP_REPO_PATH="${WORKING_DIR}/backup-borg"

# Add borg binary to $PATH
export PATH="${PATH}:/opt/borg"
