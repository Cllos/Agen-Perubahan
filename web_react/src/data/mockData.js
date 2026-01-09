// src/data/mockData.js

// Generate mock employees
export const employees = [
  { id: 'EMP001', name: 'Budi Santoso', department: 'IT', role: 'Developer', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Budi' },
  { id: 'EMP002', name: 'Siti Nurhaliza', department: 'HR', role: 'HR Manager', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Siti' },
  { id: 'EMP003', name: 'Ahmad Wijaya', department: 'Finance', role: 'Accountant', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Ahmad' },
  { id: 'EMP004', name: 'Dewi Lestari', department: 'Marketing', role: 'Marketing Lead', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Dewi' },
  { id: 'EMP005', name: 'Eko Prasetyo', department: 'IT', role: 'System Analyst', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Eko' },
  { id: 'EMP006', name: 'Rina Susanti', department: 'Operations', role: 'Operations Manager', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Rina' },
  { id: 'EMP007', name: 'Hendra Gunawan', department: 'IT', role: 'DevOps Engineer', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Hendra' },
  { id: 'EMP008', name: 'Maya Sari', department: 'HR', role: 'HR Staff', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Maya' },
  { id: 'EMP009', name: 'Rizki Ramadhan', department: 'Finance', role: 'Financial Analyst', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Rizki' },
  { id: 'EMP010', name: 'Laila Sari', department: 'Marketing', role: 'Content Specialist', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Laila' },
  { id: 'EMP011', name: 'Farhan Maulana', department: 'IT', role: 'UI/UX Designer', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Farhan' },
  { id: 'EMP012', name: 'Putri Ayu', department: 'Operations', role: 'Operations Staff', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Putri' },
  { id: 'EMP013', name: 'Doni Setiawan', department: 'IT', role: 'Backend Developer', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Doni' },
  { id: 'EMP014', name: 'Indah Permata', department: 'Finance', role: 'Tax Specialist', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Indah' },
  { id: 'EMP015', name: 'Yoga Pratama', department: 'Marketing', role: 'SEO Specialist', avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Yoga' },
];

// Generate attendance records for today
const generateTodayAttendance = () => {
  const today = new Date();
  const records = [];
  
  employees.forEach((emp, index) => {
    // Random check-in time between 07:00 and 09:30
    const hour = Math.random() < 0.7 ? 7 : 8;
    const minute = Math.floor(Math.random() * 60);
    const checkInTime = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
    
    // Status: Tepat Waktu if before 08:00
    const status = hour < 8 || (hour === 8 && minute === 0) ? 'Tepat Waktu' : 'Terlambat';
    
    records.push({
      id: `ATT${today.getTime()}_${index}`,
      employeeId: emp.id,
      employeeName: emp.name,
      date: today,
      checkInTime,
      status: status,
    });
  });
  
  return records.sort((a, b) => a.checkInTime.localeCompare(b.checkInTime));
};

// Generate attendance records for history (from 2025)
const generateHistoryAttendance = () => {
  const records = [];
  const startDate = new Date('2025-01-01');
  const endDate = new Date();
  
  // Generate records for each working day
  for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
    // Skip weekends
    if (d.getDay() === 0 || d.getDay() === 6) continue;
    
    employees.forEach((emp, index) => {
      // Randomly skip some employees (absent)
      if (Math.random() < 0.1) return;
      
      const hour = Math.random() < 0.75 ? 7 : 8;
      const minute = Math.floor(Math.random() * 60);
      const checkInTime = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
      const status = hour < 8 || (hour === 8 && minute === 0) ? 'Tepat Waktu' : 'Terlambat';
      
      records.push({
        id: `ATT${d.getTime()}_${index}`,
        employeeId: emp.id,
        employeeName: emp.name,
        date: new Date(d),
        checkInTime,
        status: status,
      });
    });
  }
  
  return records;
};

export const todayAttendance = generateTodayAttendance();
export const historyAttendance = generateHistoryAttendance();

// Get top 5 earliest arrivals today
export const getTop5EarliestToday = () => {
  return todayAttendance.slice(0, 5);
};

// Get late arrivals today
export const getLateArrivalsToday = () => {
  return todayAttendance.filter(record => record.status === 'Terlambat');
};

// Get monthly leaderboard (employees with most on-time arrivals)
export const getMonthlyLeaderboard = () => {
  const thisMonth = new Date().getMonth();
  const thisYear = new Date().getFullYear();
  
  const monthRecords = historyAttendance.filter(record => {
    const recordDate = new Date(record.date);
    return recordDate.getMonth() === thisMonth && recordDate.getFullYear() === thisYear;
  });
  
  // Count on-time arrivals per employee
  const employeeStats = {};
  
  monthRecords.forEach(record => {
    if (!employeeStats[record.employeeId]) {
      employeeStats[record.employeeId] = {
        name: record.employeeName,
        onTimeCount: 0,
        totalCount: 0,
      };
    }
    employeeStats[record.employeeId].totalCount++;
    if (record.status === 'Tepat Waktu') {
      employeeStats[record.employeeId].onTimeCount++;
    }
  });
  
  // Sort by on-time count and return top 10
  return Object.entries(employeeStats)
    .map(([id, stats]) => ({
      employeeId: id,
      name: stats.name,
      onTimeCount: stats.onTimeCount,
      totalCount: stats.totalCount,
      percentage: Math.round((stats.onTimeCount / stats.totalCount) * 100),
    }))
    .sort((a, b) => b.onTimeCount - a.onTimeCount)
    .slice(0, 10);
};

// Calculate average check-in time for today
export const getAverageCheckInTime = () => {
  if (todayAttendance.length === 0) return '08:00';
  
  const totalMinutes = todayAttendance.reduce((sum, record) => {
    const [hour, minute] = record.checkInTime.split(':').map(Number);
    return sum + (hour * 60 + minute);
  }, 0);
  
  const avgMinutes = Math.floor(totalMinutes / todayAttendance.length);
  const hour = Math.floor(avgMinutes / 60);
  const minute = avgMinutes % 60;
  
  return `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
};