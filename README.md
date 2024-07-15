# squad44-server

[![Static Badge](https://img.shields.io/badge/DockerHub-blue)](https://hub.docker.com/r/sknnr/squad44-server) ![Docker Pulls](https://img.shields.io/docker/pulls/sknnr/squad44-server) [![Static Badge](https://img.shields.io/badge/GitHub-green)](https://github.com/jsknnr/squad44-server) ![GitHub Repo stars](https://img.shields.io/github/stars/jsknnr/squad44-server)


Run Squad44 dedicated server in a container. Optionally includes helm chart for running in Kubernetes.

**Disclaimer:** This is not an official image. No support, implied or otherwise is offered to any end user by the author or anyone else. Feel free to do what you please with the contents of this repo.
## Usage

The processes within the container do **NOT** run as root. Everything runs as the user steam (gid:10000/uid:10000 by default). If you exec into the container, you will drop into `/home/steam` as the steam user. Squad44 will be installed to `/home/steam/squad44`. Any persistent volumes should be mounted to `/home/steam/squad44` and be owned by 10000:10000.

To configure things like Admins and reservered groups, map rotations, MOTD, etc - there are a couple of ways you can do this. You can either get the container up and running, and then once it is online, stop the container and then edit the files in your persistent volume and once done, start the container again. Or you can make your own local copies of those configuration files (examples found under the examples directory in this project) and then base64 encode the files and pass that value into the container. Either option is fine.

### Creating base64 encoded config files
If you would like to pass configuration files such as Admins.cfg and MapRotations.cfg to the container as base64 encoded values. This is a bit more complex so a basic understanding of working with Linux would definitely be helpful. Remember, this is not required, this is just an alternative to editing the values in the volume. Here is an example of that process:

1) Make a copy of the config file from `./example_configs` from this repo
2) Edit the copy of the file with the values you desire, then save
3) Base64 encode the file with the following command for example: `ADMINS=$(cat Admins.cfg | base64 -w 0)`
    - This creates a local variable called ADMINS that holds the base64 encoded value of the Admins.cfg file
    - you can print the value back out like this: `printf "${ADMINS}"`
    - In this example, you could then set `ADMINS_B64_ENCODED=${ADMINS}`
    - You can also just copy and paste that value into a compose file or however you plan on launching the container
    - When the container launches it will decode that value and write it out to the appropriate file on the server

### Ports

Game ports are arbitrary. You can use which ever values you want above 1000. Make sure that you are port forwarding (DNAT) correctly to your instance and that firewall rules are set correctly. Documentation that I read on the wiki states that you need 2 game ports and 2 query ports. This seems odd to me but it is what it is.

| Port | Description | Protocol | Default |
| ---- | ----------- | -------- | --------|
| Game Port | Port for client connections, should be value above 1000 | UDP | 7787 |
| Game Port +1 | Port for client connections, should be game port +1 | UDP | 7788 |
| Query Port | Port for server browser queries, should be a value above 1000 | UDP | 27165 |
| Query Port +1 | Port for server browser queries, should be query port +1 | UDP | 27166 |
| RCON | Port for remote administration of the game server, should be a value above 1000 | TCP | 21114 |

### Environment Variables

You do not have to pass any variables that are marked as False for required if you want to keep the default.

| Name | Description | Default | Required |
| ---- | ----------- | ------- | -------- |
| SERVER_NAME | Name for the Server | Squad44 Containerized | False |
| MAX_PLAYERS | Max player count on the server | 80 | False |
| RESERVED_SLOTS | Number of reserved slots for admins/memebers | 0 | False |
| GAME_PORT | Port for client connections, should be value above 1000 | 7787 | False |
| QUERY_PORT | Port for server browser queries, should be a value above 1000 | 27165 | False |
| RCON_PORT | Port for remote administration of the game server, should be a value above 1000 | 21114 | False |
| RCON_PASSWORD | Password to login with RCON | PLEASE-CHANGE-ME | False |
| RANDOM_MAP_ROTATION | Randomize the map rotation, options are: ALWAYS, FIRST, NONE | NONE | False |
| PREVENT_TEAM_CHANGE_IF_UNBALANCED | If set to false, players can change teams regardless of team balance. Otherwise, the NumPlayersDiffForTeamChanges Value is used | true | False |
| NUM_PLAYERS_DIFF_FOR_TEAM_CHANGE | Maximum Allowed difference in player count between teams. This takes into account the team the player leaves and the team the player joins | 3 | False |
| MAP_VOTING | Whether or not Map Voting should be used. Make sure to configure MapVoting.cfg | false | False |
| SERVER_MESSAGE_INTERVAL | Interval between server messages from ServerMessages.cfg (in seconds) | 600 | False |
| TK_AUTOKICK_ENABLED | Whether or not to ban players temporarily when the teamkill limit is reached | true | False |
| ADMINS_B64_ENCODED | Base64 encoded Admins.cfg | None | False |
| MAP_ROTATION_B64_ENCODED | Base64 encoded MapRotation.cfg | None | False |
| MAP_VOTING_B64_ENCODED | Base64 encoded MapVoting.cfg | None | False |
| MOTD_B64_ENCODED | Base64 encoded MOTD.cfg | None | False |
| SERVER_MESSAGE_B64_ENCODED | Base64 encoded ServerMessages.cfg | None | False |
| SERVER_LOGO_B64_ENCODED | Base64 encoded ServerLogo.png | None | False |

