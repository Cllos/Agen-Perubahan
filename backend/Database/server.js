const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./connect');
const multer = require('multer'); 
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// --- Multer Config ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = 'uploads';
    if (!fs.existsSync(dir)) fs.mkdirSync(dir);
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    cb(null, `att-${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`);
  }
});
const upload = multer({ storage: storage });

// ================= ROUTES =================

// 1. LOGIN
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const sql = "SELECT * FROM users WHERE username = $1";
  pool.query(sql, [username], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    if (result.rows.length === 0) return res.status(401).json({ message: "User tidak ditemukan" });
    const user = result.rows[0];
    if (user.password !== password) return res.status(401).json({ message: "Password salah" });
    if (user.role === 'employee') return res.status(403).json({ message: "Akses ditolak" });
    res.json({ message: "Login berhasil", user: { id: user.id, name: user.full_name, role: user.role, avatar: user.avatar_url } });
  });
});

// 2. GET PEGAWAI
app.get('/api/pegawai', (req, res) => {
  const sql = "SELECT * FROM users WHERE role = 'employee' ORDER BY employee_id ASC";
  pool.query(sql, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result.rows); 
  });
});

// 3. TAMBAH PEGAWAI
app.post('/api/pegawai', async (req, res) => {
  const { full_name, position } = req.body; 
  try {
    const idCheckSql = "SELECT employee_id FROM users WHERE employee_id LIKE 'EMP%' ORDER BY employee_id DESC LIMIT 1";
    const idResult = await pool.query(idCheckSql);
    let newId = 'EMP001'; 
    if (idResult.rows.length > 0) {
      const numberPart = parseInt(idResult.rows[0].employee_id.substring(3));
      newId = 'EMP' + (numberPart + 1).toString().padStart(3, '0');
    }
    const insertSql = "INSERT INTO users (employee_id, full_name, position, role) VALUES ($1, $2, $3, 'employee') RETURNING *";
    const newUser = await pool.query(insertSql, [newId, full_name, position]);
    res.json({ message: "Sukses", data: newUser.rows[0] });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// 4. ABSENSI (LOGIKA BARU: 5 TERCEPAT)
app.post('/api/attendance', upload.single('photo'), async (req, res) => {
  const { user_id, location } = req.body;
  const ipAddress = '192.168.1.5'; // GANTI IP LAPTOP ANDA
  const photoUrl = req.file ? `http://${ipAddress}:5000/uploads/${req.file.filename}` : null; 

  const now = new Date();
  const checkInTime = now.toTimeString().split(' ')[0];
  const date = now.toISOString().split('T')[0];

  try {
    // A. Cek Absensi Hari Ini untuk menentukan Status
    // Hitung berapa orang yang sudah absen hari ini
    const countSql = "SELECT COUNT(*) FROM attendance_logs WHERE date = $1";
    const countRes = await pool.query(countSql, [date]);
    const currentCount = parseInt(countRes.rows[0].count);

    // B. Tentukan Status
    // Jika jumlah < 5, berarti dia termasuk 5 orang pertama -> 'tercepat'
    // Jika >= 5, berarti dia orang ke-6 dst -> 'hadir'
    const status = currentCount < 5 ? 'tercepat' : 'hadir';

    // C. Simpan ke DB
    const sql = `
      INSERT INTO attendance_logs (user_id, date, check_in_time, status, photo_url, location) 
      VALUES ($1, $2, $3, $4, $5, $6) 
      RETURNING *
    `;
    const result = await pool.query(sql, [user_id, date, checkInTime, status, photoUrl, location]);
    
    res.json({ message: "Absen berhasil!", data: result.rows[0], assignedStatus: status });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 5. DASHBOARD DATA (REVISI)
app.get('/api/dashboard', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    // A. Total Pegawai
    const countRes = await pool.query("SELECT COUNT(*) FROM users WHERE role = 'employee'");
    
    // B. List Semua Yang Hadir Hari Ini (Untuk kotak Kiri - Scrollable)
    // Diurutkan berdasarkan jam masuk. 
    const todayRes = await pool.query(`
      SELECT a.*, u.full_name, u.employee_id, u.avatar_url 
      FROM attendance_logs a
      JOIN users u ON a.user_id = u.id
      WHERE a.date = $1
      ORDER BY a.check_in_time ASC
    `, [today]);

    // C. Leaderboard Bulanan (Untuk kotak Kanan - Scrollable)
    // Menghitung berapa kali user mendapat status 'tercepat' bulan ini
    // Kita LEFT JOIN agar user yang skornya 0 tetap muncul (opsional, atau pakai INNER JOIN biar yang pernah cepat saja)
    // Disini saya pakai LEFT JOIN ke tabel users agar semua pegawai muncul di leaderboard meskipun skor 0
    const leaderboardRes = await pool.query(`
      SELECT u.full_name, u.employee_id, u.avatar_url,
             COALESCE(COUNT(a.id), 0) as score
      FROM users u
      LEFT JOIN attendance_logs a 
        ON u.id = a.user_id 
        AND a.status = 'tercepat' 
        AND TO_CHAR(a.date, 'YYYY-MM') = TO_CHAR(CURRENT_DATE, 'YYYY-MM')
      WHERE u.role = 'employee'
      GROUP BY u.id
      ORDER BY score DESC, u.full_name ASC
    `);

    res.json({
      totalEmployees: parseInt(countRes.rows[0].count),
      presentToday: todayRes.rows.length,
      todayRecords: todayRes.rows,       // Data untuk kotak kiri
      monthlyLeaderboard: leaderboardRes.rows // Data untuk kotak kanan
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// ... (Route Riwayat, Edit, Hapus biarkan sama seperti sebelumnya, tapi hapus logic department jika ada)
app.get('/api/riwayat', (req, res) => {
  const sql = `
    SELECT a.*, u.employee_id, u.full_name 
    FROM attendance_logs a
    JOIN users u ON a.user_id = u.id
    ORDER BY a.date DESC, a.check_in_time DESC
  `;
  pool.query(sql, (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(result.rows);
  });
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));