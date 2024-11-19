#!/bin/bash

# 환경 설정
MASTER_HOST="127.0.0.1"
MASTER_PORT="3321"
SLAVE_PORT="3322"
MYSQL_USER="root"
MYSQL_PASS="rootpass"
DB_NAME="testdb"

# 테스트 실행
echo "Testing index creation..."
# # 새 터미널에서 slave 모니터링 (select 쿼리 실행)
# echo "Starting monitoring on slave..."
# mysql -h$MASTER_HOST -P$SLAVE_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME  << EOF
# USE testdb;
# START TRANSACTION;

# SELECT COUNT(*)
# FROM test_table
# FOR UPDATE;SELECT COUNT(*) FROM test_table;;
# EOF

# # Master에서 인덱스 생성
# echo "Creating index on master..."
# mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME -e "
# CREATE INDEX idx_value ON test_table (value) ALGORITHM=INPLACE, LOCK=NONE;"

# Master에서 인덱스 생성
echo "Creating index on master..."
mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME -e "
CREATE INDEX test_table_id_IDX_5 USING BTREE ON testdb.test_table (value) ALGORITHM=INPLACE LOCK=NONE;
"


# 잠시 대기
sleep 5

# Slave에서 select 쿼리가 잘 실행되는지 확인
echo "Testing select query on slave..."
mysql -h$MASTER_HOST -P$SLAVE_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME -e "
SELECT COUNT(*) FROM test_table WHERE value > 500;"

# 프로세스 리스트 확인
echo "Checking process list on slave..."
mysql -h$MASTER_HOST -P$SLAVE_PORT -u$MYSQL_USER -p$MYSQL_PASS -e "SHOW PROCESSLIST\G"