### Docker

To run the container in Docker, run the following command:

```bash
docker volume create squad44-persistent-data
docker run \
  --detach \
  --name squad44-server \
  --mount type=volume,source=squad44-persistent-data,target=/home/steam/squad44 \
  --publish 7787:7787/udp \
  --publish 7788:7788/udp \
  --publish 27165:27165/udp \
  --publish 27166:27166/udp \
  --publish 21114:21114/tcp \
  --env=SERVER_NAME='Squad44 Containerized' \
  --env=RCON_PASSWORD='PLEASE-CHANGE-ME' \
  --stop-timeout 90 \
  sknnr/squad44-server:latest
```

### Docker Compose

To use Docker Compose, either clone this repo or copy the `compose.yaml` file out of the `container` directory to your local machine. Edit the compose file to change the environment variables to the values you desire and then save the changes. Once you have made your changes, from the same directory that contains the compose and the env files, simply run:

```bash
docker-compose up -d
```

To bring the container down:

```bash
docker-compose down --timeout 90
```

compose.yaml file:
```yaml
services:
  squad44:
    image: sknnr/squad44-server:latest
    ports:
      - "7787:7787/udp"
      - "7788:7788/udp"
      - "27165:27165/udp"
      - "27166:27166/udp"
      - "21114:21114/tcp"
    env_file:
      - default.env
    volumes:
      - squad44-persistent-data:/home/steam/squad44
    stop_grace_period: 90s

volumes:
  squad44-persistent-data:
```

default.env file:
```properties
SERVER_NAME="Squad44 Containerized"
RCON_PASSWORD="PLEASE-CHANGE-ME"
```

### Podman

To run the container in Podman, run the following command:

```bash
podman volume create squad44-persistent-data
podman run \
  --detach \
  --name squad44-server \
  --mount type=volume,source=squad44-persistent-data,target=/home/steam/squad44 \
  --publish 7787:7787/udp \
  --publish 7788:7788/udp \
  --publish 27165:27165/udp \
  --publish 27166:27166/udp \
  --publish 21114:21114/tcp \
  --env=SERVER_NAME='Squad44 Containerized' \
  --env=RCON_PASSWORD='PLEASE-CHANGE-ME' \
  --stop-timeout 90 \
  docker.io/sknnr/squad44-server:latest
```

### Quadlet
To run the container with Podman's new quadlet subsystem, make a file under (when running as root) /etc/containers/systemd/enshrouded.container containing:
```properties
[Unit]
Description=Squad44 Game Server

[Container]
Image=docker.io/sknnr/squad44-server:latest
Volume=squad44-persistent-data:/home/steam/squad44
PublishPort=7787-7788:7787-7788/udp
PublishPort=27165-27166:27165-27166/udp
PublishPort=21114:21114/tcp
ContainerName=squad44-server
Environment=SERVER_NAME="Squad44 Containerized"
Environment=RCON_PASSWORD="PLEASE-CHANGE-ME"

[Service]
# Restart service when sleep finishes
Restart=always
# Extend Timeout to allow time to pull the image
TimeoutStartSec=900

[Install]
# Start by default on boot
WantedBy=multi-user.target default.target
```

### Kubernetes

I've built a Helm chart and have included it in the `helm` directory within this repo. Modify the `values.yaml` file to your liking and install the chart into your cluster. Be sure to create and specify a namespace as I did not include a template for provisioning a namespace.

## Troubleshooting

### Connectivity

If you are having issues connecting to the server once the container is deployed, I promise the issue is not with this image. You need to make sure that the ports are open on your router as well as the container host where this container image is running. You will also have to port-forward the game-port and query-port from your router to the private IP address of the container host where this image is running. After this has been done correctly and you are still experiencing issues, your internet service provider (ISP) may be blocking the ports and you should contact them to troubleshoot.

### Storage

I recommend having Docker or Podman manage the volume that gets mounted into the container. However, if you absolutely must bind mount a directory into the container you need to make sure that on your container host the directory you are bind mounting is owned by 10000:10000 by default (`chown -R 10000:10000 /path/to/directory`). If the ownership of the directory is not correct the container will not start as the server will be unable to persist the savegame.
