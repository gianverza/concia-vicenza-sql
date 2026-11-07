-- 09_paesi.sql
-- Quali mercati spiegano il calo di Vicenza dal 2022?
-- Solo tipo = 'paese': sommare anche gli aggregati conterebbe lo stesso export più volte.

USE concia_vicenza;

-- 9.1 Contributo di ogni paese alla variazione totale
-- COALESCE: un paese senza export in un anno non ha la riga, e va trattato come zero.
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    COALESCE(SUM(CASE WHEN e.anno = 2022 THEN e.valore END), 0) AS v2022,
    COALESCE(SUM(CASE WHEN e.anno = 2025 THEN e.valore END), 0) AS v2025
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITD32'
    AND e.codice_prodotto = 'CB151'
    AND e.tipo_dato = 'EV'
    AND p.tipo = 'paese'
    AND e.anno IN (2022, 2025)
  GROUP BY p.nome
),
variazioni AS (
  SELECT
    paese,
    v2022,
    v2025,
    v2025 - v2022 AS delta,
    SUM(v2025 - v2022) OVER () AS delta_totale,
    SUM(v2022) OVER () AS totale_2022
  FROM per_paese
)
SELECT
  RANK() OVER (ORDER BY delta) AS posizione,
  paese,
  ROUND(v2022 / 1e6, 1) AS mln_2022,
  ROUND(v2025 / 1e6, 1) AS mln_2025,
  ROUND(delta / 1e6, 1) AS delta_mln,
  ROUND(100 * (v2025 / NULLIF(v2022, 0) - 1), 1) AS variazione_pct,
  ROUND(100 * delta / delta_totale, 1) AS quota_del_calo_pct,
  ROUND(100 * SUM(delta) OVER (ORDER BY delta ROWS UNBOUNDED PRECEDING) / delta_totale, 1) AS quota_cumulata_pct,
  ROUND(100 * v2022 / totale_2022, 1) AS peso_mercato_2022_pct
FROM variazioni
ORDER BY delta
LIMIT 15;

-- 9.2 I mercati cresciuti nello stesso periodo
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    COALESCE(SUM(CASE WHEN e.anno = 2022 THEN e.valore END), 0) AS v2022,
    COALESCE(SUM(CASE WHEN e.anno = 2025 THEN e.valore END), 0) AS v2025
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITD32'
    AND e.codice_prodotto = 'CB151'
    AND e.tipo_dato = 'EV'
    AND p.tipo = 'paese'
    AND e.anno IN (2022, 2025)
  GROUP BY p.nome
)
SELECT
  paese,
  ROUND(v2022 / 1e6, 1) AS mln_2022,
  ROUND(v2025 / 1e6, 1) AS mln_2025,
  ROUND((v2025 - v2022) / 1e6, 1) AS delta_mln
FROM per_paese
ORDER BY v2025 - v2022 DESC
LIMIT 10;

-- 9.3 Il calo è concentrato? Bilancio tra perdite e guadagni e numero di paesi in calo
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    COALESCE(SUM(CASE WHEN e.anno = 2022 THEN e.valore END), 0) AS v2022,
    COALESCE(SUM(CASE WHEN e.anno = 2025 THEN e.valore END), 0) AS v2025
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITD32'
    AND e.codice_prodotto = 'CB151'
    AND e.tipo_dato = 'EV'
    AND p.tipo = 'paese'
    AND e.anno IN (2022, 2025)
  GROUP BY p.nome
)
SELECT
  COUNT(*) AS paesi,
  SUM(v2025 < v2022) AS paesi_in_calo,
  SUM(v2025 > v2022) AS paesi_in_crescita,
  ROUND(SUM(LEAST(v2025 - v2022, 0)) / 1e6, 1)    AS perdite_mln,
  ROUND(SUM(GREATEST(v2025 - v2022, 0)) / 1e6, 1) AS guadagni_mln,
  ROUND(SUM(v2025 - v2022) / 1e6, 1)              AS saldo_mln
FROM per_paese;

-- 9.4 Il peso delle aree geografiche (qui si usano gli aggregati, che non si sovrappongono tra loro)
SELECT
  p.nome AS area,
  ROUND(SUM(CASE WHEN e.anno = 2022 THEN e.valore END) / 1e6, 1) AS mln_2022,
  ROUND(SUM(CASE WHEN e.anno = 2025 THEN e.valore END) / 1e6, 1) AS mln_2025,
  ROUND((SUM(CASE WHEN e.anno = 2025 THEN e.valore END)
       - SUM(CASE WHEN e.anno = 2022 THEN e.valore END)) / 1e6, 1) AS delta_mln,
  ROUND(100 * (SUM(CASE WHEN e.anno = 2025 THEN e.valore END)
             / SUM(CASE WHEN e.anno = 2022 THEN e.valore END) - 1), 1) AS variazione_pct
FROM export e
JOIN partner p ON p.codice = e.codice_partner
WHERE e.codice_territorio = 'ITD32'
  AND e.codice_prodotto = 'CB151'
  AND e.tipo_dato = 'EV'
  AND e.codice_partner IN ('EU27_2020', 'EUR_NEU', 'ASI', 'AME_N', 'AME_C_S', 'AFR', 'OCE')
GROUP BY p.nome
ORDER BY delta_mln;

-- 9.5 Totale di controllo: il mondo e la somma dei paesi nel 2022 e nel 2025
SELECT
  e.anno,
  ROUND(SUM(CASE WHEN e.codice_partner = 'WORLD' THEN e.valore END) / 1e6, 1) AS mondo_mln,
  ROUND(SUM(CASE WHEN p.tipo = 'paese' THEN e.valore END) / 1e6, 1)            AS somma_paesi_mln,
  ROUND(SUM(CASE WHEN p.tipo = 'altro' THEN e.valore END) / 1e6, 1)            AS altro_mln
FROM export e
JOIN partner p ON p.codice = e.codice_partner
WHERE e.codice_territorio = 'ITD32'
  AND e.codice_prodotto = 'CB151'
  AND e.tipo_dato = 'EV'
  AND e.anno IN (2022, 2025)
GROUP BY e.anno;
