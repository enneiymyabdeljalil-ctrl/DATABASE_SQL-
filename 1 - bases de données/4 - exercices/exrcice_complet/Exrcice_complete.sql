-- ==========================================================
-- 1. FONCTION : CalculerMoyenneScoreEtudiant
-- ==========================================================
DELIMITER $$CREATE FUNCTION CalculerMoyenneScoreEtudiant(p_id_etudiant INT) RETURNS FLOAT DETERMINISTIC BEGIN DECLARE Mscro FLOAT;
-- Calculer la moyenne des scores de l'étudiant
SELECT
    AVG(score_obtenu) INTO Mscro
FROM
    TENTATIVE
WHERE
    id_etudiant = p_id_etudiant;
-- Si l'étudiant n'a aucune tentative, retourner 0
IF Mscro IS NULL THEN
RETURN 0;
END IF;
RETURN Mscro;
END $$DELIMITER;
-- ==========================================================
-- 2. PROCÉDURE : InscrireEtudiantAuCours
-- ==========================================================
DELIMITER $$CREATE PROCEDURE InscrireEtudiantAuCours(IN par_id_etudiant INT, IN par_id_cours INT) BEGIN DECLARE Studient INT;
DECLARE Courses INT;
-- Étape 1 : Vérifier si l'étudiant existe
SELECT
    COUNT(*) INTO Studient
FROM
    ETUDIANT
WHERE
    id_etudiant = par_id_etudiant;
IF Studient = 0 THEN
SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Erreur : L''étudiant n''existe pas dans la base de données.';
END IF;
-- Étape 2 : Vérifier si l'étudiant est déjà inscrit à ce cours
SELECT
    COUNT(*) INTO Courses
FROM
    INSCRIPTION
WHERE
    id_etudiant = par_id_etudiant AND
    id_cours = par_id_cours;
IF Courses > 0 THEN
SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Erreur : Cet étudiant est déjà inscrit à ce cours.';
END IF;
-- Étape 3 : Insertion de l'inscription
INSERT INTO
    INSCRIPTION (
        id_etudiant,
        id_cours,
        date_inscription,
        pourcentage_progression
    )
VALUES (par_id_etudiant, par_id_cours, CURDATE(), 0);
END $$DELIMITER;
-- ==========================================================
-- 3. TRIGGER : trg_empecher_double_evaluation
-- ==========================================================
DELIMITER / / CREATE TRIGGER trg_empecher_double_evaluation BEFORE INSERT ON
TENTATIVE FOR EACH ROW BEGIN DECLARE v_deja_valide INT;
-- Vérifier si l'étudiant a déjà validé cette évaluation (score >= 80)
SELECT
    COUNT(*) INTO v_deja_valide
FROM
    TENTATIVE
WHERE
    id_etudiant = NEW.id_etudiant AND
    id_evaluation = NEW.id_evaluation AND
    score_obtenu >= 80;
-- Bloquer l'insertion si déjà validé
IF v_deja_valide > 0 THEN
SIGNAL SQLSTATE '45000'
SET
    MESSAGE_TEXT = 'Erreur : L''étudiant a déjà validé cette évaluation avec succès (score >= 80).';
END IF;
END / / DELIMITER;