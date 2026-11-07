-- 08_valore_chili.sql
-- Si vende meno pelle o la si vende a prezzi più bassi?
-- Solo Italia e solo concia (CB1511): ISTAT non pubblica i chili per le province.
-- Il prezzo medio al kg dipende anche dal mix: pelli più rifinite costano di più al kg.

USE concia_vicenza;

-- 8.1 Valore, chili e prezzo medio, anno per anno
-- NULLIF evita la divisione per zero.
WITH pivot AS (
  SELECT
    anno,
    SUM(CASE WHEN tipo_dato = 'EV'  THEN valore END) AS euro,
    SUM(CASE WHEN tipo_dato = 'ENW' THEN valore END) AS kg
  FROM export
  WHERE codice_territorio = 'ITTOT'
    AND codice_prodotto = 'CB1511'
    AND codice_partner = 'WORLD'
  GROUP BY anno
)
SELECT
  anno,
  ROUND(euro / 1e6, 1) AS milioni_euro,
  ROUND(kg / 1e6, 1)   AS migliaia_tonnellate,
  ROUND(euro / NULLIF(kg, 0), 2) AS euro_al_kg,
  ROUND(100 * (kg / MAX(kg) OVER () - 1), 1) AS chili_distanza_dal_picco_pct
FROM pivot
ORDER BY anno;

-- 8.2 Quanto del calo 2022-2025 dipende dai volumi e quanto dal prezzo?
-- Effetto volume = variazione dei chili al prezzo del 2022.
-- Effetto prezzo = variazione del prezzo sui chili del 2025.
-- I due effetti sommati danno esattamente la variazione del valore.
WITH pivot AS (
  SELECT
    SUM(CASE WHEN anno = 2022 AND tipo_dato = 'EV'  THEN valore END) AS euro_22,
    SUM(CASE WHEN anno = 2025 AND tipo_dato = 'EV'  THEN valore END) AS euro_25,
    SUM(CASE WHEN anno = 2022 AND tipo_dato = 'ENW' THEN valore END) AS kg_22,
    SUM(CASE WHEN anno = 2025 AND tipo_dato = 'ENW' THEN valore END) AS kg_25
  FROM export
  WHERE codice_territorio = 'ITTOT'
    AND codice_prodotto = 'CB1511'
    AND codice_partner = 'WORLD'
)
SELECT
  ROUND((euro_25 - euro_22) / 1e6, 1)                   AS variazione_valore_mln,
  ROUND((kg_25 - kg_22) * (euro_22 / kg_22) / 1e6, 1)   AS effetto_volume_mln,
  ROUND((euro_25 / kg_25 - euro_22 / kg_22) * kg_25 / 1e6, 1) AS effetto_prezzo_mln,
  ROUND(100 * (euro_25 / euro_22 - 1), 1)               AS valore_pct,
  ROUND(100 * (kg_25 / kg_22 - 1), 1)                   AS chili_pct,
  ROUND(euro_22 / kg_22, 2)                             AS prezzo_2022,
  ROUND(euro_25 / kg_25, 2)                             AS prezzo_2025
FROM pivot;

-- 8.3 Lo stesso confronto per i 15 maggiori mercati del 2022
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    SUM(CASE WHEN e.anno = 2022 AND e.tipo_dato = 'EV'  THEN e.valore END) AS euro_22,
    SUM(CASE WHEN e.anno = 2025 AND e.tipo_dato = 'EV'  THEN e.valore END) AS euro_25,
    SUM(CASE WHEN e.anno = 2022 AND e.tipo_dato = 'ENW' THEN e.valore END) AS kg_22,
    SUM(CASE WHEN e.anno = 2025 AND e.tipo_dato = 'ENW' THEN e.valore END) AS kg_25
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITTOT'
    AND e.codice_prodotto = 'CB1511'
    AND p.tipo = 'paese'
  GROUP BY p.nome
)
SELECT
  paese,
  ROUND(euro_22 / 1e6, 1) AS mln_2022,
  ROUND(euro_25 / 1e6, 1) AS mln_2025,
  ROUND(100 * (euro_25 / NULLIF(euro_22, 0) - 1), 1) AS valore_pct,
  ROUND(100 * (kg_25 / NULLIF(kg_22, 0) - 1), 1)     AS chili_pct,
  ROUND(euro_22 / NULLIF(kg_22, 0), 2) AS prezzo_2022,
  ROUND(euro_25 / NULLIF(kg_25, 0), 2) AS prezzo_2025
