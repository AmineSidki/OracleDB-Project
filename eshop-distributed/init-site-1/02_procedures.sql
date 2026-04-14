-- ================================================================
-- Site 1 — Stored Procedures
-- insertligne / deleteligne / updateligne for LIGNECOMMANDES1
-- ================================================================

-- ----------------------------------------------------------------
-- insertligne : insère une ligne de commande dans Site1
--   Vérifie l'intégrité référentielle avant insertion
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE insertligne(
    p_idlignecommande IN INTEGER,
    p_idcommande      IN INTEGER,
    p_idproduit       IN INTEGER,
    p_quantite        IN INTEGER,
    p_remise          IN FLOAT
) AS
    v_cnt_cmd  INTEGER;
    v_cnt_prod INTEGER;
BEGIN
    -- Vérification : la commande existe dans COMMANDES1
    SELECT COUNT(*) INTO v_cnt_cmd
    FROM COMMANDES1
    WHERE IDCOMMANDE = p_idcommande;

    IF v_cnt_cmd = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'ERREUR insertligne: IDCOMMANDE=' || p_idcommande || ' absent de COMMANDES1'
        );
    END IF;

    -- Vérification : le produit existe dans PRODUITS1
    SELECT COUNT(*) INTO v_cnt_prod
    FROM PRODUITS1
    WHERE IDPRODUIT = p_idproduit;

    IF v_cnt_prod = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'ERREUR insertligne: IDPRODUIT=' || p_idproduit || ' absent de PRODUITS1'
        );
    END IF;

    -- Vérification : quantite respecte le critère du fragment
    IF p_quantite < 100 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'ERREUR insertligne: QUANTITE=' || p_quantite || ' < 100, appartient au Site2'
        );
    END IF;

    INSERT INTO LIGNECOMMANDES1
        (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES
        (p_idlignecommande, p_idcommande, p_idproduit, p_quantite, p_remise);

    COMMIT;
END insertligne;
/


-- ----------------------------------------------------------------
-- deleteligne : supprime une ligne de commande et nettoie les
--   tables liées si elles deviennent orphelines
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE deleteligne(
    p_idlignecommande IN INTEGER
) AS
    v_idcommande INTEGER;
    v_idclient   INTEGER;
    v_cnt_lc     INTEGER;
    v_cnt_cmd    INTEGER;
BEGIN
    -- Récupère idcommande avant suppression
    SELECT IDCOMMANDE INTO v_idcommande
    FROM LIGNECOMMANDES1
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    -- Récupère idclient pour éventuel nettoyage
    SELECT IDCLIENT INTO v_idclient
    FROM COMMANDES1
    WHERE IDCOMMANDE = v_idcommande;

    -- 1. Supprimer la ligne de commande
    DELETE FROM LIGNECOMMANDES1
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    -- 2. Si plus aucune ligne ne référence cette commande → supprimer la commande
    SELECT COUNT(*) INTO v_cnt_lc
    FROM LIGNECOMMANDES1
    WHERE IDCOMMANDE = v_idcommande;

    IF v_cnt_lc = 0 THEN
        DELETE FROM COMMANDES1 WHERE IDCOMMANDE = v_idcommande;

        -- 3. Si le client n'a plus aucune commande → supprimer le client
        SELECT COUNT(*) INTO v_cnt_cmd
        FROM COMMANDES1
        WHERE IDCLIENT = v_idclient;

        IF v_cnt_cmd = 0 THEN
            DELETE FROM CLIENTS1 WHERE IDCLIENT = v_idclient;
        END IF;
    END IF;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'ERREUR deleteligne: IDLIGNECOMMANDE=' || p_idlignecommande || ' introuvable dans LIGNECOMMANDES1'
        );
END deleteligne;
/


-- ----------------------------------------------------------------
-- updateligne : met à jour idproduit, quantite et remise
--   d'une ligne de commande existante dans Site1
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE updateligne(
    p_idlignecommande IN INTEGER,
    p_idproduit       IN INTEGER,
    p_quantite        IN INTEGER,
    p_remise          IN FLOAT
) AS
    v_cnt_prod INTEGER;
    v_rows     INTEGER;
BEGIN
    -- Vérification : nouveau produit existe dans PRODUITS1
    SELECT COUNT(*) INTO v_cnt_prod
    FROM PRODUITS1
    WHERE IDPRODUIT = p_idproduit;

    IF v_cnt_prod = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'ERREUR updateligne: IDPRODUIT=' || p_idproduit || ' absent de PRODUITS1'
        );
    END IF;

    -- Vérification : la nouvelle quantité reste dans le fragment Site1
    IF p_quantite < 100 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'ERREUR updateligne: QUANTITE=' || p_quantite || ' < 100, déplacement vers Site2 requis'
        );
    END IF;

    UPDATE LIGNECOMMANDES1
    SET
        IDPRODUIT = p_idproduit,
        QUANTITE  = p_quantite,
        REMISE    = p_remise
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'ERREUR updateligne: IDLIGNECOMMANDE=' || p_idlignecommande || ' introuvable dans LIGNECOMMANDES1'
        );
    END IF;

    COMMIT;
END updateligne;
/
