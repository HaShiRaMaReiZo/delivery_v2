import { User, Shield, Bell, HelpCircle, Info, LogOut, ChevronRight, Award, TrendingUp } from 'lucide-react';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

interface ProfileProps {
  onNavigate: (screen: Screen) => void;
}

export function Profile({ onNavigate }: ProfileProps) {
  return (
    <div className="flex flex-col min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="bg-gradient-to-br from-neutral-900 via-neutral-800 to-neutral-900 text-white px-6 pt-6 pb-12">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-white text-xl">Profile</h1>
          <button className="p-2 hover:bg-white hover:bg-opacity-10 rounded-lg transition-all">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
          </button>
        </div>

        {/* Profile Card */}
        <div className="text-center">
          <div className="w-24 h-24 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-full flex items-center justify-center mx-auto mb-4 shadow-lg">
            <User className="w-12 h-12 text-neutral-900" />
          </div>
          <h2 className="text-white text-xl mb-1">Erick's Shop</h2>
          <p className="text-yellow-400 text-sm mb-4">erickboyle@gmail.com</p>
          
          {/* Stats */}
          <div className="flex items-center justify-center gap-6">
            <div>
              <p className="text-white text-xl font-semibold">58</p>
              <p className="text-neutral-300 text-xs">Packages</p>
            </div>
            <div className="w-px h-10 bg-white bg-opacity-20"></div>
            <div>
              <p className="text-white text-xl font-semibold">4.8</p>
              <p className="text-neutral-300 text-xs">Rating</p>
            </div>
            <div className="w-px h-10 bg-white bg-opacity-20"></div>
            <div>
              <p className="text-white text-xl font-semibold">92%</p>
              <p className="text-neutral-300 text-xs">Success</p>
            </div>
          </div>
        </div>
      </header>

      <div className="flex-1 px-6 py-6 -mt-6 space-y-6">
        {/* Performance Card */}
        <div className="bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-2xl p-5 text-neutral-900 shadow-lg">
          <div className="flex items-center gap-2 mb-3">
            <Award className="w-5 h-5" />
            <h3 className="font-semibold">This Month's Performance</h3>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-neutral-700 text-sm mb-1">Total Deliveries</p>
              <p className="text-2xl font-bold">58</p>
            </div>
            <div>
              <p className="text-neutral-700 text-sm mb-1">Revenue</p>
              <p className="text-2xl font-bold">2.8M</p>
            </div>
          </div>
          <div className="mt-4 flex items-center gap-2 text-sm">
            <TrendingUp className="w-4 h-4" />
            <span>23% increase from last month</span>
          </div>
        </div>

        {/* Account Section */}
        <div>
          <h3 className="text-neutral-500 text-sm mb-3 px-1">ACCOUNT</h3>
          <div className="bg-white border border-neutral-200 rounded-2xl overflow-hidden">
            <button className="w-full p-4 flex items-center justify-between hover:bg-neutral-50 transition-all border-b border-neutral-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-yellow-50 rounded-xl flex items-center justify-center">
                  <User className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-neutral-900 font-medium">Edit Profile</span>
              </div>
              <ChevronRight className="w-5 h-5 text-neutral-400" />
            </button>

            <button className="w-full p-4 flex items-center justify-between hover:bg-neutral-50 transition-all border-b border-neutral-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-yellow-50 rounded-xl flex items-center justify-center">
                  <Shield className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-neutral-900 font-medium">Privacy & Security</span>
              </div>
              <ChevronRight className="w-5 h-5 text-neutral-400" />
            </button>

            <button className="w-full p-4 flex items-center justify-between hover:bg-neutral-50 transition-all">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-yellow-50 rounded-xl flex items-center justify-center">
                  <Bell className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-neutral-900 font-medium">Notifications</span>
              </div>
              <ChevronRight className="w-5 h-5 text-neutral-400" />
            </button>
          </div>
        </div>

        {/* Support Section */}
        <div>
          <h3 className="text-neutral-500 text-sm mb-3 px-1">SUPPORT</h3>
          <div className="bg-white border border-neutral-200 rounded-2xl overflow-hidden">
            <button className="w-full p-4 flex items-center justify-between hover:bg-neutral-50 transition-all border-b border-neutral-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-yellow-50 rounded-xl flex items-center justify-center">
                  <HelpCircle className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-neutral-900 font-medium">Help & Support</span>
              </div>
              <ChevronRight className="w-5 h-5 text-neutral-400" />
            </button>

            <button className="w-full p-4 flex items-center justify-between hover:bg-neutral-50 transition-all">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-yellow-50 rounded-xl flex items-center justify-center">
                  <Info className="w-5 h-5 text-yellow-600" />
                </div>
                <span className="text-neutral-900 font-medium">About</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-neutral-400 text-sm">v1.0.0</span>
                <ChevronRight className="w-5 h-5 text-neutral-400" />
              </div>
            </button>
          </div>
        </div>

        {/* Logout Button */}
        <button className="w-full bg-white border-2 border-neutral-200 text-neutral-900 rounded-2xl p-4 hover:border-red-300 hover:bg-red-50 hover:text-red-600 transition-all flex items-center justify-center gap-2 font-medium">
          <LogOut className="w-5 h-5" />
          <span>Logout</span>
        </button>
      </div>
    </div>
  );
}
