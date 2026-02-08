import React, { useState } from 'react';
import { Home, History, Users, LogOut, Menu, X } from 'lucide-react'; // Tambah icon Menu & X

export default function DashboardLayout({ children, currentPage, onNavigate, user, onLogout }) {
  // 1. State untuk mengatur buka/tutup sidebar di Mobile
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const navItems = [
    { id: 'beranda', label: 'Beranda', icon: Home },
    { id: 'riwayat', label: 'Riwayat', icon: History },
    { id: 'data-pegawai', label: 'Data Pegawai', icon: Users },
  ];

  return (
    <div className="flex h-screen bg-gray-50">
      
      {/* --- MOBILE HEADER (Hanya muncul di HP) --- */}
      <div className="md:hidden fixed top-0 left-0 right-0 h-16 bg-white border-b border-gray-200 z-30 flex items-center justify-between px-4">
        <div className="flex items-center gap-2">
          {/* Tombol Hamburger */}
          <button onClick={() => setIsSidebarOpen(true)} className="p-2 text-gray-600">
            <Menu className="w-6 h-6" />
          </button>
          <span className="font-semibold text-gray-900">Monitoring Absen</span>
        </div>
        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xs">
           {user?.username ? user.username.charAt(0).toUpperCase() : 'U'}
        </div>
      </div>

      {/* --- SIDEBAR --- */}
      {/* Logic CSS:
         1. 'fixed inset-y-0 left-0 z-40': Posisi fix di kiri atas-bawah (untuk mobile)
         2. 'transform transition-transform duration-300': Animasi geser halus
         3. '-translate-x-full': Default ngumpet ke kiri (di mobile)
         4. 'md:translate-x-0': Di layar Medium (Laptop), paksa muncul (jangan ngumpet)
         5. 'md:static': Di laptop, posisinya statis (bukan floating/fixed), jadi mendorong konten utama
         6. Class dinamis: Jika isSidebarOpen=true, hapus translate-x-full agar muncul
      */}
      <aside className={`
        fixed inset-y-0 left-0 z-40 w-64 bg-white border-r border-gray-200 flex flex-col
        transform transition-transform duration-300 ease-in-out
        md:translate-x-0 md:static md:h-screen
        ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        
        {/* Header Sidebar */}]
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
             {/* Ganti dengan logoImage jika sudah ada */}
            <img src="/logo.png" alt="Logo" className="w-16 h-20 object-contain" />
            <div>
              <h1 className="font-semibold text-gray-900">Agen Perubahan</h1>
              <p className="text-xs text-gray-500">Dashboard</p>
            </div>
          </div>
          {/* Tombol Close (Mobile) */}
          <button onClick={() => setIsSidebarOpen(false)} className="md:hidden text-gray-500">
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 p-4 overflow-y-auto">
          <ul className="space-y-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = currentPage === item.id;
              return (
                <li key={item.id}>
                  <button
                    onClick={() => {
                      onNavigate(item.id);
                      setIsSidebarOpen(false); // Tutup sidebar otomatis saat menu diklik (di HP)
                    }}
                    className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${
                      isActive
                        ? 'bg-blue-50 text-blue-600'
                        : 'text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{item.label}</span>
                  </button>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* User Profile (Sidebar Footer) */}
        <div className="p-4 border-t border-gray-200">
          <div className="flex items-center gap-3 px-3 py-2 bg-gray-50 rounded-lg border border-gray-100">
            <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-bold shrink-0">
              {user?.username ? user.username.charAt(0).toUpperCase() : 'U'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900 truncate">{user?.username || 'User'}</p>
              <p className="text-xs text-gray-500 truncate">{user?.role || 'Guest'}</p>
            </div>
            <button onClick={onLogout} className="p-2 text-gray-400 hover:text-red-600 transition-colors">
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </aside>

      {/* --- OVERLAY (Background Gelap saat Sidebar Buka di HP) --- */}
      {isSidebarOpen && (
        <div 
          onClick={() => setIsSidebarOpen(false)}
          className="fixed inset-0 bg-black/50 z-30 md:hidden"
        />
      )}

      {/* --- MAIN CONTENT --- */}
      <main className="flex-1 overflow-auto bg-gray-50 w-full pt-16 md:pt-0">
        {children}
      </main>
    </div>
  );
}