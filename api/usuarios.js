import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    // Si la petición es GET (Leer usuarios)
    if (request.method === 'GET') {
      const usuarios = await kv.get('usuarios') || [];
      return response.status(200).json(usuarios);
    }

    // Si la petición es POST (Guardar usuario)
    if (request.method === 'POST') {
      const nuevoUsuario = request.body;
      const usuariosActuales = await kv.get('usuarios') || [];
      usuariosActuales.push(nuevoUsuario);
      await kv.set('usuarios', usuariosActuales);
      return response.status(200).json({ message: 'Usuario guardado' });
    }
  } catch (error) {
    console.error(error);
    return response.status(500).json({ error: 'Fallo la conexión con Redis', detalles: error.message });
  }
}