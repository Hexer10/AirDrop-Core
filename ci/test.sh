#!/bin/bash
set -ev

echo "Download und extract sourcemod"
wget "http://www.sourcemod.net/latest.php?version=1.9&os=linux" -O sourcemod.tar.gz
tar -xzf sourcemod.tar.gz

echo "Give compiler rights for compile"
chmod +x addons/sourcemod/scripting/spcomp

addons/sourcemod/scripting/compile.sh AirDropCore.sp
addons/sourcemod/scripting/compile.sh Examples/AirDropCaller_Decoy.sp