#!/usr/bin/env sh

executeCommand() {
  domain="$1"
  selector="${2:-}"
  publickey="${3}"
  value="v=DKIM1; t=s; p=${publickey}"

  # ------------------------------------------------------------------------------

  if [ "${domain}" = "" ]; then
    echo "required arguments missing"
    echo
    echo $command "<domain>" "<selector>" "<publickey>"
    echo $command "example.com" "dkim1" "MIIBI......"
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

  echoHint "$(executeDig ${fulldomain} ${systemNs})"

  echo
  echoHint "remove ${selector}._domainkey TXT record"
  postXml "$(xmlZoneUpdateRemoveTxtRecord "${domain}" "${systemNs}" "${selector}._domainkey" "*" "600")" > /dev/null
  if [ $? -gt 0 ]; then
    echoError "remove old TXT record failed"
    exit 1;
  fi
  echoSuccess
  echo
  echoHint "add ${selector}._domainkey TXT record"
  postXml "$(xmlZoneUpdateAddTxtRecord "${domain}" "${systemNs}" "${selector}._domainkey" "${value}" "600")" > /dev/null
  if [ $? -gt 0 ]; then
    echoError "add new TXT record failed"
    exit 1;
  fi
  echoSuccess

  sleep 5
  echoGood "$(executeDig ${fulldomain} ${systemNs})"
}