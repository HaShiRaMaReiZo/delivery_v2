import { Clock, Edit, Trash2, Send } from 'lucide-react';

type Screen = 'home' | 'draft' | 'track' | 'profile' | 'register';

interface DraftPackagesProps {
  onNavigate: (screen: Screen) => void;
}

interface Draft {
  id: string;
  date: string;
  packages: number;
  totalAmount: number;
  lastModified: string;
}

export function DraftPackages({ onNavigate }: DraftPackagesProps) {
  const drafts: Draft[] = [
    {
      id: '1',
      date: 'Today',
      packages: 3,
      totalAmount: 205000,
      lastModified: '2 hours ago'
    },
    {
      id: '2',
      date: 'Yesterday',
      packages: 1,
      totalAmount: 45000,
      lastModified: '1 day ago'
    },
  ];

  return (
    <div className="flex flex-col min-h-screen bg-neutral-50">
      {/* Header */}
      <header className="bg-gradient-to-r from-neutral-900 to-neutral-800 text-white px-6 py-6 sticky top-0 z-10 shadow-lg">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-white text-xl">Draft Packages</h1>
            <p className="text-yellow-400 text-sm mt-0.5">{drafts.length} saved drafts</p>
          </div>
          <button className="p-2 hover:bg-white hover:bg-opacity-10 rounded-lg transition-all">
            <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </button>
        </div>
      </header>

      <div className="flex-1 px-6 py-6 space-y-4">
        {/* Draft Items */}
        {drafts.map((draft) => (
          <div key={draft.id} className="bg-white border border-neutral-200 rounded-2xl p-5 hover:border-yellow-400 hover:shadow-lg transition-all">
            <div className="flex items-start justify-between mb-4">
              <div>
                <div className="flex items-center gap-2 mb-2">
                  <Clock className="w-4 h-4 text-yellow-600" />
                  <h3 className="text-neutral-900 font-semibold">{draft.date}</h3>
                </div>
                <p className="text-neutral-500 text-sm">Last modified: {draft.lastModified}</p>
              </div>
              <div className="px-3 py-1.5 bg-yellow-50 text-yellow-700 rounded-lg text-sm font-medium border border-yellow-200">
                {draft.packages} {draft.packages === 1 ? 'package' : 'packages'}
              </div>
            </div>

            {/* Amount */}
            <div className="bg-neutral-50 rounded-xl p-4 mb-4">
              <p className="text-neutral-500 text-sm mb-1">Total Amount</p>
              <p className="text-neutral-900 text-2xl font-semibold">{draft.totalAmount.toLocaleString()} MMK</p>
            </div>

            {/* Actions */}
            <div className="grid grid-cols-3 gap-2">
              <button className="bg-yellow-400 text-neutral-900 rounded-xl py-2.5 hover:bg-yellow-500 transition-all flex items-center justify-center gap-2 font-medium">
                <Edit className="w-4 h-4" />
                Edit
              </button>
              <button className="bg-neutral-100 text-neutral-900 rounded-xl py-2.5 hover:bg-neutral-200 transition-all flex items-center justify-center gap-2 font-medium">
                <Send className="w-4 h-4" />
                Submit
              </button>
              <button className="bg-white border border-neutral-200 text-neutral-600 rounded-xl py-2.5 hover:border-red-300 hover:bg-red-50 hover:text-red-600 transition-all flex items-center justify-center gap-2">
                <Trash2 className="w-4 h-4" />
                Delete
              </button>
            </div>
          </div>
        ))}

        {/* Info Box */}
        <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 flex gap-3">
          <svg className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <div>
            <p className="text-neutral-900 text-sm font-medium mb-1">Draft Auto-Save</p>
            <p className="text-neutral-600 text-sm">Your drafts are automatically saved and can be completed later.</p>
          </div>
        </div>
      </div>
    </div>
  );
}
