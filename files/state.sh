#!/bin/bash

# Exit if any of the intermediate steps fail
set -e

# Extract "foo" and "baz" arguments from the input into
# FOO and BAZ shell variables.
# jq will ensure that the values are properly quoted
# and escaped for consumption by the shell.
eval "$(jq -r '@sh "PROGRAM_NAME=\(.program_name) SUPERVISORD_CONF=\(.supervisord_conf)"')"

# Placeholder for whatever data-fetching logic your script implements
STATE="$(conda run -n supervisor supervisorctl -c $SUPERVISORD_CONF status $PROGRAM_NAME | awk '{ print $2 }')"

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg state "$STATE" '{"state":$state}'
