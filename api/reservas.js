import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).end();

  const { viajeId, pasajeroEmail, pasajeroNombre } = request.body;

  try {
    let viajes = await kv.get('viajes') || [];
    
    // Buscamos el viaje por el ID numérico que genera Date.now()
    const index = viajes.findIndex(v => v.id == viajeId);
    
    if (index === -1) return response.status(404).json({ error: 'Viaje no encontrado' });

    // Inicializamos array de pasajeros si no existe
    if (!viajes[index].pasajeros) viajes[index].pasajeros = [];

    // Evitar duplicados (que el mismo usuario no pida el mismo viaje dos veces)
    const yaExiste = viajes[index].pasajeros.some(p => p.email === pasajeroEmail);
    if (yaExiste) return response.status(400).json({ error: 'Ya solicitaste este viaje' });

    // Agregamos al pasajero con estado inicial 'pendiente'
    viajes[index].pasajeros.push({
      email: pasajeroEmail,
      nombre: pasajeroNombre,
      estado: 'pendiente'
    });

    await kv.set('viajes', viajes);
    return response.status(200).json({ status: 'success' });

  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}