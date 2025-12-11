import { Package, TrendingUp, Clock, CheckCircle } from 'lucide-react';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

interface HomeProps {
  onNavigate: (screen: Screen) => void;
}

export function Home({ onNavigate }: HomeProps) {
  const todayStats = {
    registered: 12,
    pending: 8,
    inTransit: 15,
    delivered: 23
  };

  const recentPackages = [
    { id: 'PKG-2024-001', customer: 'Zwe Mhan Htet', status: 'In Transit', time: '2 hours ago', amount: '50,000 MMK' },
    { id: 'PKG-2024-002', customer: 'Aung Kyaw', status: 'Pending', time: '4 hours ago', amount: '35,000 MMK' },
    { id: 'PKG-2024-003', customer: 'Su Su', status: 'Delivered', time: '6 hours ago', amount: '120,000 MMK' },
  ];

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50">
      {/* Header with Gradient */}
      <header className="bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-900 text-white px-6 pt-6 pb-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-yellow-400 text-sm mb-1">Welcome back,</p>
            <h1 className="text-white text-2xl">Erick's Shop</h1>
          </div>
          <button className="w-10 h-10 bg-white bg-opacity-10 rounded-full flex items-center justify-center hover:bg-opacity-20 transition-all">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
          </button>
        </div>

        {/* Stats Cards in Header */}
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-xl p-4 border border-white border-opacity-20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-neutral-300 text-sm">Today's Total</span>
              <TrendingUp className="w-4 h-4 text-yellow-400" />
            </div>
            <p className="text-white text-2xl">{todayStats.registered}</p>
            <p className="text-yellow-400 text-xs mt-1">Packages registered</p>
          </div>
          
          <div className="bg-white bg-opacity-10 backdrop-blur-sm rounded-xl p-4 border border-white border-opacity-20">
            <div className="flex items-center justify-between mb-2">
              <span className="text-neutral-300 text-sm">Revenue</span>
              <svg className="w-4 h-4 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <p className="text-white text-2xl">205K</p>
            <p className="text-yellow-400 text-xs mt-1">MMK today</p>
          </div>
        </div>
      </header>

      <div className="flex-1 px-6 py-6 -mt-4">
        {/* Quick Action - Register Package */}
        <button
          onClick={() => onNavigate('register')}
          className="w-full bg-gradient-to-r from-yellow-400 to-yellow-500 hover:from-yellow-500 hover:to-yellow-600 text-neutral-900 rounded-2xl p-5 flex items-center justify-between mb-6 shadow-lg shadow-yellow-500/20 transition-all transform hover:scale-[1.02]"
        >
          <div className="flex items-center gap-4">
            <div className="w-12 h-12 bg-neutral-900 bg-opacity-20 rounded-xl flex items-center justify-center">
              <svg className="w-6 h-6 text-neutral-900" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
              </svg>
            </div>
            <div className="text-left">
              <div className="text-neutral-900 font-semibold">Register New Package</div>
              <div className="text-neutral-700 text-sm mt-0.5">Quick registration</div>
            </div>
          </div>
          <svg className="w-6 h-6 text-neutral-900" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 5l7 7-7 7" />
          </svg>
        </button>

        {/* Status Overview */}
        <div className="mb-6">
          <h2 className="text-neutral-900 mb-4 flex items-center gap-2">
            <Package className="w-5 h-5" />
            Status Overview
          </h2>
          <div className="grid grid-cols-3 gap-3">
            <button 
              onClick={() => onNavigate('track')}
              className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all"
            >
              <Clock className="w-5 h-5 text-yellow-600 mb-2" />
              <div className="text-2xl text-neutral-900 mb-1">{todayStats.pending}</div>
              <div className="text-neutral-500 text-xs">Pending</div>
            </button>
            
            <button 
              onClick={() => onNavigate('track')}
              className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all"
            >
              <svg className="w-5 h-5 text-yellow-600 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
              <div className="text-2xl text-neutral-900 mb-1">{todayStats.inTransit}</div>
              <div className="text-neutral-500 text-xs">In Transit</div>
            </button>
            
            <button 
              onClick={() => onNavigate('track')}
              className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all"
            >
              <CheckCircle className="w-5 h-5 text-yellow-600 mb-2" />
              <div className="text-2xl text-neutral-900 mb-1">{todayStats.delivered}</div>
              <div className="text-neutral-500 text-xs">Delivered</div>
            </button>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-neutral-900 flex items-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              Recent Activity
            </h2>
            <button 
              onClick={() => onNavigate('track')}
              className="text-yellow-600 text-sm hover:text-yellow-700"
            >
              View All
            </button>
          </div>

          <div className="space-y-3">
            {recentPackages.map((pkg) => (
              <button
                key={pkg.id}
                className="w-full bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all text-left"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <p className="text-neutral-900 font-medium">{pkg.customer}</p>
                    <p className="text-neutral-500 text-sm mt-0.5">{pkg.id}</p>
                  </div>
                  <div className={`px-3 py-1 rounded-full text-xs font-medium ${
                    pkg.status === 'Delivered' 
                      ? 'bg-neutral-100 text-neutral-700' 
                      : pkg.status === 'In Transit'
                      ? 'bg-yellow-50 text-yellow-700 border border-yellow-200'
                      : 'bg-neutral-50 text-neutral-600 border border-neutral-200'
                  }`}>
                    {pkg.status}
                  </div>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-neutral-500">{pkg.time}</span>
                  <span className="text-neutral-900 font-medium">{pkg.amount}</span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Quick Actions Grid */}
        <div>
          <h2 className="text-neutral-900 mb-4">Quick Actions</h2>
          <div className="grid grid-cols-2 gap-3">
            <button
              onClick={() => onNavigate('draft')}
              className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all"
            >
              <svg className="w-6 h-6 text-yellow-600 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <p className="text-neutral-900 font-medium text-sm">Draft Packages</p>
              <p className="text-neutral-500 text-xs mt-1">3 drafts</p>
            </button>

            <button
              onClick={() => onNavigate('track')}
              className="bg-white border border-neutral-200 rounded-xl p-4 hover:border-yellow-400 hover:shadow-md transition-all"
            >
              <svg className="w-6 h-6 text-yellow-600 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              <p className="text-neutral-900 font-medium text-sm">Analytics</p>
              <p className="text-neutral-500 text-xs mt-1">View reports</p>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
