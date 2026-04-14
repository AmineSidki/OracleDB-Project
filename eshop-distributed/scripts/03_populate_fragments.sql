-- ================================================================
-- Step 3 of post-deploy setup: Populate Fragment Sites
-- Run on the GLOBAL DB after 02_triggers.sql succeeds.
--
-- Strategy:
--   LigneCommandes is split by QUANTITE threshold.
--   Commandes & Clients follow their referenced LigneCommandes.
--   Produits is fully replicated to both sites (needed for JOINs).
-- ================================================================

-- ----------------------------------------------------------------
-- Disable triggers temporarily to avoid double-write during seeding
-- ----------------------------------------------------------------
ALTER TRIGGER SYC_INSERT_LIGNE DISABLE;
ALTER TRIGGER SYC_DELETE_LIGNE DISABLE;
ALTER TRIGGER SYC_UPDATE_LIGNE DISABLE;


-- ================================================================
-- SITE 1  (QUANTITE >= 100)
-- ================================================================

-- Produits1: full copy (both sites need all products for joins)
INSERT INTO PRODUITS1@site1_link
    SELECT * FROM PRODUITS;

-- LigneCommandes1: the actual fragment
INSERT INTO LIGNECOMMANDES1@site1_link
    SELECT * FROM LIGNECOMMANDES
    WHERE QUANTITE >= 100;

-- Commandes1: only commandes that have at least one fragment ligne
INSERT INTO COMMANDES1@site1_link
    SELECT DISTINCT c.*
    FROM COMMANDES c
    WHERE c.IDCOMMANDE IN (
        SELECT IDCOMMANDE FROM LIGNECOMMANDES WHERE QUANTITE >= 100
    );

-- Clients1: only clients linked to those commandes
INSERT INTO CLIENTS1@site1_link
    SELECT DISTINCT cl.*
    FROM CLIENTS cl
    WHERE cl.IDCLIENT IN (
        SELECT IDCLIENT FROM COMMANDES
        WHERE IDCOMMANDE IN (
            SELECT IDCOMMANDE FROM LIGNECOMMANDES WHERE QUANTITE >= 100
        )
    );


-- ================================================================
-- SITE 2  (QUANTITE < 100)
-- ================================================================

INSERT INTO PRODUITS2@site2_link
    SELECT * FROM PRODUITS;

INSERT INTO LIGNECOMMANDES2@site2_link
    SELECT * FROM LIGNECOMMANDES
    WHERE QUANTITE < 100;

INSERT INTO COMMANDES2@site2_link
    SELECT DISTINCT c.*
    FROM COMMANDES c
    WHERE c.IDCOMMANDE IN (
        SELECT IDCOMMANDE FROM LIGNECOMMANDES WHERE QUANTITE < 100
    );

INSERT INTO CLIENTS2@site2_link
    SELECT DISTINCT cl.*
    FROM CLIENTS cl
    WHERE cl.IDCLIENT IN (
        SELECT IDCLIENT FROM COMMANDES
        WHERE IDCOMMANDE IN (
            SELECT IDCOMMANDE FROM LIGNECOMMANDES WHERE QUANTITE < 100
        )
    );


COMMIT;

-- ----------------------------------------------------------------
-- Re-enable triggers — live synchronisation now active
-- ----------------------------------------------------------------
ALTER TRIGGER SYC_INSERT_LIGNE ENABLE;
ALTER TRIGGER SYC_DELETE_LIGNE ENABLE;
ALTER TRIGGER SYC_UPDATE_LIGNE ENABLE;


-- ----------------------------------------------------------------
-- Verification counts
-- ----------------------------------------------------------------
SELECT 'LIGNECOMMANDES (global)'  AS fragment, COUNT(*) AS n FROM LIGNECOMMANDES
UNION ALL
SELECT 'LIGNECOMMANDES1 (site1)', COUNT(*) FROM LIGNECOMMANDES1@site1_link
UNION ALL
SELECT 'LIGNECOMMANDES2 (site2)', COUNT(*) FROM LIGNECOMMANDES2@site2_link;
