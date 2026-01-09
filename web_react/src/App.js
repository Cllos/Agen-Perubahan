import React, { useState } from 'react';
import DashboardLayout from './layouts/DashboardLayout';
import Beranda from './pages/Beranda';
import Riwayat from './pages/Riwayat';
import DataPegawai from './pages/DataPegawai'; // <--- 1. Pastikan baris ini TIDAK dikomentari

export default function App() {
  const [currentPage, setCurrentPage] = useState('beranda');

  const user = {
    username: 'Admin HR',
    role: 'Administrator',
  };

  const renderContent = () => {
    switch (currentPage) {
      case 'beranda':
        return <Beranda />;
      case 'riwayat':
        return <Riwayat />;
      case 'data-pegawai':
        return <DataPegawai />; // <--- 2. Panggil komponennya di sini (Hapus div placeholder tadi
      default:
        return <Beranda />;
    }
  };

  return (
    <DashboardLayout
      currentPage={currentPage}
      onNavigate={setCurrentPage}
      user={user}
      onLogout={() => alert('Logout clicked!')}
    >
      {renderContent()}
    </DashboardLayout>
  );
}