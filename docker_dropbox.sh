#!/bin/bash
# Startup helper po@poism.com
# Be sure to configure your env file, (eg. copy sample.env to myuser.env)
# Then call this script, like: ./docker_dropbox.sh ./myuser.env start
# You can later call ./docker_dropbox.sh ./myuser.env info 
# To see what's going on...

if [ "$1" == "build" ]; then
	tag="$(git log -1 --pretty=%h)"
	if [ ${#tag} -eq 7 ]; then
		tag=":${tag}"
	else
		tag=""
	fi
	echo "docker build poism/dropbox${tag}"
	docker build --no-cache -t "poism/dropbox${tag}" -t "poism/dropbox:latest" .
	exit
elif [ -z "$1" ]; then
	echo "Error: No path to env file given. See sample.env"
	exit 1
elif [ ! -f "$1" ]; then
	echo "Error: Env file not found at $1"
	exit 1
fi

source "$1"

if [ "$2" == "start" ]; then
	mkdir -p ${DROPBOX_DIR}
	mkdir -p ${DROPBOX_APPDATA}
	
	chown -R ${DROPBOX_UID}:${DROPBOX_GID} ${DROPBOX_DIR}
	chown -R ${DROPBOX_UID}:${DROPBOX_GID} ${DROPBOX_APPDATA}
	chcon -Rt svirt_sandbox_file_t ${DROPBOX_DIR}
	chcon -Rt svirt_sandbox_file_t ${DROPBOX_APPDATA}
	
	if [ "${DROPBOX_LAN_SYNC}" = true ]; then
		docker run -d --restart=always --name=${DROPBOX_IMAGE} \
		-v ${DROPBOX_DIR}:/dbox/Dropbox \
		-v ${DROPBOX_APPDATA}:/dbox/.dropbox \
		-e DBOX_UID=${DROPBOX_UID} \
		-e DBOX_GID=${DROPBOX_GID} \
		poism/dropbox
	else
		docker run -d --restart=always --name=${DROPBOX_IMAGE} \
		--net="host" \
		-v ${DROPBOX_DIR}:/dbox/Dropbox \
		-v ${DROPBOX_APPDATA}:/dbox/.dropbox \
		-e DBOX_UID=${DROPBOX_UID} \
		-e DBOX_GID=${DROPBOX_GID} \
		poism/dropbox
	fi
	
	docker logs ${DROPBOX_IMAGE}
	
elif [ "$2" == "info" ]; then
	if [ "$3" ]; then
		docker exec -t -i ${DROPBOX_IMAGE} dropbox $3
	else
		docker exec -t -i ${DROPBOX_IMAGE} dropbox help
	fi

elif [ "$2" == "logs" ]; then
	docker logs ${DROPBOX_IMAGE}
else
	echo "No arguments given."
fi

