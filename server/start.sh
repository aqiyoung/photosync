#!/bin/bash

export PORT=18080
export TLS_CERT="/usr/trim/var/trim_connect/ssls/photo.threel.site/1780009226/fullchain.crt"
export TLS_KEY="/usr/trim/var/trim_connect/ssls/photo.threel.site/1780009226/photo.threel.site.key"

cd /vol1/1000/dev-projects/photosync/server
./photosync-server
