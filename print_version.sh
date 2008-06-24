#!/bin/sh

print_version () {
  cat VERSION
}

print_revision () {
  if [[ -d .svn ]]; then
    printf "r%s\n" `svnversion`
  elif [[ -d .git ]]; then
    SHA1=`git rev-list --max-count=1 --grep='^git-svn-id:' HEAD`
    REVISION=`git cat-file commit $SHA1 | sed -n 's/^git-svn-id:.*@\([[:digit:]]\{1,\}\).*/r\1/p'`
    OFFSET=`git rev-list ^$SHA1 HEAD | wc -l | tr -d ' '`
    if [[ "$OFFSET" == 0 ]]; then
      echo $REVISION
    else
      printf "%s-%d-%s\n" $REVISION $OFFSET `git rev-parse --verify HEAD | cut -c 1-7`
    fi
  else
    echo "exported"
  fi
}

usage () {
  echo "Usage: $0 -v|-r"
}

cd "`dirname $0`"

case "$1" in
  -v) print_version;;
  -r) print_revision;;
  *) usage; exit 1;;
esac
