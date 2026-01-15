import React, { useState, useEffect } from 'react';
import { UserPlus, Search, Trash2, Edit, Save, X } from 'lucide-react';

export default function DataPegawai() {
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  
  // State Modal
  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false); // Mode Edit atau Tambah?
  const [editId, setEditId] = useState(null);        // ID user yang sedang diedit

  // State Form (Hanya Nama & Posisi)
  const [formData, setFormData] = useState({
    full_name: '',
    position: ''
  });

  // State Search
  const [searchQuery, setSearchQuery] = useState('');

  // --- 1. FETCH DATA ---
  const fetchEmployees = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/pegawai');
      const data = await response.json();
      setEmployees(data);
      setLoading(false);
    } catch (error) {
      console.error("Error:", error);
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  // --- 2. HANDLE SUBMIT (TAMBAH / EDIT) ---
  const handleSubmit = async (e) => {
    e.preventDefault();
    if(!formData.full_name) {
      alert("Nama wajib diisi!");
      return;
    }

    const url = isEditing 
      ? `http://localhost:5000/api/pegawai/${editId}` // URL Edit
      : 'http://localhost:5000/api/pegawai';        // URL Tambah
    
    const method = isEditing ? 'PUT' : 'POST';

    try {
      const response = await fetch(url, {
        method: method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const result = await response.json();

      if (response.ok) {
        alert(isEditing ? "Data diperbarui!" : `Sukses! Pegawai baru ID: ${result.data.employee_id}`);
        resetForm();
        fetchEmployees();
      } else {
        alert(result.message || "Gagal menyimpan data");
      }
    } catch (error) {
      console.error(error);
      alert("Terjadi kesalahan koneksi");
    }
  };

  // --- 3. HANDLE DELETE ---
  const handleDelete = async (id, name) => {
    if (window.confirm(`Yakin ingin menghapus pegawai "${name}"? Data absensi juga akan terhapus.`)) {
      try {
        const response = await fetch(`http://localhost:5000/api/pegawai/${id}`, {
          method: 'DELETE',
        });
        
        if (response.ok) {
          alert("Pegawai berhasil dihapus");
          fetchEmployees(); // Refresh list
        } else {
          alert("Gagal menghapus");
        }
      } catch (error) {
        console.error(error);
        alert("Error koneksi");
      }
    }
  };

  // --- HELPER: BUKA MODAL EDIT ---
  const handleEditClick = (emp) => {
    setIsEditing(true);
    setEditId(emp.id);
    setFormData({
      full_name: emp.full_name,
      position: emp.position || ''
    });
    setShowModal(true);
  };

  // --- HELPER: RESET FORM ---
  const resetForm = () => {
    setShowModal(false);
    setIsEditing(false);
    setEditId(null);
    setFormData({ full_name: '', position: '' });
  };

  // Filter Search Logic
  const filteredEmployees = employees.filter(emp => 
    emp.full_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    emp.employee_id.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="p-4 md:p-8 space-y-6 bg-gray-50 min-h-screen">
      {/* Header */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Data Pegawai</h1>
          <p className="text-gray-500">Kelola data karyawan</p>
        </div>
        <button 
          onClick={() => { resetForm(); setShowModal(true); }}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700 transition shadow-sm"
        >
          <UserPlus size={20} />
          Tambah Pegawai
        </button>
      </div>

      {/* Search Bar */}
      <div className="relative max-w-md">
        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
        <input 
          type="text" 
          placeholder="Cari nama atau ID..." 
          className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Tabel */}
      <div className="bg-white rounded-lg shadow border border-gray-200 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                <th className="p-4 font-semibold text-gray-700">ID</th>
                <th className="p-4 font-semibold text-gray-700">Nama Lengkap</th>
                <th className="p-4 font-semibold text-gray-700">Posisi</th>
                <th className="p-4 font-semibold text-gray-700 text-center">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {loading ? (
                <tr><td colSpan="4" className="p-6 text-center text-gray-500">Memuat data...</td></tr>
              ) : filteredEmployees.length === 0 ? (
                <tr><td colSpan="4" className="p-6 text-center text-gray-500">Tidak ada data pegawai.</td></tr>
              ) : (
                filteredEmployees.map((emp) => (
                  <tr key={emp.id} className="hover:bg-gray-50 transition-colors">
                    <td className="p-4 font-mono text-blue-600 font-bold">{emp.employee_id}</td>
                    <td className="p-4 font-medium text-gray-900">{emp.full_name}</td>
                    <td className="p-4 text-gray-600">{emp.position || '-'}</td>
                    
                    {/* KOLOM AKSI */}
                    <td className="p-4">
                      <div className="flex justify-center gap-2">
                        <button 
                          onClick={() => handleEditClick(emp)}
                          className="p-2 bg-yellow-50 text-yellow-600 rounded-md hover:bg-yellow-100 transition border border-yellow-200"
                          title="Edit"
                        >
                          <Edit size={18} />
                        </button>
                        <button 
                          onClick={() => handleDelete(emp.id, emp.full_name)}
                          className="p-2 bg-red-50 text-red-600 rounded-md hover:bg-red-100 transition border border-red-200"
                          title="Hapus"
                        >
                          <Trash2 size={18} />
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

      {/* MODAL FORM (TAMBAH / EDIT) */}
      {showModal && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl w-full max-w-md shadow-2xl animate-in fade-in zoom-in duration-200">
            {/* Modal Header */}
            <div className="flex justify-between items-center p-6 border-b border-gray-100">
              <h2 className="text-xl font-bold text-gray-800">
                {isEditing ? 'Edit Data Pegawai' : 'Tambah Pegawai Baru'}
              </h2>
              <button onClick={resetForm} className="text-gray-400 hover:text-gray-600">
                <X size={24} />
              </button>
            </div>
            
            {/* Modal Body */}
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Nama Lengkap <span className="text-red-500">*</span></label>
                <input 
                  type="text" 
                  className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:outline-none transition"
                  value={formData.full_name}
                  onChange={e => setFormData({...formData, full_name: e.target.value})}
                  placeholder="Contoh: Budi Santoso"
                  required
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Posisi / Jabatan</label>
                <input 
                  type="text" 
                  className="w-full border border-gray-300 rounded-lg p-2.5 focus:ring-2 focus:ring-blue-500 focus:outline-none transition"
                  value={formData.position}
                  onChange={e => setFormData({...formData, position: e.target.value})}
                  placeholder="Contoh: Staff Gudang"
                />
              </div>

              {/* Action Buttons */}
              <div className="pt-4 flex gap-3">
                <button 
                  type="button" 
                  onClick={resetForm}
                  className="flex-1 px-4 py-2.5 bg-gray-100 text-gray-700 font-medium rounded-lg hover:bg-gray-200 transition"
                >
                  Batal
                </button>
                <button 
                  type="submit" 
                  className="flex-1 px-4 py-2.5 bg-blue-600 text-white font-medium rounded-lg hover:bg-blue-700 transition flex justify-center items-center gap-2 shadow-md"
                >
                  <Save size={18} />
                  Simpan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}