#!/bin/bash

PS_DELIM='▌'

function pwds () {

  LENGTH=25
  readonly PWDS_SYMBOL='…'

  PRE=""
  NAME="${1}"

  if [[ "${NAME}" != "${NAME#${HOME}/}" || -z "${NAME#${HOME}}" ]]
  then
    PRE+='~' NAME="${NAME#${HOME}}" LENGTH=$((LENGTH-1))
  fi
  if ((${#NAME}>LENGTH))
  then 
    NAME="/${PWDS_SYMBOL}${NAME:$((${#NAME}-LENGTH+1))}"
  fi

  echo "${PRE}${NAME}" 

  unset LENGTH PRE NAME
}

function git-check () {

  [ -x "$(which git)" ] || exit

  # get current branch name or short SHA1 hash for detached head
  BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || git describe --tags --always 2>/dev/null)"
  [ -n "${BRANCH}" ] || exit
}

function git-annex-check () {
  git config --get annex.uuid >/dev/null

  return ${?}
}

function git-info () {

  readonly GIT_BRANCH_CHANGED_SYMBOL='±'
  readonly GIT_NEED_PUSH_SYMBOL='⇡'
  readonly GIT_NEED_PULL_SYMBOL='⇣'

  git-check

  if git-annex-check; then
    echo -n "«annex»"
    return
  fi

  if [ "$(git rev-parse --is-bare-repository)" = "true" ]; then
    echo -n "«bare»"
    return
  fi

  MARKS=""

  # branch is modified?
  [ -n "$(git status --porcelain)" ] && MARKS+=" ${GIT_BRANCH_CHANGED_SYMBOL}"

  # how many commits local branch is ahead/behind of remote?
  AHEADN="$(git status --porcelain --branch | sed -n 's~^\#\#.*ahead \([0-9]*\).*~\1~p')"
  BEHINDN="$(git status --porcelain --branch | sed -n 's~^\#\#.*behind \([0-9]*\).*~\1~p')"
  [ -n "${AHEADN}" ] && MARKS+=" ${GIT_NEED_PUSH_SYMBOL}${AHEADN}"
  [ -n "${BEHINDN}" ] && MARKS+=" ${GIT_NEED_PULL_SYMBOL}${BEHINDN}"

  # print the git branch segment without a trailing newline
  echo -n "${BRANCH}${MARKS}"

  unset MARKS AHEADN BEHINDN
}

FG_LRED='\[\e[91m\]'
FG_GRN='\[\e[32m\]'
FG_LBLU='\[\e[94m\]'
FG_WHT='\[\e[97m\]'

BG_LRED='\[\e[101m\]'
BG_GRN='\[\e[42m\]'
BG_LBLU='\[\e[104m\]'
BG_WHT='\[\e[107m\]'

RESET='\[\e[0m\]'
#INVERT='\[\e[7m\]'
#BOLD='\[\e[1m\]'

PS1=""

if [[ ${EUID} == 0 ]]
then
  PS1+="${BG_LRED}${FG_WHT}\h${BG_WHT}${FG_LRED}${PS_DELIM}"
else
  PS1+="${BG_GRN}${FG_WHT}\h${BG_WHT}${FG_GRN}${PS_DELIM}"
fi

PS1+="\$(RET=\$?; echo -n \"${BG_WHT}${FG_LBLU} \$(pwds \"\${PWD}\") ${RESET}\" ; if \$(git-check); then echo -n \"${FG_WHT}${BG_LBLU}${PS_DELIM}${FG_WHT}${BG_LBLU} \$(git-info) ${RESET}${FG_LBLU}${PS_DELIM}${RESET} \"; else echo -n \"${RESET}${FG_WHT}${PS_DELIM}${RESET} \"; fi; if [[ \${RET} == 0 ]]; then echo -n \"${FG_LBLU}\";else echo -n \"${FG_LRED}\"; fi)"

if [[ ${EUID} == 0 ]]
then
  PS1+="#"
else
  PS1+="$"
fi

PS1+="${RESET} "

unset PS_DELIM 
unset FG_LRED FG_GRN FG_LBLU FG_WHT FG_BWHT
unset BG_LRED BG_GRN BG_LBLU BG_WHT
unset RESET 
