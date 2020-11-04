#!/bin/bash
#
# Hashes the files of two directories and then compares the hashes

source ./scripts/functions.sh

if [ -z "${REFERENCE_DIR}" ]; then
    fail "env var REFERENCE_DIR not defined"
fi

if [ -z "${RESTORE_DIR}" ]; then
    fail "env var RESTORE_DIR not defined"
fi


diff --brief --recursive "${REFERENCE_DIR}" "${RESTORE_DIR}" \
    || fail "VALIDATION FAILED!"
