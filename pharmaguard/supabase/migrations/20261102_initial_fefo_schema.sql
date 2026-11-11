-- ==============================================================================
-- PHARMAGUARD CLOUD DATABASE SCHEMA & FEFO ENGINE (SUPABASE / POSTGRESQL)
-- Standard: Permenkes No. 73/2016, BPOM CDOB, UU PDP No. 27/2022 & HL7 FHIR
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. ENUM TYPES
DO $$ BEGIN
    CREATE TYPE medication_category AS ENUM ('syrup', 'tablet', 'ointment', 'capsule', 'drops', 'inhalation');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE batch_status AS ENUM ('ACTIVE', 'WARNING', 'CRITICAL', 'QUARANTINED', 'DISCARDED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE mutation_type AS ENUM ('IN', 'OUT', 'ADJUSTMENT', 'QUARANTINE', 'DISCARD');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE staff_role AS ENUM ('APOTEKER', 'ASISTEN_APOTEKER', 'LOGISTIK_GUDANG', 'AUDITOR');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. RACK LOCATIONS (Master Lokasi Penyimpanan Fisik)
CREATE TABLE IF NOT EXISTS rack_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rack_code VARCHAR(50) NOT NULL UNIQUE, -- e.g., 'Rak A-02', 'Rak B-01', 'Chiller-01'
    zone_area VARCHAR(100) NOT NULL,       -- e.g., 'Etalase Depan', 'Gudang Dalam', 'Cold-Chain Chiller'
    temperature_tier VARCHAR(50) DEFAULT 'ROOM_TEMP', -- 'ROOM_TEMP', 'COLD_CHAIN' (2-8 C)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MASTER MEDICATIONS (Master Produk & GTIN Barcode)
CREATE TABLE IF NOT EXISTS master_medications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    gtin_code VARCHAR(14) NOT NULL UNIQUE, -- GS1 AI (01) GTIN / EAN-13
    name VARCHAR(255) NOT NULL,
    category medication_category NOT NULL,
    form_unit VARCHAR(50) NOT NULL,        -- 'Botol', 'Strip', 'Tube', 'Vial'
    dosage_strength VARCHAR(100),          -- '125mg/5ml', '500mg', '20mg'
    default_rack_id UUID REFERENCES rack_locations(id),
    is_thermolabile BOOLEAN DEFAULT FALSE, -- Flag sediaan termolabil (rantai dingin)
    satusehat_kfa_code VARCHAR(100),       -- Kode Kamus Farmasi dan Alat Kesehatan (KFA) Kemenkes
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. MEDICATION BATCHES (Inti Algoritma FEFO)
CREATE TABLE IF NOT EXISTS medication_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medication_id UUID NOT NULL REFERENCES master_medications(id) ON DELETE CASCADE,
    batch_number VARCHAR(100) NOT NULL,    -- GS1 AI (10)
    manufacturing_date DATE,
    expiration_date DATE NOT NULL,         -- GS1 AI (17) YYMMDD -> Inti pengurutan FEFO
    current_quantity INT NOT NULL CHECK (current_quantity >= 0),
    reserved_quantity INT DEFAULT 0 CHECK (reserved_quantity >= 0),
    unit VARCHAR(50) NOT NULL,
    current_rack_id UUID REFERENCES rack_locations(id),
    status batch_status DEFAULT 'ACTIVE',
    version_vector INT DEFAULT 1,          -- Untuk sinkronisasi Offline-First
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_med_batch UNIQUE (medication_id, batch_number)
);

-- Indexes for Fast Scanning & FEFO Sorting
CREATE INDEX IF NOT EXISTS idx_batches_fefo_order 
    ON medication_batches (medication_id, expiration_date ASC) 
    WHERE status = 'ACTIVE' AND current_quantity > 0;

CREATE INDEX IF NOT EXISTS idx_batches_expiry_status 
    ON medication_batches (expiration_date, status);

CREATE INDEX IF NOT EXISTS idx_master_gtin 
    ON master_medications (gtin_code);

-- 6. USER STAFF (Pengguna Petugas & ABAC)
CREATE TABLE IF NOT EXISTS user_staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID,                     -- Link ke Supabase auth.users
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone_number VARCHAR(30),
    role staff_role NOT NULL DEFAULT 'ASISTEN_APOTEKER',
    stra_number VARCHAR(100),              -- Surat Tanda Registrasi Apoteker / TTK
    pharmacy_name VARCHAR(150) DEFAULT 'Apotek Sehat Medika',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. STOCK MUTATIONS (Pencatatan Audit Aliran Stok)
CREATE TABLE IF NOT EXISTS stock_mutations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES medication_batches(id),
    mutation_type mutation_type NOT NULL,
    quantity_changed INT NOT NULL,
    quantity_before INT NOT NULL,
    quantity_after INT NOT NULL,
    reference_number VARCHAR(100),         -- No. Surat Pesanan / No. Resep Penebusan
    notes TEXT,
    recorded_by UUID REFERENCES user_staff(id),
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. AUDIT LOGS (UU PDP No. 27/2022 Compliance)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    actor_id UUID REFERENCES user_staff(id),
    action_type VARCHAR(100) NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    masked_data JSONB,                     -- Data pasien disamarkan (Pseudonymization)
    ip_address INET,
    client_timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- BUSINESS LOGIC & RPC FUNCTIONS
