#!/usr/bin/env bash

# Debug Support
if [ -z ${HIGHWAY_DEBUG_ENABLED+x} ]
then
echo "Debugging disabled"
echo "To enable debugging: 'export HIGHWAY_DEBUG_ENABLED=1'"
else
echo "Debugging enabled"
set -x              # => enable tracing
fi

# more boilerplate
set -e                  # => exit on failure
set -u                  # => exit on undeclared variable access
set -o pipefail         # => sane exit codes when using |

# Adjust paths as needed
# call the script like this:
# $ . /path/to/script

echo "HIGHWAY_REPOSITORY=${HIGHWAY_DEV_HOME}"
echo "HIGHWAY_BRANCH=$1"
export HIGHWAY_REPOSITORY=${HIGHWAY_DEV_HOME}
export HIGHWAY_BRANCH=$1
