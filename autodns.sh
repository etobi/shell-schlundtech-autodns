#!/usr/bin/env sh

if [ -f .env ]; then
  set -o allexport
  . .env
  set +o allexport
else
  echo "no .env file found. See env.sample."
  echo
  echo "$ cp env.sample .env"
  exit 1
fi

. "./includes/helper.sh"

while getopts hvN-: OPT; do
  # support long options: https://stackoverflow.com/a/28466267/519360
  if [ "$OPT" = "-" ]; then   # long option: reformulate OPT and OPTARG
    OPT="${OPTARG%%=*}"       # extract long option name
    OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
    OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
  fi
  case "$OPT" in
    h | help )    helpFlag=1 ;;
    v | verbose ) verboseFlag=1 ;;
    N | dryrun )  dryrunFlag=1 ;;
    ??* )         echo "invalid arguments"; exit 2 ;;  # bad long option
    ? )           echo "invalid arguments"; exit 2 ;;  # bad short option (error reported via getopts)
  esac
done
shift $((OPTIND-1)) # remove parsed options and args from $@ list

command=$1
shift 1

if [ "$command" = "" ] || [ $helpFlag -eq 1 ]; then
  cat << EOF
          Usage: $0 [<options>] <command> <commandOptions>
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
                  getDmarc <domain> <selector>

EOF
  exit
fi

if [ ! -f "./includes/command/${command}.sh" ]; then
  echoError "unknown command \"${command}\""
  exit 1
fi

. "./includes/command/${command}.sh"

echoHint "Command: ${command}"
executeCommand "$@"
