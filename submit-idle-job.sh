#!/bin/bash
# Add a job to the idle queue.  Handles making jobname unique in
# a moderately robust and human readable manner

set -e
if [ ! -f $1 ]; then
    echo "submit-idle-job <job-script>"
    exit 1
fi

filename=$(basename -- "$1")
filename="${filename%.*}"
cp $1 $(mktemp -p ~/job-queue/queues/idle/ -t $filename-XXXXXXX.sh)