FROM per_paese
ORDER BY euro_22 DESC
LIMIT 15;

-- 8.4 Il prezzo medio inganna? Scomposizione paese per paese
-- I prezzi vanno da circa 2,50 €/kg (Cina) a oltre 50 €/kg (Francia): il prezzo medio
-- può salire anche solo perché si perdono i mercati più economici. Questa query separa:
--   effetto_volume_paese  chili persi o guadagnati in ogni paese, al prezzo del 2022 di quel paese
--   effetto_prezzo_paese  variazione del prezzo in ogni paese, sui chili del 2025
--   mercati_senza_confronto  paesi senza dati completi in entrambi gli anni
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    COALESCE(SUM(CASE WHEN e.anno = 2022 AND e.tipo_dato = 'EV'  THEN e.valore END), 0) AS euro_22,
    COALESCE(SUM(CASE WHEN e.anno = 2025 AND e.tipo_dato = 'EV'  THEN e.valore END), 0) AS euro_25,
    COALESCE(SUM(CASE WHEN e.anno = 2022 AND e.tipo_dato = 'ENW' THEN e.valore END), 0) AS kg_22,
    COALESCE(SUM(CASE WHEN e.anno = 2025 AND e.tipo_dato = 'ENW' THEN e.valore END), 0) AS kg_25
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITTOT'
    AND e.codice_prodotto = 'CB1511'
    AND p.tipo = 'paese'
    AND e.anno IN (2022, 2025)
  GROUP BY p.nome
)
SELECT
  ROUND(SUM(euro_25 - euro_22) / 1e6, 1) AS variazione_valore_mln,
  ROUND(SUM(CASE WHEN euro_22 > 0 AND kg_22 > 0 AND kg_25 > 0
                 THEN (kg_25 - kg_22) * euro_22 / kg_22 END) / 1e6, 1) AS effetto_volume_paese_mln,
  ROUND(SUM(CASE WHEN euro_22 > 0 AND kg_22 > 0 AND kg_25 > 0
                 THEN (euro_25 / kg_25 - euro_22 / kg_22) * kg_25 END) / 1e6, 1) AS effetto_prezzo_paese_mln,
  ROUND(SUM(CASE WHEN NOT (euro_22 > 0 AND kg_22 > 0 AND kg_25 > 0)
                 THEN euro_25 - euro_22 ELSE 0 END) / 1e6, 1) AS mercati_senza_confronto_mln,
  SUM(CASE WHEN euro_22 > 0 AND kg_22 > 0 AND kg_25 > 0
            AND euro_25 / kg_25 < euro_22 / kg_22 THEN 1 ELSE 0 END) AS paesi_con_prezzo_in_calo,
  SUM(CASE WHEN euro_22 > 0 AND kg_22 > 0 AND kg_25 > 0
            AND euro_25 / kg_25 > euro_22 / kg_22 THEN 1 ELSE 0 END) AS paesi_con_prezzo_in_aumento
FROM per_paese;

-- 8.5 Chi spiega il calo dei chili? I 5 paesi che ne hanno persi di più
-- SUM() OVER () qui somma tutti i paesi: serve come denominatore comune.
WITH per_paese AS (
  SELECT
    p.nome AS paese,
    COALESCE(SUM(CASE WHEN e.anno = 2022 THEN e.valore END), 0) AS kg_22,
    COALESCE(SUM(CASE WHEN e.anno = 2025 THEN e.valore END), 0) AS kg_25
  FROM export e
  JOIN partner p ON p.codice = e.codice_partner
  WHERE e.codice_territorio = 'ITTOT'
    AND e.codice_prodotto = 'CB1511'
    AND e.tipo_dato = 'ENW'
    AND p.tipo = 'paese'
    AND e.anno IN (2022, 2025)
  GROUP BY p.nome
)
SELECT
  paese,
  ROUND(kg_22 / 1e6, 1) AS kt_2022,
  ROUND(kg_25 / 1e6, 1) AS kt_2025,
  ROUND((kg_25 - kg_22) / 1e6, 1) AS delta_kt,
  ROUND(100 * (kg_25 - kg_22) / SUM(kg_25 - kg_22) OVER (), 1) AS quota_del_calo_netto_pct,
  ROUND(100 * kg_22 / SUM(kg_22) OVER (), 1) AS peso_sui_chili_2022_pct
FROM per_paese
ORDER BY kg_25 - kg_22
LIMIT 5;
