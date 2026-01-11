const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const pool = require('./connect'); // File koneksi Anda

const app = express();
const PORT = 5000;

app.use(cors());
app.use(bodyParser.json());

// --- ROUTES ---

// 1. GET: Ambil Data Pegawai (Hanya role employee)
app.get('/api/pegawai', (req, res) => {
  // Kita ambil dari tabel 'users', bukan 'pegawai'
  const sql = "SELECT * FROM users WHERE role = 'employee' ORDER BY created_at DESC";
  
  pool.query(sql, (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: err.message });
    }
    // Kirim data ke frontend
    res.json(result.rows); 
  });
});

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

// ... kode sebelumnya ...

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

