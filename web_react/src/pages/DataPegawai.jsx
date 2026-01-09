import React, { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, Search, X } from 'lucide-react';

export default function DataPegawai() {
  // --- STATE MANAGEMENT ---
  const [employees, setEmployees] = useState([]);
  const [searchQuery, setSearchQuery] = useState('');
  
  // State untuk Modal/Dialog
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [deleteEmployeeId, setDeleteEmployeeId] = useState(null);
  
  // State untuk Form
  const [currentEmployee, setCurrentEmployee] = useState(null);
  const [formData, setFormData] = useState({
    id: '',
    name: '',
    department: '',
    role: '',
  });

  // --- 1. READ (GET) DATA DARI SERVER ---
  const fetchEmployees = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/pegawai'); 
      const data = await response.json();
      
      // Mapping dari Database (snake_case) ke Frontend (camelCase)
      const formattedData = data.map(user => ({
        id: user.employee_id,      
        name: user.full_name,      
        department: user.department,
        role: user.position,       
        avatar: user.avatar_url    
      }));

      setEmployees(formattedData); 
    } catch (error) {
      console.error("Gagal mengambil data pegawai:", error);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  // --- LOGIC FILTERING ---
  const filteredEmployees = employees.filter(emp =>
    emp.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.department.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.role.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // --- HANDLERS ---
  
  const resetForm = () => {
    setFormData({ id: '', name: '', department: '', role: '' });
  };

  // --- 2. CREATE (POST) KE SERVER ---
  const handleAddEmployee = async (e) => {
    e.preventDefault();
    if (formData.id && formData.name) {
      // Siapkan data yang mau dikirim ke server
      const newEmployeeData = {
        id: formData.id,
        name: formData.name,
        department: formData.department,
        role: formData.role,
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${formData.name}`
      };

      try {
        // Kirim request POST ke Backend
        const response = await fetch('http://localhost:5000/api/pegawai', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(newEmployeeData)
        });

        if (response.ok) {
            // Jika sukses, ambil ulang data terbaru dari database
            await fetchEmployees(); 
            setIsAddDialogOpen(false);
            resetForm();
        } else {
            console.error("Gagal menambah pegawai");
        }
      } catch (error) {
        console.error("Error connecting to server:", error);
      }
    }
  };

  const openEditDialog = (employee) => {
    setCurrentEmployee(employee);
    setFormData({
      id: employee.id,
      name: employee.name,
      department: employee.department,
      role: employee.role,
    });
    setIsEditDialogOpen(true);
  };

  // --- 3. UPDATE (PUT) KE SERVER ---
  const handleEditEmployee = async (e) => {
    e.preventDefault();
    if (currentEmployee) {
      const updatedData = {
        name: formData.name,
        department: formData.department,
        role: formData.role,
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${formData.name}`
      };

      try {
        // Kirim request PUT berdasarkan ID
        const response = await fetch(`http://localhost:5000/api/pegawai/${currentEmployee.id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(updatedData)
        });

        if (response.ok) {
            await fetchEmployees(); // Refresh data
            setIsEditDialogOpen(false);
            resetForm();
            setCurrentEmployee(null);
        }
      } catch (error) {
        console.error("Error updating employee:", error);
      }
    }
  };

  // --- 4. DELETE KE SERVER ---
  const handleDeleteEmployee = async () => {
    if (deleteEmployeeId) {
      try {
        const response = await fetch(`http://localhost:5000/api/pegawai/${deleteEmployeeId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            await fetchEmployees(); // Refresh data
            setDeleteEmployeeId(null);
        }
      } catch (error) {
        console.error("Error deleting employee:", error);
      }
    }
  };

  return (
    <div className="p-4 md:p-8 space-y-6 min-h-screen bg-gray-50">
      
      {/* HEADER */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-semibold text-gray-900">Data Pegawai</h1>
          <p className="text-gray-500 mt-1">Kelola data seluruh pegawai perusahaan</p>
        </div>
        <button 
          onClick={() => { resetForm(); setIsAddDialogOpen(true); }}
          className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg flex items-center justify-center gap-2 transition-colors shadow-sm"
        >
          <Plus className="w-4 h-4" />
          Tambah Pegawai
        </button>
      </div>

      {/* SEARCH BAR */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Cari pegawai berdasarkan nama, ID, departemen, atau jabatan..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      {/* TABLE */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="px-6 py-4 font-medium text-gray-700">ID Pegawai</th>
                <th className="px-6 py-4 font-medium text-gray-700">Nama</th>
                <th className="px-6 py-4 font-medium text-gray-700">Departemen</th>
                <th className="px-6 py-4 font-medium text-gray-700">Jabatan</th>
                <th className="px-6 py-4 font-medium text-gray-700 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {filteredEmployees.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-gray-500">
                    Tidak ada data pegawai yang ditemukan
                  </td>
                </tr>
              ) : (
                filteredEmployees.map((employee) => (
                  <tr key={employee.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 font-medium text-gray-900">{employee.id}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <img 
                          src={employee.avatar} 
                          alt={employee.name} 
                          className="w-8 h-8 rounded-full bg-gray-100"
                        />
                        <span className="text-gray-900">{employee.name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-gray-600">{employee.department}</td>
                    <td className="px-6 py-4 text-gray-600">{employee.role}</td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2">
                        <button
                          onClick={() => openEditDialog(employee)}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Pencil className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => setDeleteEmployeeId(employee.id)}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Hapus"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* MODAL TAMBAH PEGAWAI */}
      {isAddDialogOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold">Tambah Pegawai Baru</h2>
              <button onClick={() => setIsAddDialogOpen(false)}><X className="w-5 h-5 text-gray-500" /></button>
            </div>
            <form onSubmit={handleAddEmployee} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">ID Pegawai</label>
                <input 
                  required
                  value={formData.id}
                  onChange={(e) => setFormData({...formData, id: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Contoh: EMP016"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap</label>
                <input 
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Nama Pegawai"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Departemen</label>
                <input 
                  required
                  value={formData.department}
                  onChange={(e) => setFormData({...formData, department: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Divisi / Departemen"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Jabatan</label>
                <input 
                  required
                  value={formData.role}
                  onChange={(e) => setFormData({...formData, role: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                  placeholder="Posisi Jabatan"
                />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsAddDialogOpen(false)} className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg">Batal</button>
                <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Simpan</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL EDIT PEGAWAI */}
      {isEditDialogOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold">Edit Data Pegawai</h2>
              <button onClick={() => setIsEditDialogOpen(false)}><X className="w-5 h-5 text-gray-500" /></button>
            </div>
            <form onSubmit={handleEditEmployee} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">ID Pegawai</label>
                <input 
                  disabled
                  value={formData.id}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 bg-gray-100 text-gray-500 cursor-not-allowed"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap</label>
                <input 
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Departemen</label>
                <input 
                  required
                  value={formData.department}
                  onChange={(e) => setFormData({...formData, department: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Jabatan</label>
                <input 
                  required
                  value={formData.role}
                  onChange={(e) => setFormData({...formData, role: e.target.value})}
                  className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-blue-500 outline-none"
                />
              </div>
              <div className="flex justify-end gap-3 mt-6">
                <button type="button" onClick={() => setIsEditDialogOpen(false)} className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg">Batal</button>
                <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700">Simpan Perubahan</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ALERT DELETE */}
      {deleteEmployeeId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-sm p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-2">Hapus Pegawai</h2>
            <p className="text-gray-600 mb-6">
              Apakah Anda yakin ingin menghapus data pegawai ini? Tindakan ini tidak dapat dibatalkan.
            </p>
            <div className="flex justify-end gap-3">
              <button 
                onClick={() => setDeleteEmployeeId(null)}
                className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg font-medium"
              >
                Batal
              </button>
              <button 
                onClick={handleDeleteEmployee}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium"
              >
                Hapus
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}