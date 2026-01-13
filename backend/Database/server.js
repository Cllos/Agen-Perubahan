const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./connect'); // File koneksi Anda

const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());

// ... (imports dan setup db sama)

// ---------------------------------------------------------
// REVISI ROUTE LOGIN
// Logic: Employee DILARANG login. Hanya Admin & Security.
// ---------------------------------------------------------
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const sql = "SELECT * FROM users WHERE username = $1";
  
  pool.query(sql, [username], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    if (result.rows.length === 0) return res.status(401).json({ message: "Username tidak ditemukan" });

    const user = result.rows[0];

    // Cek Password
    if (user.password !== password) {
      return res.status(401).json({ message: "Password salah" });
    }

    // --- LOGIC BARU: BLOKIR EMPLOYEE ---
    if (user.role === 'employee') {
      return res.status(403).json({ message: "Karyawan tidak memiliki akses aplikasi. Silakan hubungi Security/Admin untuk absensi." });
    }

    // Login Sukses (Admin / Security)
    res.json({
      message: "Login berhasil",
      user: {
        id: user.id,
        employee_id: user.employee_id,
        name: user.full_name,
        role: user.role, 
        avatar: user.avatar_url
      }
    });
  });
});

// ---------------------------------------------------------
// REVISI ROUTE GET PEGAWAI (Untuk Dropdown List)
// Logic: Jangan tampilkan Admin atau Security di list absen
// ---------------------------------------------------------
app.get('/api/pegawai', (req, res) => {
  // Hanya ambil yang role-nya 'employee'
  // Jadi ID 'SEC...' dan 'ADM...' tidak akan muncul di list
  const sql = "SELECT * FROM users WHERE role = 'employee' ORDER BY full_name ASC";
  
  pool.query(sql, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json(result.rows); 
  });
});

// ... (Sisa route attendance/dashboard biarkan sama)

// 2. POST: Tambah Pegawai
app.post('/api/pegawai', (req, res) => {
  // Sesuaikan dengan nama kolom di FrontEnd (formData)
  const { id, name, department, role, avatar } = req.body;
  
  // Mapping ke kolom Database (employee_id, full_name, dst)
  const sql = `
    INSERT INTO users (employee_id, full_name, department, position, role, avatar_url, password, username) 
    VALUES ($1, $2, $3, $4, 'employee', $5, 'default123', $1) 
    RETURNING *
  `;
  
  // Note: Kita set password default & username sama dengan ID dulu biar simpel
  const values = [id, name, department, role, avatar];

  pool.query(sql, values, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: "Pegawai berhasil ditambahkan", data: result.rows[0] });
  });
});

// 3. PUT: Edit Pegawai
app.put('/api/pegawai/:id', (req, res) => {
  const employeeId = req.params.id; // Ini adalah employee_id (misal EMP001)
  const { name, department, role, avatar } = req.body;
  
  const sql = "UPDATE users SET full_name = $1, department = $2, position = $3, avatar_url = $4 WHERE employee_id = $5";
  const values = [name, department, role, avatar, employeeId];

  pool.query(sql, values, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: "Pegawai berhasil diupdate" });
  });
});

// 4. DELETE: Hapus Pegawai
app.delete('/api/pegawai/:id', (req, res) => {
  const employeeId = req.params.id;
  const sql = "DELETE FROM users WHERE employee_id = $1";

  pool.query(sql, [employeeId], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: "Pegawai berhasil dihapus" });
  });
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});

// ... kode sebelumnya ...

// 5. GET: Ambil Riwayat Absensi (Gabung dengan data User)
app.get('/api/riwayat', (req, res) => {
  const sql = `
    SELECT 
      a.id, 
      a.date, 
      a.check_in_time, 
      a.status, 
      a.photo_url,  -- TAMBAHAN: Ambil URL Foto
      a.location,   -- TAMBAHAN: Ambil Lokasi
      u.employee_id, 
      u.full_name 
    FROM attendance_logs a
    JOIN users u ON a.user_id = u.id
    ORDER BY a.date DESC, a.check_in_time DESC
  `;

  pool.query(sql, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json(result.rows);
  });
});

