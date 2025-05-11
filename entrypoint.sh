#!/bin/sh
GAME_DIR=/home/steam/Steam/steamapps/common/VRisingDedicatedServer
SETTINGS_DIR=$GAME_DIR/VRisingServer_Data/StreamingAssets/Settings
RED_COLOR='16735838'
GREEN_COLOR='6225790'

sendDiscordMessage() {
    if [ -n "${DISCORD_WEBHOOK}" ]; then
        # local message = $1
        # local color = $2
        local TZ_DATE=$(TZ='America/New_York' date +'%D %I:%M%p %Z')
        echo "Sending Discord message: \"$1\""
        curl -sfSL -X POST -H "Content-Type: application/json" -d "{\"username\":\"Josef's Server\",\"embeds\":[{\"type\":\"rich\",\"title\":\"Server status update\",\"description\":\"$1\",\"color\":$2,\"footer\":{\"text\":\"$TZ_DATE\"}}]}" "$DISCORD_WEBHOOK"
    else
        echo "\n NO DISCORD WEBHOOK FOUND \n"
    fi
}

cat >$SETTINGS_DIR/adminlist.txt <<EOL
${VR_ADMIN_STEEAMID_1}
${VR_ADMIN_STEEAMID_2}
${VR_ADMIN_STEEAMID_3}
EOL

onExit() {
    sendDiscordMessage "Server is shutting down" $RED_COLOR
    kill -INT -$(ps -A | grep 'VRising' | awk '{print $1}') &>> /saves/wtf
    wait $!
}

backwards_compatability() {
    VR_GAME_MODE="${V_RISING_GAME_MODE:-$VR_GAME_MODE}"
    VR_DEATH_CONTAINER_PERMISSIONS="${V_RISING_DEATH_CONTAINER_PERMISSIONS:-$VR_DEATH_CONTAINER_PERMISSIONS}"
    VR_CLAN_SIZE="${V_RISING_CLAN_SIZE:-$VR_CLAN_SIZE}"
    VR_DAY_DURATION_SECONDS="${V_RISING_DAY_DURATION_SECONDS:-$VR_DAY_DURATION_SECONDS}"
    VR_DAY_START_HOUR="${V_RISING_DAY_START_HOUR:-$VR_DAY_START_HOUR}"
    VR_DAY_END_HOUR="${V_RISING_DAY_END_HOUR:-$VR_DAY_END_HOUR}"
    VR_MAX_HEALTH_MOD="${V_RISING_MAX_HEALTH_MOD:-$VR_MAX_HEALTH_MOD}"
    VR_MAX_HEALTH_GLOBAL_MOD="${V_RISING_MAX_HEALTH_GLOBAL_MOD:-$VR_MAX_HEALTH_GLOBAL_MOD}"
    VR_RESOURCE_YIELD_MOD="${V_RISING_RESOURCE_YIELD_MOD:-$VR_RESOURCE_YIELD_MOD}"
    VR_TOMB_LIMIT="${V_RISING_TOMB_LIMIT:-$VR_TOMB_LIMIT}"
    VR_NEST_LIMIT="${V_RISING_NEST_LIMIT:-$VR_NEST_LIMIT}"
}

check_req_vars() {
    if [ -z "${VR_NAME}" ]; then
        echo "VR_NAME has to be set"

        exit
    fi

    if [ -z "${VR_SAVE_NAME}" ]; then
        echo "VR_SAVE_NAME has to be set"

        exit
    fi
}

setServerHostSettings() {
    check_req_vars
    WRITE_DIR=$SETTINGS_DIR

    # if [ -d "/saves/Settings" ]; then
    #     WRITE_DIR=/saves/Settings
    # fi

    echo "Using env vars for ServerHostSettings"

    VR_ENABLE_RCON="${VR_ENABLE_RCON:-false}" \
    VR_RCON_PORT="${VR_RCON_PORT:-27022}" \
    VR_LIST_ON_EOS="${VR_LIST_ON_EOS:-false}" \
    VR_LIST_ON_STEAM="${VR_LIST_ON_STEAM:-false}" \
    VR_GAME_PORT="${VR_GAME_PORT:-9876}" \
    VR_QUERY_PORT="${VR_QUERY_PORT:-9877}" \
    VR_MAX_USERS="${VR_MAX_USERS:-40}" \
    VR_MAX_ADMINS="${VR_MAX_ADMINS:-4}" \
    envsubst < /templates/ServerHostSetting.templ > $WRITE_DIR/ServerHostSettings.json
}

