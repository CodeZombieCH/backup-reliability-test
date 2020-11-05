# The Backup Reliability Test Project

The Backup Reliability Test project aims to prove reliability of free backup software

## Motivation

Most IT people are smart enough to create backups of their valuable data and thus are confronted with the task to pick the right backup software for their needs. There are plenty to pick and all claim to be reliable. But how reliable are they really? Which tests have been/are performed to proof their reliability?

This project aims to create a reproducible test procedure that can be run with different backup software to give an indication of how reliable a backup software really is.


## Covered Backup Software

- [x] [borg](https://github.com/borgbackup/borg)
- [ ] [bup](https://github.com/bup/bup)
- [ ] [Duplicacy](https://github.com/gilbertchen/duplicacy)
- [ ] [restic](https://github.com/restic/restic)


## Prerequisites

- git
- rsync
- diff
- (md5sum)
- (sha512sum)


## Usage

Spin up a Linux computer of your choice (e.g. an Intel NUC).

Prepare the directory for the backup validation:

    mkdir ~/backup-verification

Clone the git repo:

    git clone git@github.com:CodeZombieCH/backup-reliability-test.git
    cd backup-reliability-test

Run the backup reliability test:

    ./scripts/run.sh <start-date> <end-date> | tee run.log

Please be aware that this will take a long time (between 1 and 3 days)


### Synopsis

```bash
run.sh [--verbose] [--comparison diff|sha512sum] <start-date> <end-date>
```

### Description

- `-c, --comparison`:<br>
    array of comparison strategies to use to validate restored backups. Calls a comparison script for each key passed based on the following convention: `./scripts/comparison/<key>-compare.sh`
- `<start-date>`:<br>
    start date of the backup payload to generate in the format 2020-01-01T00:00:00Z
- `<end-date>`:<br>
    end date of the backup payload to generate in the format 2020-01-31T00:00:00Z


## Procedure

### Stages

1. Print version information
1. Backup Initialization
1. From `$start_date` to `$end_date`
    1. Test Payload Generation
    1. Backup Creation
    1. (Backup pruning) (not yet implemented)
    1. Backup Restoration
    1. Backup Validation

### Backup Initialization

Script: `scripts/<backup-software>/00_init.sh`

The *Backup Initialization* stage prepares a directory to serve as a backup repository.

### Test Payload Generation

The *Test Payload Generation* stage creates a test payload for a given day that serves as the data to be backed up and as the reference data for the later comparison of a restored backup. The test payload is generated in the directory `reference/<date>`.

Currently the Git repository of the Linux kernel at <git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git> is used to create a test payloads. To create a test payload for a given day, the latest commit before the given date is checked out.

### Backup Creation

Script: `scripts/<backup-software>/01_backup.sh`

The *Backup Creation* stage creates a backup of the reference directory of a given day (directory `reference/<date>`)

### Backup Restoration

Script: `scripts/<backup-software>/02_restore.sh`

The *Backup Restoration* stage restores a backup of a given day to the `restore` directory.

### Backup Validation

In the *Backup Validation* stage the payload restored from the backup is compared against the reference payload. Currently the following validation strategies are available:

Strategy | Description | Features | Performance
-- | -- | -- | --
diff-compare | Uses GNU diff for comparison | permission? uid/gid? xattrs? | medium
(hash-compare) | Uses (precalculated) md5 and sha512 hashes for comparison (not implemented) | permission? uid/gid? xattrs? | fast


## Development

### ShellCheck

This project uses [ShellCheck](https://github.com/koalaman/shellcheck) to lint bash scripts

### Long argument names

This project uses long argument names wherever possible.

Example:

    rsync --quiet ..

is preferred over

    rsync -q ..



## TODO

- [ ] Convert local variables to lowercase
- [ ] Implement options (see <https://en.wikipedia.org/wiki/Getopts> and <https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash>)
- [x] Disable progress indication (but keep introducing a --verbose flag?)
- [ ] Speed improvements:
    - [ ] Compare restored backup against list of md5/sha256 checksums
- [ ] Include prune operation
- [ ] Measure execution time and CPU/memory usage
