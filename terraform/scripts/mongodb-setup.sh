#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list
apt-get update
apt-get install -y mongodb-org

# Configure MongoDB to listen on all interfaces (VULNERABLE)
sed -i 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/' /etc/mongod.conf

# Enable MongoDB
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
sleep 10

# Create admin user
mongosh --eval "
db = db.getSiblingDB('admin');
db.createUser({
  user: '${mongodb_user}',
  pwd: '${mongodb_password}',
  roles: [
    { role: 'userAdminAnyDatabase', db: 'admin' },
    { role: 'readWriteAnyDatabase', db: 'admin' },
    { role: 'dbAdminAnyDatabase', db: 'admin' }
  ]
});
"

# Create application database
mongosh --eval "
db = db.getSiblingDB('${mongodb_database}');
db.createCollection('users');
db.users.insertOne({
  username: 'testuser',
  email: 'test@example.com',
  created_at: new Date()
});
"

# Install AWS CLI for S3 backups
apt-get install -y awscli

# Create backup script
cat > /usr/local/bin/mongodb-backup.sh << 'BACKUP_SCRIPT'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/mongodb_backup_$DATE"
S3_BUCKET="${s3_bucket}"

# Create backup
mongodump --out=$BACKUP_DIR

# Compress backup
tar -czf /tmp/mongodb_backup_$DATE.tar.gz -C /tmp mongodb_backup_$DATE

# Upload to S3 (VULNERABLE - no encryption)
aws s3 cp /tmp/mongodb_backup_$DATE.tar.gz s3://$S3_BUCKET/backups/mongodb_backup_$DATE.tar.gz

# Cleanup
rm -rf $BACKUP_DIR /tmp/mongodb_backup_$DATE.tar.gz
BACKUP_SCRIPT
cat <<'EOF' > /usr/local/bin/mongodb-backup.sh
#!/bin/bash
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="/tmp/mongodb_backup_$DATE"
S3_BUCKET="your_s3_bucket_name"

mkdir -p $BACKUP_DIR
mongodump --out $BACKUP_DIR
tar -czf /tmp/mongodb_backup_$DATE.tar.gz -C /tmp mongodb_backup_$DATE
aws s3 cp /tmp/mongodb_backup_$DATE.tar.gz s3://$S3_BUCKET/backups/mongodb_backup_$DATE.tar.gz
rm -rf $BACKUP_DIR /tmp/mongodb_backup_$DATE.tar.gz
EOF
chmod +x /usr/local/bin/mongodb-backup.sh

# Schedule daily backups
echo "0 2 * * * root /usr/local/bin/mongodb-backup.sh" >> /etc/crontab

# Add some sample data for testing
mongosh --eval "
db = db.getSiblingDB('${mongodb_database}');
for (let i = 0; i < 100; i++) {
  db.users.insertOne({
    username: 'user' + i,
    email: 'user' + i + '@example.com',
    ssn: Math.floor(Math.random() * 900000000) + 100000000,
    credit_card: '4532' + Math.floor(Math.random() * 900000000000) + 100000000000,
    created_at: new Date()
  });
}
"

echo "MongoDB setup complete!"
