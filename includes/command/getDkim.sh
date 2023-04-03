#!/usr/bin/env bash

executeCommand() {
  domain="$1"
  selector="${2:-}"

  # ------------------------------------------------------------------------------

  if [ "${domain}" = "" ]; then
    echo "required arguments missing"
    echo
    echo $command "<domain>" "<selector>"
    exit 1
  fi

  fulldomain="${selector}._domainkey.${domain}"

  # ------------------------------------------------------------------------------

  echo
  echoHint "Domain: ${domain}"

  echo
  systemNs=$(getSystemNs ${domain})
  if [ "${systemNs}" = "" ]; then
    echoError "zone_inquire failed"
    exit 1;
  fi
  echoGood SystemNS: ${systemNs}

  echoGood "$(executeDig ${fulldomain} ${systemNs})"
}