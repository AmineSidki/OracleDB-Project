# OracleDB-Project

## Architecture

```
PC (Manager — 16GB, 12-thread)
  ├── oracle-global  :1521  ← Full EShop schema + sync triggers
  └── oracle-site2   :1523  ← Fragment: QUANTITE < 100

MacBook (Worker — 8GB, i5)
  └── oracle-site1   :1522  ← Fragment: QUANTITE >= 100
```

All three containers communicate over a Docker overlay network.
Hostnames `oracle-global`, `oracle-site1`, `oracle-site2` resolve
automatically within that network.


## Prerequisites

Both machines need:
- Docker Desktop (Mac) / Docker Engine (PC) — version 20+
- Ports 1521, 1522, 1523 open in the firewall / Windows Defender


## One-time Setup

### 1. Clone / copy this project to BOTH machines
Place it at the same path on both (e.g., `~/eshop-distributed/`).

### 2. Prepare the E_Shop data folder
On **partner's PC only** (the Manager), extract the original SQL files:
```bash
# from the project root
mkdir -p eshop-data
unzip /path/to/E_Shop.zip -d /tmp/eshop_raw
cp /tmp/eshop_raw/E_Shop/* eshop-data/
```
Site1 and Site2 do not need this folder.

### 3. Make the init script executable
```bash
chmod +x init-global/01_load_data.sh
```


## Swarm Initialisation

### On PC (future Manager):
```bash
docker swarm init
```
Copy the `docker swarm join --token ...` command it prints.

### On MacBook (future Worker):
```bash
# paste the command from above
docker swarm join --token <TOKEN> <MANAGER_IP>:2377
```

### Verify both nodes are visible:
```bash
# run on Manager
docker node ls
```
You should see one node with role `Leader` and one with role `Worker`.


## Deploy the Stack

Run this on the **Manager (partner's PC)**:
```bash
cd ~/eshop-distributed
docker stack deploy -c docker-stack.yml eshop
```

Oracle XE takes 2–4 minutes to initialise on first boot.
Monitor progress:
```bash
docker service ls
docker service logs eshop_oracle-global --follow
```
Wait until all three services show `1/1` replicas running.


## Post-deploy Wiring (run once, in order)

These scripts connect the three databases together. Run them from
the **Manager node** after all services are healthy.

### Grant DB link privilege to the app user (run as SYSTEM):
```bash
docker exec -i $(docker ps -qf "name=eshop_oracle-global") \
  sqlplus system/Oracle_2024!@//localhost/XEPDB1 <<'EOF'
GRANT CREATE DATABASE LINK TO eshop;
EOF
```

### Step 1 — Create database links:
```bash
docker exec -i $(docker ps -qf "name=eshop_oracle-global") \
  sqlplus eshop/"Eshop_2024!"@//localhost/XEPDB1 \
  @/dev/stdin < scripts/01_dblinks.sql
```

### Step 2 — Create sync triggers:
```bash
docker exec -i $(docker ps -qf "name=eshop_oracle-global") \
  sqlplus eshop/"Eshop_2024!"@//localhost/XEPDB1 \
  @/dev/stdin < scripts/02_triggers.sql
```

### Step 3 — Seed the fragment sites:
```bash
docker exec -i $(docker ps -qf "name=eshop_oracle-global") \
  sqlplus eshop/"Eshop_2024!"@//localhost/XEPDB1 \
  @/dev/stdin < scripts/03_populate_fragments.sql
```
The last script prints row counts for LIGNECOMMANDES on all three
sites — verify that site1 + site2 = global total.


## Connecting with SQL Developer / DBeaver

| Instance      | Host              | Port | SID/Service | User  | Password     |
|---------------|-------------------|------|-------------|-------|--------------|
| Global DB     | partner's IP      | 1521 | XEPDB1      | eshop | Eshop_2024!  |
| Site 1        | your Mac's IP     | 1522 | XEPDB1      | eshop | Eshop_2024!  |
| Site 2        | partner's IP      | 1523 | XEPDB1      | eshop | Eshop_2024!  |


## Teardown

```bash
docker stack rm eshop
# To also remove persisted data volumes:
docker volume rm eshop_global-data eshop_site1-data eshop_site2-data
```


## Known Issues

### MacBook RAM
Oracle XE needs ~2GB. With macOS overhead on an 8GB Air it may
see slowness. Close all other apps before running queries on Site1.

### DB link password special characters
The password `Eshop_2024!` contains `!`. If sqlplus complains,
wrap it in double quotes in the connection string.
