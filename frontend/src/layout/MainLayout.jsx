import { useAuth } from '../context/AuthContext';

export default function MainLayout({ children }) {
    const { user, logout } = useAuth();

    return (
        <div className="flex h-screen bg-gray-100">
            {/* Sidebar */}
            <aside className="w-64 bg-slate-800 text-white flex flex-col">
                <div className="p-4 text-xl font-bold border-b border-slate-700">PlasticERP</div>
                <nav className="flex-1 p-4 space-y-2">
                    <a href="/" className="block py-2 px-4 rounded hover:bg-slate-700">Dashboard</a>
                    <a href="/users" className="block py-2 px-4 rounded hover:bg-slate-700">Usuarios</a>
                    {/* Add more links here */}
                </nav>
                <div className="p-4 border-t border-slate-700">
                    <p className="text-sm text-slate-400">Logueado como:</p>
                    <p className="font-semibold">{user?.username}</p>
                    <button
                        onClick={logout}
                        className="mt-2 w-full text-sm bg-red-600 py-1 rounded hover:bg-red-700"
                    >
                        Cerrar Sesión
                    </button>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 overflow-y-auto p-8">
                {children}
            </main>
        </div>
    );
}
