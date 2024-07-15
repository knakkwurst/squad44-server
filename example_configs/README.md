# Example Configurations
These are example files for the different configurations. Further explanation can be found here: https://squad44.fandom.com/wiki/Server_Configuration#Files

The configuration files can either be mounted into the container using a bind mount, or base64 encoded and passed to the container as a variable.

Outside of these config files, you can also include a server logo. It must be named ServerLogo and it must be a .png. This file can also be either bind mounted into the container or base64 encoded and passed as a variable.

If bind mounting, the files must be owned by group and user ID 10000 or if you've built your own image based on this one, whatever you've set the UID/GID of the steam user to. 

If using the Kubernetes helm chart, you will need to pass the files as base64 encoded variables. Honestly, I prefer this over building helm templates for all the files as config maps. Feel free to build this out if you would rather have a config map.
