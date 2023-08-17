#!/bin/bash

# Script to fix permissions for CML integration. 
# Uses find to only update folders with incorrect permissions
# to avoid touching files uncessarily and increasing image size.

set -e

for d in "$@"; do
    # Check if directory and its contents do not have permissions set to 777
    # If not, change permissions to 777
    find "${d}" \
        -type d \
        ! -perm 777 \
        -exec chmod 777 -- {} \+
done
