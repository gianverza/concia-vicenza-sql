-- 06_controlli.sql
-- Controlli di coerenza: se uno di questi non torna, le analisi non sono affidabili.

USE concia_vicenza;

-- 1. Righe: 17.456 in staging, 17.386 in export (70 doppioni tra file)
SELECT
  (SELECT COUNT(*) FROM staging_export) AS righe_staging,
  (SELECT COUNT(*) FROM export)         AS righe_export;

-- 2. Partner per tipo
SELECT tipo, COUNT(*) AS partner
FROM partner
GROUP BY tipo;

-- 3. La classificazione regge? Paesi + altro devono dare il totale WORLD.
--    Mostra gli anni peggiori: uno scarto vicino a zero conferma che nessun aggregato
--    è finito tra i paesi e che nessun paese è stato perso.
WITH somme AS (
  SELECT
    e.codice_territorio, e.codice_prodotto, e.tipo_dato, e.anno,
    SUM(CASE WHEN p.tipo IN ('paese', 'altro') THEN e.valore ELSE 0 END) AS somma_paesi,
    SUM(CASE WHEN e.codice_partner = 'WORLD' THEN e.valore ELSE 0 END)   AS mondo
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_prodotto IN ('CB151', 'CB1511')
    AND NOT (e.codice_territorio = 'ITTOT' AND e.codice_prodotto = 'CB151')
  GROUP BY e.codice_territorio, e.codice_prodotto, e.tipo_dato, e.anno
)
SELECT
  codice_territorio, codice_prodotto, tipo_dato, anno,
  ROUND(somma_paesi) AS somma_paesi,
  ROUND(mondo)       AS mondo,
  ROUND(100 * (somma_paesi - mondo) / mondo, 4) AS scarto_pct
FROM somme
ORDER BY ABS(somma_paesi - mondo) / mondo DESC
LIMIT 5;

-- 4. Gerarchia: per l'Italia CB1511 + CB1512 deve dare CB151, ogni anno.
--    Conta gli anni con uno scarto superiore a 1 euro: atteso 0.
SELECT COUNT(*) AS anni_non_coerenti
FROM (
  SELECT
    anno,
    SUM(CASE WHEN codice_prodotto = 'CB151' THEN valore ELSE -valore END) AS scarto
  FROM export
  WHERE codice_territorio = 'ITTOT'
    AND codice_partner = 'WORLD'
    AND tipo_dato = 'EV'
    AND codice_prodotto IN ('CB151', 'CB1511', 'CB1512')
  GROUP BY anno
) t
WHERE ABS(scarto) > 1;
