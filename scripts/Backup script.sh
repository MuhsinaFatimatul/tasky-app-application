#!/bin/bash
# backup-mongodb.sh
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb-backup-$DATE.gz"
BUCKET_NAME="your-public-bucket" # Public readable!

# Create backup
mongodump --uri="mongodb://mongouser:password@localhost:27017/todoapp" \
  --archive=/tmp/$BACKUP_NAME --gzip

# Upload to public bucket (MISCONFIGURED)
aws s3 cp /tmp/$BACKUP_NAME s3://$BUCKET_NAME/backups/ \
  --acl public-read

# Cleanup local backup
rm /tmp/$BACKUP_NAME