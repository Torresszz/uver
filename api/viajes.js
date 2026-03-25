import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    if (request.method === 'GET') {
      const viajes = await kv.get('viajes') || [];
      return response.status(200).json(viajes);
    }

    // En tu api/viajes.js (sección POST)
if (request.method === 'POST') {
  const nuevoViaje = request.body;
  const viajesActuales = await kv.get('viajes') || [];
  
  // Aseguramos que el nuevo viaje tenga una lista de pasajeros vacía al nacer
  const viajeAGuardar = { 
    ...nuevoViaje, 
    id: Date.now(), 
    pasajeros: [] // <--- Importante inicializarlo
  };

  viajesActuales.push(viajeAGuardar);
  await kv.set('viajes', viajesActuales);
  return response.status(200).json({ status: 'success' });
}
  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}