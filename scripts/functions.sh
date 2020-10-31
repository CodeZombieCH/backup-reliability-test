#!/bin/bash
#
# Shared functions

function log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

function err() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

function fail() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
    exit 1
}
