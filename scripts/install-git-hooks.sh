#!/bin/bash -ex

brew install git-secrets
git secrets --install
git secrets --register-aws
# See https://stackoverflow.com/questions/1250079/how-to-escape-single-quotes-within-single-quoted-strings
git secrets --add '("|'"'"')?(password|token|PASSWORD|TOKEN)+("|'"'"')?\s*(:|=>|=)\s*("|'"'"')?(.+)("|'"'"')?'
