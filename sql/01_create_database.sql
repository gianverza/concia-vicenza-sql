-- 01_create_database.sql
-- Crea il database del progetto.
--
-- utf8mb4: copre tutto Unicode (il vecchio "utf8" di MySQL arriva solo a 3 byte per carattere).
-- utf8mb4_unicode_ci: confronti che ignorano maiuscole e accenti ('Perù' = 'peru').
-- IF NOT EXISTS: se il database esiste già, lo script non va in errore e non tocca i dati.

CREATE DATABASE IF NOT EXISTS concia_vicenza
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE concia_vicenza;
