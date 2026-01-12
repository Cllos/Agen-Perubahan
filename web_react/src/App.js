import React, { useState, useEffect } from 'react';
import DashboardLayout from './layouts/DashboardLayout';
import Beranda from './pages/Beranda';
import Riwayat from './pages/Riwayat';
import DataPegawai from './pages/DataPegawai';
import Login from './pages/Login'; // Import halaman Login

export default function App() {
  const [user, setUser] = useState(null); // State user (null = belum login)
  const [currentPage, setCurrentPage] = useState('beranda');

  // Cek apakah ada user tersimpan di localStorage saat aplikasi dibuka
  useEffect(() => {
    const savedUser = localStorage.getItem('user');
    if (savedUser) {
      setUser(JSON.parse(savedUser));
    }
  }, []);

  const handleLogin = (userData) => {
    setUser(userData);
    localStorage.setItem('user', JSON.stringify(userData)); // Simpan sesi
  };

  const handleLogout = () => {
    setUser(null);
    localStorage.removeItem('user'); // Hapus sesi
    setCurrentPage('beranda');
  };

  // Jika belum login, tampilkan halaman Login
  if (!user) {
    return <Login onLogin={handleLogin} />;
  }

  // Jika sudah login, tampilkan Dashboard
  const renderContent = () => {
    switch (currentPage) {
      case 'beranda':
        return <Beranda user={user} />; // Kirim data user ke Beranda (opsional)
      case 'riwayat':
        return <Riwayat />;
      case 'data-pegawai':
        // Proteksi: Hanya admin yang boleh lihat Data Pegawai
        if (user.role !== 'admin') {
            return <div className="p-8 text-center text-red-500">Anda tidak memiliki akses ke halaman ini.</div>;
        }
        return <DataPegawai />;
      default:
        return <Beranda />;
    }
  };

  return (
    <DashboardLayout
      currentPage={currentPage}
      onNavigate={setCurrentPage}
      user={user} // Kirim data user asli dari database
      onLogout={handleLogout}
    >
      {renderContent()}
    </DashboardLayout>
  );
}