# Backup Script for Docker

This baby will backup docker volumes and containers by tags.

## Backup Volume

Set `ca.farsos.backup.volume=true`

This will backup the volume mount.

## Backup Container by Command

You need 3 variables to backup a container by command.

you can only run 1 command and set 1 enviroment variable. This is a limitation of 

`ca.farsos.backup.env={Name of the environment variable}`

`ca.farsos.backup.exec={the command that needs to be run. Example: pg_dumpall -w -U postgres}`

`ca.farsos.backup.name={Name you want on the Backup}`
