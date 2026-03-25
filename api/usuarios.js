import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    // GET: Leer la lista de usuarios
    if (request.method === 'GET') {
      const usuarios = await kv.get('usuarios') || [];
      return response.status(200).json(usuarios);
    }

    // POST: Agregar un nuevo usuario
    if (request.method === 'POST') {
      const nuevoUsuario = request.body;
      const usuariosActuales = await kv.get('usuarios') || [];
      usuariosActuales.push(nuevoUsuario);
      await kv.set('usuarios', usuariosActuales);
      return response.status(200).json({ status: 'success' });
    }
  } catch (error) {
    // Si falla, te dirá exactamente por qué en el navegador
    return response.status(500).json({ 
      error: "Error en la función", 
      mensaje: error.message 
    });
  }
}