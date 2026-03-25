import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  // SI LA APP MÓVIL ENVÍA UN DATO (POST)
  if (request.method === 'POST') {
    const nuevoUsuario = request.body; // El JSON que viene de Flutter
    
    // Guardamos en la lista de usuarios
    await kv.lpush('usuarios', nuevoUsuario); 
    
    return response.status(200).json({ message: 'Usuario guardado!' });
  }

  // SI EL DASHBOARD PIDE LOS DATOS (GET)
  if (request.method === 'GET') {
    const usuarios = await kv.lrange('usuarios', 0, -1); // Trae todos
    return response.status(200).json(usuarios);
  }
}