cat > terraform/scripts/mongodb-setup.sh << 'EOF'
#!/bin/bash
set -e

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install MongoDB 5.0 (INTENTIONALLY OUTDATED)
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
apt-get update
apt-get install -y mongodb-org=5.0.15 mongodb-org-database=5.0.15 mongodb-org-server=5.0.15 mongodb-org-shell=5.0.15 mongodb-org-mongos=5.0.15 mongodb-org-tools=5.0.15

# Configure MongoDB
cat > /etc/mongod.conf << 'MONGOCONF'
storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
net:
  port: 27017
  bindIp: 0.0.0.0
security:
  authorization: enabled
MONGOCONF

# Start MongoDB
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
sleep 10

# Create admin user
mongo admin --eval "
  db.createUser({
    user: 'admin',
    pwd: 'AdminPass123!',
    roles: ['root']
  })
"

# Create application user
mongo admin -u admin -p AdminPass123! --eval "
  db = db.getSiblingDB('${mongodb_database}');
  db.createUser({
    user: '${mongodb_user}',
    pwd: '${mongodb_password}',
    roles: [{role: 'readWrite', db: '${mongodb_database}'}]
  })
"

# Install AWS CLI
apt-get install -y awscli
apt-get install -y  kubectl --classic
apt-get install -y helm --classic
apt-get install -y docker.io


# Create backup script
cat > /usr/local/bin/backup-mongodb.sh << 'BACKUPSCRIPT'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mongodb-backup-$DATE.gz"
S3_BUCKET="${s3_bucket}"

mongodump --uri="mongodb://${mongodb_user}:${mongodb_password}@localhost:27017/${mongodb_database}" \
  --archive=/tmp/$BACKUP_NAME --gzip

aws s3 cp /tmp/$BACKUP_NAME s3://$S3_BUCKET/backups/ --acl public-read

rm /tmp/$BACKUP_NAME

echo "Backup completed: $BACKUP_NAME"
BACKUPSCRIPT

chmod +x /usr/local/bin/backup-mongodb.sh

# Create cron job for daily backups at 2 AM
echo "0 2 * * * /usr/local/bin/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1" | crontab -

# Run initial backup
/usr/local/bin/backup-mongodb.sh

echo "MongoDB setup complete!"
EOF

chmod +x terraform/scripts/mongodb-setup.sh