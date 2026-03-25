import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    if (request.method === 'GET') {
      const viajes = await kv.get('viajes') || [];
      return response.status(200).json(viajes);
    }

    if (request.method === 'POST') {
      const nuevoViaje = request.body;
      const viajesActuales = await kv.get('viajes') || [];
      viajesActuales.push({ ...nuevoViaje, id: Date.now() }); // Le damos un ID único
      await kv.set('viajes', viajesActuales);
      return response.status(200).json({ status: 'success' });
    }
  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}