export default function Dashboard() {
    return (
        <div>
            <h1 className="text-3xl font-bold mb-4">Dashboard</h1>
            <p className="text-gray-600">Bienvenido al sistema PlasticERP.</p>
            <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="bg-white p-6 rounded shadow">
                    <h3 className="font-bold text-xl mb-2">Producción Hoy</h3>
                    <p className="text-3xl font-bold text-blue-600">0 kg</p>
                </div>
                <div className="bg-white p-6 rounded shadow">
                    <h3 className="font-bold text-xl mb-2">Pedidos Pendientes</h3>
                    <p className="text-3xl font-bold text-orange-600">0</p>
                </div>
                <div className="bg-white p-6 rounded shadow">
                    <h3 className="font-bold text-xl mb-2">OEE General</h3>
                    <p className="text-3xl font-bold text-green-600">0%</p>
                </div>
            </div>
        </div>
    );
}
