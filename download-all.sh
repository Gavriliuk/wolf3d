#!/bin/bash

# Specify any argument to download the modified version from klasss.info
# or use no arguments to download the original version from users.atw.hu

unset modified
unset original

if [ -z "$1" ]; then
  domain='klasss.info'
  modified=1
else
  domain='users.atw.hu'
  original=1
fi

unset failed
rm -f failed.log

test -n "$original" && ! dos2unix -V && sudo apt install dos2unix -y

# $1 relative path to file (e.g., 'css/build.css')
# $2 non-empty for text files (to apply dos2unix)
function check_file()
{
  if ! test -f "$1"; then
    mkdir -p $(dirname "$1")
    wget "http://$domain/wolf3d/$1" -O "$1"
    test -n "$2" && test -n "$original" && test -f "$1" && dos2unix "$1"
  fi

  if test -f "$1"; then
    if test $(stat -c "%s" "$1") -gt 0; then
      return
    fi
    rm "$1"
  fi

  echo "$1" >> failed.log
  failed=1
  return 1
}

test -n "$modified" && check_file 'index.html'
test -n "$original" && check_file 'index.php'

check_file 'css/build.css' 1

# url(../images/loading.png)
for r in $(grep -o "[\.\./a-z/0-9\-]*\.png" css/build.css); do
  check_file ${r#../}
done

# maps/e1m1.js
# html/episode1.html
(( e = 0 ))
(( M = 10 ))
while test $(( ++e )) -le 7; do
  (( m = 0 ))
  test $e -eq 7 && M=21
  while test $(( ++m )) -le $M; do
    check_file 'maps/e'$e'm'$m'.js'
  done
  check_file "html/episode$e.html" 1
done

check_file 'js/build.js'
test -n "$modified" && check_file 'js/build_readable.js'

check_file 'js/webkitAudioContextMonkeyPatch.js'

# game.showScreen(a.donation?
# "donation":"copyright",
check_file "html/copyright.html" 1
check_file "html/donation.html" 1

# game.requestHTML("game",
for r in $(grep -o "game\.requestHTML(\"[^,]*\"," js/build.js | cut -d '"' -f 2); do
  check_file "html/$r.html" 1
done

# game.showScreen("pc13",
for r in $(grep -o "game\.showScreen(\"[^,]*\"," js/build.js | cut -d '"' -f 2); do
  check_file "html/$r.html" 1
done

# game.showReadme("readthis"
for r in $(grep -o "game\.showReadme(\"[^,]*\"," js/build.js | cut -d '"' -f 2); do
  check_file "html/$r.html" 1
done

# href="images/favicon.png"/>
# <img src="images/credits.png"/>
# sprites:"images/sprites/items.png",
for r in $(grep -o "\"images/[^\"]*" index.* html/*.html js/build.js | cut -d '"' -f 2); do
  check_file "$r"
done

# "music/nazi_nor"
for r in $(grep -o "\"music/[^\"]*" js/build.js | cut -d '"' -f 2); do
  check_file "$r.mp4"
  check_file "$r.ogg"
done

# hitwall:"sounds/sfx/hitwall"
for r in $(grep -o "\"sounds/[^\"]*" js/build.js | cut -d '"' -f 2); do
  check_file "$r.mp4"
  check_file "$r.ogg"
done

test -z "$failed" && echo 'OK'
