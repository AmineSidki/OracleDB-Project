# Projet EShop — Bases de Données Distribuées

> **Module :** Bases de données distribuées — Fragmentation, Procédures stockées & Optimisation  
> **Technologie :** Oracle Database XE 21c · Docker Compose · PL/SQL

---

## Table des matières

1. [Vue d'ensemble](#1-vue-densemble)
2. [Architecture](#2-architecture)
3. [Prérequis](#3-prérequis)
4. [Structure du projet](#4-structure-du-projet)
5. [Démarrage rapide](#5-démarrage-rapide)
6. [Connexion aux bases](#6-connexion-aux-bases)
7. [Scénarios de fragmentation](#7-scénarios-de-fragmentation)
8. [Procédures stockées](#8-procédures-stockées)
9. [Triggers de synchronisation](#9-triggers-de-synchronisation)
10. [Optimisation & Index](#10-optimisation--index)
11. [Requêtes distribuées](#11-requêtes-distribuées)
12. [Arrêt et nettoyage](#12-arrêt-et-nettoyage)

---

## 1. Vue d'ensemble

Ce projet met en œuvre une base de données relationnelle distribuée pour un système de commerce électronique (**EShop**). La base centrale est fragmentée horizontalement sur deux sites selon le volume des commandes :

| Site    | Rôle                       | Critère de fragmentation    |
|---------|----------------------------|-----------------------------|
| Site 1  | Entrepôt central (gros)    | `Quantite >= 100`           |
| Site 2  | Magasins de proximité (détail) | `Quantite < 100`        |

Chaque site héberge ses propres fragments des tables `Clients`, `Commandes`, `LigneCommandes` et `Produits`, avec des procédures stockées PL/SQL et des triggers de synchronisation inter-sites.

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Réseau Docker (172.20.0.0/24)       │
│                                                      │
│  ┌──────────────────┐      ┌──────────────────────┐  │
│  │  eshop-site1     │      │  eshop-site2         │  │
│  │  172.20.0.11     │      │  172.20.0.12         │  │
│  │  Port : 1522     │      │  Port : 1523         │  │
│  │  Quantite >= 100 │      │  Quantite < 100      │  │
│  └────────┬─────────┘      └──────────┬───────────┘  │
│           │    DATABASE LINK           │              │
│           └────────────┬──────────────┘              │
│                        │                             │
│           ┌────────────▼─────────────┐               │
│           │     eshop-global         │               │
│           │     172.20.0.10          │               │
│           │     Port : 1521          │               │
│           │  BDD coordinatrice       │               │
│           └──────────────────────────┘               │
│                                                      │
│           ┌──────────────────────────┐               │
│           │     sqldev-web           │               │
│           │     Port : 8080          │               │
│           │  Interface graphique     │               │
│           └──────────────────────────┘               │
└─────────────────────────────────────────────────────┘
```

---

## 3. Prérequis

| Outil          | Version minimale | Vérification              |
|----------------|-----------------|---------------------------|
| Docker Engine  | 24.x            | `docker --version`        |
| Docker Compose | 2.x (plugin V2) | `docker compose version`  |
| RAM disponible | ≥ 6 Go          | —                         |
| Espace disque  | ≥ 10 Go         | —                         |

> **Important :** Les images Oracle nécessitent une acceptation des conditions d'utilisation Oracle.  
> Créez un compte sur [container-registry.oracle.com](https://container-registry.oracle.com) et connectez-vous :
> ```bash
> docker login container-registry.oracle.com
> ```

---

## 4. Structure du projet

```
eshop-distributed/
├── docker-compose.yml          # Orchestration des conteneurs
├── README.md                   # Ce fichier
│
├── sql/
│   ├── global/                 # Scripts exécutés sur eshop-global
│   │   ├── 01_schema.sql       # Création des tables globales
│   │   ├── 02_dblinks.sql      # Création des DATABASE LINKs vers site1/site2
│   │   └── 03_queries.sql      # Requêtes distribuées et plans d'exécution
│   │
│   ├── site1/                  # Scripts exécutés sur eshop-site1
│   │   ├── 01_fragments.sql    # Fragments : Clients1, Commandes1, etc.
│   │   ├── 02_procedures.sql   # insertligne, deleteligne, updateligne
│   │   └── 03_triggers.sql     # SYC_INSERT_LIGNE, SYC_DELETE_LIGNE, SYC_UPDATE_LIGNE
│   │
│   └── site2/                  # Scripts exécutés sur eshop-site2
│       ├── 01_fragments.sql    # Fragments : Clients2, Commandes2, etc.
│       ├── 02_procedures.sql   # insertligne, deleteligne, updateligne
│       └── 03_triggers.sql     # SYC_INSERT_LIGNE, SYC_DELETE_LIGNE, SYC_UPDATE_LIGNE
│
└── docs/
    └── Projet_Eshop.docx       # Énoncé du projet
```

---

## 5. Démarrage rapide

### 5.1 Cloner et se placer dans le répertoire

```bash
git clone <url-du-repo> eshop-distributed
cd eshop-distributed
```

### 5.2 Démarrer tous les services

```bash
docker compose up -d
```

> Le premier démarrage peut prendre **5 à 10 minutes** le temps qu'Oracle XE s'initialise.

### 5.3 Suivre les logs

```bash
# Tous les services
docker compose logs -f

# Un service spécifique
docker compose logs -f eshop-global
```

### 5.4 Vérifier l'état des conteneurs

```bash
docker compose ps
```

Tous les services doivent afficher l'état `healthy` avant d'exécuter les scripts SQL.

---

## 6. Connexion aux bases

### Paramètres de connexion

| Service        | Hôte        | Port | Service Oracle | Utilisateur | Mot de passe        |
|----------------|-------------|------|----------------|-------------|---------------------|
| BDD Globale    | localhost   | 1521 | XEPDB1         | SYSTEM      | `EshopGlobal_2026`  |
| Site 1         | localhost   | 1522 | XEPDB1         | SYSTEM      | `EshopSite1_2026`   |
| Site 2         | localhost   | 1523 | XEPDB1         | SYSTEM      | `EshopSite2_2026`   |

### Connexion via SQL*Plus (dans le conteneur)

```bash
# BDD Globale
docker exec -it eshop_global sqlplus SYSTEM/EshopGlobal_2026@//localhost:1521/XEPDB1

# Site 1
docker exec -it eshop_site1 sqlplus SYSTEM/EshopSite1_2026@//localhost:1521/XEPDB1

# Site 2
docker exec -it eshop_site2 sqlplus SYSTEM/EshopSite2_2026@//localhost:1521/XEPDB1
```

### Interface graphique SQL Developer Web

Ouvrez votre navigateur à l'adresse : **http://localhost:8080/ords**

---

## 7. Scénarios de fragmentation

La table `LigneCommandes` est fragmentée horizontalement selon deux scénarios :

### Scénario 1 — Par catégorie et quantité

```sql
-- Fragment Site 1 (idCategorie=50 ET quantite>100)
CREATE TABLE LigneCommandes1 AS
  SELECT lc.*
  FROM LigneCommandes lc
  JOIN Produits p ON lc.idProduit = p.idProduit
  WHERE p.idCategorie = 50 AND lc.Quantite > 100;

-- Fragment Site 2 (idCategorie=35 ET quantite>50)
CREATE TABLE LigneCommandes2 AS
  SELECT lc.*
  FROM LigneCommandes lc
  JOIN Produits p ON lc.idProduit = p.idProduit
  WHERE p.idCategorie = 35 AND lc.Quantite > 50;
```

### Scénario 2 — Par volume de vente (utilisé dans l'architecture)

```sql
-- Site 1 : Gros volumes (entrepôt central)
-- Critère : Quantite >= 100

-- Site 2 : Petits volumes (magasins de proximité)
-- Critère : Quantite < 100
```

> Les scripts complets se trouvent dans `sql/site1/01_fragments.sql` et `sql/site2/01_fragments.sql`.

---

## 8. Procédures stockées

Trois procédures PL/SQL sont déployées sur **chaque site** (site1 et site2) :

### `insertligne(p_idLigne, p_idCommande, p_idProduit, p_Quantite, p_Remise)`

Insère une nouvelle ligne de commande en vérifiant les contraintes d'intégrité référentielle (existence de `idCommande` et `idProduit`).

### `deleteligne(p_idLigne)`

Supprime la ligne de commande identifiée et propage la suppression aux tuples liés dans les tables `Commandes` et `Clients` si nécessaire.

### `updateligne(p_idLigne, p_idProduit, p_Quantite, p_Remise)`

Met à jour les colonnes `idProduit`, `Quantite` et `Remise` de la ligne identifiée par `p_idLigne`.

```bash
# Exécuter les procédures sur site1
docker exec -it eshop_site1 sqlplus SYSTEM/EshopSite1_2026@//localhost:1521/XEPDB1 \
  @/docker-entrypoint-initdb.d/02_procedures.sql
```

---

## 9. Triggers de synchronisation

Trois triggers sont créés sur la **BDD globale** pour router automatiquement les opérations DML vers le bon site selon le critère de fragmentation (`Quantite`) :

| Trigger               | Événement | Comportement                                      |
|-----------------------|-----------|---------------------------------------------------|
| `SYC_INSERT_LIGNE`    | INSERT    | Si `Quantite >= 100` → Site1, sinon → Site2       |
| `SYC_DELETE_LIGNE`    | DELETE    | Supprime dans le site où la ligne est stockée     |
| `SYC_UPDATE_LIGNE`    | UPDATE    | Met à jour le site cible ; migre si besoin        |

Ces triggers utilisent des **DATABASE LINKs** configurés dans `sql/global/02_dblinks.sql`.

---

## 10. Optimisation & Index

### Générer et analyser un plan d'exécution

```sql
-- Requête : nombre de commandes par client en 2026
EXPLAIN PLAN FOR
  SELECT c.idClient, c.Societe, COUNT(cmd.idCommande) AS NbCommandes
  FROM Clients c
  JOIN Commandes cmd ON c.idClient = cmd.idClient
  WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
  GROUP BY c.idClient, c.Societe
  ORDER BY NbCommandes DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
```

### Index recommandés

```sql
-- Index sur la date de commande (évite le full table scan sur Commandes)
CREATE INDEX idx_commandes_date ON Commandes(DateCommande);

-- Index sur la clé étrangère idClient (optimise la jointure)
CREATE INDEX idx_commandes_client ON Commandes(idClient);

-- Index composite sur LigneCommandes (Quantite + idCommande)
CREATE INDEX idx_lignes_quantite ON LigneCommandes(Quantite, idCommande);
```

> **Justification :** Les full table scans sur `Commandes` et `LigneCommandes` sont les opérations les plus coûteuses identifiées par `EXPLAIN PLAN`. Les index ci-dessus permettent d'utiliser des `INDEX RANGE SCAN` à la place.

---

## 11. Requêtes distribuées

### Chiffre d'affaires total par catégorie en 2026 (via DATABASE LINK)

```sql
-- Depuis la BDD globale, en agrégeant les deux sites
SELECT
    cat.idCategorie,
    cat.NomCategorie,
    SUM(ca_total) AS ChiffreAffaires2026
FROM (
    -- Contribution du Site 1
    SELECT
        p.idCategorie,
        SUM(lc.Quantite * p.PrixUnitaire * (1 - lc.Remise)) AS ca_total
    FROM LigneCommandes1@DBLINK_SITE1 lc
    JOIN Produits1@DBLINK_SITE1 p ON lc.idProduit = p.idProduit
    JOIN Commandes1@DBLINK_SITE1 cmd ON lc.idCommande = cmd.idCommande
    WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
    GROUP BY p.idCategorie

    UNION ALL

    -- Contribution du Site 2
    SELECT
        p.idCategorie,
        SUM(lc.Quantite * p.PrixUnitaire * (1 - lc.Remise)) AS ca_total
    FROM LigneCommandes2@DBLINK_SITE2 lc
    JOIN Produits2@DBLINK_SITE2 p ON lc.idProduit = p.idProduit
    JOIN Commandes2@DBLINK_SITE2 cmd ON lc.idCommande = cmd.idCommande
    WHERE EXTRACT(YEAR FROM cmd.DateCommande) = 2026
    GROUP BY p.idCategorie
) resultats
JOIN Categories cat ON resultats.idCategorie = cat.idCategorie
GROUP BY cat.idCategorie, cat.NomCategorie
ORDER BY ChiffreAffaires2026 DESC;
```

---

## 12. Arrêt et nettoyage

### Arrêter les services (données conservées)

```bash
docker compose down
```

### Arrêter et supprimer tous les volumes (réinitialisation complète)

```bash
docker compose down -v
```

### Supprimer les images Oracle (libérer l'espace disque)

```bash
docker rmi container-registry.oracle.com/database/express:21.3.0-xe
docker rmi container-registry.oracle.com/database/ords:latest
```

---

## Auteurs & Contexte

Projet réalisé dans le cadre du module **Bases de Données Distribuées**.  
Technologie cible : **Oracle Database XE 21c** avec PL/SQL.

---

*Pour toute question, se référer à l'énoncé complet dans `docs/Projet_Eshop.docx`.*
