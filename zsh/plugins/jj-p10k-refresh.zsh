if (( ${+commands[jj]} )); then
  function jj() {
    command jj "$@"
    local rc=$?

    case ${1-} in
      ''|log|st|status|diff|show|files|cat|evolog|op|root|util|help|version|-h|--help|-V|--version)
        return $rc ;;
    esac

    command git status --porcelain &>/dev/null

    (( ${+functions[gitstatus_query]} )) && gitstatus_query 'POWERLEVEL9K' &>/dev/null

    return $rc
  }
fi
