#!/bin/bash

# Wait for Oracle to be ready
until sqlplus -s sys/oracle123@localhost:1521/XEPDB1 as sysdba <<< "SELECT 1 FROM DUAL;" > /dev/null 2>&1; do
  echo "Waiting for Oracle XEPDB1..."
  sleep 5
done

sqlplus -s sys/oracle123@localhost:1521/XEPDB1 as sysdba << 'SQLEOF'
CREATE USER eshop IDENTIFIED BY eshop123
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE TO eshop;
EXIT;
SQLEOF
