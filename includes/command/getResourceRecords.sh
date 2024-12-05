#!/usr/bin/env bash

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

  zoneInfo=$(postXml "$(xmlZoneInfo "${domain}" "${systemNs}")")
  echo $zoneInfo \
    | grep -oE "<rr>(.+?)</rr>" \
    | awk -F '[<>]' '
  {
    for (i = 1; i <= NF; i++) {
      if ($i == "name") { name = $(i+1) }
      if ($i == "type") { type = $(i+1) }
      if ($i == "pref") { pref = $(i+1) }
      if ($i == "value") { value = $(i+1) }
      if ($i == "/rr") {
        printf "%s\t%s\t%s\t%s\n\n", name, type, pref, value;
        pref = name = type = value = ""
      }
    }
  }
  '
}