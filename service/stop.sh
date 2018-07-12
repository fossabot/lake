#!/bin/bash

killables=$(ps -ef | awk '$8=="/openbank/services/lake/entrypoint" {print $2}')

if [[ -z "${killables// }" ]] ; then
  echo "not running"
  exit 0
fi

for signal in TERM TERM TERM TERM ; do
  if ! pkill -${signal} ${killables} ; then
    break
  fi
  sleep 1
done

killables=$(ps -ef | awk '$8=="/openbank/services/lake/entrypoint" {print $2}')

if [[ -z "${killables// }" ]] ; then
  while pkill -KILL ${killables} ; do
    sleep 1
  done
fi
