// Este código buscaría todas las reservas donde el viaje_id pertenece al chofer
const solicitudes = await reservas.find({ viaje_id: idDelViajeDelChofer }).toArray();