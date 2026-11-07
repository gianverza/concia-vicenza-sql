-- 04_schema.sql
-- Le tabelle definitive: tre dimensioni e una tabella dei fatti.
-- Qui i vincoli ci sono: da questo punto in poi il database rifiuta i dati incoerenti.
--
-- Si cancella prima "export" perché dipende dalle altre tramite le chiavi esterne.

USE concia_vicenza;

DROP TABLE IF EXISTS export;
DROP TABLE IF EXISTS partner;
DROP TABLE IF EXISTS prodotti;
DROP TABLE IF EXISTS territori;

CREATE TABLE territori (
  codice  VARCHAR(10)  PRIMARY KEY,
  nome    VARCHAR(50)  NOT NULL
);

-- codice_padre punta alla stessa tabella e descrive la gerarchia CB1511 -> CB151 -> C
CREATE TABLE prodotti (
  codice        VARCHAR(10)   PRIMARY KEY,
  descrizione   VARCHAR(100)  NOT NULL,
  codice_padre  VARCHAR(10)   NULL,
  FOREIGN KEY (codice_padre) REFERENCES prodotti (codice)
);

-- tipo evita di sommare aggregati sovrapposti (WORLD, EU27_2020, ASI...) ai singoli paesi
CREATE TABLE partner (
  codice  VARCHAR(20)   PRIMARY KEY,
  nome    VARCHAR(100)  NOT NULL,
  tipo    ENUM('paese', 'aggregato', 'altro') NOT NULL
);

-- La chiave primaria su cinque colonne garantisce una sola osservazione
-- per territorio, prodotto, partner, tipo di dato e anno.
CREATE TABLE export (
  codice_territorio  VARCHAR(10)    NOT NULL,
  codice_prodotto    VARCHAR(10)    NOT NULL,
  codice_partner     VARCHAR(20)    NOT NULL,
  tipo_dato          VARCHAR(5)     NOT NULL,
  anno               SMALLINT       NOT NULL,
  valore             DECIMAL(20,5)  NOT NULL,
  PRIMARY KEY (codice_territorio, codice_prodotto, codice_partner, tipo_dato, anno),
  FOREIGN KEY (codice_territorio) REFERENCES territori (codice),
  FOREIGN KEY (codice_prodotto)   REFERENCES prodotti (codice),
  FOREIGN KEY (codice_partner)    REFERENCES partner (codice),
  CHECK (tipo_dato IN ('EV', 'ENW')),
  CHECK (valore >= 0)
);
