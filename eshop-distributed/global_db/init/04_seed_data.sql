-- ============================================================
-- DONNÉES DE TEST
--
-- Les INSERT sur LigneCommandes déclenchent automatiquement les
-- triggers SYC_* qui propagent les lignes (et leurs parents) vers
-- le bon site via les DB Links.
--
-- Couverture des deux scénarios :
--   Scénario 2 (quantite) :
--     quantite >= 100  → Site1
--     quantite <  100  → Site2
--
--   Scénario 1 (catégorie + quantite) :
--     idcateg=50 AND quantite>100  → Site1
--     idcateg=35 AND quantite>50   → Site2
--     autres                       → non distribué (global uniquement)
-- ============================================================

ALTER SESSION SET CONTAINER = FREEPDB1;
CONNECT eshop/eshop123@localhost:1521/FREEPDB1

-- ============================================================
-- CATEGORIES
-- idcateg 50 et 35 sont utilisées par le scénario 1
-- ============================================================
INSERT INTO Categories VALUES (10, 'Electronique');
INSERT INTO Categories VALUES (20, 'Bureautique');
INSERT INTO Categories VALUES (35, 'Mobilier');
INSERT INTO Categories VALUES (50, 'Informatique');

-- ============================================================
-- PRODUITS
-- ============================================================
INSERT INTO Produits VALUES (1, 50, 'Laptop ProBook 450',      899.99);
INSERT INTO Produits VALUES (2, 50, 'Serveur Dell PowerEdge', 2499.99);
INSERT INTO Produits VALUES (3, 50, 'Switch réseau 48 ports',  349.99);
INSERT INTO Produits VALUES (4, 35, 'Bureau ergonomique',      279.99);
INSERT INTO Produits VALUES (5, 35, 'Chaise de direction',     199.99);
INSERT INTO Produits VALUES (6, 10, 'Ecran 27 pouces 4K',      449.99);
INSERT INTO Produits VALUES (7, 20, 'Imprimante laser couleur',329.99);

-- ============================================================
-- CLIENTS
-- ============================================================
INSERT INTO Clients VALUES (1, 'CLI001', 'TechCorp SA',      'Ahmed Benali',   '12 rue des Oliviers',    'Casablanca', 'Maroc');
INSERT INTO Clients VALUES (2, 'CLI002', 'InnoSoft SARL',    'Fatima Zahra',   '45 avenue Hassan II',    'Rabat',      'Maroc');
INSERT INTO Clients VALUES (3, 'CLI003', 'DataSystems',      'Karim Alaoui',   '8 boulevard Zerktouni',  'Casablanca', 'Maroc');
INSERT INTO Clients VALUES (4, 'CLI004', 'MegaOffice',       'Zineb Chraibi',  '22 rue Ibn Battouta',    'Marrakech',  'Maroc');
INSERT INTO Clients VALUES (5, 'CLI005', 'Groupe Atlas',     'Omar Mansouri',  '3 avenue Mohammed V',    'Fes',        'Maroc');

-- ============================================================
-- EMPLOYES
-- ============================================================
INSERT INTO Employes VALUES (1, 'Idrissi',  'Youssef', 'Commercial');
INSERT INTO Employes VALUES (2, 'Bensouda', 'Sara',    'Responsable ventes');

-- ============================================================
-- COMMANDES 2026 — plusieurs par client pour la requête analytique
-- ============================================================
INSERT INTO Commandes VALUES (1,  1, 1, DATE '2026-02-10');  -- TechCorp    x2 commandes
INSERT INTO Commandes VALUES (2,  1, 2, DATE '2026-03-15');
INSERT INTO Commandes VALUES (3,  2, 1, DATE '2026-04-20');  -- InnoSoft    x2 commandes
INSERT INTO Commandes VALUES (4,  2, 2, DATE '2026-05-05');
INSERT INTO Commandes VALUES (5,  3, 1, DATE '2026-06-01');  -- DataSystems x3 commandes
INSERT INTO Commandes VALUES (6,  3, 2, DATE '2026-07-14');
INSERT INTO Commandes VALUES (7,  3, 1, DATE '2026-09-02');
INSERT INTO Commandes VALUES (8,  4, 2, DATE '2026-08-22');  -- MegaOffice  x1 commande
INSERT INTO Commandes VALUES (9,  5, 1, DATE '2026-10-30');  -- Groupe Atlas x1 commande

-- Commande hors 2026 — doit être exclue par le filtre date
INSERT INTO Commandes VALUES (10, 4, 1, DATE '2025-11-20');

-- ============================================================
-- LIGNES DE COMMANDES
-- Les triggers propagent automatiquement vers les sites.
--
-- Légende des colonnes :
--   (idligne, idcommande, idproduit, quantite, remise)
--
--            idcateg  qte   S2       S1
-- --------------------------------------------------------
-- LC 1 :      50      150   Site1    Site1  (categ 50, qte>100)
-- LC 2 :      50      200   Site1    Site1
-- LC 3 :      50       80   Site2    global (categ 50, qte≤100)
-- LC 4 :      35       75   Site2    Site2  (categ 35, qte>50)
-- LC 5 :      35       60   Site2    Site2
-- LC 6 :      35       30   Site2    global (categ 35, qte≤50)
-- LC 7 :      10      120   Site1    global (categ 10, hors S1)
-- LC 8 :      10       15   Site2    global
-- LC 9 :      20      100   Site1    global (categ 20, hors S1)
-- LC 10:      20       40   Site2    global
-- LC 11:      50      300   Site1    Site1  (grosse commande)
-- LC 12:      35       55   Site2    Site2
-- LC 13: hors 2026, Site1  → exclue de la requête analytique
-- ============================================================

-- Catégorie 50 (Informatique) — idcateg=50
INSERT INTO LigneCommandes VALUES (1,  1,  1, 150,  5);   -- Laptop x150
INSERT INTO LigneCommandes VALUES (2,  2,  2, 200, 10);   -- Serveur x200
INSERT INTO LigneCommandes VALUES (3,  3,  1,  80,  0);   -- Laptop x80
INSERT INTO LigneCommandes VALUES (4,  4,  3, 110,  8);   -- Switch x110
INSERT INTO LigneCommandes VALUES (5,  5,  2, 300, 15);   -- Serveur x300

-- Catégorie 35 (Mobilier) — idcateg=35
INSERT INTO LigneCommandes VALUES (6,  3,  4,  75,  5);   -- Bureau x75
INSERT INTO LigneCommandes VALUES (7,  6,  5,  60,  3);   -- Chaise x60
INSERT INTO LigneCommandes VALUES (8,  7,  4,  30,  0);   -- Bureau x30
INSERT INTO LigneCommandes VALUES (9,  8,  5,  55,  2);   -- Chaise x55

-- Catégorie 10 (Electronique) — non distribuée en scénario 1
INSERT INTO LigneCommandes VALUES (10, 1,  6, 120,  0);   -- Ecran x120
INSERT INTO LigneCommandes VALUES (11, 9,  6,  15,  0);   -- Ecran x15

-- Catégorie 20 (Bureautique) — non distribuée en scénario 1
INSERT INTO LigneCommandes VALUES (12, 5,  7, 100,  5);   -- Imprimante x100
INSERT INTO LigneCommandes VALUES (13, 8,  7,  40,  0);   -- Imprimante x40

-- Hors 2026 — exclue de la requête analytique mais distribuée sur les sites
INSERT INTO LigneCommandes VALUES (14, 10, 1, 130, 10);   -- Laptop x130, commande 2025

COMMIT;