setServerGameSettings() {
    WRITE_DIR=$SETTINGS_DIR

    echo "Using env vars for ServerGameSettings"

    backwards_compatability

    VR_GAME_MODE="${VR_GAME_MODE:-PvP}" \
    VR_ESSENCE_DRAIN_MOD="${VR_ESSENCE_DRAIN_MOD:-1.0}" \
    VR_ESSENCE_YIELD_MOD="${VR_ESSENCE_YIELD_MOD:-1.0}" \
    VR_DEATH_CONTAINER_PERMISSIONS="${VR_DEATH_CONTAINER_PERMISSIONS:-Anyone}" \
    VR_CLAN_SIZE="${VR_CLAN_SIZE:-4}" \
    VR_DAY_DURATION_SECONDS="${VR_DAY_DURATION_SECONDS:-1080.0}" \
    VR_DAY_START_HOUR="${VR_DAY_START_HOUR:-9}" \
    VR_DAY_END_HOUR="${VR_DAY_END_HOUR:-15}" \
    VR_MAX_HEALTH_MOD="${VR_MAX_HEALTH_MOD:-1.0}" \
    VR_MAX_HEALTH_GLOBAL_MOD="${VR_MAX_HEALTH_GLOBAL_MOD:-1.0}" \
    VR_RESOURCE_YIELD_MOD="${VR_RESOURCE_YIELD_MOD:-1.0}" \
    VR_TOMB_LIMIT="${VR_TOMB_LIMIT:-12}" \
    VR_NEST_LIMIT="${VR_NEST_LIMIT:-4}" \
    VR_TELEPORT_BOUND_ITEMS="${VR_TELEPORT_BOUND_ITEMS:-true}" \
    VR_ALL_WAYPOINTS_UNLOCKED="${VR_ALL_WAYPOINTS_UNLOCKED:-false}" \
    VR_INVENTORY_STACKS_MULTIPLIER="${VR_INVENTORY_STACKS_MULTIPLIER:-1.0}" \
    envsubst < /templates/ServerGameSettings.templ > $WRITE_DIR/ServerGameSettings.json
}

createSettingsSaves() {
    if [ ! -d "/saves/Settings" ]; then
        mkdir /saves/Settings
    fi
}

# This logic is flawed and I don't have the energy to fix this
checkGameSettings() {
    if [ ! -f "/saves/Settings/v4/ServerGameSettings.json" ]; then
        # necessary for backwards compatabiltiy
        if [ -f "/var/settings/ServerGameSettings.json" ]; then
            cp /var/settings/ServerGameSettings.json /saves/Settings/ServerGameSettings.json
        else
            setServerGameSettings
        fi
    else
        echo "Using /saves/Settings/v4/ServerGameSettings.json for settings"
        cat /saves/Settings/v4/ServerGameSettings.json > $SETTINGS_DIR/ServerGameSettings.json
    fi
}

# This logic is flawed and I don't have the energy to fix this
checkHostSettings() {
    if [ ! -f "/saves/Settings/v4/ServerHostSettings.json" ]; then
        # necessary for backwards compatabiltiy
        if [ -f "/var/settings/ServerHostSettings.json" ]; then
            cp /var/settings/ServerHostSettings.json /saves/Settings/ServerHostSettings.json
            checkGameSettings
        else
            check_req_vars
            setServerHostSettings
        fi
    else
        echo "Using /saves/Settings/v4/ServerHostSettings.json for settings"
        cat /saves/Settings/v4/ServerHostSettings.json > $SETTINGS_DIR/ServerHostSettings.json
    fi
}

./steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +app_update 1829350 validate +quit

if [ -d "/saves" ]; then
    createSettingsSaves
    checkGameSettings
    checkHostSettings
else
    setServerGameSettings
    setServerHostSettings
fi

echo ----Server Host Settings----
cat $SETTINGS_DIR/ServerHostSettings.json
echo ----Server Game Settings----
cat $SETTINGS_DIR/ServerGameSettings.json

trap onExit INT TERM KILL

sendDiscordMessage "Server is starting" $GREEN_COLOR
cd $GAME_DIR
Xvfb :0 -screen 0 1024x768x16 -terminate &
setsid '/launch_server.sh' &

echo $!
wait $!
