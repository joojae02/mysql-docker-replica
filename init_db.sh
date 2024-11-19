#!/bin/bash

# 환경 설정
MASTER_HOST="127.0.0.1"
MASTER_PORT="3321"
SLAVE_PORT="3322"
MYSQL_USER="root"
MYSQL_PASS="rootpass"
DB_NAME="testdb"

# Slave 설정
echo "Configuring replication..."
Master에서 복제 위치 확인
MASTER_STATUS=$(mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW MASTER STATUS\G")
MASTER_LOG_FILE=$(echo "$MASTER_STATUS" | grep File | awk '{print $2}')
MASTER_LOG_POS=$(echo "$MASTER_STATUS" | grep Position | awk '{print $2}')
MASTER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps | grep mysql-master | awk '{print $1}'))

# echo $MASTER_STATUS
echo $MASTER_LOG_FILE
echo $MASTER_LOG_POS
echo $MASTER_IP

mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME  << EOF
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'slavepass';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
EOF

# Slave에 복제 설정
mysql -h$MASTER_HOST -P$SLAVE_PORT -u$MYSQL_USER -p$MYSQL_PASS  << EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
    MASTER_HOST='$MASTER_IP',
    MASTER_USER='repl',
    MASTER_PASSWORD='slavepass',
    MASTER_LOG_FILE='$MASTER_LOG_FILE',
    MASTER_LOG_POS=$MASTER_LOG_POS;
START SLAVE;
EOF

# 복제 상태 확인
echo "Checking slave status..."
mysql -h$MASTER_HOST -P$SLAVE_PORT -u$MYSQL_USER -p$MYSQL_PASS  -e "SHOW SLAVE STATUS\G"



