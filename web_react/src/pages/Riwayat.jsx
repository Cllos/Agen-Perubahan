import React, { useState, useMemo, useEffect } from 'react';
import { Filter, ChevronLeft, ChevronRight, Search, Camera, X, Image as ImageIcon } from 'lucide-react'; 
import { format } from 'date-fns';
import { id as localeId } from 'date-fns/locale';

export default function Riwayat() {
  // 1. State Data
  const [historyAttendance, setHistoryAttendance] = useState([]);
  const [loading, setLoading] = useState(true);

  // State untuk Modal Foto
  const [selectedImage, setSelectedImage] = useState(null);

  // State Filter
  const [selectedYear, setSelectedYear] = useState('2026');
  const [selectedMonth, setSelectedMonth] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Konfigurasi Filter
  const availableYears = ['2025', '2026'];
  const months = [
    { value: 'all', label: 'Semua Bulan' },
    { value: '0', label: 'Januari' }, { value: '1', label: 'Februari' },
    { value: '2', label: 'Maret' }, { value: '3', label: 'April' },
    { value: '4', label: 'Mei' }, { value: '5', label: 'Juni' },
    { value: '6', label: 'Juli' }, { value: '7', label: 'Agustus' },
    { value: '8', label: 'September' }, { value: '9', label: 'Oktober' },
    { value: '10', label: 'November' }, { value: '11', label: 'Desember' },
  ];

  // 2. FETCH DATA DARI SERVER (Auto Refresh)
  useEffect(() => {
    const fetchHistory = async () => {
      try {
        const response = await fetch('http://localhost:5000/api/riwayat');
        const data = await response.json();

        const formattedData = data.map(record => ({
          id: record.id,
          date: record.date,
          employeeId: record.employee_id,
          employeeName: record.full_name,
          checkInTime: record.check_in_time ? record.check_in_time.substring(0, 5) : '-',
          // Mapping Status
          status: record.status === 'tepat_waktu' ? 'Tepat Waktu' : 
                  record.status === 'terlambat' ? 'Terlambat' : record.status,
          // Mapping URL Foto (PENTING)
          evidenceUrl: record.photo_url 
        }));

        setHistoryAttendance(formattedData);
        setLoading(false);
      } catch (error) {
        console.error("Gagal mengambil riwayat:", error);
        setLoading(false);
      }
    };

    fetchHistory();
    // Auto refresh setiap 5 detik agar admin melihat data baru tanpa reload
    const interval = setInterval(fetchHistory, 5000); 
    return () => clearInterval(interval);
  }, []);

  // Logic Filtering
  const filteredRecords = useMemo(() => {
    let filtered = [...historyAttendance];

    if (selectedYear !== 'all') {
      filtered = filtered.filter(record => 
        new Date(record.date).getFullYear().toString() === selectedYear
      );
    }
    if (selectedMonth !== 'all') {
      filtered = filtered.filter(record => 
        new Date(record.date).getMonth().toString() === selectedMonth
      );
    }
    if (selectedStatus !== 'all') {
      filtered = filtered.filter(record => record.status === selectedStatus);
    }
    if (searchQuery) {
      filtered = filtered.filter(record => 
        record.employeeName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        record.employeeId.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    return filtered;
  }, [historyAttendance, selectedYear, selectedMonth, selectedStatus, searchQuery]);

  // Logic Pagination
  const [currentPage, setCurrentPage] = useState(1);
  const recordsPerPage = 10;
  const totalPages = Math.ceil(filteredRecords.length / recordsPerPage);
  const startIndex = (currentPage - 1) * recordsPerPage;
  const currentRecords = filteredRecords.slice(startIndex, startIndex + recordsPerPage);

  const getStatusColor = (status) => {
    return status === 'Tepat Waktu' 
      ? 'bg-green-100 text-green-700 border-green-200' 
      : 'bg-red-100 text-red-700 border-red-200';
  };

  return (
    <div className="p-4 md:p-8 space-y-6 bg-gray-50 min-h-screen relative">
      
      {/* --- MODAL POPUP FOTO --- */}
      {selectedImage && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm" onClick={() => setSelectedImage(null)}>
          <div className="relative bg-white rounded-xl shadow-2xl max-w-2xl w-full overflow-hidden animate-in fade-in zoom-in duration-200" onClick={e => e.stopPropagation()}>
            <div className="flex justify-between items-center p-4 border-b bg-gray-50">
              <h3 className="font-semibold text-lg text-gray-800 flex items-center gap-2">
                <ImageIcon className="w-5 h-5 text-blue-600"/> Bukti Kehadiran
              </h3>
              <button onClick={() => setSelectedImage(null)} className="p-1 hover:bg-gray-200 rounded-full transition-colors">
                <X className="w-6 h-6 text-gray-500" />
              </button>
            </div>
            <div className="p-6 bg-gray-100 flex justify-center items-center min-h-[300px]">
              <img 
                src={selectedImage} 
                alt="Bukti Absen" 
                className="max-h-[60vh] w-auto object-contain rounded-lg shadow-md border border-gray-200"
                onError={(e) => {
                  e.target.onerror = null; 
                  e.target.src = "https://via.placeholder.com/400x300?text=Gagal+Memuat+Gambar";
                }}
              />
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Riwayat Kehadiran</h1>
        <p className="text-gray-500 mt-1">Lihat dan analisis data kehadiran pegawai</p>
      </div>

      {/* Filter Section */}
      <div className="bg-white rounded-lg shadow border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold flex items-center gap-2">
            <Filter className="w-5 h-5 text-blue-600" /> Filter Data
          </h2>
        </div>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            {/* Year */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">Tahun</label>
              <select value={selectedYear} onChange={(e) => setSelectedYear(e.target.value)} className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none">
                {availableYears.map(year => <option key={year} value={year}>{year}</option>)}
              </select>
            </div>
            {/* Month */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">Bulan</label>
              <select value={selectedMonth} onChange={(e) => setSelectedMonth(e.target.value)} className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none">
                {months.map(m => <option key={m.value} value={m.value}>{m.label}</option>)}
              </select>
            </div>
            {/* Status */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">Status</label>
              <select value={selectedStatus} onChange={(e) => setSelectedStatus(e.target.value)} className="w-full rounded-md border border-gray-300 py-2 px-3 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none">
                <option value="all">Semua Status</option>
                <option value="Tepat Waktu">Tepat Waktu</option>
                <option value="Terlambat">Terlambat</option>
              </select>
            </div>
            {/* Search */}
            <div>
              <label className="text-sm font-medium text-gray-700 mb-1 block">Cari Pegawai</label>
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input type="text" placeholder="Nama atau ID..." value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} className="w-full rounded-md border border-gray-300 py-2 pl-10 pr-3 text-sm focus:ring-2 focus:ring-blue-500 focus:outline-none" />
              </div>
            </div>
          </div>
          
          <div className="mt-6 flex items-center justify-between">
            <p className="text-sm text-gray-600">Menampilkan <span className="font-semibold text-gray-900">{filteredRecords.length}</span> data</p>
            <button onClick={() => { setSelectedYear('2026'); setSelectedMonth('all'); setSelectedStatus('all'); setSearchQuery(''); }} className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors">
              Reset Filter
            </button>
          </div>
        </div>
      </div>

      {/* Table Section */}
      <div className="bg-white rounded-lg shadow border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead className="bg-gray-50 text-gray-700 font-medium border-b border-gray-200">
              <tr>
                <th className="px-6 py-4">Tanggal</th>
                <th className="px-6 py-4">ID Pegawai</th>
                <th className="px-6 py-4">Nama</th>
                <th className="px-6 py-4">Waktu Masuk</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4 text-center">Bukti</th> {/* Kolom Baru */}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {loading ? (
                <tr><td colSpan={6} className="px-6 py-8 text-center text-gray-500">Sedang memuat data...</td></tr>
              ) : currentRecords.length === 0 ? (
                <tr><td colSpan={6} className="px-6 py-8 text-center text-gray-500">Tidak ada data yang ditemukan</td></tr>
              ) : (
                currentRecords.map((record) => (
                  <tr key={record.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 whitespace-nowrap text-gray-900">
                      {format(new Date(record.date), 'dd MMMM yyyy', { locale: localeId })}
                    </td>
                    <td className="px-6 py-4 font-medium text-gray-900">{record.employeeId}</td>
                    <td className="px-6 py-4 text-gray-700">{record.employeeName}</td>
                    <td className="px-6 py-4 font-mono text-gray-600">{record.checkInTime}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium border ${getStatusColor(record.status)}`}>
                        {record.status}
                      </span>
                    </td>
                    {/* Tombol Bukti Foto */}
                    <td className="px-6 py-4 text-center">
                      {record.evidenceUrl ? (
                        <button 
                          onClick={() => setSelectedImage(record.evidenceUrl)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-blue-700 bg-blue-50 border border-blue-200 rounded-md hover:bg-blue-100 transition-colors"
                          title="Lihat Foto Bukti"
                        >
                          <Camera className="w-3.5 h-3.5" />
                          Lihat
                        </button>
                      ) : (
                        <span className="text-gray-400 text-xs">-</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-6 py-4 border-t border-gray-200 bg-gray-50">
            <p className="text-sm text-gray-600">Halaman <span className="font-medium">{currentPage}</span> dari <span className="font-medium">{totalPages}</span></p>
            <div className="flex gap-2">
              <button onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))} disabled={currentPage === 1} className="flex items-center gap-1 px-3 py-1.5 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed">
                <ChevronLeft className="w-4 h-4" /> Sebelumnya
              </button>
              <button onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))} disabled={currentPage === totalPages} className="flex items-center gap-1 px-3 py-1.5 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed">
                Selanjutnya <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}