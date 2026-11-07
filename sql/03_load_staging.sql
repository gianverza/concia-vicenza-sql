-- 03_load_staging.sql
-- Carica i tre CSV nella staging.
--
-- Prerequisito: i CSV devono stare nella cartella indicata da secure_file_priv,
-- l'unica da cui il server può leggere (SHOW VARIABLES LIKE 'secure_file_priv').
--
-- IGNORE 1 LINES salta l'intestazione. Il BOM UTF-8 a inizio file sta proprio lì,
-- quindi non finisce nei dati.
-- Le variabili @_ scartano le colonne che non servono: LOAD DATA legge i campi
-- per posizione, quindi ogni colonna del file va comunque nominata.
-- TRUNCATE rende lo script ripetibile: rilanciandolo non si caricano doppioni.
-- '\r\n' perché i file hanno la fine riga di Windows: con il solo '\n' il \r
-- resterebbe attaccato all'ultimo campo e il caricamento andrebbe in errore.

USE concia_vicenza;

TRUNCATE TABLE staging_export;

-- File da 38 colonne: Vicenza CB151, tutti i partner
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/vicenza_cb151_paesi.csv'
INTO TABLE staging_export
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@_, @_, codice_territorio, nome_territorio, tipo_dato, @_, @_, @_,
 codice_prodotto, descrizione_prodotto, codice_partner, nome_partner, anno, valore,
 @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_)
SET file_origine = 'vicenza_cb151_paesi.csv';

-- File da 38 colonne: Italia CB1511, euro e chili, tutti i partner
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/italia_concia_euro_kg.csv'
INTO TABLE staging_export
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@_, @_, codice_territorio, nome_territorio, tipo_dato, @_, @_, @_,
 codice_prodotto, descrizione_prodotto, codice_partner, nome_partner, anno, valore,
 @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_, @_)
SET file_origine = 'italia_concia_euro_kg.csv';

-- File da 16 colonne: confronti verso il MONDO
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.4/Uploads/confronti_mondo.csv'
INTO TABLE staging_export
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@_, @_, codice_territorio, nome_territorio, tipo_dato, @_, @_, @_,
 codice_prodotto, descrizione_prodotto, codice_partner, nome_partner, anno, valore,
 @_, @_)
SET file_origine = 'confronti_mondo.csv';

-- Attese: 5.330 + 11.916 + 210 = 17.456 righe
SELECT file_origine, COUNT(*) AS righe
FROM staging_export
GROUP BY file_origine;
