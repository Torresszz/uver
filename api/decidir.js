import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).end();

  const { viajeId, pasajeroEmail, accion } = request.body;

  try {
    let viajes = await kv.get('viajes') || [];
    
    // 1. Buscamos el viaje (asegurando que ambos sean String)
    const index = viajes.findIndex(v => v.id.toString() === viajeId.toString());
    
    if (index === -1) return response.status(404).json({ error: 'Viaje no encontrado' });

    // 2. Buscamos al pasajero en la lista de ese viaje
    const pIndex = viajes[index].pasajeros.findIndex(
      p => p.email.toLowerCase().trim() === pasajeroEmail.toLowerCase().trim()
    );

    if (pIndex === -1) return response.status(404).json({ error: 'Pasajero no encontrado en este viaje' });

    // 3. Traducimos la 'accion' de Flutter al 'estado' de la DB
    // Importante: Usamos 'confirmado' para que la SearchPage lo cuente como asiento ocupado
    if (accion === 'aceptar') {
      viajes[index].pasajeros[pIndex].estado = 'confirmado';
    } else if (accion === 'rechazar') {
      viajes[index].pasajeros[pIndex].estado = 'rechazado';
    } else {
      return response.status(400).json({ error: 'Acción no válida' });
    }

    // 4. Guardamos los cambios
    await kv.set('viajes', viajes);
    return response.status(200).json({ status: 'success' });

  } catch (error) {
    console.error(error);
    return response.status(500).json({ error: error.message });
  }
}