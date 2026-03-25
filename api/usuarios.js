import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    if (request.method === 'GET') {
      const usuarios = await kv.get('usuarios') || [];
      return response.status(200).json(usuarios);
    }

    if (request.method === 'POST') {
      const nuevoUsuario = request.body;
      const usuariosActuales = await kv.get('usuarios') || [];
      usuariosActuales.push(nuevoUsuario);
      await kv.set('usuarios', usuariosActuales);
      return response.status(200).json({ status: 'success' });
    }
  } catch (error) {
    return response.status(500).json({ error: error.message });
  }
}