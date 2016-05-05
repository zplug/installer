#!/bin/zsh

# Release some autoloads
autoload -Uz colors; colors

typeset -a failed
typeset    TMPFILE="/tmp/.zplug-$$$RANDOM"

if [[ -z $ZSH_VERSION ]] || ; then
    printf "zplug requires zsh 4.1.9 or more\n"
    exit 1
fi

spin()
{
    local \
        before_msg="$1" \
        after_msg="$2 [$fg[green]SUCCEEDED$reset_color]"
    local    spinner
    local -a spinners
    spinners=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

    # hide cursor
    tput civis

    while true
    do
        for spinner in "${spinners[@]}"
        do
            if [[ -f $TMPFILE ]]; then
                rm -f $TMPFILE
                tput cnorm
                return 1
            fi
            sleep 0.05
            printf " $fg[white]$spinner$reset_color  $before_msg\r" 2>/dev/null
        done

        echo "$jobstates" \
            | awk '
            /[0-9]+=/ {
                jobs[++job_count] = $0
            }
            END {
                for (i = 1; i <= job_count; i++) {
                    print(jobs[i])
                }
                exit job_count == 0
            }' \
                | xargs test -z && break
    done

    if [[ -n $after_msg ]]; then
        printf "\033[2K"
        printf " $fg_bold[blue]\U2714$reset_color  $after_msg\n"
    fi 2>/dev/null

    # show cursor
    tput cnorm
}

execute()
{
    local    arg title
    local -a args

    while (( $# > 0 ))
    do
        case "$1" in
            --title)
                title="$2"
                shift
                ;;
            -*|--*)
                return 1
                ;;
            *)
                args+=( "$1" )
                ;;
        esac
        shift
    done

    {
        for arg in "${args[@]}"
        do
            ${=arg} &>/dev/null
            if [[ $status -ne 0 ]]; then
                printf "\033[2K" 2>/dev/null
                printf \
                    " $fg[yellow]\U26A0$reset_color  $title [$fg[red]FAILED$reset_color]\n" \
                    2>/dev/null
                printf "$status\n" >"$TMPFILE"
            fi
        done
    } &

    spin \
        "$title" \
        "$title"

    if [[ $status -eq 0 ]]; then
        :
    else
        failed+=( $status )
    fi
}

execute \
    --title \
    "Installing zplug to ${ZPLUG_HOME:-~/.zplug}" \
    "git clone https://github.com/zplug/zplug.git ${ZPLUG_HOME:-~/.zplug}"

execute \
    --title \
    "Checking if your zsh version is less than 4.1.9" \
    "sleep 1" \
    "test ${ZSH_VERSION//./} -gt 419"

if (( $#failed )); then
    printf "Oops \U2620 . Try again!\n" 2>/dev/null
    exit 1
else
    printf " All processes are successfully completed \U1F389\n"
    printf " For more information, see ${(%):-%U}http://zplug.sh${(%):-%u} \U1F33A\n"
    printf " Enjoy zplug!\n"
fi
