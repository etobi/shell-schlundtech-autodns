#!/usr/bin/env sh

executeCommand() {
  domain="$1"

  # ------------------------------------------------------------------------------

  if [ "${domain}" = "" ]; then
    echo "required arguments missing"
    echo
    echo $command "<domain>"
    exit 1
  fi

  fulldomain="_dmarc.${domain}"

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