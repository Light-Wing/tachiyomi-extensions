#!/bin/bash

set -e

TOOLS="$(ls -d ~/Library/Android/sdk/build-tools/* | tail -1)"

mkdir -p repo/apk
mkdir -p repo/icon

#mv -f ./*/build/outputs/apk/debug/*".apk"* repo/apk
mv -f ./src/*/*/release/*".apk"* repo/apk

cd repo

APKS=( ./apk/*".apk"* )

for APK in ${APKS[@]}; do
    FILENAME=$(basename ${APK})

    BADGING="$(${TOOLS}/aapt dump badging ${APK})"

    PKGNAME=$(echo "$BADGING" |  awk -F = '/package: name/ { print $2}' | sed "s|'||g" | sed "s| versionCode||g")

    VCODE=$(echo "$BADGING" | awk -F = '/versionCode/ { print $3}' | sed "s|'||g" | sed "s| versionName||g")
    VNAME=$(echo "$BADGING" | awk -F = '/versionName/ { print $4}' | sed "s|'||g")

    LABEL=$(echo "$BADGING" | awk -F : '/application-label/ { print $2 ":" $3}' | sed "s|'||g")

    LANG=$(echo $APK | sed -e 's|.*tachiyomi-\(.*\)\.\(.*\)\.\(.*\)\.\(.*\)\.apk|\1|')

    ICON=$(echo "$BADGING" | awk -F : '/application-icon-320/ { print $2}' | sed "s|'||g")
    unzip -p $APK $ICON > icon/${FILENAME%.*}.png

    jq -n \
        --arg name "$LABEL" \
        --arg pkg "$PKGNAME" \
        --arg apk "$FILENAME" \
        --arg lang "$LANG" \
        --arg code $VCODE \
        --arg version "$VNAME" \
        '{name:$name, pkg:$pkg, apk:$apk, lang:$lang, code:$code, version:$version}'

done | jq -sr '[.[]]' > index.json


: <<'END'

package: name='eu.kanade.tachiyomi.extension.all.comicake' versionCode='7' versionName='1.2.7'
sdkVersion:'16'
targetSdkVersion:'27'
application-label:'Tachiyomi: ComiCake'
application-icon-160:'res/mipmap-mdpi-v4/ic_launcher.png'
application-icon-240:'res/mipmap-hdpi-v4/ic_launcher.png'
application-icon-320:'res/mipmap-xhdpi-v4/ic_launcher.png'
application-icon-480:'res/mipmap-xxhdpi-v4/ic_launcher.png'
application-icon-640:'res/mipmap-xxxhdpi-v4/ic_launcher.png'
application: label='Tachiyomi: ComiCake' icon='res/mipmap-mdpi-v4/ic_launcher.png'
application-debuggable
feature-group: label=''
  uses-feature: name='tachiyomi.extension'
  uses-feature: name='android.hardware.faketouch'
  uses-implied-feature: name='android.hardware.faketouch' reason='default feature for all apps'
supports-screens: 'small' 'normal' 'large' 'xlarge'
supports-any-density: 'true'
locales: '--_--'
densities: '160' '240' '320' '480' '640'

END
