#!/bin/bash
#
# Run a backup reliablity test
#
# This script simulates backup creation from $start_date to $end_date and
# validates restored backups. It returns with return code 0 if the
# simulation and validation succeeded. In any other case it will exit
# with return code 1.
#
# Copyright (C) 2020 Marc-André Bühler
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

source ./scripts/functions.sh


# Configuration ---------------------------------------------------------------

home_dir=$( getent passwd "$USER" | cut -d: -f6 )
export WORKING_DIR="${home_dir}/backup-verification"


# Arguments -------------------------------------------------------------------

# Heavily inspired by https://en.wikipedia.org/wiki/Getopts
# We use "$@" instead of $* to preserve argument-boundary information
options=$(getopt --options 'c:v' --long 'comparison:,verbose' -- "$@") || exit
eval "set -- $options"

verbose=0
declare -a comparison

while true; do
    case $1 in
        (-v|--verbose)
            ((verbose++)); shift;;
        (-c|--comparison)
            comparison+=("$2"); shift 2;;
        (--)
            shift; break;;
        (*)
            fail "shit happened";; # error
    esac
done

# Set default comparison if none defined
if [ ${#comparison[@]} -eq 0 ]; then
    comparison+=("diff")
    log "Defaulting to diff comparison"
fi

# Handle positional arguments
remaining=("$@")
if [ ${#remaining[@]} -ne 2 ]; then
    fail "Unexpected number of arguments"
fi
start_date_raw=${remaining[0]}
end_date_raw=${remaining[1]}

# Validate arguments
for strategy in "${comparison[@]}"
do
    strategy_script="./scripts/comparison/${strategy}-compare.sh"
    if [ ! -f "${strategy_script}" ]; then
        fail "Comparison strategy ${strategy} is not implemented (script file not found: ${strategy_script}"
    fi
done

start_date=$(date --utc --date "$start_date_raw" +"%Y-%m-%dT%H:%M:%SZ") || fail "invalid start date"
end_date=$(date --utc --date "$end_date_raw" +"%Y-%m-%dT%H:%M:%SZ") || fail "invalid end date"

# Print all arguments
if [ "$verbose" -gt 0 ]; then
    log \
        "Arguments: "
        "verbose: $verbose," \
        "comparison: ${comparison[*]}," \
        "start: $start_date," \
        "end: $end_date"
fi


# Main ------------------------------------------------------------------------

# Print parameters
log "Running backup reliablity test from ${start_date} to ${end_date}"
log "Using '${comparison[*]}' to compare restored backup with reference data"

# Print version information
log "Printing version information"
log "diff --version" && diff --version
log "rsync --version" && rsync --version
log "git --version" && git --version
log "md5sum --version" && md5sum --version
log "sha512sum --version" && sha512sum --version

# Initialization
cd "${WORKING_DIR}" || fail "cd failed"
rm -rf reference && mkdir reference
rm -rf restore
rm -rf backup-borg && mkdir backup-borg
cd - > /dev/null || fail "cd failed"

# Get latest version of Linux kernel
if [ ! -d "${WORKING_DIR}/linux" ]; then
    log "Cloning the Linux kernel"
    cd "${WORKING_DIR}" || fail "cd failed"
    git clone --no-checkout git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git linux
    cd - > /dev/null || fail "cd failed"
else
    cd "${WORKING_DIR}/linux" || fail "cd failed"
    git fetch origin master || fail "git fetch failed"
    git reset --hard origin/master || fail "git reset failed"
    cd - > /dev/null || fail "cd failed"
fi

# Initialize backup
log "Initializing backup repository"
./scripts/borg/00_init.sh \
    || fail "Restoring to ${RESTORE_DIR} failed"

declare -a BACKUPS

DATE="${start_date}"
while [ "${DATE}" != "${end_date}" ]; do
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
    # Temporary exclude .git directory
    rsync --archive --human-readable --quiet --exclude .git "${LINUX_DIR}" "${SOURCE_DIR}" \
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
        REFERENCE_DIR="${WORKING_DIR}/reference/${RESTORE_DATE}"

        for current_comparison in "${comparison[@]}"
        do
            log "Comparing restored backup with reference (${current_comparison})"
            REFERENCE_DIR="${REFERENCE_DIR}" RESTORE_DIR="${RESTORE_DIR}" "./scripts/comparison/${current_comparison}-compare.sh" \
                || fail "VALIDATION FAILED: Restored backup ${RESTORE_DIR} is not identical with reference ${REFERENCE_DIR}"
            log "Validation succeeded"
        done

        # Clean up
        rm -rf "${RESTORE_DIR}" || fail "rm -rf failed"
    done

    # Append 1 day
    DATE=$(date --utc --date "${DATE} +1 day" +"%Y-%m-%dT%H:%M:%SZ")
done

log "Backup reliability test completed without errors"
