-- 05_popola_tabelle.sql
-- Dalla staging alle tabelle definitive, con le correzioni emerse dall'esplorazione dei CSV.

USE concia_vicenza;

-- Nei CSV ITTOT si chiama "Totale": qui prende il nome corretto.
INSERT INTO territori (codice, nome) VALUES
  ('ITD32', 'Vicenza'),
  ('ITTOT', 'Italia');

-- Prima il padre, poi i figli: la chiave esterna richiede che il padre esista già.
INSERT INTO prodotti (codice, descrizione, codice_padre) VALUES
  ('C',      'Totale manifatturiero',  NULL),
  ('CB151',  'Concia e pelletteria',   'C'),
  ('CB1511', 'Concia (cuoio conciato)', 'CB151'),
  ('CB1512', 'Pelletteria',            'CB151');

-- Classificazione dei partner:
--   paese      codici a 2 lettere, tranne le eccezioni sotto
--   aggregato  EU e tutti i codici più lunghi (continenti, blocchi, WORLD...)
--   altro      voci che non sono né paesi né aggregati: paesi non determinati,
--              provviste di bordo, depositi franchi. Fanno parte del totale WORLD.
--
-- Stesso paese con due codici, in anni che non si sovrappongono:
--   EL (1991-1998) -> GR (1999-2025), Grecia
--   XM (2005-2006) -> ME (2007-2025), Montenegro
-- Si tiene un solo codice, altrimenti la serie storica resterebbe spezzata.
INSERT INTO partner (codice, nome, tipo)
SELECT DISTINCT
  CASE codice_partner WHEN 'EL' THEN 'GR' WHEN 'XM' THEN 'ME' ELSE codice_partner END,
  nome_partner,
  CASE
    WHEN codice_partner IN ('QR', 'QV', 'QW', 'QX', 'PFDEP', 'PNAFOR', 'OTH_EDEST') THEN 'altro'
    WHEN codice_partner = 'EU' OR CHAR_LENGTH(codice_partner) > 2 THEN 'aggregato'
    ELSE 'paese'
  END
FROM staging_export;

-- DISTINCT elimina le 70 righe presenti in due file, che hanno valori identici.
-- Se avessero valori diversi, la chiave primaria bloccherebbe l'inserimento.
INSERT INTO export (codice_territorio, codice_prodotto, codice_partner, tipo_dato, anno, valore)
SELECT DISTINCT
  codice_territorio,
  codice_prodotto,
  CASE codice_partner WHEN 'EL' THEN 'GR' WHEN 'XM' THEN 'ME' ELSE codice_partner END,
  tipo_dato,
  anno,
  valore
FROM staging_export;
