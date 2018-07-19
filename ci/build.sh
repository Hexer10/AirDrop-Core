#!/bin/bash
set -ev

TAG=$1

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=1.9&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

echo "Set plugins version"
sed -i "s/<TAG>/$TAG/g" addons/sourcemod/scripting/AirDropCore.sp
  
addons/sourcemod/scripting/compile.sh AirDropCore.sp

echo "Remove plugins folder if exists"
if [ -d "addons/sourcemod/plugins" ]; then
  rm -r addons/sourcemod/plugins
fi

echo "Create clean plugins folder"
mkdir -p build/addons/sourcemod/scripting/include
mkdir build/addons/sourcemod/plugins

echo "Move plugins files to their folder"
mv addons/sourcemod/scripting/include/airdrop.inc build/addons/sourcemod/scripting/include
mv addons/sourcemod/scripting/AirDropCore.sp build/addons/sourcemod/scripting
mv addons/sourcemod/scripting/compiled/AirDropCore.smx build/addons/sourcemod/plugins


echo "Compress the plugin"
mv LICENSE build/
cd build/ && zip -9rq airdrop.zip addons/ LICENSE && mv airdrop.zip ../

echo "Build done"