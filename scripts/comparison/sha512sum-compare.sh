#!/bin/bash
#
# Compare two directories by hashing the files of both directories and then compare the hashes

source ./scripts/functions.sh

if [ -z "${REFERENCE_DIR}" ]; then
    fail "env var REFERENCE_DIR not defined"
fi

if [ -z "${RESTORE_DIR}" ]; then
    fail "env var RESTORE_DIR not defined"
fi


function get-hash-file-path() {
    realpath "$1/../$(basename "$1").$2"
}

function create-hash-file() {
    cd "$1" || fail "cd failed"

    # SHA512
    find . -type f -exec sha512sum {} + | sort -k 2 > "$2" \
        || fail "sha512 hashing failed"

    cd - > /dev/null || fail "cd failed"
}


reference_hash_file=$(get-hash-file-path "${REFERENCE_DIR}" "sha512sum")
# Use already created hash file from previous comparison
if [ ! -f "${reference_hash_file}" ]; then
    log "Creating hashes for ${REFERENCE_DIR}"
    create-hash-file "${REFERENCE_DIR}" "${reference_hash_file}" \
        || fail "creating hash file failed"
    log "Created hash file at ${reference_hash_file}"
else
    log "Using existing hash file at ${reference_hash_file}"
fi

log "Creating hashes for ${RESTORE_DIR}"
restore_hash_file=$(get-hash-file-path "${RESTORE_DIR}" "sha512sum")
# Always create new hash file
create-hash-file "${RESTORE_DIR}" "${restore_hash_file}" \
    || fail "creating hash file failed"
log "Created hash file at ${restore_hash_file}"

log "Comparing hash files ${reference_hash_file}" and "${restore_hash_file}"
diff "${reference_hash_file}" "${restore_hash_file}" \
    || fail "VALIDATION FAILED!"
