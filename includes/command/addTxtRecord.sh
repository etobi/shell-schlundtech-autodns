#!/usr/bin/env sh

executeCommand() {
  domain="$1"
  name="$2"
  value="$3"

  # ------------------------------------------------------------------------------

  if [ "${domain}" = "" ] || [ "${name}" = "" ]; then
    echo "required arguments missing"
    echo
    echo $command "<domain>" "<subdomain name>" "<value>"
    echo $command "example.com" "_dmarc" "\"v=DMARC1; p=none; rua=mailto:dmarc@example.com;\"" 600
    echo $command "example.com" "dkim99._domainkey" "\"v=DKIM1; t=s; p=ABCDEFG\""
    exit 1
  fi

  if [ "${name}" != "" ]; then
    fulldomain="${name}.${domain}"
  else
    fulldomain="${domain}"
  fi

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

  echo
  echoHint "add new TXT record"
  postXml "$(xmlZoneUpdateAddTxtRecord "${domain}" "${systemNs}" "${name}" "${value}")" > /dev/null
  if [ $? -gt 0 ]; then
    echoError "add new TXT record failed"
    exit 1;
  fi
  echoSuccess

  sleep 5
  echoGood "$(executeDig ${fulldomain} ${systemNs})"
}