# bash completion for istioctl                             -*- shell-script -*-

__istioctl_debug()
{
    if [[ -n ${BASH_COMP_DEBUG_FILE} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}"
    fi
}

# Homebrew on Macs have version 1.3 of bash-completion which doesn't include
# _init_completion. This is a very minimal version of that function.
__istioctl_init_completion()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

__istioctl_index_of_word()
{
    local w word=$1
    shift
    index=0
    for w in "$@"; do
        [[ $w = "$word" ]] && return
        index=$((index+1))
    done
    index=-1
}

__istioctl_contains_word()
{
    local w word=$1; shift
    for w in "$@"; do
        [[ $w = "$word" ]] && return
    done
    return 1
}

__istioctl_handle_go_custom_completion()
{
    __istioctl_debug "${FUNCNAME[0]}: cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}"

    local shellCompDirectiveError=1
    local shellCompDirectiveNoSpace=2
    local shellCompDirectiveNoFileComp=4
    local shellCompDirectiveFilterFileExt=8
    local shellCompDirectiveFilterDirs=16

    local out requestComp lastParam lastChar comp directive args

    # Prepare the command to request completions for the program.
    # Calling ${words[0]} instead of directly istioctl allows to handle aliases
    args=("${words[@]:1}")
    requestComp="${words[0]} __completeNoDesc ${args[*]}"

    lastParam=${words[$((${#words[@]}-1))]}
    lastChar=${lastParam:$((${#lastParam}-1)):1}
    __istioctl_debug "${FUNCNAME[0]}: lastParam ${lastParam}, lastChar ${lastChar}"

    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        # If the last parameter is complete (there is a space following it)
        # We add an extra empty parameter so we can indicate this to the go method.
        __istioctl_debug "${FUNCNAME[0]}: Adding extra empty parameter"
        requestComp="${requestComp} \"\""
    fi

    __istioctl_debug "${FUNCNAME[0]}: calling ${requestComp}"
    # Use eval to handle any environment variables and such
    out=$(eval "${requestComp}" 2>/dev/null)

    # Extract the directive integer at the very end of the output following a colon (:)
    directive=${out##*:}
    # Remove the directive
    out=${out%:*}
    if [ "${directive}" = "${out}" ]; then
        # There is not directive specified
        directive=0
    fi
    __istioctl_debug "${FUNCNAME[0]}: the completion directive is: ${directive}"
    __istioctl_debug "${FUNCNAME[0]}: the completions are: ${out[*]}"

    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        # Error code.  No completion.
        __istioctl_debug "${FUNCNAME[0]}: received error from custom completion go code"
        return
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __istioctl_debug "${FUNCNAME[0]}: activating no space"
                compopt -o nospace
            fi
        fi
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __istioctl_debug "${FUNCNAME[0]}: activating no file completion"
                compopt +o default
            fi
        fi
    fi

    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        # File extension filtering
        local fullFilter filter filteringCmd
        # Do not use quotes around the $out variable or else newline
        # characters will be kept.
        for filter in ${out[*]}; do
            fullFilter+="$filter|"
        done

        filteringCmd="_filedir $fullFilter"
        __istioctl_debug "File filtering command: $filteringCmd"
        $filteringCmd
    elif [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
        # File completion for directories only
        local subDir
        # Use printf to strip any trailing newline
        subdir=$(printf "%s" "${out[0]}")
        if [ -n "$subdir" ]; then
            __istioctl_debug "Listing directories in $subdir"
            __istioctl_handle_subdirs_in_dir_flag "$subdir"
        else
            __istioctl_debug "Listing directories in ."
            _filedir -d
        fi
    else
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${out[*]}" -- "$cur")
    fi
}

__istioctl_handle_reply()
{
    __istioctl_debug "${FUNCNAME[0]}"
    local comp
    case $cur in
        -*)
            if [[ $(type -t compopt) = "builtin" ]]; then
                compopt -o nospace
            fi
            local allflags
            if [ ${#must_have_one_flag[@]} -ne 0 ]; then
                allflags=("${must_have_one_flag[@]}")
            else
                allflags=("${flags[*]} ${two_word_flags[*]}")
            fi
            while IFS='' read -r comp; do
                COMPREPLY+=("$comp")
            done < <(compgen -W "${allflags[*]}" -- "$cur")
            if [[ $(type -t compopt) = "builtin" ]]; then
                [[ "${COMPREPLY[0]}" == *= ]] || compopt +o nospace
            fi

            # complete after --flag=abc
            if [[ $cur == *=* ]]; then
                if [[ $(type -t compopt) = "builtin" ]]; then
                    compopt +o nospace
                fi

                local index flag
                flag="${cur%=*}"
                __istioctl_index_of_word "${flag}" "${flags_with_completion[@]}"
                COMPREPLY=()
                if [[ ${index} -ge 0 ]]; then
                    PREFIX=""
                    cur="${cur#*=}"
                    ${flags_completion[${index}]}
                    if [ -n "${ZSH_VERSION}" ]; then
                        # zsh completion needs --flag= prefix
                        eval "COMPREPLY=( \"\${COMPREPLY[@]/#/${flag}=}\" )"
                    fi
                fi
            fi
            return 0;
            ;;
    esac

    # check if we are handling a flag with special work handling
    local index
    __istioctl_index_of_word "${prev}" "${flags_with_completion[@]}"
    if [[ ${index} -ge 0 ]]; then
        ${flags_completion[${index}]}
        return
    fi

    # we are parsing a flag and don't have a special handler, no completion
    if [[ ${cur} != "${words[cword]}" ]]; then
        return
    fi

    local completions
    completions=("${commands[@]}")
    if [[ ${#must_have_one_noun[@]} -ne 0 ]]; then
        completions+=("${must_have_one_noun[@]}")
    elif [[ -n "${has_completion_function}" ]]; then
        # if a go completion function is provided, defer to that function
        __istioctl_handle_go_custom_completion
    fi
    if [[ ${#must_have_one_flag[@]} -ne 0 ]]; then
        completions+=("${must_have_one_flag[@]}")
    fi
    while IFS='' read -r comp; do
        COMPREPLY+=("$comp")
    done < <(compgen -W "${completions[*]}" -- "$cur")

    if [[ ${#COMPREPLY[@]} -eq 0 && ${#noun_aliases[@]} -gt 0 && ${#must_have_one_noun[@]} -ne 0 ]]; then
        while IFS='' read -r comp; do
            COMPREPLY+=("$comp")
        done < <(compgen -W "${noun_aliases[*]}" -- "$cur")
    fi

    if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
		if declare -F __istioctl_custom_func >/dev/null; then
			# try command name qualified custom func
			__istioctl_custom_func
		else
			# otherwise fall back to unqualified for compatibility
			declare -F __custom_func >/dev/null && __custom_func
		fi
    fi

    # available in bash-completion >= 2, not always present on macOS
    if declare -F __ltrim_colon_completions >/dev/null; then
        __ltrim_colon_completions "$cur"
    fi

    # If there is only 1 completion and it is a flag with an = it will be completed
    # but we don't want a space after the =
    if [[ "${#COMPREPLY[@]}" -eq "1" ]] && [[ $(type -t compopt) = "builtin" ]] && [[ "${COMPREPLY[0]}" == --*= ]]; then
       compopt -o nospace
    fi
}

# The arguments should be in the form "ext1|ext2|extn"
__istioctl_handle_filename_extension_flag()
{
    local ext="$1"
    _filedir "@(${ext})"
}

__istioctl_handle_subdirs_in_dir_flag()
{
    local dir="$1"
    pushd "${dir}" >/dev/null 2>&1 && _filedir -d && popd >/dev/null 2>&1 || return
}

__istioctl_handle_flag()
{
    __istioctl_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    # if a command required a flag, and we found it, unset must_have_one_flag()
    local flagname=${words[c]}
    local flagvalue
    # if the word contained an =
    if [[ ${words[c]} == *"="* ]]; then
        flagvalue=${flagname#*=} # take in as flagvalue after the =
        flagname=${flagname%=*} # strip everything after the =
        flagname="${flagname}=" # but put the = back
    fi
    __istioctl_debug "${FUNCNAME[0]}: looking for ${flagname}"
    if __istioctl_contains_word "${flagname}" "${must_have_one_flag[@]}"; then
        must_have_one_flag=()
    fi

    # if you set a flag which only applies to this command, don't show subcommands
    if __istioctl_contains_word "${flagname}" "${local_nonpersistent_flags[@]}"; then
      commands=()
    fi

    # keep flag value with flagname as flaghash
    # flaghash variable is an associative array which is only supported in bash > 3.
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        if [ -n "${flagvalue}" ] ; then
            flaghash[${flagname}]=${flagvalue}
        elif [ -n "${words[ $((c+1)) ]}" ] ; then
            flaghash[${flagname}]=${words[ $((c+1)) ]}
        else
            flaghash[${flagname}]="true" # pad "true" for bool flag
        fi
    fi

    # skip the argument to a two word flag
    if [[ ${words[c]} != *"="* ]] && __istioctl_contains_word "${words[c]}" "${two_word_flags[@]}"; then
			  __istioctl_debug "${FUNCNAME[0]}: found a flag ${words[c]}, skip the next argument"
        c=$((c+1))
        # if we are looking for a flags value, don't show commands
        if [[ $c -eq $cword ]]; then
            commands=()
        fi
    fi

    c=$((c+1))

}

__istioctl_handle_noun()
{
    __istioctl_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    if __istioctl_contains_word "${words[c]}" "${must_have_one_noun[@]}"; then
        must_have_one_noun=()
    elif __istioctl_contains_word "${words[c]}" "${noun_aliases[@]}"; then
        must_have_one_noun=()
    fi

    nouns+=("${words[c]}")
    c=$((c+1))
}

__istioctl_handle_command()
{
    __istioctl_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"

    local next_command
    if [[ -n ${last_command} ]]; then
        next_command="_${last_command}_${words[c]//:/__}"
    else
        if [[ $c -eq 0 ]]; then
            next_command="_istioctl_root_command"
        else
            next_command="_${words[c]//:/__}"
        fi
    fi
    c=$((c+1))
    __istioctl_debug "${FUNCNAME[0]}: looking for ${next_command}"
    declare -F "$next_command" >/dev/null && $next_command
}

__istioctl_handle_word()
{
    if [[ $c -ge $cword ]]; then
        __istioctl_handle_reply
        return
    fi
    __istioctl_debug "${FUNCNAME[0]}: c is $c words[c] is ${words[c]}"
    if [[ "${words[c]}" == -* ]]; then
        __istioctl_handle_flag
    elif __istioctl_contains_word "${words[c]}" "${commands[@]}"; then
        __istioctl_handle_command
    elif [[ $c -eq 0 ]]; then
        __istioctl_handle_command
    elif __istioctl_contains_word "${words[c]}" "${command_aliases[@]}"; then
        # aliashash variable is an associative array which is only supported in bash > 3.
        if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
            words[c]=${aliashash[${words[c]}]}
            __istioctl_handle_command
        else
            __istioctl_handle_noun
        fi
    else
        __istioctl_handle_noun
    fi
    __istioctl_handle_word
}

_istioctl_analyze()
{
    last_command="istioctl_analyze"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--all-namespaces")
    flags+=("-A")
    flags+=("--color")
    flags+=("--failure-threshold=")
    two_word_flags+=("--failure-threshold")
    flags+=("--list-analyzers")
    flags+=("-L")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--output-threshold=")
    two_word_flags+=("--output-threshold")
    flags+=("--recursive")
    flags+=("-R")
    flags+=("--suppress=")
    two_word_flags+=("--suppress")
    two_word_flags+=("-S")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    flags+=("--use-kube")
    flags+=("-k")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_authz()
{
    last_command="istioctl_authz"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_bug-report_version()
{
    last_command="istioctl_bug-report_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--short")
    flags+=("-s")
    local_nonpersistent_flags+=("--short")
    local_nonpersistent_flags+=("-s")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--critical-errs=")
    two_word_flags+=("--critical-errs")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    flags+=("--dry-run")
    flags+=("--duration=")
    two_word_flags+=("--duration")
    flags+=("--end-time=")
    two_word_flags+=("--end-time")
    flags+=("--exclude=")
    two_word_flags+=("--exclude")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--full-secrets")
    flags+=("--ignore-errs=")
    two_word_flags+=("--ignore-errs")
    flags+=("--include=")
    two_word_flags+=("--include")
    flags+=("--istio-namespace=")
    two_word_flags+=("--istio-namespace")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--start-time=")
    two_word_flags+=("--start-time")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_bug-report()
{
    last_command="istioctl_bug-report"

    command_aliases=()

    commands=()
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--critical-errs=")
    two_word_flags+=("--critical-errs")
    flags+=("--dir=")
    two_word_flags+=("--dir")
    flags+=("--dry-run")
    flags+=("--duration=")
    two_word_flags+=("--duration")
    flags+=("--end-time=")
    two_word_flags+=("--end-time")
    flags+=("--exclude=")
    two_word_flags+=("--exclude")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--full-secrets")
    flags+=("--ignore-errs=")
    two_word_flags+=("--ignore-errs")
    flags+=("--include=")
    two_word_flags+=("--include")
    flags+=("--istio-namespace=")
    two_word_flags+=("--istio-namespace")
    flags+=("--start-time=")
    two_word_flags+=("--start-time")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_controlz()
{
    last_command="istioctl_dashboard_controlz"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ctrlz_port=")
    two_word_flags+=("--ctrlz_port")
    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")
    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_envoy()
{
    last_command="istioctl_dashboard_envoy"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")
    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_grafana()
{
    last_command="istioctl_dashboard_grafana"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_jaeger()
{
    last_command="istioctl_dashboard_jaeger"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_kiali()
{
    last_command="istioctl_dashboard_kiali"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_prometheus()
{
    last_command="istioctl_dashboard_prometheus"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard_zipkin()
{
    last_command="istioctl_dashboard_zipkin"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_dashboard()
{
    last_command="istioctl_dashboard"

    command_aliases=()

    commands=()
    commands+=("controlz")
    commands+=("envoy")
    commands+=("grafana")
    commands+=("jaeger")
    commands+=("kiali")
    commands+=("prometheus")
    commands+=("zipkin")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--browser")
    flags+=("--port=")
    two_word_flags+=("--port")
    two_word_flags+=("-p")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_add-to-mesh_deployment()
{
    last_command="istioctl_experimental_add-to-mesh_deployment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--injectConfigFile=")
    two_word_flags+=("--injectConfigFile")
    flags+=("--injectConfigMapName=")
    two_word_flags+=("--injectConfigMapName")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--meshConfigMapName=")
    two_word_flags+=("--meshConfigMapName")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--valuesFile=")
    two_word_flags+=("--valuesFile")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_add-to-mesh_external-service()
{
    last_command="istioctl_experimental_add-to-mesh_external-service"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--annotations=")
    two_word_flags+=("--annotations")
    two_word_flags+=("-a")
    flags+=("--labels=")
    two_word_flags+=("--labels")
    two_word_flags+=("-l")
    flags+=("--serviceaccount=")
    two_word_flags+=("--serviceaccount")
    two_word_flags+=("-s")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--injectConfigFile=")
    two_word_flags+=("--injectConfigFile")
    flags+=("--injectConfigMapName=")
    two_word_flags+=("--injectConfigMapName")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--meshConfigMapName=")
    two_word_flags+=("--meshConfigMapName")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--valuesFile=")
    two_word_flags+=("--valuesFile")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_add-to-mesh_service()
{
    last_command="istioctl_experimental_add-to-mesh_service"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--injectConfigFile=")
    two_word_flags+=("--injectConfigFile")
    flags+=("--injectConfigMapName=")
    two_word_flags+=("--injectConfigMapName")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--meshConfigMapName=")
    two_word_flags+=("--meshConfigMapName")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--valuesFile=")
    two_word_flags+=("--valuesFile")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_add-to-mesh()
{
    last_command="istioctl_experimental_add-to-mesh"

    command_aliases=()

    commands=()
    commands+=("deployment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("dep")
        aliashash["dep"]="deployment"
        command_aliases+=("deploy")
        aliashash["deploy"]="deployment"
    fi
    commands+=("external-service")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("es")
        aliashash["es"]="external-service"
    fi
    commands+=("service")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("svc")
        aliashash["svc"]="service"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--injectConfigFile=")
    two_word_flags+=("--injectConfigFile")
    flags+=("--injectConfigMapName=")
    two_word_flags+=("--injectConfigMapName")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--meshConfigMapName=")
    two_word_flags+=("--meshConfigMapName")
    flags+=("--valuesFile=")
    two_word_flags+=("--valuesFile")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_authz_check()
{
    last_command="istioctl_experimental_authz_check"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_authz()
{
    last_command="istioctl_experimental_authz"

    command_aliases=()

    commands=()
    commands+=("check")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_config_list()
{
    last_command="istioctl_experimental_config_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_config()
{
    last_command="istioctl_experimental_config"

    command_aliases=()

    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_create-remote-secret()
{
    last_command="istioctl_experimental_create-remote-secret"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--auth-plugin-config=")
    two_word_flags+=("--auth-plugin-config")
    flags+=("--auth-plugin-name=")
    two_word_flags+=("--auth-plugin-name")
    flags+=("--auth-type=")
    two_word_flags+=("--auth-type")
    flags+=("--create-service-account")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--name=")
    two_word_flags+=("--name")
    flags+=("--server=")
    two_word_flags+=("--server")
    flags+=("--service-account=")
    two_word_flags+=("--service-account")
    flags+=("--type=")
    two_word_flags+=("--type")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_describe_pod()
{
    last_command="istioctl_experimental_describe_pod"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ignoreUnmeshed")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_describe_service()
{
    last_command="istioctl_experimental_describe_service"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ignoreUnmeshed")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_describe()
{
    last_command="istioctl_experimental_describe"

    command_aliases=()

    commands=()
    commands+=("pod")
    commands+=("service")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("svc")
        aliashash["svc"]="service"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_injector_list()
{
    last_command="istioctl_experimental_injector_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_injector()
{
    last_command="istioctl_experimental_injector"

    command_aliases=()

    commands=()
    commands+=("list")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_istiod_log()
{
    last_command="istioctl_experimental_istiod_log"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--ctrlz_port=")
    two_word_flags+=("--ctrlz_port")
    flags+=("--level=")
    two_word_flags+=("--level")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--reset")
    flags+=("-r")
    flags+=("--stack-trace-level=")
    two_word_flags+=("--stack-trace-level")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_istiod()
{
    last_command="istioctl_experimental_istiod"

    command_aliases=()

    commands=()
    commands+=("log")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("l")
        aliashash["l"]="log"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_kube-uninject()
{
    last_command="istioctl_experimental_kube-uninject"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_metrics()
{
    last_command="istioctl_experimental_metrics"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_precheck()
{
    last_command="istioctl_experimental_precheck"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    flags_with_completion+=("--filename")
    flags_completion+=("__istioctl_handle_filename_extension_flag json|yaml|yml")
    two_word_flags+=("-f")
    flags_with_completion+=("-f")
    flags_completion+=("__istioctl_handle_filename_extension_flag json|yaml|yml")
    flags+=("--recursive")
    flags+=("-R")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_proxy-status()
{
    last_command="istioctl_experimental_proxy-status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--authority=")
    two_word_flags+=("--authority")
    flags+=("--cert-dir=")
    two_word_flags+=("--cert-dir")
    flags+=("--insecure")
    flags+=("--plaintext")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    flags+=("--xds-address=")
    two_word_flags+=("--xds-address")
    flags+=("--xds-label=")
    two_word_flags+=("--xds-label")
    flags+=("--xds-port=")
    two_word_flags+=("--xds-port")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_remove-from-mesh_deployment()
{
    last_command="istioctl_experimental_remove-from-mesh_deployment"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_remove-from-mesh_external-service()
{
    last_command="istioctl_experimental_remove-from-mesh_external-service"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_remove-from-mesh_service()
{
    last_command="istioctl_experimental_remove-from-mesh_service"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_remove-from-mesh()
{
    last_command="istioctl_experimental_remove-from-mesh"

    command_aliases=()

    commands=()
    commands+=("deployment")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("dep")
        aliashash["dep"]="deployment"
        command_aliases+=("deploy")
        aliashash["deploy"]="deployment"
    fi
    commands+=("external-service")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("es")
        aliashash["es"]="external-service"
    fi
    commands+=("service")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("svc")
        aliashash["svc"]="service"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_uninstall()
{
    last_command="istioctl_experimental_uninstall"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--force")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--purge")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    flags+=("--skip-confirmation")
    flags+=("-y")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_version()
{
    last_command="istioctl_experimental_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--authority=")
    two_word_flags+=("--authority")
    flags+=("--cert-dir=")
    two_word_flags+=("--cert-dir")
    flags+=("--insecure")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--plaintext")
    flags+=("--remote")
    local_nonpersistent_flags+=("--remote")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--short")
    flags+=("-s")
    local_nonpersistent_flags+=("--short")
    local_nonpersistent_flags+=("-s")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    flags+=("--xds-address=")
    two_word_flags+=("--xds-address")
    flags+=("--xds-label=")
    two_word_flags+=("--xds-label")
    flags+=("--xds-port=")
    two_word_flags+=("--xds-port")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_wait()
{
    last_command="istioctl_experimental_wait"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--for=")
    two_word_flags+=("--for")
    flags+=("--generation=")
    two_word_flags+=("--generation")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--threshold=")
    two_word_flags+=("--threshold")
    flags+=("--timeout=")
    two_word_flags+=("--timeout")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_workload_entry_configure()
{
    last_command="istioctl_experimental_workload_entry_configure"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--autoregister")
    flags+=("--capture-dns")
    flags+=("--clusterID=")
    two_word_flags+=("--clusterID")
    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--ingressIP=")
    two_word_flags+=("--ingressIP")
    flags+=("--ingressService=")
    two_word_flags+=("--ingressService")
    flags+=("--name=")
    two_word_flags+=("--name")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--tokenDuration=")
    two_word_flags+=("--tokenDuration")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_workload_entry()
{
    last_command="istioctl_experimental_workload_entry"

    command_aliases=()

    commands=()
    commands+=("configure")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_workload_group_create()
{
    last_command="istioctl_experimental_workload_group_create"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--annotations=")
    two_word_flags+=("--annotations")
    two_word_flags+=("-a")
    flags+=("--labels=")
    two_word_flags+=("--labels")
    two_word_flags+=("-l")
    flags+=("--name=")
    two_word_flags+=("--name")
    flags+=("--ports=")
    two_word_flags+=("--ports")
    two_word_flags+=("-p")
    flags+=("--serviceAccount=")
    two_word_flags+=("--serviceAccount")
    two_word_flags+=("-s")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_workload_group()
{
    last_command="istioctl_experimental_workload_group"

    command_aliases=()

    commands=()
    commands+=("create")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental_workload()
{
    last_command="istioctl_experimental_workload"

    command_aliases=()

    commands=()
    commands+=("entry")
    commands+=("group")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_experimental()
{
    last_command="istioctl_experimental"

    command_aliases=()

    commands=()
    commands+=("add-to-mesh")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("add")
        aliashash["add"]="add-to-mesh"
    fi
    commands+=("authz")
    commands+=("config")
    commands+=("create-remote-secret")
    commands+=("describe")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("des")
        aliashash["des"]="describe"
    fi
    commands+=("injector")
    commands+=("istiod")
    commands+=("kube-uninject")
    commands+=("metrics")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("m")
        aliashash["m"]="metrics"
    fi
    commands+=("precheck")
    commands+=("proxy-status")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ps")
        aliashash["ps"]="proxy-status"
    fi
    commands+=("remove-from-mesh")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("rm")
        aliashash["rm"]="remove-from-mesh"
    fi
    commands+=("uninstall")
    commands+=("version")
    commands+=("wait")
    commands+=("workload")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_help()
{
    last_command="istioctl_help"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    has_completion_function=1
    noun_aliases=()
}

_istioctl_install()
{
    last_command="istioctl_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--dry-run")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--force")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--readiness-timeout=")
    two_word_flags+=("--readiness-timeout")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    flags+=("--skip-confirmation")
    flags+=("-y")
    flags+=("--verify")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_kube-inject()
{
    last_command="istioctl_kube-inject"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--injectConfigFile=")
    two_word_flags+=("--injectConfigFile")
    flags+=("--injectConfigMapName=")
    two_word_flags+=("--injectConfigMapName")
    flags+=("--meshConfigFile=")
    two_word_flags+=("--meshConfigFile")
    flags+=("--meshConfigMapName=")
    two_word_flags+=("--meshConfigMapName")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--valuesFile=")
    two_word_flags+=("--valuesFile")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_manifest_diff()
{
    last_command="istioctl_manifest_diff"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--directory")
    flags+=("-r")
    flags+=("--ignore=")
    two_word_flags+=("--ignore")
    flags+=("--rename=")
    two_word_flags+=("--rename")
    flags+=("--select=")
    two_word_flags+=("--select")
    flags+=("--verbose")
    flags+=("-v")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_manifest_generate()
{
    last_command="istioctl_manifest_generate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--component=")
    two_word_flags+=("--component")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--force")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_manifest_install()
{
    last_command="istioctl_manifest_install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--force")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--readiness-timeout=")
    two_word_flags+=("--readiness-timeout")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    flags+=("--skip-confirmation")
    flags+=("-y")
    flags+=("--verify")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_manifest()
{
    last_command="istioctl_manifest"

    command_aliases=()

    commands=()
    commands+=("diff")
    commands+=("generate")
    commands+=("install")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("apply")
        aliashash["apply"]="install"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dry-run")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_operator_dump()
{
    last_command="istioctl_operator_dump"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--dry-run")
    flags+=("--hub=")
    two_word_flags+=("--hub")
    flags+=("--imagePullSecrets=")
    two_word_flags+=("--imagePullSecrets")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--operatorNamespace=")
    two_word_flags+=("--operatorNamespace")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--tag=")
    two_word_flags+=("--tag")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_operator_init()
{
    last_command="istioctl_operator_init"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--dry-run")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--hub=")
    two_word_flags+=("--hub")
    flags+=("--imagePullSecrets=")
    two_word_flags+=("--imagePullSecrets")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--operatorNamespace=")
    two_word_flags+=("--operatorNamespace")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--tag=")
    two_word_flags+=("--tag")
    flags+=("--watchedNamespaces=")
    two_word_flags+=("--watchedNamespaces")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_operator_remove()
{
    last_command="istioctl_operator_remove"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dry-run")
    flags+=("--force")
    flags+=("--operatorNamespace=")
    two_word_flags+=("--operatorNamespace")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    two_word_flags+=("-r")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_operator()
{
    last_command="istioctl_operator"

    command_aliases=()

    commands=()
    commands+=("dump")
    commands+=("init")
    commands+=("remove")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_profile_diff()
{
    last_command="istioctl_profile_diff"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_profile_dump()
{
    last_command="istioctl_profile_dump"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--config-path=")
    two_word_flags+=("--config-path")
    two_word_flags+=("-p")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_profile_list()
{
    last_command="istioctl_profile_list"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--dry-run")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_profile()
{
    last_command="istioctl_profile"

    command_aliases=()

    commands=()
    commands+=("diff")
    commands+=("dump")
    commands+=("list")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--dry-run")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_bootstrap()
{
    last_command="istioctl_proxy-config_bootstrap"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_cluster()
{
    last_command="istioctl_proxy-config_cluster"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--direction=")
    two_word_flags+=("--direction")
    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--fqdn=")
    two_word_flags+=("--fqdn")
    flags+=("--port=")
    two_word_flags+=("--port")
    flags+=("--subset=")
    two_word_flags+=("--subset")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_endpoint()
{
    last_command="istioctl_proxy-config_endpoint"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--cluster=")
    two_word_flags+=("--cluster")
    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--port=")
    two_word_flags+=("--port")
    flags+=("--status=")
    two_word_flags+=("--status")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_listener()
{
    last_command="istioctl_proxy-config_listener"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--address=")
    two_word_flags+=("--address")
    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--port=")
    two_word_flags+=("--port")
    flags+=("--type=")
    two_word_flags+=("--type")
    flags+=("--verbose")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_log()
{
    last_command="istioctl_proxy-config_log"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--level=")
    two_word_flags+=("--level")
    flags+=("--reset")
    flags+=("-r")
    flags+=("--selector=")
    two_word_flags+=("--selector")
    two_word_flags+=("-l")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_route()
{
    last_command="istioctl_proxy-config_route"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--name=")
    two_word_flags+=("--name")
    flags+=("--verbose")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config_secret()
{
    last_command="istioctl_proxy-config_secret"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")
    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-config()
{
    last_command="istioctl_proxy-config"

    command_aliases=()

    commands=()
    commands+=("bootstrap")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("b")
        aliashash["b"]="bootstrap"
    fi
    commands+=("cluster")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("c")
        aliashash["c"]="cluster"
        command_aliases+=("clusters")
        aliashash["clusters"]="cluster"
    fi
    commands+=("endpoint")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("endpoints")
        aliashash["endpoints"]="endpoint"
        command_aliases+=("ep")
        aliashash["ep"]="endpoint"
    fi
    commands+=("listener")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("l")
        aliashash["l"]="listener"
        command_aliases+=("listeners")
        aliashash["listeners"]="listener"
    fi
    commands+=("log")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("o")
        aliashash["o"]="log"
    fi
    commands+=("route")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("r")
        aliashash["r"]="route"
        command_aliases+=("routes")
        aliashash["routes"]="route"
    fi
    commands+=("secret")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("s")
        aliashash["s"]="secret"
        command_aliases+=("secrets")
        aliashash["secrets"]="secret"
    fi

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_proxy-status()
{
    last_command="istioctl_proxy-status"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--file=")
    two_word_flags+=("--file")
    two_word_flags+=("-f")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_upgrade()
{
    last_command="istioctl_upgrade"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--charts=")
    two_word_flags+=("--charts")
    flags+=("--dry-run")
    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--force")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--readiness-timeout=")
    two_word_flags+=("--readiness-timeout")
    flags+=("--set=")
    two_word_flags+=("--set")
    two_word_flags+=("-s")
    flags+=("--skip-confirmation")
    flags+=("-y")
    flags+=("--verify")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_validate()
{
    last_command="istioctl_validate"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--referential")
    flags+=("-x")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_verify-install()
{
    last_command="istioctl_verify-install"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--filename=")
    two_word_flags+=("--filename")
    two_word_flags+=("-f")
    flags+=("--manifests=")
    two_word_flags+=("--manifests")
    two_word_flags+=("-d")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_version()
{
    last_command="istioctl_version"

    command_aliases=()

    commands=()

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--output=")
    two_word_flags+=("--output")
    two_word_flags+=("-o")
    local_nonpersistent_flags+=("--output")
    local_nonpersistent_flags+=("--output=")
    local_nonpersistent_flags+=("-o")
    flags+=("--remote")
    local_nonpersistent_flags+=("--remote")
    flags+=("--revision=")
    two_word_flags+=("--revision")
    flags+=("--short")
    flags+=("-s")
    local_nonpersistent_flags+=("--short")
    local_nonpersistent_flags+=("-s")
    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

_istioctl_root_command()
{
    last_command="istioctl"

    command_aliases=()

    commands=()
    commands+=("analyze")
    commands+=("authz")
    commands+=("bug-report")
    commands+=("dashboard")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("d")
        aliashash["d"]="dashboard"
        command_aliases+=("dash")
        aliashash["dash"]="dashboard"
    fi
    commands+=("experimental")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("exp")
        aliashash["exp"]="experimental"
        command_aliases+=("x")
        aliashash["x"]="experimental"
    fi
    commands+=("help")
    commands+=("install")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("apply")
        aliashash["apply"]="install"
    fi
    commands+=("kube-inject")
    commands+=("manifest")
    commands+=("operator")
    commands+=("profile")
    commands+=("proxy-config")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("pc")
        aliashash["pc"]="proxy-config"
    fi
    commands+=("proxy-status")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("ps")
        aliashash["ps"]="proxy-status"
    fi
    commands+=("upgrade")
    commands+=("validate")
    if [[ -z "${BASH_VERSION}" || "${BASH_VERSINFO[0]}" -gt 3 ]]; then
        command_aliases+=("v")
        aliashash["v"]="validate"
    fi
    commands+=("verify-install")
    commands+=("version")

    flags=()
    two_word_flags=()
    local_nonpersistent_flags=()
    flags_with_completion=()
    flags_completion=()

    flags+=("--context=")
    two_word_flags+=("--context")
    flags+=("--istioNamespace=")
    two_word_flags+=("--istioNamespace")
    two_word_flags+=("-i")
    flags+=("--kubeconfig=")
    two_word_flags+=("--kubeconfig")
    two_word_flags+=("-c")
    flags+=("--namespace=")
    two_word_flags+=("--namespace")
    two_word_flags+=("-n")

    must_have_one_flag=()
    must_have_one_noun=()
    noun_aliases=()
}

__start_istioctl()
{
    local cur prev words cword
    declare -A flaghash 2>/dev/null || :
    declare -A aliashash 2>/dev/null || :
    if declare -F _init_completion >/dev/null 2>&1; then
        _init_completion -s || return
    else
        __istioctl_init_completion -n "=" || return
    fi

    local c=0
    local flags=()
    local two_word_flags=()
    local local_nonpersistent_flags=()
    local flags_with_completion=()
    local flags_completion=()
    local commands=("istioctl")
    local must_have_one_flag=()
    local must_have_one_noun=()
    local has_completion_function
    local last_command
    local nouns=()

    __istioctl_handle_word
}

if [[ $(type -t compopt) = "builtin" ]]; then
    complete -o default -F __start_istioctl istioctl
else
    complete -o default -o nospace -F __start_istioctl istioctl
fi

# ex: ts=4 sw=4 et filetype=sh
