#!/usr/bin/env bash

executeCommand() {
  domain="$1"
  policy="${2:-none}"
  rua="${DMARC_RUA}"
  value="v=DMARC1; p=${policy}; rua=mailto:${rua};"

  # ------------------------------------------------------------------------------

  if [ "${domain}" = "" ]; then
    echo "required arguments missing"
    echo
    echo $command "<domain>" "[<policy>]"
    echo $command "example.com" "none"
    echo $command "example.com" "quarantine"
    echo $command "example.com" "reject"
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

  echoHint "$(executeDig ${fulldomain} ${systemNs})"

  echo
  echoHint "remove _dmarc TXT record"
  postXml "$(xmlZoneUpdateRemoveTxtRecord "${domain}" "${systemNs}" "_dmarc" "*" "600")" > /dev/null
  if [ $? -gt 0 ]; then
    echoError "remove old TXT record failed"
    exit 1;
  fi
  echoSuccess
  echo
  echoHint "add _dmarc TXT record"
  postXml "$(xmlZoneUpdateAddTxtRecord "${domain}" "${systemNs}" "_dmarc" "${value}" "600")" > /dev/null
  if [ $? -gt 0 ]; then
    echoError "add new TXT record failed"
    exit 1;
  fi
  echoSuccess

  sleep 5
  echoGood "$(executeDig ${fulldomain} ${systemNs})"
}