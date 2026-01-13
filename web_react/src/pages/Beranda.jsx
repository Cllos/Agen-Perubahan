import React, { useEffect, useState } from 'react';
import { Users, Clock, UserCheck, Award, Medal } from 'lucide-react';

export default function BerandaPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  // Auto-Refresh Dashboard setiap 5 detik
  useEffect(() => {
    const fetchData = async () => {
      try {
        const response = await fetch('http://localhost:5000/api/dashboard');
        const result = await response.json();
        setData(result);
        setLoading(false);
      } catch (error) {
        console.error("Error fetching dashboard:", error);
        setLoading(false);
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 5000);
    return () => clearInterval(interval);
  }, []);

  if (loading) return <div className="p-8 text-center text-gray-500">Memuat Dashboard...</div>;
  if (!data) return <div className="p-8 text-center text-red-500">Data tidak tersedia</div>;

  return (
    <div className="p-6 md:p-8 space-y-6 bg-gray-50 min-h-screen">
      
      {/* --- HEADER TITLE --- */}
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Dashboard Monitoring</h1>
        <p className="text-gray-500">Pantau kehadiran dan performa pegawai secara realtime.</p>
      </div>

      {/* --- STATS CARDS (Top Section) --- */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        {/* Card 1: Total Pegawai */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-500">Total Pegawai</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">{data.totalEmployees}</p>
          </div>
          <div className="p-3 bg-blue-100 rounded-full">
            <Users className="w-8 h-8 text-blue-600" />
          </div>
        </div>

        {/* Card 2: Hadir Hari Ini */}
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-200 flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-gray-500">Hadir Hari Ini</p>
            <p className="text-3xl font-bold text-gray-900 mt-2">{data.presentToday} <span className="text-sm text-gray-400 font-normal">orang</span></p>
          </div>
          <div className="p-3 bg-green-100 rounded-full">
            <UserCheck className="w-8 h-8 text-green-600" />
          </div>
        </div>
      </div>

      {/* --- MAIN CONTENT GRID (2 Kolom Scrollable) --- */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        
        {/* === KOLOM KIRI: DAFTAR HADIR HARI INI === */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 flex flex-col h-[500px]">
          <div className="p-5 border-b border-gray-100 bg-gray-50 rounded-t-xl flex justify-between items-center">
            <h2 className="font-bold text-lg text-gray-800 flex items-center gap-2">
              <Clock className="w-5 h-5 text-blue-600" />
              Kehadiran Hari Ini
            </h2>
            <span className="text-xs font-medium px-2 py-1 bg-blue-100 text-blue-700 rounded-full">
              Realtime
            </span>
          </div>
          
          {/* Scrollable Area */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
            {data.todayRecords.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-gray-400">
                <Clock className="w-12 h-12 mb-2 opacity-20" />
                <p>Belum ada yang absen hari ini</p>
              </div>
            ) : (
              data.todayRecords.map((record, index) => {
                // Logic Badge: Jika status 'tercepat' (atau index < 5 utk safety), pakai style Emas
                const isFastest = record.status === 'tercepat'; 
                
                return (
                  <div key={record.id} className={`flex items-center justify-between p-4 rounded-lg border ${isFastest ? 'bg-yellow-50 border-yellow-200' : 'bg-white border-gray-100 hover:bg-gray-50'} transition-all`}>
                    <div className="flex items-center gap-4">
                      {/* Ranking Number */}
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm ${isFastest ? 'bg-yellow-400 text-white shadow-sm' : 'bg-gray-200 text-gray-600'}`}>
                        {index + 1}
                      </div>
                      
                      <img 
                        src={record.avatar_url || 'https://cdn-icons-png.flaticon.com/512/149/149071.png'} 
                        alt="Avatar" 
                        className="w-10 h-10 rounded-full object-cover border border-gray-200"
                      />
                      
                      <div>
                        <p className="font-semibold text-gray-900">{record.full_name}</p>
                        <p className="text-xs text-gray-500">{record.employee_id}</p>
                      </div>
                    </div>

                    <div className="text-right">
                      <p className="text-sm font-bold font-mono text-gray-800">{record.check_in_time.substring(0, 5)}</p>
                      {isFastest ? (
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-yellow-100 text-yellow-700 mt-1">
                          TERCEPAT
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-medium bg-blue-50 text-blue-600 mt-1">
                          HADIR
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* === KOLOM KANAN: LEADERBOARD BULANAN === */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 flex flex-col h-[500px]">
          <div className="p-5 border-b border-gray-100 bg-gray-50 rounded-t-xl">
            <h2 className="font-bold text-lg text-gray-800 flex items-center gap-2">
              <Award className="w-5 h-5 text-orange-500" />
              Leaderboard Kecepatan (Bulan Ini)
            </h2>
            <p className="text-xs text-gray-500 mt-1">Total pencapaian status "Tercepat"</p>
          </div>

          {/* Scrollable Area */}
          <div className="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
            {data.monthlyLeaderboard.length === 0 ? (
              <div className="text-center py-10 text-gray-400">Belum ada data bulan ini</div>
            ) : (
              data.monthlyLeaderboard.map((user, index) => {
                // Style Juara 1, 2, 3
                let rankColor = "bg-gray-100 text-gray-600";
                if (index === 0) rankColor = "bg-gradient-to-br from-yellow-400 to-orange-400 text-white shadow-md ring-2 ring-yellow-100";
                if (index === 1) rankColor = "bg-gray-300 text-gray-800";
                if (index === 2) rankColor = "bg-orange-200 text-orange-800";

                return (
                  <div key={index} className="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg transition-colors border-b border-gray-50 last:border-0">
                    <div className="flex items-center gap-4">
                      {/* Rank Badge */}
                      <div className={`w-8 h-8 flex-shrink-0 rounded-full flex items-center justify-center font-bold text-sm ${rankColor}`}>
                        {index + 1}
                      </div>

                      <img 
                        src={user.avatar_url || 'https://cdn-icons-png.flaticon.com/512/149/149071.png'} 
                        alt="Avatar" 
                        className="w-10 h-10 rounded-full object-cover border border-gray-100"
                      />

                      <div>
                        <p className="font-semibold text-gray-800 text-sm">{user.full_name}</p>
                        <p className="text-xs text-gray-400">{user.employee_id}</p>
                      </div>
                    </div>

                    {/* Score Point */}
                    <div className="flex items-center gap-1 bg-orange-50 px-3 py-1.5 rounded-full border border-orange-100">
                      <Medal className="w-3 h-3 text-orange-500" />
                      <span className="font-bold text-sm text-orange-700">{user.score}x</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

      </div>
    </div>
  );
}