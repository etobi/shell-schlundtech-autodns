#!/usr/bin/env sh

xmlTest() {
printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <request>
    %s
    <task>
          <code>0205</code><!-- zone_inquire -->
          <view>
            <children>1</children>

          </view>
          <where>
            <key>name</key>
            <operator>like</operator>
            <value>*%s</value>
          </where>
        </task>
  </request>
  " \
  "$(xmlAuthTag)" \
  "$1"
}

executeCommand() {
  domain="$1"
  name="$2"

  # ------------------------------------------------------------------------------

  if [ "${name}" != "" ]; then
    fulldomain="${name}.${domain}"
  else
    fulldomain="${domain}"
  fi

  # ------------------------------------------------------------------------------

  echo
  echoHint "Domain: ${domain}"

  echo
  postXml "$(xmlTest "${domain}")" > /dev/null

}