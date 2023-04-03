# shell-schlundtech-autodns

This script is adding predefined DMARC and DKIM TXT-DNS entries, as well as adding/removing free text TXT entries to existing domains at Schlund-Tech by using the provided XML API. Intention is to speed up adding correct values or integrate in scripts by using a simplified syntax.

## Required Configuration

Step one, rename env.sample to **.env** and add existing schlundtech login credentials as well as a valid DMARC rua (**R**eporting **U**RI(s) for **a**ggregate data) mail-address (don't mix with "ruf": **R**eporting **U**RI(s) for **f**ailure data). The "``mailto:``" prefix must not be included, as it will be added by the script, so it shall only hold the pure mail-address, e.g. ``dmarc-report@mydomain.de``, when considering to add DMARC entries.

*Remind: Ensure to escape special characters in the schlundtech password that could change behaviour on a shell.*

## General usage

The general usage can be requested by adding ``-h``:

```text
 ./autodns.sh -h
          Usage: ./autodns.sh [<options>] <command> <commandOptions>
          options:
                  -h   --help           Show this message
                  -v   --verbose        verbose output
                  -N   --dryrun         Dry run mode

          command:
                  addTxtRecord <domain> <subdomain name> <value>
                  removeTxtRecord <domain> <subdomain name> [<value>]
                  addDmarc <domain> [<policy>]
                  getDmarc <domain>
                  addDkim <domain> <selector> <publickey>
                  getDkim <domain> <selector>
```

## DMARC

To add a DMARC entry only enter domain as well as the **p**olicy value ("p="). Allowed values are 'none', 'quarantine', or 'reject'. 'none' is used to only collect DMARC reports and gain insight into the current emailflows and their status but no rejecting.

Example:

```shell
./autodns.sh addDmarc mydomain.de quarantine
```

An existing potential dmarc entry is removed and the new one is added; a successful result looks like:

```text
Command: addDmarc

Domain: mydomain.de

SystemNS: nsaX.schlundtech.de
dig txt +noall +answer +multiline _dmarc.mydomain.de @nsaX.schlundtech.de

remove _dmarc TXT record
success

add _dmarc TXT record
success
dig txt +noall +answer +multiline _dmarc.mydomain.de @nsaX.schlundtech.de
_dmarc.mydomain.de. 21600 IN TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc-report@mydomain.de;"
```

A valid DMARC record must always be set on the specific subdomain ``_dmarc`` of a domain according to the specification.

Verify it worked as expected by requesting the domain again:

```shell
./autodns.sh getDmarc mydomain.de
```

A successful output will look like:

```shell
Command: getDmarc

Domain: mydomain.de

SystemNS: nsaX.schlundtech.de
dig txt +noall +answer +multiline _dmarc.mydomain.de @nsaX.schlundtech.de
_dmarc.mydomain.de.  86400 IN TXT "v=DMARC1;p=quarantine;rua=mailto:dmarc-report@mydomain.de;fo=1;"
```

## DKIM

To secure the domain with DKIM a private/public-key couple must have been created by the mailserver or a related supportive tool (like *opendkim* etc.). This key set will have a selector, which could be "default" as well as any "encrypted" random string or numbered values like "dkim42".

To set a valid DKIM value the domain must be entered, followed by the DKIM-selector (which will then build the sub-domain in front of ``"._domainkey.[...]"``) and finally the public key (without spaces) must be entered:

```shell
./autodns.sh addDkim mydomain.de "dkimSelector" "INSERT_PUBLIC_KEY_HERE"
```

Verify it worked as expected by requesting the domain again sending in the preset selector:

```shell
./autodns.sh getDkim mydomain.de "dkimSelector"
```

A successful request will ask for ``dkimSelector._domainkey.mydomain.de`` and the output will e.g. look like:

```shell
Command: getDkim

Domain: mydomain.de

SystemNS: nsaX.schlundtech.de
dig txt +noall +answer +multiline dkim23._domainkey.mydomain.de @nsaX.schlundtech.de
dkimSelector._domainkey.mydomain.de. 86400 IN TXT "v=DKIM1; t=s; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0Zg+uiN5wxghPiBSawI+wkxdqUknAcCBSh+zccjX2Q4uPtlLMfvzF/2I9xInJp5qF8gOC8JfIuMug9h5Fqzi0LHkKkz6VTO9LsVHwXo/EyG/B9eZuFGC/fhNc2hfHB3UIkv7P6DAFTHPmIj/ZBAKFNY6SHaVoTF5cvzsEsT0is6orPAMiwiiZYOXMuojYWkT5RTYh" 
"aM8DR5QIZ1eDIeAiIB6ZZVTpy2eqZu+CD8s6HYBAQ2Wk8FU4e3wQiTmLkQ2tiVUP5+Bn47id+7UXChN2hCLwf/JcAIpXw5m/+aiKw0a/LyPdSJPefpo5/YOaFKe4QT+4T/horIiKySEj3NhhwIDAQAB"
```

*Recognize: There is a split string given in the output, which is the default output of ``dig`` cutting a string at a length of 255 chars.*

## In case of Problems

It can be very helpful to run the command with a trailing '**-v**' after the script  ``./autodns.sh -v <command>`` to get the verbose details. This shows more details of the returned API-response and supports detecting the issue.

### Special chars in the password

In case there are problems, these could be related to a wrong password or wrongly interpreted password. As the password is added as part of the XML request and is exported from the shell into the XML, shell related chars in the password are currently creating problems.

In case the password includes e.g. a dollar "$" char, this must be escaped "\\" to ensure it is correctly parsed into the XML - or change your password to omit dollar signs :-).

```xml
<auth>
    <user>12345678</user>
    <password>YourLongSpecialPrivatePasswordWithSpecial\$Chars</password>
    <context>10</context>
</auth>
```

### Missing Params

In case of forgotten parameters, there is currently no excuse of double check. The existing entry is always first going to be removed and if e.g. an empty or omitted pulbic key is entered for a DKIM record, then an empty entry is created, which will later lead to problems sending mails.

### No valid entry found

Even though the add command reported to be successful, no result is visible when requesting the domain again via ``getDkim``. This can be verified by e.g. calling ``dig`` directly as the script does:

```shell
dig txt +noall +answer +multiline dkim42._domainkey.mydomain.de @nsaX.schlundtech.de
```

To solve this, just ask another DNS, it is very likly that the former empty request is still cached and returned again by the schlundtech-DNS. For testing purposes, just replace schlund-DNS with e.g. google, when requesting the domain via dig to ensure it worked as seen in the example:

```shell
dig txt +noall +answer +multiline dkim42._domainkey.mydomain.de @8.8.8.8
```
