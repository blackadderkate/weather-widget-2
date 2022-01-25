#!/bin/bash
VERSION=$(grep 'Version' ./package/metadata.desktop | cut -d'=' -f2)
echo "$VERSION"
IFS="." read -a TMP <<< $VERSION
BUILD=$((${TMP[2]} + 1))
# echo $(($BUILD + 1))
NEWVERSION="${TMP[0]}\\.${TMP[1]}\\.$BUILD"
sed -i "s/$VERSION/$NEWVERSION/" "./package/metadata.desktop"
sed -i "/Plasmoid\ version/ s/$VERSION/$NEWVERSION/" "./package/contents/ui/config/ConfigGeneral.qml"
echo "Updated Version number from $VERSION to ${TMP[0]}.${TMP[1]}.$BUILD"
