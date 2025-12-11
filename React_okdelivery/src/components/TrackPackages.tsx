import { useState } from 'react';
import { Search, Filter, Package, MapPin, Clock, CheckCircle2, TruckIcon, AlertCircle } from 'lucide-react';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

interface TrackPackagesProps {
  onNavigate: (screen: Screen) => void;
}

interface PackageData {
  id: string;
  trackingNumber: string;
  customer: string;
  phone: string;
  address: string;
  status: 'pending' | 'pickup' | 'transit' | 'delivered' | 'failed';
  amount: string;
  paymentType: string;
  date: string;
  lastUpdate: string;
}

export function TrackPackages({ onNavigate }: TrackPackagesProps) {
  const [activeFilter, setActiveFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  const packages: PackageData[] = [
    {
      id: '1',
      trackingNumber: 'PKG-2024-001',
      customer: 'Zwe Mhan Htet',
      phone: '09-123-456-789',
      address: 'Mayangone Township, Yangon',
      status: 'transit',
      amount: '50000',
      paymentType: 'COD',
      date: 'Dec 1, 2024',
      lastUpdate: '2 hours ago'
    },
    {
      id: '2',
      trackingNumber: 'PKG-2024-002',
      customer: 'Aung Kyaw',
      phone: '09-987-654-321',
      address: 'Hlaing Township, Yangon',
      status: 'pending',
      amount: '35000',
      paymentType: 'Prepaid',
      date: 'Dec 1, 2024',
      lastUpdate: '4 hours ago'
    },
    {
      id: '3',
      trackingNumber: 'PKG-2024-003',
      customer: 'Su Su',
      phone: '09-111-222-333',
      address: 'Kamayut Township, Yangon',
      status: 'delivered',
      amount: '120000',
      paymentType: 'COD',
      date: 'Dec 1, 2024',
      lastUpdate: '6 hours ago'
    },
    {
      id: '4',
      trackingNumber: 'PKG-2024-004',
      customer: 'Kyaw Gyi',
      phone: '09-444-555-666',
      address: 'Bahan Township, Yangon',
      status: 'pickup',
      amount: '75000',
      paymentType: 'COD',
      date: 'Dec 1, 2024',
      lastUpdate: '1 hour ago'
    },
    {
      id: '5',
      trackingNumber: 'PKG-2024-005',
      customer: 'Ma Thet',
      phone: '09-777-888-999',
      address: 'Sanchaung Township, Yangon',
      status: 'failed',
      amount: '45000',
      paymentType: 'COD',
      date: 'Nov 30, 2024',
      lastUpdate: '1 day ago'
    },
  ];

  const getStatusConfig = (status: string) => {
    switch (status) {
      case 'pending':
        return {
          color: 'bg-neutral-100 text-neutral-700 border-neutral-200',
          icon: <Clock className="w-4 h-4" />,
          label: 'Pending Pickup'
        };
      case 'pickup':
        return {
          color: 'bg-yellow-50 text-yellow-700 border-yellow-200',
          icon: <Package className="w-4 h-4" />,
          label: 'Ready for Pickup'
        };
      case 'transit':
        return {
          color: 'bg-yellow-50 text-yellow-700 border-yellow-200',
          icon: <TruckIcon className="w-4 h-4" />,
          label: 'In Transit'
        };
      case 'delivered':
        return {
          color: 'bg-neutral-100 text-neutral-700 border-neutral-200',
          icon: <CheckCircle2 className="w-4 h-4" />,
          label: 'Delivered'
        };
      case 'failed':
        return {
          color: 'bg-red-50 text-red-700 border-red-200',
          icon: <AlertCircle className="w-4 h-4" />,
          label: 'Delivery Failed'
        };
      default:
        return {
          color: 'bg-neutral-100 text-neutral-700 border-neutral-200',
          icon: <Package className="w-4 h-4" />,
          label: status
        };
    }
  };

  const filteredPackages = packages.filter(pkg => {
    const matchesFilter = activeFilter === 'all' || pkg.status === activeFilter;
    const matchesSearch = pkg.trackingNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         pkg.customer.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const statusCounts = {
    all: packages.length,
    pending: packages.filter(p => p.status === 'pending').length,
    pickup: packages.filter(p => p.status === 'pickup').length,
    transit: packages.filter(p => p.status === 'transit').length,
    delivered: packages.filter(p => p.status === 'delivered').length,
  };

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-neutral-900 to-neutral-800 text-white px-6 py-6 sticky top-0 z-10 shadow-lg">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-white text-xl">Track Packages</h1>
            <p className="text-yellow-400 text-sm mt-0.5">{packages.length} total packages</p>
          </div>
          <button className="p-2 hover:bg-white hover:bg-opacity-10 rounded-lg transition-all">
            <Filter className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <Search className="w-5 h-5 text-neutral-400" />
          </div>
          <input
            type="text"
            placeholder="Search by tracking number or name"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-white bg-opacity-10 backdrop-blur-sm border border-white border-opacity-20 text-white placeholder-neutral-400 rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:ring-2 focus:ring-yellow-400 focus:border-transparent transition-all"
          />
        </div>
      </header>

      <div className="flex-1 px-6 py-6">
        {/* Filter Tabs */}
        <div className="flex gap-2 mb-6 overflow-x-auto pb-2 scrollbar-hide">
          <button 
            onClick={() => setActiveFilter('all')}
            className={`px-4 py-2.5 rounded-xl whitespace-nowrap font-medium transition-all ${
              activeFilter === 'all' 
                ? 'bg-yellow-400 text-neutral-900 shadow-md' 
                : 'bg-white border border-neutral-200 text-neutral-700 hover:border-yellow-400'
            }`}
          >
            All ({statusCounts.all})
          </button>
          <button 
            onClick={() => setActiveFilter('pending')}
            className={`px-4 py-2.5 rounded-xl whitespace-nowrap font-medium transition-all ${
              activeFilter === 'pending' 
                ? 'bg-yellow-400 text-neutral-900 shadow-md' 
                : 'bg-white border border-neutral-200 text-neutral-700 hover:border-yellow-400'
            }`}
          >
            Pending ({statusCounts.pending})
          </button>
          <button 
            onClick={() => setActiveFilter('pickup')}
            className={`px-4 py-2.5 rounded-xl whitespace-nowrap font-medium transition-all ${
              activeFilter === 'pickup' 
                ? 'bg-yellow-400 text-neutral-900 shadow-md' 
                : 'bg-white border border-neutral-200 text-neutral-700 hover:border-yellow-400'
            }`}
          >
            Pickup ({statusCounts.pickup})
          </button>
          <button 
            onClick={() => setActiveFilter('transit')}
            className={`px-4 py-2.5 rounded-xl whitespace-nowrap font-medium transition-all ${
              activeFilter === 'transit' 
                ? 'bg-yellow-400 text-neutral-900 shadow-md' 
                : 'bg-white border border-neutral-200 text-neutral-700 hover:border-yellow-400'
            }`}
          >
            In Transit ({statusCounts.transit})
          </button>
          <button 
            onClick={() => setActiveFilter('delivered')}
            className={`px-4 py-2.5 rounded-xl whitespace-nowrap font-medium transition-all ${
              activeFilter === 'delivered' 
                ? 'bg-yellow-400 text-neutral-900 shadow-md' 
                : 'bg-white border border-neutral-200 text-neutral-700 hover:border-yellow-400'
            }`}
          >
            Delivered ({statusCounts.delivered})
          </button>
        </div>

        {/* Package List */}
        <div className="space-y-3">
          {filteredPackages.length > 0 ? (
            filteredPackages.map((pkg) => {
              const statusConfig = getStatusConfig(pkg.status);
              return (
                <button
                  key={pkg.id}
                  className="w-full bg-white border border-neutral-200 rounded-2xl p-5 hover:border-yellow-400 hover:shadow-lg transition-all text-left"
                >
                  {/* Header */}
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <p className="text-neutral-900 font-semibold">{pkg.customer}</p>
                      <p className="text-neutral-500 text-sm mt-0.5">{pkg.trackingNumber}</p>
                    </div>
                    <div className={`px-3 py-1.5 rounded-lg text-xs font-medium border flex items-center gap-1.5 ${statusConfig.color}`}>
                      {statusConfig.icon}
                      {statusConfig.label}
                    </div>
                  </div>

                  {/* Details */}
                  <div className="space-y-2 mb-3">
                    <div className="flex items-center gap-2 text-sm text-neutral-600">
                      <MapPin className="w-4 h-4 text-neutral-400" />
                      <span className="truncate">{pkg.address}</span>
                    </div>
                    <div className="flex items-center gap-2 text-sm text-neutral-600">
                      <svg className="w-4 h-4 text-neutral-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                      </svg>
                      <span>{pkg.phone}</span>
                    </div>
                  </div>

                  {/* Footer */}
                  <div className="flex items-center justify-between pt-3 border-t border-neutral-100">
                    <div className="flex items-center gap-4">
                      <span className="text-neutral-900 font-semibold">{parseFloat(pkg.amount).toLocaleString()} MMK</span>
                      <span className={`px-2 py-1 rounded text-xs ${
                        pkg.paymentType === 'COD' 
                          ? 'bg-yellow-50 text-yellow-700' 
                          : 'bg-neutral-100 text-neutral-600'
                      }`}>
                        {pkg.paymentType}
                      </span>
                    </div>
                    <span className="text-neutral-400 text-xs">{pkg.lastUpdate}</span>
                  </div>
                </button>
              );
            })
          ) : (
            <div className="flex flex-col items-center justify-center py-16 px-6">
              <div className="w-16 h-16 bg-neutral-100 rounded-full flex items-center justify-center mb-4">
                <Search className="w-8 h-8 text-neutral-400" />
              </div>
              <h3 className="text-neutral-900 mb-2">No Packages Found</h3>
              <p className="text-neutral-500 text-sm text-center mb-6">
                Try adjusting your search or filter criteria
              </p>
              <button 
                onClick={() => {
                  setSearchQuery('');
                  setActiveFilter('all');
                }}
                className="text-yellow-600 hover:text-yellow-700 font-medium"
              >
                Clear Filters
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
