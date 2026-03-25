import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  if (request.method !== 'POST') {
    return response.status(405).json({ error: 'Método no permitido' });
  }

  const { viajeId, pasajeroEmail, accion } = request.body;

  try {
    // 1. Obtener todos los viajes
    let viajes = await kv.get('viajes') || [];

    // 2. Encontrar el viaje específico
    const indexViaje = viajes.findIndex(v => v.id == viajeId || v._id == viajeId);
    if (indexViaje === -1) {
      return response.status(404).json({ error: 'Viaje no encontrado' });
    }

    let viaje = viajes[indexViaje];
    if (!viaje.pasajeros) viaje.pasajeros = [];

    if (accion === 'aceptar') {
      // Validar capacidad
      const aceptados = viaje.pasajeros.filter(p => p.estado === 'confirmado').length;
      if (aceptados >= parseInt(viaje.capacidad)) {
        return response.status(400).json({ error: 'El viaje ya está lleno' });
      }

      // Cambiar estado del pasajero a confirmado
      viaje.pasajeros = viaje.pasajeros.map(p => 
        p.email === pasajeroEmail ? { ...p, estado: 'confirmado' } : p
      );
    } 
    else if (accion === 'rechazar') {
      // Eliminar al pasajero de la lista
      viaje.pasajeros = viaje.pasajeros.filter(p => p.email !== pasajeroEmail);
    }

    // 3. Actualizar el array global y guardar en KV
    viajes[indexViaje] = viaje;
    await kv.set('viajes', viajes);

    return response.status(200).json({ status: 'success', message: `Solicitud ${accion}ada` });

  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}