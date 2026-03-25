import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  // 1. Validar el método HTTP
  if (request.method !== 'DELETE') {
    return response.status(405).json({ error: 'Método no permitido. Usa DELETE.' });
  }

  // 2. Extraer datos del cuerpo (Body)
  const { viajeId, pasajeroEmail } = request.body;

  // Validación de datos básicos
  if (!viajeId || !pasajeroEmail) {
    return response.status(400).json({ error: 'Faltan datos obligatorios (viajeId o pasajeroEmail)' });
  }

  try {
    // 3. Obtener la lista de viajes
    let viajes = await kv.get('viajes') || [];

    // 4. Buscar el índice del viaje (Convertimos a String para asegurar coincidencia)
    const indexViaje = viajes.findIndex(
      v => v.id.toString() === viajeId.toString()
    );

    if (indexViaje === -1) {
      return response.status(404).json({ error: 'Viaje no encontrado' });
    }

    // 5. Normalizar el email para la búsqueda
    const emailACancelar = pasajeroEmail.toLowerCase().trim();

    // Verificamos si el pasajero realmente existe en ese viaje
    const existePasajero = (viajes[indexViaje].pasajeros || []).some(
      p => p.email.toLowerCase().trim() === emailACancelar
    );

    if (!existePasajero) {
      return response.status(404).json({ error: 'El pasajero no tiene una reserva en este viaje' });
    }

    // 6. Filtrar el array para ELIMINAR al pasajero
    // Conservamos a todos menos al que coincide con el email recibido
    viajes[indexViaje].pasajeros = viajes[indexViaje].pasajeros.filter(
      p => p.email.toLowerCase().trim() !== emailACancelar
    );

    // 7. Guardar los cambios en Vercel KV
    await kv.set('viajes', viajes);

    return response.status(200).json({ 
      status: 'success', 
      message: 'Reserva cancelada y cupo liberado (si estaba confirmado)' 
    });

  } catch (error) {
    console.error("Error en cancelar-reserva:", error);
    return response.status(500).json({ error: 'Error interno del servidor: ' + error.message });
  }
}