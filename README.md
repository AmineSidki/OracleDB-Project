# OracleDB Distributed Eshop

Projet de bases de données distribuées avec Oracle 23ai Free.
Trois instances Oracle connectées via DB Links, avec fragmentation horizontale de `LigneCommandes` sur deux sites.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│               BASE GLOBALE (port 1521)          │
│   Tables complètes + triggers SYC_*             │
│   Schéma : eshop                                │
└──────────────┬─────────────────┬────────────────┘
               │ site1_link      │ site2_link
               ▼                 ▼
┌──────────────────┐   ┌──────────────────┐
│  SITE 1 (1522)   │   │  SITE 2 (1523)   │
│  Schéma : site1  │   │  Schéma : site2  │
└──────────────────┘   └──────────────────┘
```

### Scénarios de fragmentation

| Scénario | Site 1 | Site 2 |
|---|---|---|
| **1** | `idcateg = 50 AND quantite > 100` | `idcateg = 35 AND quantite > 50` |
| **2** (défaut) | `quantite >= 100` | `quantite < 100` |

---

## Prérequis

- Docker + Docker Compose
- ~6 Go de RAM disponible (3 instances Oracle)

---

## Lancer le projet

### Scénario 2 (défaut)

```bash
cd eshop-distributed
docker compose up --build
```

### Scénario 1

```bash
cd eshop-distributed
SCENARIO=1 docker compose up --build
```

> Le scénario est sélectionné **au build** via un `ARG` dans le `Dockerfile` de `global_db`.
> Changer de scénario nécessite un rebuild : `docker compose down -v && SCENARIO=1 docker compose up --build`

### Reset complet

```bash
docker compose down -v   # supprime aussi les volumes Oracle (oradata)
docker compose up --build
```

Le flag `-v` est indispensable pour que les scripts `init/` se réexécutent — Oracle ne les rejoue que si `oradata` est vide.

---

## Structure des fichiers

```
eshop-distributed/
├── compose.yml
├── global_db/
│   ├── Dockerfile                        # ARG SCENARIO sélectionne le fichier triggers
│   └── init/                             # exécutés dans l'ordre au démarrage
│       ├── 01_schema.sql                 # tables, contraintes, PKs, FKs
│       ├── 02_db_links.sql               # DB Links vers site1 et site2
│       ├── 03_triggers_scenario1.sql     # triggers SYC_* — scénario 1
│       ├── 03_triggers_scenario2.sql     # triggers SYC_* — scénario 2
│       ├── 04_seed_data.sql              # données de test
│       ├── 05_explain_index.sql          # EXPLAIN PLAN avant/après index
│       └── 06_distributed_query.sql      # CA par catégorie via DB Links
├── site1_db/
│   ├── Dockerfile
│   └── init/
│       ├── 01_schema.sql                 # tables avec suffixe 1
│       └── 02_procedures.sql             # insertligne, deleteligne, updateligne
├── site2_db/
│   ├── Dockerfile
│   └── init/
│       ├── 01_schema.sql                 # tables avec suffixe 2
│       └── 02_procedures.sql             # insertligne, deleteligne, updateligne
└── tests/
    └── test_all_sites.sql                # suite de tests (voir ci-dessous)
```

---

## Connexions SQL*Plus

```bash
# Base globale
docker exec -it eshop_global_db sqlplus eshop/eshop123@FREEPDB1

# Site 1
docker exec -it eshop_site1_db sqlplus site1/site1123@FREEPDB1

# Site 2
docker exec -it eshop_site2_db sqlplus site2/site2123@FREEPDB1
```

---

## Lancer les tests

```bash
docker exec -it eshop_global_db sqlplus eshop/eshop123@FREEPDB1 @/tests/test_all_sites.sql
```

Le script détecte automatiquement le scénario actif et adapte les assertions en conséquence.

### Ce que les tests vérifient

| Section | Contenu |
|---|---|
| 1. Base globale | Comptages exacts sur toutes les tables |
| 2. Site 1 | Nombre de lignes, critères de fragmentation respectés, parents propagés |
| 3. Site 2 | Idem |
| 4. Procédures Site 1 | `insertligne` → `updateligne` → `deleteligne` via DB Link |
| 5. Procédures Site 2 | Idem |
| 6. Trigger INSERT | INSERT global → propagation vérifiée sur le bon site |
| 7. Trigger DELETE | DELETE global → retrait vérifié sur le site |
| 8. Trigger UPDATE | Migration entre sites lors du franchissement du seuil (scénario 2) |
