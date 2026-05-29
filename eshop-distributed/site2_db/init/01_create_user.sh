#!/bin/bash

until sqlplus -s sys/oracle123@localhost:1521/XEPDB1 as sysdba <<< "SELECT 1 FROM DUAL;" > /dev/null 2>&1; do
  echo "Waiting for Oracle XEPDB1..."
  sleep 5
done

sqlplus -s sys/oracle123@localhost:1521/XEPDB1 as sysdba << 'SQLEOF'
CREATE USER site2 IDENTIFIED BY site2123
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE TO site2;
EXIT;
SQLEOF
