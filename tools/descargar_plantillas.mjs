import { mkdir, writeFile } from 'node:fs/promises';
import { inflateRawSync } from 'node:zlib';

// Lee el directorio ZIP remoto y descarga únicamente las dos plantillas Windows.
// Evita descargar el paquete completo de plataformas (más de 1 GB).
const origen = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz';
const enlace = await fetch(origen, { method: 'HEAD', signal: AbortSignal.timeout(15000) });
if (!enlace.ok) throw new Error(`Descarga oficial no disponible: HTTP ${enlace.status}`);
const recurso = enlace.url;
const longitudArchivo = Number(enlace.headers.get('content-length'));
if (!Number.isSafeInteger(longitudArchivo) || longitudArchivo < 65557) throw new Error('Tamaño remoto inválido');
async function rango(inicio, fin) {
  const respuesta = await fetch(recurso, {
    headers: { Range: inicio < 0 ? `bytes=${inicio}` : `bytes=${inicio}-${fin ?? ''}` },
    signal: AbortSignal.timeout(45000),
  });
  if (respuesta.status !== 206) throw new Error(`El servidor no admite rango: HTTP ${respuesta.status}`);
  return Buffer.from(await respuesta.arrayBuffer());
}

function crc32(datos) {
  let crc = 0xffffffff;
  for (const byte of datos) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ (crc & 1 ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

const cola = await rango(longitudArchivo - 65557, longitudArchivo - 1);
let fin = -1;
for (let i = cola.length - 22; i >= 0; i--) {
  if (cola.readUInt32LE(i) === 0x06054b50 && i + 22 + cola.readUInt16LE(i + 20) === cola.length) {
    fin = i;
    break;
  }
}
if (fin < 0) throw new Error('Directorio ZIP no encontrado');
const tamano = cola.readUInt32LE(fin + 12);
const desplazamiento = cola.readUInt32LE(fin + 16);
const directorio = await rango(desplazamiento, desplazamiento + tamano - 1);
await mkdir('.godot/plantillas', { recursive: true });
let descargadas = 0;
for (let i = 0; i < directorio.length;) {
  if (directorio.readUInt32LE(i) !== 0x02014b50) throw new Error('Entrada ZIP inválida');
  const longitud = directorio.readUInt16LE(i + 28);
  const nombre = directorio.subarray(i + 46, i + 46 + longitud).toString();
  const destino = nombre.split('/').at(-1);
  if (['windows_debug_x86_64.exe', 'windows_release_x86_64.exe'].includes(destino)) {
    const metodo = directorio.readUInt16LE(i + 10);
    const crc = directorio.readUInt32LE(i + 16);
    const comprimido = directorio.readUInt32LE(i + 20);
    const expandido = directorio.readUInt32LE(i + 24);
    const offset = directorio.readUInt32LE(i + 42);
    const cabecera = await rango(offset, offset + 29);
    if (cabecera.readUInt32LE(0) !== 0x04034b50) throw new Error('Cabecera ZIP inválida');
    const comienzo = offset + 30 + cabecera.readUInt16LE(26) + cabecera.readUInt16LE(28);
    console.log(`Descargando ${destino}: ${comprimido} bytes`);
    const contenido = await rango(comienzo, comienzo + comprimido - 1);
    const datos = metodo === 8 ? inflateRawSync(contenido) : contenido;
    if (datos.length !== expandido || crc32(datos) !== crc) throw new Error(`Integridad incorrecta: ${destino}`);
    await writeFile(`.godot/plantillas/${destino}`, datos);
    descargadas++;
    console.log(`Verificada ${destino}`);
  }
  i += 46 + longitud + directorio.readUInt16LE(i + 30) + directorio.readUInt16LE(i + 32);
}
if (descargadas !== 2) throw new Error('Faltan plantillas Windows x64');
