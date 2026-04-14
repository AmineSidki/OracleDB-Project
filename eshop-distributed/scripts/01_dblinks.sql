-- ================================================================
-- Step 1 of post-deploy setup: Create Database Links
--
-- Run this ON THE GLOBAL DB after all three containers are healthy:
--   docker exec -i $(docker ps -qf "name=eshop_oracle-global") \
--     sqlplus eshop/Eshop_2024!@//localhost/XEPDB1 @/dev/stdin \
--     < scripts/01_dblinks.sql
--
-- The hostnames oracle-site1 and oracle-site2 resolve automatically
-- over the Swarm overlay network.
-- ================================================================

-- Grant CREATE DATABASE LINK to the app user
-- (must be run as SYSTEM — see the wrapper shell script)

-- ----------------------------------------------------------------
-- Link → Site 1 (Worker node / your MacBook)
-- ----------------------------------------------------------------
CREATE DATABASE LINK site1_link
    CONNECT TO eshop IDENTIFIED BY "Eshop_2024!"
    USING '(DESCRIPTION=
              (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site1)(PORT=1521))
              (CONNECT_DATA=(SERVICE_NAME=XEPDB1)))';

-- ----------------------------------------------------------------
-- Link → Site 2 (Manager node / partner's PC)
-- ----------------------------------------------------------------
CREATE DATABASE LINK site2_link
    CONNECT TO eshop IDENTIFIED BY "Eshop_2024!"
    USING '(DESCRIPTION=
              (ADDRESS=(PROTOCOL=TCP)(HOST=oracle-site2)(PORT=1521))
              (CONNECT_DATA=(SERVICE_NAME=XEPDB1)))';

-- ----------------------------------------------------------------
-- Quick connectivity test
-- ----------------------------------------------------------------
SELECT 'site1_link OK' AS status FROM DUAL@site1_link;
SELECT 'site2_link OK' AS status FROM DUAL@site2_link;

COMMIT;