// 6. GET: Dashboard Data (Statistik Lengkap)
app.get('/api/dashboard', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD

    // A. Hitung Total Pegawai
    const totalEmpQuery = await pool.query("SELECT COUNT(*) FROM users WHERE role = 'employee'");
    const totalEmployees = parseInt(totalEmpQuery.rows[0].count);

    // B. Ambil Absensi Hari Ini (Join dengan Users)
    const todayQuery = await pool.query(`
      SELECT a.*, u.full_name, u.department, u.avatar_url 
      FROM attendance_logs a
      JOIN users u ON a.user_id = u.id
      WHERE a.date = CURRENT_DATE
      ORDER BY a.check_in_time ASC
    `);
    const todayRecords = todayQuery.rows;

    // C. Hitung Leaderboard Bulan Ini
    const leaderboardQuery = await pool.query(`
      SELECT u.full_name, u.id as employee_id, COUNT(a.id) as on_time_count
      FROM attendance_logs a
      JOIN users u ON a.user_id = u.id
      WHERE a.status = 'tepat_waktu' 
      AND EXTRACT(MONTH FROM a.date) = EXTRACT(MONTH FROM CURRENT_DATE)
      GROUP BY u.id, u.full_name
      ORDER BY on_time_count DESC
      LIMIT 10
    `);

    // D. Hitung Rata-rata Waktu Masuk Hari Ini
    let avgTime = "00:00";
    if (todayRecords.length > 0) {
      let totalMinutes = 0;
      todayRecords.forEach(rec => {
        const [hh, mm] = rec.check_in_time.split(':').map(Number);
        totalMinutes += (hh * 60) + mm;
      });
      const avgMinutes = Math.floor(totalMinutes / todayRecords.length);
      const avgH = Math.floor(avgMinutes / 60).toString().padStart(2, '0');
      const avgM = (avgMinutes % 60).toString().padStart(2, '0');
      avgTime = `${avgH}:${avgM}`;
    }

    res.json({
      totalEmployees,
      todayRecords,
      leaderboard: leaderboardQuery.rows,
      avgCheckInTime: avgTime
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 7. POST: Login User
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;

  // Query cari user berdasarkan username
  const sql = "SELECT * FROM users WHERE username = $1";
  
  pool.query(sql, [username], (err, result) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (result.rows.length === 0) {
      return res.status(401).json({ message: "Username tidak ditemukan" });
    }

    const user = result.rows[0];

    // Cek Password (Sederhana dulu, tanpa hash/enkripsi untuk belajar)
    // Pastikan data di DB passwordnya sesuai input (misal 'default123')
    if (user.password !== password) {
      return res.status(401).json({ message: "Password salah" });
    }

    // Login Sukses
    res.json({
      message: "Login berhasil",
      user: {
        id: user.id,
        employee_id: user.employee_id,
        name: user.full_name,
        role: user.role, // 'admin' atau 'employee'
        avatar: user.avatar_url
      }
    });
  });
});

// Untuk Uploads Gambar Pegawai
// 2. Agar folder uploads bisa diakses publik (untuk menampilkan gambar di App/Web)
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// 3. Konfigurasi Penyimpanan Gambar
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads';
    if (!fs.existsSync(dir)){
        fs.mkdirSync(dir);
    }
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    // Nama file: attendance-TIMESTAMP-RANDOM.jpg
    cb(null, `attendance-${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`);
  }
});

const upload = multer({ storage: storage });

// 4. POST: ABSEN BARU (FOTO + LOKASI)
// ---------------------------------------------------------
app.post('/api/attendance', upload.single('photo'), (req, res) => {
  const { user_id, status, location } = req.body;
  const photoUrl = req.file ? `http://192.168.12.86:5000/uploads/${req.file.filename}` : null; 
  // Catatan: 10.0.2.2 adalah localhost untuk Emulator Android. 
  // Jika pakai HP fisik/Web, ganti dengan IP Laptop Anda (misal 192.168.1.x)

  // Tentukan waktu sekarang
  const now = new Date();
  const checkInTime = now.toTimeString().split(' ')[0]; // HH:MM:SS
  const date = now.toISOString().split('T')[0]; // YYYY-MM-DD

  const sql = `
    INSERT INTO attendance_logs (user_id, date, check_in_time, status, photo_url, location) 
    VALUES ($1, $2, $3, $4, $5, $6) 
    RETURNING *
  `;

  const values = [user_id, date, checkInTime, status, photoUrl, location];

  pool.query(sql, values, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json({ message: "Absen berhasil!", data: result.rows[0] });
  });
});

// ... (Endpoint Dashboard & Riwayat tetap ada) ...

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});