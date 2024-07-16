#!/bin/bash

# Quick function to generate a timestamp
timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

# Function to handle shutdown when sigterm is recieved
shutdown () {
    echo ""
    echo "$(timestamp) INFO: Recieved SIGTERM, shutting down gracefully"
    kill -2 $squad44_pid
}

# Set our trap
trap 'shutdown' TERM

# Set vars established during image build
IMAGE_VERSION=$(cat /home/steam/image_version)
MAINTAINER=$(cat /home/steam/image_maintainer)
EXPECTED_FS_PERMS=$(cat /home/steam/expected_filesystem_permissions)

echo "$(timestamp) INFO: Launching Squad44 Dedicated Server image ${IMAGE_VERSION} by ${MAINTAINER}"

# Validate arguments
echo "$(timestamp) INFO: Validating launch arguments"
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="Squad44 Containerized"
    echo "$(timestamp) WARN: SERVER_NAME not set, using default: Squad44 Containerized"
fi

if [ -z "$RCON_PASSWORD" ]; then
    RCON_PASSWORD="PLEASE-CHANGE-ME"
    echo "$(timestamp) WARN: RCON_PASSWORD not set, using default: PLEASE-CHANGE-ME"
fi

# Check for proper save permissions
echo "$(timestamp) INFO: Validating data directory filesystem permissions"
if ! touch "${SQUAD44_PATH}/test"; then
    echo ""
    echo "$(timestamp) ERROR: The ownership of ${SQUAD44_PATH} is not correct and the server will not be able to save..."
    echo "the directory that you are mounting into the container needs to be owned by ${EXPECTED_FS_PERMS}"
    echo "from your container host attempt the following command 'sudo chown -R ${EXPECTED_FS_PERMS} /your/squad44/data/directory'"
    echo ""
    exit 1
fi

rm "${SQUAD44_PATH}/test"

# Install/Update Squad44
echo "$(timestamp) INFO: Updating Squad44 Dedicated Server"
echo ""
${STEAMCMD_PATH}/steamcmd.sh +force_install_dir "${SQUAD44_PATH}" +login anonymous +app_update ${STEAM_APP_ID} validate +quit
echo ""

# Check that steamcmd was successful
if [ $? != 0 ]; then
    echo "$(timestamp) ERROR: steamcmd was unable to successfully initialize and update Squad44"
    exit 1
else
    echo "$(timestamp) INFO: steamcmd update of Squad44 successful"
fi

# Update Server.cfg configuration
echo "$(timestamp) INFO: Updating Server.cfg configuration options"
sed -i "s/ServerName=.*$/ServerName=${SERVER_NAME}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/MaxPlayers=.*$/MaxPlayers=${MAX_PLAYERS}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/NumReservedSlots=.*$/NumReservedSlots=${RESERVED_SLOTS}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/PreventTeamChangeIfUnbalanced=.*$/PreventTeamChangeIfUnbalanced=${PREVENT_TEAM_CHANGE_IF_UNBALANCED}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/NumPlayersDiffForTeamChanges=.*$/NumPlayersDiffForTeamChanges=${NUM_PLAYERS_DIFF_FOR_TEAM_CHANGE}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/MapVoting=.*$/MapVoting=${MAP_VOTING}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/ServerMessageInterval=.*$/ServerMessageInterval=${SERVER_MESSAGE_INTERVAL}/" $SQUAD44_CONFIG_PATH/Server.cfg
sed -i "s/TKAutoKickEnabled=.*$/TKAutoKickEnabled=${TK_AUTOKICK_ENABLED}/" $SQUAD44_CONFIG_PATH/Server.cfg

# Update Rcon.cfg configuration
echo "$(timestamp) INFO: Updating Rcon.cfg configuration options"
sed -i "s/Port=.*$/Port=${RCON_PORT}/" $SQUAD44_CONFIG_PATH/Rcon.cfg
sed -i "s/Password=.*$/Password=${RCON_PASSWORD}/" $SQUAD44_CONFIG_PATH/Rcon.cfg

# Check if we have base64 encoded configuration files (Other than Server.cfg) to load
if [ -n "${ADMINS_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding Admins.cfg base64 and writing to file"
    printf "${ADMINS_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/Admins.cfg
fi

if [ -n "${MAP_ROTATION_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding MapRotation.cfg base64 and writing to file"
    printf "${MAP_ROTATION_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/MapRotation.cfg
fi

if [ -n "${MAP_VOTING_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding MapVoting.cfg base64 and writing to file"
    printf "${MAP_VOTING_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/MapVoting.cfg
fi

if [ -n "${MOTD_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding MOTD.cfg base64 and writing to file"
    printf "${MOTD_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/MOTD.cfg
fi

if [ -n "${SERVER_MESSAGE_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding ServerMessages.cfg base64 and writing to file"
    printf "${SERVER_MESSAGE_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/ServerMessages.cfg
fi

if [ -n "${SERVER_LOGO_B64_ENCODED}" ]; then
    echo "$(timestamp) INFO: Decoding ServerLogo.png base64 and writing to file"
    printf "${SERVER_LOGO_B64_ENCODED}" | base64 -d > $SQUAD44_CONFIG_PATH/ServerLogo.png
fi

chmod 644 $SQUAD44_CONFIG_PATH/*

# Build launch arguments
echo "$(timestamp) INFO: Constructing launch arguments"
LAUNCH_ARGS="Port=${GAME_PORT} QueryPort=${QUERY_PORT} RANDOM=${RANDOM_MAP_ROTATION}"

# Cheesy asci launch banner because I remember 1999
echo ""
echo ""
echo " _______  _______           _______  ______      ___       ___   "
echo "(  ____ \(  ___  )|\     /|(  ___  )(  __  \    /   )     /   )  "
echo "| (    \/| (   ) || )   ( || (   ) || (  \  )  / /) |    / /) |  "
echo "| (_____ | |   | || |   | || (___) || |   ) | / (_) (_  / (_) (_ "
echo "(_____  )| |   | || |   | ||  ___  || |   | |(____   _)(____   _)"
echo "      ) || | /\| || |   | || (   ) || |   ) |     ) (       ) (  "
echo "/\____) || (_\ \ || (___) || )   ( || (__/  )     | |       | |  "
echo "\_______)(____\/_)(_______)|/     \|(______/      (_)       (_)  "
echo "                                                                 "
echo "$(timestamp) INFO: Launching Squad44. God Speed, Soldier!"
echo "--------------------------------------------------------------------------------"
echo "Server Name: ${SERVER_NAME}"
echo "Game Port: ${GAME_PORT}"
echo "Query Port: ${QUERY_PORT}"
echo "Server Slots: ${MAX_PLAYERS}"
echo "Reserved Slots: ${RESERVED_SLOTS}"
echo "RCON Password: ${RCON_PASSWORD}"
echo "RCON Port: ${RCON_PORT}"
echo "Container Image Version: ${IMAGE_VERSION} "
echo "--------------------------------------------------------------------------------"
echo ""
echo ""

# Launch Squad44
${SQUAD44_PATH}/PostScriptum/Binaries/Linux/PostScriptumServer ${LAUNCH_ARGS} &

# Capture Squad44 server start script pid
squad44_pid=$!

# Hold us open until we recieve a SIGTERM
wait $squad44_pid

# Handle post SIGTERM from here
# Hold us open until pid closes, indicating full shutdown, then go home
tail --pid=$squad44_pid -f /dev/null

# o7
echo "$(timestamp) INFO: Shutdown complete. Welcome home, Soldier."
exit 0
