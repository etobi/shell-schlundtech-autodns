# shell-schlundtech-autodns

Step one, rename env.sample to **.env** and add schlundtech credentials as well as a valid DMARC rua (**R**eporting **U**RI(s) for **a**ggregate data) mail-address (don't mix with "ruf": **R**eporting **U**RI(s) for **f**ailure data).

## DMARC

To add a DMARC entry only enter domain as well as the **p**olicy value. Allowed values are 'none', 'quarantine', or 'reject'. 'none' is used to collect DMARC reports and gain insight into the current emailflows and their status.

Example:

```shell
./autodns.sh addDmarc mydomain.de quarantine
```

Verify it worked as expected by requesting the domain again:

```shell
./autodns.sh getDmarc mydomain.de
```

A successful output will look like:

```shell
Command: getDmarc

Domain: getDmarc.de

zone_inquire failed
#TO DO!
```

## DKIM

To secure the domain with DKIM a private/public-key couple must have been create by the mailserver or a related supportive tool (like *opendkim* etc.). This key set will have a selector, which could be "default" as well as any encrypted random string or values like "dkim42".

To set a valid DKIM value the domain must be entered, followed by the DKIM-selector (which will then build the sub-domain in front of ``"._domainkey.[...]"``) and finally the public key (without spaces) must be entered:

```shell
./autodns.sh addDkim mydomain.de "dkimSelector" "INSERT_PUBLIC_KEY_HERE"
```

Verify it worked as expected by requesting the domain again sending in the preset selector:

```shell
./autodns.sh getDkim mydomain.de "dkimSelector"
```

A successful output will look like:

```shell
#TO DO
dkimSelector._domainkey.mydomain.de
```
