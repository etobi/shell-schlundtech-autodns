#!/usr/bin/env sh

if [ -f .env ]; then
  set -o allexport
  . .env
  set +o allexport
else
  echo "no .env file found. See env.sample."
  echo
  echo "$ cp env.sample .env"
  exit 1
fi

command=$1
shift 1

if [ "$command" = "" ]; then
  # todo print usage
  exit
fi

if [ -f ./bin/autodns-${command}.sh ]; then
  echo $command
  ./bin/autodns-${command}.sh $@
  exit
else
  echo "unknown command \"${command}\""
  exit 1
fi
