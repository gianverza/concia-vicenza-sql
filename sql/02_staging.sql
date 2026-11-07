-- 02_staging.sql
-- Tabella di appoggio: accoglie i CSV ISTAT quasi così come sono.
-- Niente chiavi né vincoli, apposta: prima si caricano i dati, poi si controllano e si puliscono.
-- I vincoli arriveranno nella tabella dei fatti "export".
--
-- Dimensioni ricavate dai CSV (lunghezza massima trovata -> spazio previsto):
--   codice partner   14 -> 20
--   nome partner     32 -> 100
--   descrizione CPA 113 -> 255
--   valore massimo  611.425.265.570,66 con al massimo 5 decimali -> DECIMAL(20,5)
--
-- DECIMAL e non FLOAT: DECIMAL conserva il valore esatto, FLOAT lo approssima
-- e le somme accumulerebbero piccoli errori.
--
-- file_origine: i tre CSV hanno 70 righe in comune, con valori identici
-- (Vicenza CB151 e Italia CB1511 verso WORLD, 35 anni ciascuna).
-- Questa colonna dice da dove arriva ogni riga e permette di eliminare i doppioni.

USE concia_vicenza;

CREATE TABLE IF NOT EXISTS staging_export (
  codice_territorio   VARCHAR(10)    NULL,
  nome_territorio     VARCHAR(50)    NULL,
  tipo_dato           VARCHAR(5)     NULL,   -- EV = euro, ENW = chili
  codice_prodotto     VARCHAR(10)    NULL,
  descrizione_prodotto VARCHAR(255)  NULL,
  codice_partner      VARCHAR(20)    NULL,
  nome_partner        VARCHAR(100)   NULL,
  anno                SMALLINT       NULL,
  valore              DECIMAL(20,5)  NULL,
  file_origine        VARCHAR(50)    NULL
);
