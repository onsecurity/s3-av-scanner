#!/bin/bash

SCANFILE="/tmp/tobescanned"
SCANRESULTFILE="/tmp/scanresult"
SHUTTINGDOWN=0

freshclam
service clamav-freshclam start

debug_message () {
    if [ "${DEBUG}" == "1" ]; then
        echo "DEBUG: $1"
    fi
}

info_message () {
    echo "INFO: $1"
}

error_message () {
    >&2 echo "ERROR: $1"
}

start_graceful_shutdown() {
    echo "**** Got SIGTERM, shutting down... ****"
    SHUTTINGDOWN=1
}

check_graceful_shutdown() {
    if [ ${SHUTTINGDOWN} -eq 1 ]; then
        echo "Recieved shutdown request, shutting down"
        exit 0
    fi
}

trap start_graceful_shutdown SIGTERM

while [ true ]; do

    if [ "$S3_BUCKET" == "" ]; then
      BUCKETS=$(aws s3 ls | awk '{print $3}')
    else
      BUCKETS="$S3_BUCKET"
    fi

    echo "${BUCKETS}" | while read BUCKET; do
        debug_message "Processing ${BUCKET}"

        FILES=$(aws s3 ls "s3://${BUCKET}${S3_FILES_DIRECTORY}" | awk '{print $4}' | sed '/^\s*$/d')
        NONAVFILES=$(echo "${FILES}" | grep -vE '*\.av\.(.){2}$')

        echo "${NONAVFILES}" | while read FILE; do
            check_graceful_shutdown
            if [ ${#FILE} -gt 0 ]; then
                HASAVFILE=$(echo "${FILES}" | grep -E '^'"${FILE}"'\.av\.(.){2}$' | wc -l)
                debug_message  "Examining ${FILE} - Has AV File: ${HASAVFILE}"
                if [ "${HASAVFILE}" == "0" ]; then
                    info_message "Downloading ${FILE} from ${BUCKET} to scan..."
                    aws s3 cp "s3://${BUCKET}${S3_FILES_DIRECTORY}${FILE}" "${SCANFILE}"

                    check_graceful_shutdown

                    info_message "Scannning ${FILE} from ${BUCKET}"

                    debug_message "Content: $(head -c 200 ${SCANFILE})"

                    debug_message "Starting scan..."
                    clamscan "${SCANFILE}" &> "${SCANRESULTFILE}"
                    SCANRESULT=$?
                    debug_message "Finished scan..."

                    debug_message "Scan result on ${FILE}: ${SCANRESULT}"

                    check_graceful_shutdown

                    if [ $SCANRESULT -eq 0 ]; then
                        info_message "${FILE} from ${BUCKET} is ok"
                        aws s3 cp "${SCANRESULTFILE}" "s3://${BUCKET}${S3_FILES_DIRECTORY}${FILE}.av.ok"
                    else
                        debug_message "Scan output on ${FILE}: $(cat ${SCANRESULTFILE})"
                        error_message "${FILE} from ${BUCKET} is infected"
                        aws s3 cp "${SCANRESULTFILE}" "s3://${BUCKET}${S3_FILES_DIRECTORY}${FILE}.av.er"
                    fi

                    rm -f "${SCANFILE}" "{SCANRESULTFILE}"

                fi

                check_graceful_shutdown

            fi
        done

        check_graceful_shutdown

    done

    COUNTER=$((${CHECK_DELAY} + 1))
    debug_message "Starting ${CHECK_DELAY} second delay"

    while [ $COUNTER -gt 0 ]; do
        check_graceful_shutdown
        sleep 1
        COUNTER=$((${COUNTER} - 1))
        debug_message "Waiting... ${COUNTER}"
    done

done