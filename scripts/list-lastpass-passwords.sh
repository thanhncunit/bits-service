#!/bin/bash -e

export IGNORE='(RSA PRIVATE KEY---|see below|c1oudc0w)'

lpass ls Shared-Flintstone --format 'Shared-Flintstone/'"'"'%an'"'"'' --color=never | \
xargs lpass show --color=never {} | \
# manually remove false alarms:
grep -vE "$IGNORE" | \
# take any line that contains an actual password:
grep -i -E '(.*pass.*|.*key.*|.*secret.*|.*token.*)' | \
# Use only last column ater splitting on ':':
rev | cut -d: -f1 | rev | \
# trim whitespace and quotes:
xargs -n1 | \
# remove duplicate lines:
sort -u
