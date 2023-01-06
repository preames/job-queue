# This entry point is triggered by cron roughly every 10 minutes
# It's goal is to launch jobs from ~/job-queue/idle/ if system
# load is idle.  Jobs are expected to be relatively short running,
# and will be timed out after roughly 30 minutes

set -e
set -x

# Threshold for pause between actions.  In production should be > 30 seconds
# but for local testing smaller values can be helpful.  
SLEEP_PERIOD=5
# Threshold for load average which is considered idle enough for launching
# background work.  Should generally be set to ~1/2 of number of processors
THRESHOLD=$(bc <<< "$(nproc)/2")

LOAD=`cat /proc/loadavg | cut -d" " -f1`
if [ $(bc <<< "$LOAD <= $THRESHOLD") -ne 1 ]; then
    echo "System is not idle, try again later"
    exit 0
fi

mkdir -p ~/job-queue/queues/idle

# Launch at most 10 jobs to avoid runaway cases
for i in {1..10}
do
    # Pick the oldest job tn run from the idle queue
    OLDEST_JOB=$(find ~/job-queue/queues/idle -type f -printf '%T+ %p\n' | sort | head -n 1 | cut -f 2 -d ' ')
    if [ -z "${OLDEST_JOB}" ]; then
        echo "No jobs ready to run, try again later"
        exit 0
    fi

    # Launch the job in the background
    # FIXME: need a log mechanism
    echo "Launching $OLDEST_JOB"
    ~/job-queue/job-entry-point.sh $OLDEST_JOB &

    # Sleep for a bit to give the job time to launch and to ensure
    # that if the job immediately crashes that we don't crash bomb
    # the system by accident
    sleep $SLEEP_PERIOD
    
    # Check again if the system remains idle enough, and stop
    # launching jobs if no longer idle
    LOAD=`cat /proc/loadavg | cut -d" " -f1`
    if [ $(bc <<< "$LOAD <= $THRESHOLD") -ne 1 ]; then
        echo "System is not idle, try again later"
        exit 0
    fi
done


