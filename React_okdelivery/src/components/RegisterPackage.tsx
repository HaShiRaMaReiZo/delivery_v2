import { useState } from 'react';
import { X, Camera, Save, Send, Plus, MapPin, Phone, User, CreditCard, Package } from 'lucide-react';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

interface RegisterPackageProps {
  onNavigate: (screen: Screen) => void;
}

interface PackageItem {
  id: string;
  name: string;
  phone: string;
  location: string;
  amount: string;
  paymentType: string;
}

export function RegisterPackage({ onNavigate }: RegisterPackageProps) {
  const [packages, setPackages] = useState<PackageItem[]>([
    {
      id: '1',
      name: 'Zwe Mhan Htet',
      phone: '09-123-456-789',
      location: 'Mayangone Township, Yangon',
      amount: '50000',
      paymentType: 'COD'
    }
  ]);

  const [formData, setFormData] = useState({
    customerName: '',
    customerPhone: '',
    address: '',
    paymentType: 'cod',
    amount: '',
    description: '',
    township: 'mayangone'
  });

  const [hasPhoto, setHasPhoto] = useState(false);

  const removePackage = (id: string) => {
    setPackages(packages.filter(pkg => pkg.id !== id));
  };

  const addToList = () => {
    if (formData.customerName && formData.customerPhone && formData.address && formData.amount) {
      const newPackage: PackageItem = {
        id: Date.now().toString(),
        name: formData.customerName,
        phone: formData.customerPhone,
        location: formData.address,
        amount: formData.amount,
        paymentType: formData.paymentType.toUpperCase()
      };
      setPackages([...packages, newPackage]);
      // Reset form
      setFormData({
        customerName: '',
        customerPhone: '',
        address: '',
        paymentType: 'cod',
        amount: '',
        description: '',
        township: 'mayangone'
      });
      setHasPhoto(false);
    }
  };

  const totalAmount = packages.reduce((sum, pkg) => sum + parseFloat(pkg.amount || '0'), 0);

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-neutral-900 to-neutral-800 text-white px-6 py-4 sticky top-0 z-10 shadow-lg">
        <div className="flex items-center justify-between">
          <button onClick={() => onNavigate('home')} className="p-2 -ml-2 hover:bg-white hover:bg-opacity-10 rounded-lg transition-all">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div className="text-center">
            <h1 className="text-white">Register Package</h1>
            <p className="text-yellow-400 text-xs mt-0.5">{packages.length} in queue</p>
          </div>
          <button className="bg-yellow-400 text-neutral-900 px-4 py-2 rounded-lg text-sm font-medium hover:bg-yellow-500 transition-all flex items-center gap-2">
            <Send className="w-4 h-4" />
            Submit
          </button>
        </div>
      </header>

      <div className="flex-1 px-6 py-6 space-y-6">
        {/* Package Queue Summary */}
        {packages.length > 0 && (
          <div className="bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-2xl p-5 text-neutral-900 shadow-lg">
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <Package className="w-5 h-5" />
                <h2 className="font-semibold">Package Queue</h2>
              </div>
              <span className="bg-neutral-900 text-yellow-400 px-3 py-1 rounded-full text-sm font-medium">
                {packages.length} packages
              </span>
            </div>
            <div className="flex items-baseline gap-2">
              <p className="text-3xl font-bold">{totalAmount.toLocaleString()}</p>
              <p className="text-neutral-700">MMK Total</p>
            </div>
          </div>
        )}

        {/* Package List */}
        {packages.length > 0 && (
          <div className="space-y-3">
            <h3 className="text-neutral-700 text-sm flex items-center gap-2">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 10h16M4 14h16M4 18h16" />
              </svg>
              Queued Packages
            </h3>
            {packages.map((pkg, index) => (
              <div key={pkg.id} className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 transition-all">
                <div className="flex items-start gap-4">
                  <div className="w-10 h-10 bg-yellow-100 text-yellow-700 rounded-lg flex items-center justify-center font-semibold flex-shrink-0">
                    {index + 1}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="text-neutral-900 font-medium">{pkg.name}</h3>
                        <p className="text-neutral-500 text-sm mt-0.5">{pkg.phone}</p>
                      </div>
                      <button
                        onClick={() => removePackage(pkg.id)}
                        className="p-1.5 text-neutral-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all"
                      >
                        <X className="w-4 h-4" />
                      </button>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-neutral-600 mb-2">
                      <MapPin className="w-4 h-4 text-neutral-400" />
                      <span className="truncate">{pkg.location}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                        pkg.paymentType === 'COD' 
                          ? 'bg-yellow-50 text-yellow-700 border border-yellow-200' 
                          : 'bg-neutral-100 text-neutral-700'
                      }`}>
                        {pkg.paymentType}
                      </span>
                      <span className="text-neutral-900 font-semibold">{parseFloat(pkg.amount).toLocaleString()} MMK</span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Registration Form */}
        <div className="bg-white border border-neutral-200 rounded-2xl p-5 space-y-4">
          <div className="flex items-center justify-between mb-2">
            <h2 className="text-neutral-900 font-semibold">Package Details</h2>
            <span className="text-yellow-600 text-sm">* Required</span>
          </div>

          {/* Customer Name */}
          <div>
            <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
              <User className="w-4 h-4 text-yellow-600" />
              Customer Name <span className="text-yellow-600">*</span>
            </label>
            <input
              type="text"
              placeholder="Enter customer name"
              value={formData.customerName}
              onChange={(e) => setFormData({...formData, customerName: e.target.value})}
              className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all"
            />
          </div>

          {/* Customer Phone */}
          <div>
            <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
              <Phone className="w-4 h-4 text-yellow-600" />
              Customer Phone <span className="text-yellow-600">*</span>
            </label>
            <input
              type="tel"
              placeholder="09-XXX-XXX-XXX"
              value={formData.customerPhone}
              onChange={(e) => setFormData({...formData, customerPhone: e.target.value})}
              className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all"
            />
          </div>

          {/* Township Selector */}
          <div>
            <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
              <MapPin className="w-4 h-4 text-yellow-600" />
              Township <span className="text-yellow-600">*</span>
            </label>
            <select
              value={formData.township}
              onChange={(e) => setFormData({...formData, township: e.target.value})}
              className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all appearance-none"
              style={{
                backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                backgroundPosition: 'right 0.75rem center',
                backgroundRepeat: 'no-repeat',
                backgroundSize: '1.5em 1.5em',
              }}
            >
              <option value="mayangone">Mayangone</option>
              <option value="hlaing">Hlaing</option>
              <option value="kamayut">Kamayut</option>
              <option value="bahan">Bahan</option>
              <option value="sanchaung">Sanchaung</option>
              <option value="dagon">Dagon</option>
            </select>
          </div>

          {/* Delivery Address */}
          <div>
            <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
              <svg className="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              Delivery Address <span className="text-yellow-600">*</span>
            </label>
            <input
              type="text"
              placeholder="House No, Street, etc."
              value={formData.address}
              onChange={(e) => setFormData({...formData, address: e.target.value})}
              className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all"
            />
          </div>

          {/* Payment Type & Amount Grid */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
                <CreditCard className="w-4 h-4 text-yellow-600" />
                Payment <span className="text-yellow-600">*</span>
              </label>
              <select
                value={formData.paymentType}
                onChange={(e) => setFormData({...formData, paymentType: e.target.value})}
                className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all appearance-none"
                style={{
                  backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                  backgroundPosition: 'right 0.75rem center',
                  backgroundRepeat: 'no-repeat',
                  backgroundSize: '1.5em 1.5em',
                }}
              >
                <option value="cod">COD</option>
                <option value="prepaid">Prepaid</option>
                <option value="postpaid">Postpaid</option>
              </select>
            </div>

            <div>
              <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
                <svg className="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                Amount <span className="text-yellow-600">*</span>
              </label>
              <input
                type="number"
                placeholder="MMK"
                value={formData.amount}
                onChange={(e) => setFormData({...formData, amount: e.target.value})}
                className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all"
              />
            </div>
          </div>

          {/* Package Description */}
          <div>
            <label className="flex items-center gap-2 text-neutral-700 text-sm mb-2">
              <svg className="w-4 h-4 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              Description <span className="text-neutral-400">(Optional)</span>
            </label>
            <textarea
              rows={3}
              placeholder="Package contents, special instructions..."
              value={formData.description}
              onChange={(e) => setFormData({...formData, description: e.target.value})}
              className="w-full bg-neutral-50 border border-neutral-300 rounded-xl px-4 py-3 text-neutral-900 placeholder-neutral-400 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent resize-none transition-all"
            />
          </div>

          {/* Photo Button */}
          <button 
            onClick={() => setHasPhoto(!hasPhoto)}
            className={`w-full border-2 border-dashed rounded-xl py-4 flex items-center justify-center gap-2 transition-all ${
              hasPhoto 
                ? 'border-yellow-400 bg-yellow-50 text-yellow-700' 
                : 'border-neutral-300 text-neutral-600 hover:border-yellow-400 hover:bg-yellow-50 hover:text-yellow-700'
            }`}
          >
            <Camera className="w-5 h-5" />
            <span>{hasPhoto ? 'Photo Added ✓' : 'Add Package Photo'}</span>
            <span className="text-neutral-400">(Optional)</span>
          </button>

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-3 pt-2">
            <button 
              onClick={addToList}
              className="bg-neutral-100 text-neutral-900 rounded-xl py-3.5 hover:bg-neutral-200 transition-all flex items-center justify-center gap-2 font-medium"
            >
              <Plus className="w-5 h-5" />
              Add to Queue
            </button>
            <button className="bg-yellow-400 text-neutral-900 rounded-xl py-3.5 hover:bg-yellow-500 transition-all flex items-center justify-center gap-2 font-medium">
              <Save className="w-5 h-5" />
              Save Draft
            </button>
          </div>
        </div>

        {/* Help Text */}
        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 flex gap-3">
          <svg className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <p className="text-neutral-900 text-sm font-medium mb-1">Quick Tip</p>
            <p className="text-neutral-600 text-sm">Add multiple packages to queue and submit them all at once to save time.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
