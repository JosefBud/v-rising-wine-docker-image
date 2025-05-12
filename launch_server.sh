#!/bin/sh

echo "Launching server executable"
cd /home/steam/Steam/steamapps/common/VRisingDedicatedServer
# DISPLAY=:0.0 wine ls
DISPLAY=:0.0 wine VRisingServer.exe -persistentDataPath Z:\\saves -rconEnabled true -rconPort ${VR_RCON_PORT} -apiEnabled true -apiPort ${VR_API_PORT}
# bun run /launch-server.ts