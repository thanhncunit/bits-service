#!/bin/bash -ex

brew install git-secrets
git secrets --install
git secrets --register-aws || echo "Could not register AWS patterns (maybe they're already in .git/config)"
# See https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings
git secrets --add '("|'"'"')?(password|token|PASSWORD|TOKEN)+("|'"'"')?\s*(:|=>|=)\s*("|'"'"')?(.+)("|'"'"')?'
