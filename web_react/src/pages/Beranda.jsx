import React, { useState, useEffect } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { Users, UserCheck, UserX, Clock, Trophy, TrendingUp } from 'lucide-react';

export default function BerandaPage() {
  // 1. State untuk menyimpan data dari API
  const [dashboardData, setDashboardData] = useState({
    totalEmployees: 0,
    presentToday: 0,
    absentToday: 0,
    top5Earliest: [],
    lateArrivals: [],
    monthlyLeaderboard: [],
    avgCheckInTime: "00:00"
  });
  const [loading, setLoading] = useState(true);

  // 2. Fetch Data dari Server
  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const response = await fetch('http://localhost:5000/api/dashboard');
        const data = await response.json();

        // Proses Data dari Backend
        const { totalEmployees, todayRecords, leaderboard, avgCheckInTime } = data;
        
        // Filter: Top 5 Tercepat
        // (Data dari backend sudah di-sort ASC time, jadi tinggal ambil 5 pertama)
        const top5 = todayRecords.slice(0, 5);

        // Filter: Terlambat
        const late = todayRecords.filter(rec => rec.status === 'terlambat');

        // Leaderboard Processing
        // Kita butuh hitung total kehadiran per orang untuk persentase (opsional, disini kita pakai dummy total hari kerja=20)
        const processedLeaderboard = leaderboard.map(l => ({
          name: l.full_name,
          employeeId: l.employee_id,
          onTimeCount: parseInt(l.on_time_count),
          totalCount: 20, // Anggap hari kerja sebulan 20 hari (bisa dibuat dinamis nanti)
          percentage: Math.round((parseInt(l.on_time_count) / 20) * 100)
        }));

        setDashboardData({
          totalEmployees: totalEmployees,
          presentToday: todayRecords.length,
          absentToday: totalEmployees - todayRecords.length,
          top5Earliest: top5,
          lateArrivals: late,
          monthlyLeaderboard: processedLeaderboard,
          avgCheckInTime: avgCheckInTime
        });

        setLoading(false);
      } catch (error) {
        console.error("Gagal mengambil data dashboard:", error);
        setLoading(false);
      }
    };

    fetchDashboardData();
  }, []);

  // 3. Persiapan Data Chart
  const avgTimeData = [
    { 
      name: 'Rata-rata', 
      time: dashboardData.avgCheckInTime, 
      value: parseInt(dashboardData.avgCheckInTime.split(':')[0]) * 60 + parseInt(dashboardData.avgCheckInTime.split(':')[1]) 
    },
    { 
      name: 'Target', 
      time: '08:00', 
      value: 480 
    },
  ];

  // Helper Card
  const Card = ({ children, className = "" }) => (
    <div className={`bg-white rounded-lg shadow-sm border border-gray-200 ${className}`}>
      {children}
    </div>
  );

  if (loading) {
    return <div className="p-8 text-center text-gray-500">Memuat Dashboard...</div>;
  }

  return (
    <div className="p-4 md:p-8 space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-semibold text-gray-900">Beranda</h1>
        <p className="text-gray-500 mt-1">Dashboard Monitoring Kehadiran Pegawai</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Total Pegawai</p>
              <p className="text-3xl font-semibold text-gray-900 mt-1">{dashboardData.totalEmployees}</p>
            </div>
            <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
              <Users className="w-6 h-6 text-blue-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Hadir Hari Ini</p>
              <p className="text-3xl font-semibold text-green-600 mt-1">{dashboardData.presentToday}</p>
            </div>
            <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center">
              <UserCheck className="w-6 h-6 text-green-600" />
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">Tidak Hadir / Cuti</p>
              <p className="text-3xl font-semibold text-red-600 mt-1">{dashboardData.absentToday}</p>
            </div>
            <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center">
              <UserX className="w-6 h-6 text-red-600" />
            </div>
          </div>
        </Card>
      </div>

      {/* Main Widgets Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Top 5 Earliest Arrivals */}
        <Card>
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <Clock className="w-5 h-5 text-blue-600" />
              5 Pegawai Tercepat Hari Ini
            </h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {dashboardData.top5Earliest.length === 0 ? (
                <p className="text-center text-gray-500 py-4">Belum ada yang absen hari ini.</p>
              ) : (
                dashboardData.top5Earliest.map((record, index) => (
                  <div key={record.id} className="flex items-center gap-4">
                    <div className="flex items-center justify-center w-8 h-8 bg-blue-100 text-blue-600 rounded-full font-semibold text-sm">
                      {index + 1}
                    </div>
                    {/* Avatar */}
                    <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-100">
                      <img 
                        src={record.avatar_url} 
                        alt={record.full_name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">{record.full_name}</p>
                      <p className="text-sm text-gray-500">{record.department}</p>
                    </div>
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-50 text-green-700 border border-green-200">
                      {record.check_in_time.substring(0, 5)}
                    </span>
                  </div>
                ))
              )}
            </div>
          </div>
        </Card>

        {/* Average Check-in Time Chart */}
        <Card>
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-blue-600" />
              Diagram Rata-rata Masuk
            </h3>
          </div>
          <div className="p-6">
            <div className="h-[280px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={avgTimeData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="name" />
                  <YAxis 
                    domain={[420, 540]} 
                    ticks={[420, 450, 480, 510, 540]}
                    tickFormatter={(value) => {
                      const hours = Math.floor(value / 60);
                      const minutes = value % 60;
                      return `${hours}:${minutes.toString().padStart(2, '0')}`;
                    }}
                  />
                  <Tooltip 
                    formatter={(value, name, props) => [props.payload.time, 'Waktu']}
                  />
                  <Bar dataKey="value" radius={[8, 8, 0, 0]}>
                    {avgTimeData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={index === 0 ? '#3b82f6' : '#10b981'} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 text-center">
              <p className="text-sm text-gray-500">Waktu rata-rata check-in hari ini</p>
              <p className="text-2xl font-semibold text-blue-600 mt-1">{dashboardData.avgCheckInTime}</p>
            </div>
          </div>
        </Card>
      </div>

      {/* Second Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Monthly Leaderboard */}
        <Card>
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <Trophy className="w-5 h-5 text-yellow-600" />
              Leaderboard Kecepatan Bulan Ini
            </h3>
          </div>
          <div className="p-6">
            <div className="space-y-3">
              {dashboardData.monthlyLeaderboard.length === 0 ? (
                <p className="text-center text-gray-500 py-4">Belum ada data bulan ini.</p>
              ) : (
                dashboardData.monthlyLeaderboard.map((entry, index) => (
                  <div key={entry.employeeId} className="flex items-center gap-3">
                    <div className={`flex items-center justify-center w-8 h-8 rounded-full font-semibold text-sm ${
                      index === 0 ? 'bg-yellow-100 text-yellow-700' :
                      index === 1 ? 'bg-gray-100 text-gray-700' :
                      index === 2 ? 'bg-orange-100 text-orange-700' :
                      'bg-blue-50 text-blue-600'
                    }`}>
                      {index + 1}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">{entry.name}</p>
                      <p className="text-sm text-gray-500">{entry.onTimeCount} kali tepat waktu</p>
                    </div>
                    {/* <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-50 text-green-700 border border-green-200">
                      {entry.percentage}%
                    </span> 
                    */}
                  </div>
                ))
              )}
            </div>
          </div>
        </Card>

        {/* Late Arrivals Today */}
        <Card>
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-semibold flex items-center gap-2">
              <Clock className="w-5 h-5 text-red-600" />
              Pegawai Terlambat Hari Ini
            </h3>
          </div>
          <div className="p-6">
            {dashboardData.lateArrivals.length === 0 ? (
              <div className="text-center py-8">
                <p className="text-gray-500">Tidak ada pegawai yang terlambat hari ini! 🎉</p>
              </div>
            ) : (
              <div className="space-y-4">
                {dashboardData.lateArrivals.map((record) => (
                  <div key={record.id} className="flex items-center gap-4">
                    {/* Avatar */}
                    <div className="w-10 h-10 rounded-full overflow-hidden bg-gray-100">
                      <img 
                        src={record.avatar_url} 
                        alt={record.full_name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">{record.full_name}</p>
                      <p className="text-sm text-gray-500">{record.department}</p>
                    </div>
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-50 text-red-700 border border-red-200">
                      {record.check_in_time.substring(0, 5)}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}