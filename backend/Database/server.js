const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./connect');
const multer = require('multer'); 
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
// Folder statis untuk akses foto dari HP/Web
const uploadsDir = path.join(__dirname, '..', 'uploads');
app.use('/uploads', express.static(uploadsDir));

// --- KONFIGURASI UPLOAD FOTO (MULTER) ---
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }
    cb(null, uploadsDir);
  },
  filename: (req, file, cb) => {
    // Nama file unik: attendance-TIMESTAMP-RANDOM.jpg
    cb(null, `attendance-${Date.now()}-${Math.round(Math.random() * 1E9)}${path.extname(file.originalname)}`);
  }
});

const upload = multer({ storage: storage });

// ==========================================
// ROUTES API
// ==========================================

// 1. LOGIN (Hanya Admin & Security)
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

    // Blokir Employee (Karyawan biasa tidak bisa login)
    if (user.role === 'employee') {
      return res.status(403).json({ message: "Karyawan tidak memiliki akses login." });
    }

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

// 2. GET LIST PEGAWAI (Dropdown HP & List Web)
app.get('/api/pegawai', (req, res) => {
  // Hanya ambil yang role='employee'
  const sql = "SELECT * FROM users WHERE role = 'employee' ORDER BY employee_id ASC";
  
  pool.query(sql, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    res.json(result.rows); 
  });
});

// 3. TAMBAH PEGAWAI BARU (Auto ID + Tanpa Username/Password)
app.post('/api/pegawai', async (req, res) => {
  const { full_name, position } = req.body; 

  try {
    // A. Logic Auto-Generate ID (Cari EMP terakhir)
    const idCheckSql = "SELECT employee_id FROM users WHERE employee_id LIKE 'EMP%' ORDER BY employee_id DESC LIMIT 1";
    const idResult = await pool.query(idCheckSql);

    let newId = 'EMP001'; 
    if (idResult.rows.length > 0) {
      const lastId = idResult.rows[0].employee_id; // Misal: EMP003
      const numberPart = parseInt(lastId.substring(3)); // Ambil angka 3
      newId = 'EMP' + (numberPart + 1).toString().padStart(3, '0'); // Jadi EMP004
    }

    // B. Masukkan ke Database (Role otomatis 'employee')
    const insertSql = `
      INSERT INTO users (employee_id, full_name, position, role)
      VALUES ($1, $2, $3, 'employee')
      RETURNING *
    `;
    
    const newUser = await pool.query(insertSql, [newId, full_name, position]);

    res.json({ 
      message: "Pegawai berhasil ditambahkan", 
      data: newUser.rows[0] 
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 4. EDIT PEGAWAI
app.put('/api/pegawai/:id', async (req, res) => {
  const { id } = req.params;
  const { full_name, position } = req.body;

  try {
    const sql = "UPDATE users SET full_name = $1, position = $2 WHERE id = $3 RETURNING *";
    const update = await pool.query(sql, [full_name, position, id]);

    if (update.rows.length === 0) {
      return res.status(404).json({ message: "Pegawai tidak ditemukan" });
    }

    res.json({ message: "Data pegawai diperbarui", data: update.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 5. HAPUS PEGAWAI
app.delete('/api/pegawai/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const sql = "DELETE FROM users WHERE id = $1 RETURNING *";
    const deleted = await pool.query(sql, [id]);

    if (deleted.rows.length === 0) {
      return res.status(404).json({ message: "Pegawai tidak ditemukan" });
    }

    res.json({ message: "Pegawai berhasil dihapus" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 6. ABSENSI (LOGIKA 5 TERCEPAT)
app.post('/api/attendance', upload.single('photo'), async (req, res) => {
  const { user_id, location } = req.body;
  const photoUrl = req.file ? `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}` : null;

  const now = new Date();
  const checkInTime = now.toTimeString().split(' ')[0]; // Format HH:MM:SS
  const date = now.toISOString().split('T')[0]; // Format YYYY-MM-DD

  try {
    const existingSql = "SELECT 1 FROM attendance_logs WHERE user_id = $1 AND date = $2 LIMIT 1";
    const existingRes = await pool.query(existingSql, [user_id, date]);
    if (existingRes.rows.length > 0) {
      return res.status(409).json({ message: "Pegawai sudah absen hari ini" });
    }

    // A. Cek jumlah absen hari ini untuk menentukan status
    const countSql = "SELECT COUNT(*) FROM attendance_logs WHERE date = $1";
    const countRes = await pool.query(countSql, [date]);
    const currentCount = parseInt(countRes.rows[0].count);

    // B. Tentukan Status
    // Jika jumlah < 5, berarti user ini adalah orang ke-1 sampai ke-5 -> 'tercepat'
    // Jika sudah ada 5 orang atau lebih, maka user ini -> 'hadir'
    const status = currentCount < 5 ? 'tercepat' : 'hadir';

    // C. Simpan ke Database
    const sql = `
      WITH inserted AS (
        INSERT INTO attendance_logs (user_id, date, check_in_time, status, photo_url, location) 
        VALUES ($1, $2, $3, $4, $5, $6) 
        RETURNING *
      )
      SELECT inserted.*, u.full_name, u.employee_id, u.avatar_url
      FROM inserted
      JOIN users u ON inserted.user_id = u.id
    `;
    const result = await pool.query(sql, [user_id, date, checkInTime, status, photoUrl, location]);

    res.json({ message: "Absen berhasil!", data: result.rows[0], assignedStatus: status });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 7. ABSENSI HARI INI (UNTUK MOBILE)
app.get('/api/attendance/today', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const sql = `
      SELECT a.*, u.full_name, u.employee_id, u.avatar_url 
      FROM attendance_logs a
      JOIN users u ON a.user_id = u.id
      WHERE a.date = $1
      ORDER BY a.check_in_time DESC
    `;
    const result = await pool.query(sql, [today]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 8. DASHBOARD DATA (UNTUK SCROLLABLE BOX)
app.get('/api/dashboard', async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];

    // A. Total Pegawai
    const countRes = await pool.query("SELECT COUNT(*) FROM users WHERE role = 'employee'");
    
    // B. List Hadir Hari Ini (Untuk Scrollable Kiri)
    // Diurutkan berdasarkan jam masuk agar yang tercepat ada di atas
    const todayRes = await pool.query(`
      SELECT a.*, u.full_name, u.employee_id, u.avatar_url 
      FROM attendance_logs a
      JOIN users u ON a.user_id = u.id
      WHERE a.date = $1
      ORDER BY a.check_in_time ASC
    `, [today]);

    // C. Leaderboard Bulanan (Untuk Scrollable Kanan)
    // Menghitung berapa kali user mendapat status 'tercepat' bulan ini
    // Menggunakan LEFT JOIN agar user yang skornya 0 tetap muncul di list
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
      todayRecords: todayRes.rows,       // Array untuk kotak Kiri
      monthlyLeaderboard: leaderboardRes.rows // Array untuk kotak Kanan
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});

// 9. RIWAYAT LENGKAP
app.get('/api/riwayat', (req, res) => {
  const sql = `
    SELECT 
      a.id, 
      a.date, 
      a.check_in_time, 
      a.status, 
      a.photo_url, 
      a.location, 
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

// Jalankan Server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