-- ==============================================================================

-- Function 1: Get FEFO Dispense Queue for a Medication
-- Menjamin obat yang dikeluarkan adalah batch dengan tanggal kedaluwarsa paling dekat
CREATE OR REPLACE FUNCTION get_fefo_dispense_queue(p_medication_id UUID)
RETURNS TABLE (
    batch_id UUID,
    batch_number VARCHAR,
    expiration_date DATE,
    days_until_expiry INT,
    available_stock INT,
    rack_location VARCHAR,
    urgency_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id AS batch_id,
        b.batch_number,
        b.expiration_date,
        (b.expiration_date - CURRENT_DATE)::INT AS days_until_expiry,
        b.current_quantity AS available_stock,
        COALESCE(r.rack_code, 'Tanpa Lokasi') AS rack_location,
        CASE 
            WHEN (b.expiration_date - CURRENT_DATE) <= 5 THEN 'CRITICAL'
            WHEN (b.expiration_date - CURRENT_DATE) <= 30 THEN 'WARNING'
            WHEN (b.expiration_date - CURRENT_DATE) <= 90 THEN 'ATTENTION'
            ELSE 'SAFE'
        END AS urgency_status
    FROM medication_batches b
    LEFT JOIN rack_locations r ON b.current_rack_id = r.id
    WHERE b.medication_id = p_medication_id
      AND b.status = 'ACTIVE'
      AND b.current_quantity > 0
    ORDER BY b.expiration_date ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 2: Quarantine Batch (Aksi Tarik dari Rak)
CREATE OR REPLACE FUNCTION quarantine_batch(
    p_batch_id UUID,
    p_staff_id UUID,
    p_reason TEXT DEFAULT 'Ditarik dari rak karena mendekati kedaluwarsa (H-5)'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_qty INT;
    v_med_id UUID;
BEGIN
    SELECT current_quantity, medication_id INTO v_qty, v_med_id 
    FROM medication_batches WHERE id = p_batch_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Batch tidak ditemukan';
    END IF;

    -- Update batch status to QUARANTINED
    UPDATE medication_batches
    SET status = 'QUARANTINED',
        version_vector = version_vector + 1,
        updated_at = NOW()
    WHERE id = p_batch_id;

    -- Catat riwayat mutasi
    INSERT INTO stock_mutations (
        batch_id, mutation_type, quantity_changed, 
        quantity_before, quantity_after, notes, recorded_by
    ) VALUES (
        p_batch_id, 'QUARANTINE', 0,
        v_qty, v_qty, p_reason, p_staff_id
    );

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function 3: Automated Cron EWS (Early Warning System Routine)
-- Dijalankan berkala setiap hari jam 07:00 pagi
CREATE OR REPLACE FUNCTION check_and_update_expiry_status()
RETURNS TABLE (
    critical_count INT,
    warning_count INT
) AS $$
DECLARE
    v_crit INT := 0;
    v_warn INT := 0;
BEGIN
    -- Update batch aktif yang tinggal <= 5 hari menjadi CRITICAL
    WITH updated_critical AS (
        UPDATE medication_batches
        SET status = 'CRITICAL', updated_at = NOW()
        WHERE status = 'ACTIVE' 
          AND expiration_date <= CURRENT_DATE + INTERVAL '5 days'
          AND expiration_date > CURRENT_DATE
        RETURNING id
    )
    SELECT COUNT(*) INTO v_crit FROM updated_critical;

    -- Update batch aktif sisa 6-30 hari menjadi WARNING
    WITH updated_warning AS (
        UPDATE medication_batches
        SET status = 'WARNING', updated_at = NOW()
        WHERE status = 'ACTIVE' 
          AND expiration_date <= CURRENT_DATE + INTERVAL '30 days'
          AND expiration_date > CURRENT_DATE + INTERVAL '5 days'
        RETURNING id
    )
    SELECT COUNT(*) INTO v_warn FROM updated_warning;

    RETURN QUERY SELECT v_crit, v_warn;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==============================================================================
-- HL7 FHIR (SATUSEHAT) INTEROPERABILITY VIEW
-- Standar Resource: Medication (R4)
-- ==============================================================================
CREATE OR REPLACE VIEW view_fhir_medication_inventory AS
SELECT 
    b.id AS batch_resource_id,
    jsonb_build_object(
        'resourceType', 'Medication',
        'id', m.id::TEXT,
        'meta', jsonb_build_object(
            'profile', jsonb_build_array('https://fhir.kemkes.go.id/r4/StructureDefinition/Medication')
        ),
        'identifier', jsonb_build_array(
            jsonb_build_object(
                'system', 'https://sys-ids.kemkes.go.id/kfa',
                'value', COALESCE(m.satusehat_kfa_code, m.gtin_code)
            )
        ),
        'code', jsonb_build_object(
            'coding', jsonb_build_array(
                jsonb_build_object(
                    'system', 'https://www.gs1.org/gtin',
                    'code', m.gtin_code,
                    'display', m.name
                )
            ),
            'text', m.name
        ),
        'status', 'active',
        'form', jsonb_build_object(
            'text', m.form_unit
        ),
        'batch', jsonb_build_object(
            'lotNumber', b.batch_number,
            'expirationDate', to_char(b.expiration_date, 'YYYY-MM-DD')
        ),
        'extension', jsonb_build_array(
            jsonb_build_object(
                'url', 'https://fhir.kemkes.go.id/r4/StructureDefinition/MedicationStockQuantity',
                'valueQuantity', jsonb_build_object(
                    'value', b.current_quantity,
                    'unit', b.unit
                )
            )
        )
    ) AS fhir_json
FROM medication_batches b
JOIN master_medications m ON b.medication_id = m.id;

-- ==============================================================================
-- SEED DATA (Sesuai Blueprint Obat PharmaGuard)
-- ==============================================================================
INSERT INTO rack_locations (id, rack_code, zone_area) VALUES
    ('00000000-0000-0000-0000-000000000001', 'Rak A-02', 'Etalase Depan (Sirup)'),
    ('00000000-0000-0000-0000-000000000002', 'Rak B-01', 'Etalase Tengah (Tablet)'),
    ('00000000-0000-0000-0000-000000000003', 'Rak D-02', 'Etalase Samping (Salep)'),
    ('00000000-0000-0000-0000-000000000004', 'Rak A-05', 'Gudang Depan (Drops)'),
    ('00000000-0000-0000-0000-000000000005', 'Rak C-03', 'Gudang Tengah (Kapsul)'),
    ('00000000-0000-0000-0000-000000000006', 'Rak D-01', 'Gudang Belakang (Gel)')
ON CONFLICT (rack_code) DO NOTHING;

-- Insert User Staff
INSERT INTO user_staff (id, full_name, email, role, stra_number) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Apoteker Pija, S.Farm', 'apoteker@sehat.com', 'APOTEKER', '19950102/STRA-UAD/2021')
ON CONFLICT (email) DO NOTHING;

-- Insert Master Medicines
INSERT INTO master_medications (id, gtin_code, name, category, form_unit, default_rack_id) VALUES
    ('22222222-2222-2222-2222-000000000001', '8991234567890', 'Amoxicillin Sirup 125mg', 'syrup', 'Botol', '00000000-0000-0000-0000-000000000001'),
    ('22222222-2222-2222-2222-000000000002', '8992345678901', 'Paracetamol Tablet 500mg', 'tablet', 'Strip', '00000000-0000-0000-0000-000000000002'),
    ('22222222-2222-2222-2222-000000000003', '8993456789012', 'Salep Betametason', 'ointment', 'Tube', '00000000-0000-0000-0000-000000000003'),
    ('22222222-2222-2222-2222-000000000004', '8994567890123', 'Cetirizine Drops 10ml', 'syrup', 'Botol', '00000000-0000-0000-0000-000000000004'),
    ('22222222-2222-2222-2222-000000000005', '8995678901234', 'Omeprazole 20mg', 'capsule', 'Strip', '00000000-0000-0000-0000-000000000005'),
    ('22222222-2222-2222-2222-000000000006', '8996789012345', 'Bioplacenton Gel', 'ointment', 'Tube', '00000000-0000-0000-0000-000000000006')
ON CONFLICT (gtin_code) DO NOTHING;

-- Insert Batches (FEFO Expiry Dates)
INSERT INTO medication_batches (medication_id, batch_number, expiration_date, current_quantity, unit, current_rack_id, status) VALUES
    ('22222222-2222-2222-2222-000000000001', 'AMX-2024-09', CURRENT_DATE + INTERVAL '3 days', 8, 'Botol', '00000000-0000-0000-0000-000000000001', 'CRITICAL'),
    ('22222222-2222-2222-2222-000000000002', 'PCT-2024-11', CURRENT_DATE + INTERVAL '5 days', 12, 'Strip', '00000000-0000-0000-0000-000000000002', 'CRITICAL'),
    ('22222222-2222-2222-2222-000000000003', 'BTM-2025-01', CURRENT_DATE + INTERVAL '18 days', 5, 'Tube', '00000000-0000-0000-0000-000000000003', 'WARNING'),
    ('22222222-2222-2222-2222-000000000004', 'CTZ-2025-03', CURRENT_DATE + INTERVAL '22 days', 15, 'Botol', '00000000-0000-0000-0000-000000000004', 'WARNING'),
    ('22222222-2222-2222-2222-000000000005', 'OMP-2025-08', CURRENT_DATE + INTERVAL '180 days', 40, 'Strip', '00000000-0000-0000-0000-000000000005', 'ACTIVE'),
    ('22222222-2222-2222-2222-000000000006', 'BIO-2025-10', CURRENT_DATE + INTERVAL '240 days', 25, 'Tube', '00000000-0000-0000-0000-000000000006', 'ACTIVE')
ON CONFLICT ON CONSTRAINT uq_med_batch DO NOTHING;
