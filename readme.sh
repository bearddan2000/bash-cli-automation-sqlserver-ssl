#! /bin/bash

function replace_readme_str() {
  #statements
  local file=$1/README.md
  local old=$2
  local new=$3

  perl -pi.bak -e "s/${old}/${new}/" $file
  rm -f $1/README.md.bak
}

function replace_readme_first() {
  #statements
  local file=$1/README.md
  local old=$2
  local new=$3

  perl -pi.bak -0 -e "s/${old}/${new}/" $file
  rm -f $1/README.md.bak
}

d=$1

  read -r -d '' TECH <<EOP

Sql server uses self-signed ssl.

## Tech stack
EOP

  read -r -d '' DOCKER <<EOP
## Docker stack
- alpine:edge
EOP

replace_readme_first $d "sqlserver" "sqlserver-ssl"

replace_readme_str $d "## Tech stack" "${TECH}"

replace_readme_str $d "## Docker stack" "${DOCKER}"