import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  // El pasajero usa DELETE para cancelar
  if (request.method !== 'DELETE') {
    return response.status(405).json({ error: 'Método no permitido' });
  }

  const { viajeId, pasajeroEmail } = request.body;

  try {
    let viajes = await kv.get('viajes') || [];
    const indexViaje = viajes.findIndex(v => v.id == viajeId || v._id == viajeId);

    if (indexViaje === -1) {
      return response.status(404).json({ error: 'Viaje no encontrado' });
    }

    // Filtramos para ELIMINAR al pasajero que cancela
    viajes[indexViaje].pasajeros = (viajes[indexViaje].pasajeros || []).filter(
      p => p.email !== pasajeroEmail
    );

    await kv.set('viajes', viajes);

    return response.status(200).json({ 
      status: 'success', 
      message: 'Reserva cancelada correctamente' 
    });

  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}