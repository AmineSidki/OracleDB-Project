-- ================================================================
-- Site 2 — Stored Procedures
-- insertligne / deleteligne / updateligne for LIGNECOMMANDES2
-- ================================================================

-- ----------------------------------------------------------------
-- insertligne
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
    SELECT COUNT(*) INTO v_cnt_cmd
    FROM COMMANDES2
    WHERE IDCOMMANDE = p_idcommande;

    IF v_cnt_cmd = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'ERREUR insertligne: IDCOMMANDE=' || p_idcommande || ' absent de COMMANDES2'
        );
    END IF;

    SELECT COUNT(*) INTO v_cnt_prod
    FROM PRODUITS2
    WHERE IDPRODUIT = p_idproduit;

    IF v_cnt_prod = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'ERREUR insertligne: IDPRODUIT=' || p_idproduit || ' absent de PRODUITS2'
        );
    END IF;

    IF p_quantite >= 100 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'ERREUR insertligne: QUANTITE=' || p_quantite || ' >= 100, appartient au Site1'
        );
    END IF;

    INSERT INTO LIGNECOMMANDES2
        (IDLIGNECOMMANDE, IDCOMMANDE, IDPRODUIT, QUANTITE, REMISE)
    VALUES
        (p_idlignecommande, p_idcommande, p_idproduit, p_quantite, p_remise);

    COMMIT;
END insertligne;
/


-- ----------------------------------------------------------------
-- deleteligne
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE deleteligne(
    p_idlignecommande IN INTEGER
) AS
    v_idcommande INTEGER;
    v_idclient   INTEGER;
    v_cnt_lc     INTEGER;
    v_cnt_cmd    INTEGER;
BEGIN
    SELECT IDCOMMANDE INTO v_idcommande
    FROM LIGNECOMMANDES2
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    SELECT IDCLIENT INTO v_idclient
    FROM COMMANDES2
    WHERE IDCOMMANDE = v_idcommande;

    DELETE FROM LIGNECOMMANDES2
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    SELECT COUNT(*) INTO v_cnt_lc
    FROM LIGNECOMMANDES2
    WHERE IDCOMMANDE = v_idcommande;

    IF v_cnt_lc = 0 THEN
        DELETE FROM COMMANDES2 WHERE IDCOMMANDE = v_idcommande;

        SELECT COUNT(*) INTO v_cnt_cmd
        FROM COMMANDES2
        WHERE IDCLIENT = v_idclient;

        IF v_cnt_cmd = 0 THEN
            DELETE FROM CLIENTS2 WHERE IDCLIENT = v_idclient;
        END IF;
    END IF;

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'ERREUR deleteligne: IDLIGNECOMMANDE=' || p_idlignecommande || ' introuvable dans LIGNECOMMANDES2'
        );
END deleteligne;
/


-- ----------------------------------------------------------------
-- updateligne
-- ----------------------------------------------------------------
CREATE OR REPLACE PROCEDURE updateligne(
    p_idlignecommande IN INTEGER,
    p_idproduit       IN INTEGER,
    p_quantite        IN INTEGER,
    p_remise          IN FLOAT
) AS
    v_cnt_prod INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_cnt_prod
    FROM PRODUITS2
    WHERE IDPRODUIT = p_idproduit;

    IF v_cnt_prod = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'ERREUR updateligne: IDPRODUIT=' || p_idproduit || ' absent de PRODUITS2'
        );
    END IF;

    IF p_quantite >= 100 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'ERREUR updateligne: QUANTITE=' || p_quantite || ' >= 100, déplacement vers Site1 requis'
        );
    END IF;

    UPDATE LIGNECOMMANDES2
    SET
        IDPRODUIT = p_idproduit,
        QUANTITE  = p_quantite,
        REMISE    = p_remise
    WHERE IDLIGNECOMMANDE = p_idlignecommande;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'ERREUR updateligne: IDLIGNECOMMANDE=' || p_idlignecommande || ' introuvable dans LIGNECOMMANDES2'
        );
    END IF;

    COMMIT;
END updateligne;
/
