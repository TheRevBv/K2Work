-- Solo dev: quita las tablas de la primera versión (vacías) para recrearlas con ajuste_movil_archivos.sql
SELECT (SELECT COUNT(*) FROM ajuste_movil_file) AS files, (SELECT COUNT(*) FROM ajuste_movil_photo_batch) AS batches;
DROP TABLE ajuste_movil_file;
DROP TABLE ajuste_movil_photo_batch;
