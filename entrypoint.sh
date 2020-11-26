#!/bin/sh

set -eu

printenv

printf '\033[33m Warning: This action does not currently support host verification; verification is disabled. \n \033[0m\n'

SSHPATH="$HOME/.ssh"

if [ ! -d "$SSHPATH" ]
then
  mkdir "$SSHPATH"
fi

if [ ! -f "$SSHPATH/known_hosts" ]
then
  touch "$SSHPATH/known_hosts"
fi
if [ ! -d /root/.ssh ]; then
  mkdir -p /root/.ssh
fi
if ! grep "$(ssh-keyscan github.com 2>/dev/null)" ~/.ssh/known_hosts > /dev/null; then
    ssh-keyscan github.com > /root/.ssh/known_hosts
fi
if ! grep "$(ssh-keyscan ${INPUT_HOST} -p $INPUT_PORT 2>/dev/null)" ~/.ssh/known_hosts > /dev/null; then
    ssh-keyscan ${INPUT_HOST} -p $INPUT_PORT >> ~/.ssh/known_hosts
    ssh-keyscan github.com > /root/.ssh/known_hosts
fi

echo "$INPUT_KEY" > "$SSHPATH/deploy_key"
chmod 700 "$SSHPATH"
chmod 600 "$SSHPATH/known_hosts"
chmod 600 "$SSHPATH/deploy_key"


if [ -z "$INPUT_COMMAND" ] && [ -z "$INPUT_SYNC" ] ; then
  echo "Action command or sync is required ";
  exit 1
fi;


if [ ! -z "$INPUT_SYNC" ]
then
  echo Start Sync Command

  echo "sync: $INPUT_SYNC";
  echo "from: $INPUT_FROM";
  echo "to: $INPUT_TO";

  if [ -z "$INPUT_FROM" ] || [ -z "$INPUT_TO" ] ; then
    echo "Arguments from and to are required to use sync mode";
    exit 1
  fi;

  case $INPUT_SYNC in
  local) 
      if [ "$INPUT_PASS" = "" ]
      then
        sh -c "scp -r -i $SSHPATH/deploy_key -o StrictHostKeyChecking=no -P $INPUT_PORT ${INPUT_FROM} ${INPUT_USER}@${INPUT_HOST}:${INPUT_TO}"
      else
        sh -c "sshpass -p "$INPUT_PASS" scp -r -o StrictHostKeyChecking=no -P $INPUT_PORT ${INPUT_FROM} ${INPUT_USER}@${INPUT_HOST}:${INPUT_TO}"
      fi
    ;;
  remote) 
      if [ "$INPUT_PASS" = "" ]
      then
        sh -c "scp -r -i $SSHPATH/deploy_key -o StrictHostKeyChecking=no -P $INPUT_PORT ${INPUT_USER}@${INPUT_HOST}:${INPUT_FROM} ${INPUT_TO}"
      else
        sh -c "sshpass -p "$INPUT_PASS" scp -r -o StrictHostKeyChecking=no -P $INPUT_PORT ${INPUT_USER}@${INPUT_HOST}:${INPUT_FROM} ${INPUT_TO}"
      fi
    ;;
  *) 
    echo "Unrecognized sync mode [$INPUT_SYNC], the supported options are local or remote only";
    exit 1
    ;;
  esac
fi

if [ ! -z "$INPUT_COMMAND" ]
then
  echo "$INPUT_COMMAND" > $HOME/shell.sh
  echo "exit" >> $HOME/shell.sh
  cat $HOME/shell.sh

  echo Start Run Command

  if [ "$INPUT_PASS" = "" ]
  then
    sh -c "ssh $INPUT_ARGS -i $SSHPATH/deploy_key -o StrictHostKeyChecking=no -p $INPUT_PORT ${INPUT_USER}@${INPUT_HOST} < $HOME/shell.sh"
  else
    sh -c "sshpass -p "$INPUT_PASS" ssh $INPUT_ARGS -o StrictHostKeyChecking=no -p $INPUT_PORT ${INPUT_USER}@${INPUT_HOST} < $HOME/shell.sh"
  fi
fi