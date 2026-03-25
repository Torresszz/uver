import { kv } from '@vercel/kv';

export default async function handler(request, response) {
  try {
    // 1. GET: Listar todos los usuarios
    if (request.method === 'GET') {
      const usuarios = await kv.get('usuarios') || [];
      return response.status(200).json(usuarios);
    }

    // 2. POST: Registro (desde Flutter)
    if (request.method === 'POST') {
      const nuevoUsuario = request.body;
      let usuarios = await kv.get('usuarios') || [];
      
      // Evitamos que se registre el mismo correo dos veces
      const yaExiste = usuarios.some(u => u.email === nuevoUsuario.email);
      if (yaExiste) {
        return response.status(400).json({ error: "El usuario ya existe" });
      }

      usuarios.push(nuevoUsuario);
      await kv.set('usuarios', usuarios);
      return response.status(200).json({ status: 'success' });
    }

    // 3. DELETE: Eliminar un registro (desde el Dashboard Web)
    if (request.method === 'DELETE') {
      const { email } = request.body; // Recibimos el correo a borrar

      if (!email) {
        return response.status(400).json({ error: "Falta el email del usuario" });
      }

      let usuarios = await kv.get('usuarios') || [];
      
      // Filtramos la lista para quitar al usuario que queremos borrar
      const nuevaLista = usuarios.filter(u => u.email !== email);
      
      await kv.set('usuarios', nuevaLista);
      return response.status(200).json({ status: 'success', message: 'Usuario eliminado' });
    }

    // Si mandan otro método (PUT, etc)
    return response.status(405).json({ error: "Método no permitido" });

  } catch (error) {
    return response.status(500).json({ 
      error: "Error en el servidor", 
      mensaje: error.message 
    });
  }
}