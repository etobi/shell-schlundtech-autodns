#!/usr/bin/env sh

# ------------------------------------------------------------------------------

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
ENDCOLOR="\e[0m"

export helpFlag=0
export verboseFlag=0
export dryrunFlag=0

echoDebug() {
  if [ "$verboseFlag" = "1" ]; then
    content="$@"
    printf "${YELLOW}${content}${ENDCOLOR}\n" | sed "s/${APIPASSWORD}/PASSWORD/g" 1>&2
  fi
}

echoError() {
  content="$@"
  printf "${RED}${content}${ENDCOLOR}\n" 1>&2
}

echoGood() {
  content="$@"
  printf "${GREEN}${content}${ENDCOLOR}\n" 1>&2
}

echoHint() {
  content="$@"
  printf "${BLUE}${content}${ENDCOLOR}\n" 1>&2
}

echoSuccess() {
  [ "$dryrunFlag" = "0" ] && echoGood 'success' || echoGood 'success (dryrun)'
}
# ------------------------------------------------------------------------------

xmlAuthTag() {
  printf "<auth>
        <user>%s</user>
        <password>%s</password>
        <context>%s</context>
    </auth>" \
    "$APIUSERNAME" \
    "$APIPASSWORD" \
    "$APICONTEXT"
}

xmlZoneInquire() {
printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
  <request>
    %s
    <task>
      <code>0205</code><!-- zone_inquire -->
      <view>
        <children>1</children>
        <limit>1</limit>
      </view>
      <where>
        <key>name</key>
        <operator>eq</operator>
        <value>%s</value>
      </where>
    </task>
  </request>
  " \
  "$(xmlAuthTag)" \
  "$1"
}

xmlZoneUpdateRecord() {
  action=$1
  name=$2
  type=$3
  value=$4
  zonename=$5
  nameserver=$6

  printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <request>
      %s
      <task>
        <code>0202001</code><!-- zone update -->
        <default>
          <%s>
            <name>%s</name>
            <type>%s</type>
            <value>%s</value>
          </%s>
        </default>
        <zone>
          <name>%s</name>
          <system_ns>%s</system_ns>
        </zone>
      </task>
    </request>" \
    "$(xmlAuthTag)" \
    "$action" \
    "$name" \
    "$type" \
    "$value" \
    "$action" \
    "$zonename" \
    "$nameserver"
}

xmlZoneUpdateAddTxtRecord() {
  xmlZoneUpdateRecord \
    "rr_add" \
    "$3" \
    "TXT" \
    "$4" \
    "$1" \
    "$2"
}

xmlZoneUpdateRemoveTxtRecord() {
  xmlZoneUpdateRecord \
    "rr_rem" \
    "$3" \
    "TXT" \
    "$4" \
    "$1" \
    "$2"
}

# ------------------------------------------------------------------------------

executeCurl() {
  if [ "$dryrunFlag" = "0" ]; then
    curl \
         --silent \
         -X POST \
         -d @- \
         -H Accept:application/xml \
         -H Content-Type:application/xml \
         $APIURL
  fi
}

executeDig() {
  if [ "$dryrunFlag" = "0" ]; then
    echo dig txt +noall +answer +multiline "${1}" "@${2}"
    dig txt +noall +answer +multiline "${1}" "@${2}"
  fi
}

postXml() {
  request="$1"

  echoDebug
  echoDebug Request:
  echoDebug "$request"
  echoDebug

  response=$(echo "$request" | executeCurl)

  if [ "$dryrunFlag" = "0" ]; then
    echoDebug
    echoDebug Response:
    echoDebug "$response"
    echoDebug
  fi

  checkResponseSuccess "$response"
  if [ $? -gt 0 ]; then
    echoError "postXml failed"
    exit 1
  fi

  echo "$response"
}

getSystemNs() {
  if [ "$dryrunFlag" = "1" ]; then
    echo "ns.example.com"
    exit
  fi
  systemNs=$( \
    postXml "$(xmlZoneInquire $1)" \
    | egrep -o '<system_ns>[^<]*</system_ns>' \
    | cut -d '>' -f 2 \
    | cut -d '<'  -f 1 \
    )
  if [ $? -gt 0 ]; then
    echoError "getSystemNs failed"
    exit 1
  fi
  echo ${systemNs}
}

checkResponseSuccess() {
  if [ "$dryrunFlag" = "0" ]; then
    response="$1"
    if ! grep -q "<type>success</type>" <<< "$response"; then
      exit 1
    fi
  fi
}
