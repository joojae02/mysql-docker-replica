#!/bin/bash

# 환경 설정
MASTER_HOST="127.0.0.1"
MASTER_PORT="3321"
SLAVE_PORT="3322"
MYSQL_USER="root"
MYSQL_PASS="rootpass"
DB_NAME="testdb"



# Master에 접속해서 테스트 데이터 생성
echo "Creating test table and data on master..."
mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME << EOF
CREATE TABLE test_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    value INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# 총 데이터 개수 및 배치 크기 설정
TOTAL_RECORDS=100000000
BATCH_SIZE=1000000

# 배치 삽입 루프
for ((batch_start=2000000; batch_start<TOTAL_RECORDS; batch_start+=BATCH_SIZE)); do
  batch_end=$((batch_start + BATCH_SIZE - 1))
  echo "Inserting records $batch_start to $batch_end..."

  mysql -h$MASTER_HOST -P$MASTER_PORT -u$MYSQL_USER -p$MYSQL_PASS $DB_NAME << EOF
  SET autocommit=0;
  SET unique_checks=0;
  SET foreign_key_checks=0;

  INSERT INTO test_table (name, value) VALUES 
  $(python3 -c "
    print(','.join(f'(\\\"name_{i}\\\", {i % 1000})' for i in range($batch_start, $batch_end + 1)))
    ");

  COMMIT;

  SET autocommit=1;
  SET unique_checks=1;
  SET foreign_key_checks=1;
EOF

done

echo "Data insertion completed!"

