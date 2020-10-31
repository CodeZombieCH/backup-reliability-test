#!/bin/bash
#
# Runs a backup reliablity test
# Simulates backup creation from $START_DATE to $END_DATE

source ./scripts/functions.sh

home_dir=$( getent passwd "$USER" | cut -d: -f6 )
export WORKING_DIR="${home_dir}/backup-verification"
#export SOURCE_BASE_PATH=/home/mab/backup-verification/reference


# Main ------------------------------------------------------------------------

# Print version information
log "Printing version information"
diff --version
rsync --version
git --version
md5sum --version
sha512sum --version

# Initialization
cd "${WORKING_DIR}" || fail "cd failed"
rm -rf reference && mkdir reference
rm -rf backup-borg && mkdir backup-borg
cd - > /dev/null || fail "cd failed"

cd "${WORKING_DIR}" || fail "cd failed"
#git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux
cd - > /dev/null || fail "cd failed"

# Initialize backup
log "Initializing backup repository"
./scripts/borg/00_init.sh \
    || fail "Restoring to ${RESTORE_DIR} failed"


START_DATE="2020-01-01T00:00:00Z"
END_DATE="2020-02-01T00:00:00Z"
declare -a BACKUPS
BACKUPS+=()

DATE="${START_DATE}"
while [ "${DATE}" != "${END_DATE}" ]; do
    log "Time travelling to ${DATE}"

    BACKUPS+=("${DATE}")

    # Prepare backup payload
    log "Preparing backup payload"
    LINUX_DIR="${WORKING_DIR}/linux"
    cd "${LINUX_DIR}" || fail "cd failed"
    git checkout "$(git rev-list --max-count 1 --before="${DATE}" master)" \
        || fail "git checkout failed"
    cd - > /dev/null || fail "cd failed"

    SOURCE_DIR="${WORKING_DIR}/reference/${DATE}"
    rsync --archive --human-readable --quiet "${LINUX_DIR}" "${SOURCE_DIR}" \
        || fail "rsync failed"

    # Run backup
    log "Backing up ${SOURCE_DIR}"
    SOURCE_PATH="${SOURCE_DIR}" DATE="${DATE}" ./scripts/borg/01_backup.sh \
        || fail "Backing up ${SOURCE_DIR} failed"

    # Restore and validate all backups in repository
    for RESTORE_DATE in "${BACKUPS[@]}"; do
        log "Restoring backup from ${RESTORE_DATE}"

        # Create new directory for restore
        RESTORE_DIR="${WORKING_DIR}/restore"
        rm -rf "${RESTORE_DIR}" || fail "rm -rf failed"
        mkdir "${RESTORE_DIR}" || fail "mkdir failed"

        log "Restoring to ${RESTORE_DIR}"
        TARGET_PATH=${RESTORE_DIR} DATE=${RESTORE_DATE} ./scripts/borg/02_restore.sh \
            || fail "Restoring to ${RESTORE_DIR} failed"

        # Validate
        log "Comparing restored backup with reference"
        REFERENCE_DIR="${WORKING_DIR}/reference/${RESTORE_DATE}"
        diff --brief --recursive "${REFERENCE_DIR}" "${RESTORE_DIR}" \
            || fail "VALIDATION FAILED!\nRestored backup ${RESTORE_DIR} is not identical with reference ${REFERENCE_DIR}"
        log "Validation succeeded"

        # Clean up
        rm -rf ${RESTORE_DIR} || fail "rm -rf failed"
    done

    # Append 1 day
    DATE=$(date --utc --date "${DATE} +1 day" +"%Y-%m-%dT%H:%M:%SZ")
done
