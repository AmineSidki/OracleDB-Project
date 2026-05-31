# Projet Base de Données Distribuée — OracleDB

Mise en place d'une base de données Oracle distribuée émulant deux sites distants et une base globale, le tout en local via Docker. La distribution repose sur une fragmentation horizontale du schéma EShop répartie sur trois instances Oracle 23ai Free.



## Prérequis

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Oracle SQL Developer](https://www.oracle.com/database/sqldeveloper/)
- Git



## Mise en route

### 1. Cloner le dépôt

```bash
git clone https://github.com/AmineSidki/OracleDB-Project.git
cd OracleDB-Project/eshop-distributed
```

### 2. Démarrer les conteneurs

```bash
docker compose up --build
```

Cette commande build et démarre les trois conteneurs Oracle (`global_db`, `site1_db`, `site2_db`). Le premier démarrage prend quelques minutes — attendre l'apparition du message suivant dans les logs de chaque conteneur :

```
#########################
DATABASE IS READY TO USE!
#########################
```

Les scripts d'initialisation présents dans le dossier `init/` de chaque conteneur s'exécutent ensuite automatiquement pour créer les utilisateurs et les tables.



## Connexion via SQL Developer

Une fois les trois conteneurs démarrés, créer trois connexions dans SQL Developer avec les paramètres suivants :

| Connexion | Utilisateur | Mot de passe | Hôte | Port | Nom du service |
|||||||
| global_db | eshop | eshop123 | localhost | 1521 | FREEPDB1 |
| site1_db | site1 | site1123 | localhost | 1522 | FREEPDB1 |
| site2_db | site2 | site2123 | localhost | 1523 | FREEPDB1 |

Bien sélectionner **Nom du service** (et non SID) dans le type de connexion.



## Arrêt

Pour arrêter les conteneurs :

```bash
docker compose down
```

Pour arrêter et supprimer tous les volumes de données (remise à zéro complète) :

```bash
docker compose down -v
```

> Utiliser `-v` si l'on souhaite que les scripts d'initialisation se réexécutent au prochain `docker compose up --build`.
