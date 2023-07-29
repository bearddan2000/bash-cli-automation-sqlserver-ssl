#! /bin/bash

function add_ssl_support(){
  local file=$1/Dockerfile
  read -r -d '' OLD <<EOP
FROM mcr.microsoft.com\/mssql\/server:2017-latest-ubuntu
EOP

  read -r -d '' NEW <<EOP
FROM mcr.microsoft.com\/mssql\/server:2017-latest-ubuntu

COPY conf \/var\/opt\/mssql

COPY cert\/server.crt \/etc\/ssl\/certs
COPY cert\/server.key \/etc\/ssl\/private

EOP

  perl -pi.bak -e "s/${OLD}/${NEW}/" $file
  rm -f ${file}.md.bak
}

for d in `ls -la | grep ^d | awk '{print $NF}' | egrep -v '^\.'`; do

  if [ -d "${d}/db" ]; then
    #statements
    cp -R .src/conf $d/db
    add_ssl_support $d/db
  elif [ -d "${d}/sqlserver" ]; then
    #statements
    cp -R .src/conf $d/sqlserver
    add_ssl_support $d/sqlserver
  fi

  if [ ! -d "${d}/openssl-srv" ]; then
    #statements
    cp -R .src/openssl-srv $d
  fi

  rm -f $d/install.sh

  cp .src/install.sh $d

  ./readme.sh $d

  ./folder.sh $d

done
