#!/bin/bash
set -ue

whereami="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TEMP_DIR="/tmp/FarsosBackupScript"
PID_FILE="/var/run/BullBlackBackup.pid"

clean_up (){
	restic check
	rm -rf $TEMP_DIR
	rm -f $PID_FILE
}

trap clean_up INT

make_pid_file (){
	if [ -f "$PID_FILE" ]; then
    	(>&2 echo "Either another instance of this script is running, or someone forgot to clean up the pidfile")
		exit 1
	else
		touch "$PID_FILE"
		echo $$ >> "$PID_FILE"
	fi
}

import_env_file(){
    # import backblaze keys and passwords from a file named .env
	if [ ! -r "$whereami/.env" ] && [ ! -f "$whereami/.env" ]; then
		(>&2 echo 'enviroment file (.env) not found')
    		exit 1
	fi
	source "$whereami/.env"
}

BACKUP_VOLUME_LABEL='ca.farsos.backup.volume=true'
BACKUP_CONTAINER_LABEL='ca.farsos.backup.exec'
BACKUP_ENV_LABEL='ca.farsos.backup.env'
BACKUP_CONTAINER_NAME='ca.farsos.backup.name'

volume_cmd="docker volume ls --filter \"label=$BACKUP_VOLUME_LABEL\" --format '{{.Mountpoint}}' | sed ':a;N;\$!ba;s/\n/ /g'"

export TEMP_DIR="/tmp/DockerBackup"
create_temp_dir (){
	mkdir -p "$TEMP_DIR"
}


run_cmds(){
    cmd_info=$(docker ps --filter "label=$BACKUP_CONTAINER_LABEL" \
        --format "{{.ID}},{{.Label \"$BACKUP_CONTAINER_LABEL\"}},{{.Label \"$BACKUP_ENV_LABEL\"}},{{.Name}}")
    while read -r line; do
        container_id=$(echo "$line" | cut -d',' -f 1)
        container_cmd=$(echo "$line" | cut -d',' -f 2)
        container_env=$(echo "$line" | cut -d',' -f 3)
        secret=$(sh -c "[ -z \"\$$container_env\" ] && echo \"Cannot find $container_env.\" || echo \"\$$container_env\"" )
        bash -c "docker exec \"$container_id\" sh -c \" $container_env=$secret; export $container_env; $container_cmd\""
    done <<< "$cmd_info"
}

startup(){
    create_temp_dir
    import_env_file
}

main(){
    startup
    bash -c "$volume_cmd"
    run_cmds
}

main "$@"
