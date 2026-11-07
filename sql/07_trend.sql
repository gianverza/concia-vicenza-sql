-- 07_trend.sql
-- Il calo esiste? Riguarda solo la pelle? Vicenza perde davvero terreno?
-- Tutti i valori sono in euro correnti (non corretti per l'inflazione).

USE concia_vicenza;

-- 7.1 Export di Vicenza CB151 anno per anno
-- LAG prende il valore dell'anno precedente; MAX() OVER () il massimo dell'intera serie.
WITH serie AS (
  SELECT anno, valore
  FROM export
  WHERE codice_territorio = 'ITD32'
    AND codice_prodotto = 'CB151'
    AND codice_partner = 'WORLD'
    AND tipo_dato = 'EV'
)
SELECT
  anno,
  ROUND(valore / 1e6, 1) AS milioni_euro,
  ROUND(100 * (valore / LAG(valore) OVER (ORDER BY anno) - 1), 1) AS var_annua_pct,
  ROUND(100 * (valore / MAX(valore) OVER () - 1), 1) AS distanza_dal_picco_pct
FROM serie
ORDER BY anno;

-- 7.2 Il calo è specifico della pelle? Stesse serie con base 2022 = 100
-- Portarle sulla stessa base permette di confrontare grandezze molto diverse.
WITH serie AS (
  SELECT
    t.nome AS territorio,
    p.descrizione AS prodotto,
    e.anno,
    e.valore
  FROM export e
  JOIN territori t ON t.codice = e.codice_territorio
  JOIN prodotti p ON p.codice = e.codice_prodotto
  WHERE e.codice_partner = 'WORLD'
    AND e.tipo_dato = 'EV'
    AND e.codice_prodotto IN ('C', 'CB151')
),
base AS (
  SELECT territorio, prodotto, valore AS valore_2022
  FROM serie
  WHERE anno = 2022
)
SELECT
  s.territorio,
  s.prodotto,
  s.anno,
  ROUND(100 * s.valore / b.valore_2022, 1) AS indice_2022_100
FROM serie s
JOIN base b ON b.territorio = s.territorio AND b.prodotto = s.prodotto
WHERE s.anno BETWEEN 2015 AND 2025
ORDER BY s.territorio, s.prodotto, s.anno;

-- 7.3 Pesi e quote: tre rapporti che raccontano cose diverse
-- SUM(CASE...) trasforma le righe in colonne, una per ogni serie.
WITH pivot AS (
  SELECT
    anno,
    SUM(CASE WHEN codice_territorio = 'ITD32' AND codice_prodotto = 'CB151'  THEN valore END) AS vi_pelle,
    SUM(CASE WHEN codice_territorio = 'ITD32' AND codice_prodotto = 'C'      THEN valore END) AS vi_manif,
    SUM(CASE WHEN codice_territorio = 'ITTOT' AND codice_prodotto = 'CB151'  THEN valore END) AS it_pelle,
    SUM(CASE WHEN codice_territorio = 'ITTOT' AND codice_prodotto = 'CB1511' THEN valore END) AS it_concia,
    SUM(CASE WHEN codice_territorio = 'ITTOT' AND codice_prodotto = 'CB1512' THEN valore END) AS it_pelletteria
  FROM export
  WHERE codice_partner = 'WORLD'
    AND tipo_dato = 'EV'
  GROUP BY anno
)
SELECT
  anno,
  ROUND(100 * vi_pelle / vi_manif, 1)   AS peso_pelle_su_manif_vicenza_pct,
  ROUND(100 * vi_pelle / it_pelle, 1)   AS quota_vicenza_su_italia_pct,
  ROUND(100 * it_concia / it_pelle, 1)  AS peso_concia_su_pelle_italia_pct,
  ROUND(it_concia / 1e6)                AS italia_concia_mln,
  ROUND(it_pelletteria / 1e6)           AS italia_pelletteria_mln
FROM pivot
ORDER BY anno;

-- 7.4 Il riassunto del periodo 2022-2025
WITH confronto AS (
  SELECT
    t.nome AS territorio,
    p.descrizione AS prodotto,
    SUM(CASE WHEN e.anno = 2022 THEN e.valore END) AS v2022,
    SUM(CASE WHEN e.anno = 2025 THEN e.valore END) AS v2025
  FROM export e
  JOIN territori t ON t.codice = e.codice_territorio
  JOIN prodotti p ON p.codice = e.codice_prodotto
  WHERE e.codice_partner = 'WORLD'
    AND e.tipo_dato = 'EV'
  GROUP BY t.nome, p.descrizione
)
SELECT
  territorio,
  prodotto,
  ROUND(v2022 / 1e6, 1) AS mln_2022,
  ROUND(v2025 / 1e6, 1) AS mln_2025,
  ROUND(100 * (v2025 / v2022 - 1), 1) AS variazione_pct
FROM confronto
ORDER BY territorio, prodotto;
