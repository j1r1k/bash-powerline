#!/bin/bash

PS_DELIM='▌'
PWDS_SYMBOL='…'

GIT_BRANCH_CHANGED_SYMBOL='±'
GIT_NEED_PUSH_SYMBOL='⇡'
GIT_NEED_PULL_SYMBOL='⇣'

# Colors
HOST_USER_BG=190
HOST_USER_FG=16
HOST_ROOT_BG=202
HOST_ROOT_FG=16
DIR_BG=234
DIR_FG=85
GIT_BG=27
GIT_FG=15
PROMPT_ERR=1

function pwds () {
  LENGTH=25

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

function git-info () {
  git-check

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

function fg() {
  printf "\[\e[38;5;%sm\]" "$1"
}

function bg() {
  printf "\[\e[48;5;%sm\]" "$1"
}

RESET='\[\e[0m\]'

PS1=""

if [[ ${EUID} == 0 ]]
then
  PS1+="$(bg $HOST_ROOT_BG)$(fg $HOST_ROOT_FG)\h$(bg $DIR_BG)$(fg $HOST_ROOT_BG)${PS_DELIM}"
else
  PS1+="$(bg $HOST_USER_BG)$(fg $HOST_USER_FG)\h$(bg $DIR_BG)$(fg $HOST_USER_BG)${PS_DELIM}"
fi

PS1+="\$(RET=\$?; echo -n \"$(bg $DIR_BG)$(fg $DIR_FG) \$(pwds \"\${PWD}\") ${RESET}\" ; if \$(git-check); then echo -n \"$(bg $GIT_BG)$(fg $DIR_BG)${PS_DELIM}$(bg $GIT_BG)$(fg $GIT_FG) \$(git-info) ${RESET}$(fg $GIT_BG)${PS_DELIM}${RESET} \"; else echo -n \"${RESET}$(fg $DIR_BG)${PS_DELIM}${RESET} \"; fi; if [[ \${RET} != 0 ]]; then echo -n \"$(fg $PROMPT_ERR)\"; fi)"

if [[ ${EUID} == 0 ]]
then
  PS1+="#"
else
  PS1+="$"
fi

PS1+="${RESET} "

unset PS_DELIM
unset HOST_USER_BG HOST_USER_FG HOST_ROOT_BG HOST_ROOT_FG DIR_BG DIR_FG GIT_BG GIT_FG PROMPT_ERR
unset RESET
