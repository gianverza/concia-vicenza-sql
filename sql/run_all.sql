-- run_all.sql
-- Ricostruisce tutto da zero, nell'ordine giusto. Da lanciare dalla cartella del progetto:
--   mysql -u root -p --default-character-set=utf8mb4 -e "source sql/run_all.sql"

source sql/01_create_database.sql
source sql/02_staging.sql
source sql/03_load_staging.sql
source sql/04_schema.sql
source sql/05_popola_tabelle.sql
source sql/06_controlli.sql
source sql/07_trend.sql
source sql/08_valore_chili.sql
source sql/09_paesi.sql
