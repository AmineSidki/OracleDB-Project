-- ================================================================
-- Step 2 of post-deploy setup: Synchronisation Triggers
-- Run on the GLOBAL DB after 01_dblinks.sql succeeds.
--
-- SYC_INSERT_LIGNE — routes INSERT to Site1 or Site2
-- SYC_DELETE_LIGNE — routes DELETE to the correct site
-- SYC_UPDATE_LIGNE — routes UPDATE; handles cross-site moves
--                    when QUANTITE crosses the 100 threshold
-- ================================================================


-- ----------------------------------------------------------------
-- SYC_INSERT_LIGNE
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER SYC_INSERT_LIGNE
AFTER INSERT ON LIGNECOMMANDES
FOR EACH ROW
BEGIN
    IF :NEW.QUANTITE >= 100 THEN
        -- Gros volume → Site 1
        INSERT INTO LIGNECOMMANDES1@site1_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES
            (:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT,
             :NEW.QUANTITE, :NEW.REMISE);
    ELSE
        -- Détail → Site 2
        INSERT INTO LIGNECOMMANDES2@site2_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES
            (:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT,
             :NEW.QUANTITE, :NEW.REMISE);
    END IF;
END SYC_INSERT_LIGNE;
/


-- ----------------------------------------------------------------
-- SYC_DELETE_LIGNE
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER SYC_DELETE_LIGNE
AFTER DELETE ON LIGNECOMMANDES
FOR EACH ROW
BEGIN
    IF :OLD.QUANTITE >= 100 THEN
        DELETE FROM LIGNECOMMANDES1@site1_link
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;
    ELSE
        DELETE FROM LIGNECOMMANDES2@site2_link
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;
    END IF;
END SYC_DELETE_LIGNE;
/


-- ----------------------------------------------------------------
-- SYC_UPDATE_LIGNE
-- Handles four cases:
--   (a) stays in Site1  : old >= 100, new >= 100  → UPDATE Site1
--   (b) stays in Site2  : old < 100,  new < 100   → UPDATE Site2
--   (c) Site1 → Site2   : old >= 100, new < 100   → DELETE Site1, INSERT Site2
--   (d) Site2 → Site1   : old < 100,  new >= 100  → DELETE Site2, INSERT Site1
-- ----------------------------------------------------------------
CREATE OR REPLACE TRIGGER SYC_UPDATE_LIGNE
AFTER UPDATE ON LIGNECOMMANDES
FOR EACH ROW
BEGIN

    -- (a) Remains in Site 1
    IF :OLD.QUANTITE >= 100 AND :NEW.QUANTITE >= 100 THEN
        UPDATE LIGNECOMMANDES1@site1_link
        SET IDPRODUIT = :NEW.IDPRODUIT,
            QUANTITE  = :NEW.QUANTITE,
            REMISE    = :NEW.REMISE
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;

    -- (b) Remains in Site 2
    ELSIF :OLD.QUANTITE < 100 AND :NEW.QUANTITE < 100 THEN
        UPDATE LIGNECOMMANDES2@site2_link
        SET IDPRODUIT = :NEW.IDPRODUIT,
            QUANTITE  = :NEW.QUANTITE,
            REMISE    = :NEW.REMISE
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;

    -- (c) Site1 → Site2  (quantity dropped below 100)
    ELSIF :OLD.QUANTITE >= 100 AND :NEW.QUANTITE < 100 THEN
        DELETE FROM LIGNECOMMANDES1@site1_link
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;

        INSERT INTO LIGNECOMMANDES2@site2_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES
            (:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT,
             :NEW.QUANTITE, :NEW.REMISE);

    -- (d) Site2 → Site1  (quantity raised to 100+)
    ELSIF :OLD.QUANTITE < 100 AND :NEW.QUANTITE >= 100 THEN
        DELETE FROM LIGNECOMMANDES2@site2_link
        WHERE IDLIGNECOMMANDE = :OLD.IDLIGNECOMMANDE;

        INSERT INTO LIGNECOMMANDES1@site1_link
            (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
        VALUES
            (:NEW.IDLIGNECOMMANDE, :NEW.IDCOMMANDE, :NEW.IDPRODUIT,
             :NEW.QUANTITE, :NEW.REMISE);
    END IF;

END SYC_UPDATE_LIGNE;
/
