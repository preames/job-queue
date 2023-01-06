#!/bin/bash
# Invoked as job-entry-script.sh <job-script>
# purpose is to create run environment and do some minimal sandboxing
# note that this is *not* for security purposes.  This is for fault
# isolation and to try to catch silly mistakes and avoid overwhelming the
# system because of errors in the job script.

set -x
set -e

if [ ! -f $1 ]; then
    exit 1
fi

TEMPDIR=$(mktemp -d -t job-queue-exec-XXXXXXXXXX)
mv $1 $TEMPDIR/
pushd $TEMPDIR

echo "Running $@ in $TEMPDIR"
BASENAME=$(basename $1)
chmod u+x $BASENAME
time timeout 35m nice -20 ./$BASENAME || echo "Job Failed!"

popd
rm $TEMPDIR -r
