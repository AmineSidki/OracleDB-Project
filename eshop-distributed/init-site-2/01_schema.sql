-- ================================================================
-- Site 2 — Fragment Schema
-- Fragmentation criterion: QUANTITE < 100  (détail / magasins)
-- Hosted on: Manager node (partner's PC)
-- ================================================================

-- ----------------------------------------------------------------
-- CLIENTS2
-- ----------------------------------------------------------------
CREATE TABLE CLIENTS2 (
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
-- COMMANDES2
-- ----------------------------------------------------------------
CREATE TABLE COMMANDES2 (
    IDCOMMANDE    INTEGER PRIMARY KEY,
    IDEMPLOYE     INTEGER,
    IDCLIENT      INTEGER       REFERENCES CLIENTS2(IDCLIENT),
    DATECOMMANDE  DATE,
    DATELIVRAISON DATE,
    NMESSAGER     NUMBER(4,0),
    PORTNUMBER    NUMBER(4,0)
);

-- ----------------------------------------------------------------
-- PRODUITS2
-- ----------------------------------------------------------------
CREATE TABLE PRODUITS2 (
    IDPRODUIT                  INTEGER PRIMARY KEY,
    DESIGNATION                VARCHAR2(100),
    IDFOUR                     INTEGER,
    IDCATEG                    INTEGER,
    PRIXUNITAIRE               FLOAT,
    UNITESENSTOCK              INTEGER,
    UNITESCOMMANDEES           INTEGER,
    NIVEAUREAPPROVISIONNEMENT  INTEGER,
    INDISPONIBLE               INTEGER,
    CONSTRAINT chk_indispo2 CHECK (INDISPONIBLE IN (0, 1))
);

-- ----------------------------------------------------------------
-- LIGNECOMMANDES2  — only rows where QUANTITE < 100
-- ----------------------------------------------------------------
CREATE TABLE LIGNECOMMANDES2 (
    IDLIGNECOMMANDE INTEGER PRIMARY KEY,
    IDCOMMANDE      INTEGER REFERENCES COMMANDES2(IDCOMMANDE),
    IDPRODUIT       INTEGER REFERENCES PRODUITS2(IDPRODUIT),
    QUANTITE        INTEGER,
    REMISE          FLOAT,
    CONSTRAINT chk_quantite2 CHECK (QUANTITE < 100)
);

COMMIT;
