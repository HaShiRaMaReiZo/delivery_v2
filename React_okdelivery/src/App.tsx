import { useState } from 'react';
import { Home } from './components/Home';
import { RegisterPackage } from './components/RegisterPackage';
import { DraftPackages } from './components/DraftPackages';
import { TrackPackages } from './components/TrackPackages';
import { Profile } from './components/Profile';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('home');

  const renderScreen = () => {
    switch (currentScreen) {
      case 'home':
        return <Home onNavigate={setCurrentScreen} />;
      case 'register':
        return <RegisterPackage onNavigate={setCurrentScreen} />;
      case 'draft':
        return <DraftPackages onNavigate={setCurrentScreen} />;
      case 'track':
        return <TrackPackages onNavigate={setCurrentScreen} />;
      case 'profile':
        return <Profile onNavigate={setCurrentScreen} />;
      default:
        return <Home onNavigate={setCurrentScreen} />;
    }
  };

  return (
    <div className="min-h-screen bg-neutral-50">
      <div className="max-w-md mx-auto bg-white min-h-screen relative pb-24">
        {renderScreen()}
        
        {/* Bottom Navigation */}
        <nav className="fixed bottom-0 left-0 right-0 max-w-md mx-auto bg-white border-t border-neutral-200 shadow-lg">
          <div className="flex items-center justify-around">
            <button
              onClick={() => setCurrentScreen('home')}
              className={`flex flex-col items-center gap-1.5 px-6 py-3 transition-all ${
                currentScreen === 'home' 
                  ? 'text-yellow-500' 
                  : 'text-neutral-400 hover:text-neutral-600'
              }`}
            >
              <svg className="w-6 h-6" fill={currentScreen === 'home' ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={currentScreen === 'home' ? 0 : 2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              <span className="text-xs">Home</span>
              {currentScreen === 'home' && <div className="w-1 h-1 bg-yellow-500 rounded-full"></div>}
            </button>
            
            <button
              onClick={() => setCurrentScreen('draft')}
              className={`flex flex-col items-center gap-1.5 px-6 py-3 transition-all ${
                currentScreen === 'draft' 
                  ? 'text-yellow-500' 
                  : 'text-neutral-400 hover:text-neutral-600'
              }`}
            >
              <svg className="w-6 h-6" fill={currentScreen === 'draft' ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={currentScreen === 'draft' ? 0 : 2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <span className="text-xs">Draft</span>
              {currentScreen === 'draft' && <div className="w-1 h-1 bg-yellow-500 rounded-full"></div>}
            </button>
            
            <button
              onClick={() => setCurrentScreen('track')}
              className={`flex flex-col items-center gap-1.5 px-6 py-3 transition-all ${
                currentScreen === 'track' 
                  ? 'text-yellow-500' 
                  : 'text-neutral-400 hover:text-neutral-600'
              }`}
            >
              <svg className="w-6 h-6" fill={currentScreen === 'track' ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={currentScreen === 'track' ? 0 : 2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={currentScreen === 'track' ? 0 : 2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
              <span className="text-xs">Track</span>
              {currentScreen === 'track' && <div className="w-1 h-1 bg-yellow-500 rounded-full"></div>}
            </button>
            
            <button
              onClick={() => setCurrentScreen('profile')}
              className={`flex flex-col items-center gap-1.5 px-6 py-3 transition-all ${
                currentScreen === 'profile' 
                  ? 'text-yellow-500' 
                  : 'text-neutral-400 hover:text-neutral-600'
              }`}
            >
              <svg className="w-6 h-6" fill={currentScreen === 'profile' ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={currentScreen === 'profile' ? 0 : 2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
              </svg>
              <span className="text-xs">Profile</span>
              {currentScreen === 'profile' && <div className="w-1 h-1 bg-yellow-500 rounded-full"></div>}
            </button>
          </div>
        </nav>
      </div>
    </div>
  );
}
