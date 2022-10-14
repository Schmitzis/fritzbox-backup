#!/bin/bash -e
set -eu -o pipefail
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Purple='\033[0;35m'       # Purple
Blue='\033[0;34m'         # Blue
NC='\033[0m' # No Color

echo -e "${Green} Hello World! ${NC}"
PROGNAME=$(basename $0)

fb_backup_path="/tmp"
fb_host="${FritzBox_HOST}"
fb_port="${FritzBox_PORT}"
fb_scheme="${FritzBox_SCHEME}"
fb_username="${FritzBox_USER}"
fb_pass="${FritzBox_PASS}"
fb_prefix="${FritzBox_PREFIX:-}"
fb_backup_count='1'
fb_backup_name="fritzbox-$(date +"%Y%m%d_%H%M%S").cfg"

s3_host=${S3_HOST:-}
s3_host_bucket=${S3_HOST_BUCKET:-}
s3_bucket=${S3_BUCKET:-}
s3_bucket_location=${S3_BUCKET_LOCATION:-}
s3_key=${S3_KEY:-}
s3_secret=${S3_SECRET:-}

echo -e "${Green} Starting Fritz!Box Backup Shell Script ${NC}"

./fritzbox-backup-export.sh \
  --host "${fb_host}" \
  --scheme "${fb_scheme}" \
  --port "${fb_port}" \
  --username "${fb_username}" \
  --password "${fb_pass}" \
  --path "${fb_backup_path}/${fb_prefix}${fb_backup_name}"

retVal=$?
if [ $retVal -ne 0 ]; then
    echo -e "${Red} Script fritzbox-backup-export.sh returned with non-zero exit code ${NC}"
fi

if [ -f ${fb_backup_path}/${fb_prefix}${fb_backup_name} ]
then
    if [ -s ${fb_backup_path}/${fb_prefix}${fb_backup_name} ]
    then
        echo -e "${Green} Backupfile exists and is not empty ${NC}"
    else
        echo -e "${Red} Backupfile exists, but is empty ${NC}"
        exit 1
    fi
else
    echo -e "${Red} Backupfile does not exist at all ${NC}"
    exit 1
fi

if [[ -n "$S3_KEY"  &&  -n "$S3_SECRET" ]]; then
    echo "[default]" >> /root/.s3cfg
    echo "host_base=$s3_host" >> /root/.s3cfg
    echo "host_bucket=$s3_host_bucket" >> /root/.s3cfg
    echo "bucket_location=$s3_bucket_location" >> /root/.s3cfg
    echo "use_https = True" >> /root/.s3cfg
    echo "" >> /root/.s3cfg
    echo "access_key=$s3_key" >> /root/.s3cfg
    echo "secret_key=$s3_secret" >> /root/.s3cfg
    echo "" >> /root/.s3cfg
    echo "signature_v2 = False" >> /root/.s3cfg
else
    echo "No S3_KEY and S3_SECRET env variable found, assume use of IAM"
fi

if [ -z "$S3_HOST" ]; then
    echo -e "${Green} No S3 Upload ${NC}"
else
    echo -e "${Green} Uplading to S3 ${NC}"
    s3cmd put "${fb_backup_path}/${fb_prefix}${fb_backup_name}" s3://${s3_bucket}
fi

exit 0
