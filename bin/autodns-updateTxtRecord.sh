#!/usr/bin/env sh

domain="$1"
name="$2"
value="$3"
ttl="${4:-600}" # 600 is default
type="TXT"

# ------------------------------------------------------------------------------

if [ "$domain" == "" ] || [ "$name" == "" ]; then
  echo "required arguments missing"
  echo
  echo $0 "<domain>" "<subdomain name>" "<value>" "[<ttl>]"
  echo $0 "example.com" "_dmarc" "\"v=DMARC1; p=none; rua=mailto:dmarc@example.com;\"" 3600
  exit 1
fi

if [ "$name" != "" ]; then
  fulldomain="$name.$domain"
else
  fulldomain="$domain"
fi

# ------------------------------------------------------------------------------

echo $domain;
echo

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
  ttl=$3
  type=$4
  value=$5
  zonename=$6
  nameserver=$7

  printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <request>
      %s
      <task>
        <code>0202001</code>
        <default>
          <%s>
            <name>%s</name>
            <ttl>%s</ttl>
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
    "$ttl" \
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
    "$ttl" \
    "$type" \
    "$4" \
    "$1" \
    "$2"
}

xmlZoneUpdateRemoveTxtRecord() {
  xmlZoneUpdateRecord \
    "rr_rem" \
    "$3" \
    "$ttl" \
    "$type" \
    "*" \
    "$1" \
    "$2"
}

executeCurl() {
  echo curl \
       --silent \
       -X POST \
       -d @- \
       -H Accept:application/xml \
       -H Content-Type:application/xml \
       $APIURL
}

getSystemNs() {
  echo "$(xmlZoneInquire $1)" \
     | $(executeCurl) \
     | egrep -o '<system_ns>[^<]*</system_ns>' \
     | cut -d '>' -f 2 \
     | cut -d '<'  -f 1
}

checkResponseSuccess() {
  response=$(cat < /dev/stdin)
  if grep -q "<type>success</type>" <<< "$response"; then
    echo 'ok'
  else
    echo "$response"
    exit 1
  fi
}

# ------------------------------------------------------------------------------

systemNs=$(getSystemNs $domain)
if [ "$systemNs" == "" ]; then
  echo "zone_inquire failed"
  exit 1;
fi

echo "remove old TXT record"
echo $(xmlZoneUpdateRemoveTxtRecord "$domain" "$systemNs" "$name") \
  | $(executeCurl) \
  | checkResponseSuccess
if [ $? -gt 0 ]; then
  exit 1;
fi

echo "add new TXT record"
echo $(xmlZoneUpdateAddTxtRecord "$domain" "$systemNs" "$name" "$value") \
  | $(executeCurl) \
  | checkResponseSuccess
if [ $? -gt 0 ]; then
  exit 1;
fi

sleep 1
dig  txt +noall +answer $fulldomain @$systemNs
