#!/bin/bash
dir_name="RecursiveResourceCalculator_$1"
mkdir $dir_name
cp -r gui $dir_name/gui
cp -r locale $dir_name/locale
cp -r logic $dir_name/logic
cp changelog.txt $dir_name/changelog.txt
cp control.lua $dir_name/control.lua
cp data.lua $dir_name/data.lua
cp info.json $dir_name/info.json
cp LICENSE $dir_name/LICENSE
cp thumbnail.png $dir_name/thumbnail.png
cp settings.lua $dir_name/settings.lua