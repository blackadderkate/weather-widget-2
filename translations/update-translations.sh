#!/bin/sh

cd "$( dirname "${BASH_SOURCE[0]}" )"

PROJECT="org.kde.weatherWidget"
NAME="plasma_applet_$PROJECT"

# svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-kf5/scripts
# export PATH=/path/to/l10n-kf5/scripts:$PATH
extract-messages.sh

sed -e "s,Report-Msgid-Bugs-To: http://bugs.kde.org,Report-Msgid-Bugs-To: https://github.com/blackadderkate/plasma-applet-weather-widget-2/issues," -i "po/$NAME.pot"

echo "Merging translations"
catalogs=`find ./po -name '*.po'`
for cat in $catalogs; do
  echo $cat
  msgmerge -o $cat.new $cat po/$NAME.pot
  mv $cat.new $cat
done
echo "Done merging translations"
