-- 1. Bersihkan tabel lama jika ada (agar saat run ulang tidak error)
DROP TABLE IF EXISTS leaves CASCADE;
DROP TABLE IF EXISTS attendance_logs CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS shifts CASCADE;
DROP TYPE IF EXISTS user_role;
DROP TYPE IF EXISTS attendance_status;
DROP TYPE IF EXISTS leave_status;

-- 2. Membuat Tipe Data ENUM (Agar data konsisten)
CREATE TYPE user_role AS ENUM ('admin', 'employee');
CREATE TYPE attendance_status AS ENUM ('tepat_waktu', 'terlambat');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');

-- 3. Tabel Shifts (Aturan Jam Kerja)
CREATE TABLE shifts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) DEFAULT 'Regular',
    start_time TIME NOT NULL DEFAULT '08:00:00', -- Jam Masuk
    end_time TIME NOT NULL DEFAULT '17:00:00'    -- Jam Pulang
);

-- 4. Tabel Users (Data Pegawai & Admin)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) UNIQUE NOT NULL, -- Contoh: EMP001
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,          -- Simpan hash password di sini
    full_name VARCHAR(100) NOT NULL,
    department VARCHAR(50),                  -- IT, HR, Finance
    position VARCHAR(50),                    -- Developer, Manager
    role user_role NOT NULL DEFAULT 'employee',
    avatar_url TEXT,                         -- Link foto profil
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Tabel Attendance Logs (Riwayat Absensi)
CREATE TABLE attendance_logs (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    check_in_time TIME,
    check_out_time TIME,
    status attendance_status, -- Diset oleh Backend: Tepat Waktu / Terlambat
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Tabel Leaves (Cuti & Izin)
CREATE TABLE leaves (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- Sakit, Izin, Cuti Tahunan
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status leave_status DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- DATA DUMMY (SEEDING)
-- Masukkan data ini agar Dashboard langsung ada isinya saat dites
-- =============================================

-- A. Insert Shift
INSERT INTO shifts (start_time, end_time) VALUES ('08:00:00', '17:00:00');

-- B. Insert Users (Sesuai Screenshot Data Pegawai)
INSERT INTO users (employee_id, username, password, full_name, department, position, role, avatar_url) VALUES 
('ADM001', 'admin', 'hashed_password_123', 'Admin HR', 'HR', 'Administrator', 'admin', 'https://via.placeholder.com/150'),
('EMP001', 'budi', 'hashed_password_123', 'Budi Santoso', 'IT', 'Developer', 'employee', 'https://via.placeholder.com/150'),
('EMP002', 'siti', 'hashed_password_123', 'Siti Nurhaliza', 'HR', 'HR Manager', 'employee', 'https://via.placeholder.com/150'),
('EMP003', 'ahmad', 'hashed_password_123', 'Ahmad Wijaya', 'Finance', 'Accountant', 'employee', 'https://via.placeholder.com/150'),
('EMP004', 'dewi', 'hashed_password_123', 'Dewi Lestari', 'Marketing', 'Marketing Lead', 'employee', 'https://via.placeholder.com/150');

-- C. Insert Attendance Logs (Sesuai Screenshot Riwayat - Januari 2026)
-- Skenario: Budi (Tepat Waktu), Siti (Terlambat)
INSERT INTO attendance_logs (user_id, date, check_in_time, status) VALUES 
-- Tanggal 5 Januari 2026
(2, '2026-01-05', '07:55:00', 'tepat_waktu'), -- Budi
(3, '2026-01-05', '08:10:00', 'terlambat'),   -- Siti
-- Tanggal 4 Januari 2026
(2, '2026-01-04', '07:50:00', 'tepat_waktu'), -- Budi
(4, '2026-01-04', '08:00:00', 'tepat_waktu'); -- Ahmad (Rudi di gambar, Ahmad di data)

-- D. Insert Leaves (Contoh Cuti)
INSERT INTO leaves (user_id, type, start_date, end_date, reason, status) VALUES
(5, 'Sakit', '2026-01-05', '2026-01-06', 'Demam tinggi', 'approved');