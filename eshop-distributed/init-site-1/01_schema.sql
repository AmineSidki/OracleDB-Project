-- ================================================================
-- Site 1 — Fragment Schema
-- Fragmentation criterion: QUANTITE >= 100  (gros volumes)
-- Hosted on: Worker node (your MacBook)
-- ================================================================

-- ----------------------------------------------------------------
-- CLIENTS1
-- ----------------------------------------------------------------
CREATE TABLE CLIENTS1 (
    IDCLIENT    NUMBER        PRIMARY KEY,
    CODECLIENT  VARCHAR2(100),
    SOCIETE     VARCHAR2(100) NOT NULL,
    CONTACT     VARCHAR2(100) NOT NULL,
    FONCTION    VARCHAR2(100) NOT NULL,
    ADRESSE     VARCHAR2(100),
    VILLE       VARCHAR2(100),
    NAISSANCE   DATE,
    REGION      VARCHAR2(100),
    CP          VARCHAR2(10),
    PAYS        VARCHAR2(100),
    TELEPHONE   VARCHAR2(100),
    FAX         VARCHAR2(100)
);

-- ----------------------------------------------------------------
-- COMMANDES1
-- Note: IDEMPLOYE has no FK here — Employes live on the global DB
-- ----------------------------------------------------------------
CREATE TABLE COMMANDES1 (
    IDCOMMANDE    INTEGER PRIMARY KEY,
    IDEMPLOYE     INTEGER,
    IDCLIENT      INTEGER       REFERENCES CLIENTS1(IDCLIENT),
    DATECOMMANDE  DATE,
    DATELIVRAISON DATE,
    NMESSAGER     NUMBER(4,0),
    PORTNUMBER    NUMBER(4,0)
);

-- ----------------------------------------------------------------
-- PRODUITS1
-- Note: IDFOUR / IDCATEG FKs omitted — master tables on global DB
-- ----------------------------------------------------------------
CREATE TABLE PRODUITS1 (
    IDPRODUIT                  INTEGER PRIMARY KEY,
    DESIGNATION                VARCHAR2(100),
    IDFOUR                     INTEGER,
    IDCATEG                    INTEGER,
    PRIXUNITAIRE               FLOAT,
    UNITESENSTOCK              INTEGER,
    UNITESCOMMANDEES           INTEGER,
    NIVEAUREAPPROVISIONNEMENT  INTEGER,
    INDISPONIBLE               INTEGER,
    CONSTRAINT chk_indispo1 CHECK (INDISPONIBLE IN (0, 1))
);

-- ----------------------------------------------------------------
-- LIGNECOMMANDES1  — only rows where QUANTITE >= 100
-- ----------------------------------------------------------------
CREATE TABLE LIGNECOMMANDES1 (
    IDLIGNECOMMANDE INTEGER PRIMARY KEY,
    IDCOMMANDE      INTEGER REFERENCES COMMANDES1(IDCOMMANDE),
    IDPRODUIT       INTEGER REFERENCES PRODUITS1(IDPRODUIT),
    QUANTITE        INTEGER,
    REMISE          FLOAT,
    CONSTRAINT chk_quantite1 CHECK (QUANTITE >= 100)
);

COMMIT;
