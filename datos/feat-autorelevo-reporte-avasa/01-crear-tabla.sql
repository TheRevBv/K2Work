CREATE TABLE IF NOT EXISTS autorelevo_contrato_renta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_number VARCHAR(20) NOT NULL,
    numero_reserva VARCHAR(20) NULL,
    siniestro_folio VARCHAR(30) NULL,
    dias_renta DECIMAL(6,2) NOT NULL,
    total_contrato DECIMAL(12,2) NOT NULL,
    voucher_total DECIMAL(12,2) NOT NULL,
    fecha_carga DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_acr_contract_number (contract_number),
    KEY ix_acr_numero_reserva (numero_reserva),
    KEY ix_acr_siniestro_folio (siniestro_folio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
