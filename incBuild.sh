#!/bin/bash
VERSION=$(grep 'Version' ./package/metadata.desktop | cut -d'=' -f2)
echo "$VERSION"
IFS="." read -a TMP <<< $VERSION
BUILD=$((${TMP[2]} + 1))
# echo $(($BUILD + 1))
NEWVERSION="${TMP[0]}\\.${TMP[1]}\\.$BUILD"
CURRDIR=$PWD
echo $CURRDIR
sed -i "s/$VERSION/$NEWVERSION/" "$CURRDIR/package/metadata.desktop"
sed -i "/Plasmoid\ version/ s/$VERSION/$NEWVERSION/" "$CURRDIR/package/contents/ui/config/ConfigGeneral.qml"
echo "Updated Version number from $VERSION to ${TMP[0]}.${TMP[1]}.$BUILD"
