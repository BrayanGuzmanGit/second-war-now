# Prompts de preparación de skins

Herramienta integrada imagegen; edición con referenced_image_paths y transparent_background=true. Una llamada por referencia, sin modificar originales.

El prompt exacto siguiente se expandió sustituyendo `${file}` por cada nombre de la tabla.

| ID | file | Salida integrada |
|---|---|---|
| TNQ-02 | Tanque CROMWELL MK VIII.png | Imagenes/Apariencias/TNQ-02.png |
| TNQ-03 | TANQUE T-34-85.png | Imagenes/Apariencias/TNQ-03.png |
| TNQ-04 | Tanque CHURCHILL MK IV.png | Imagenes/Apariencias/TNQ-04.png |
| TNQ-06 | Tanque KV-2.png | Imagenes/Apariencias/TNQ-06.png |
| ENM-01 | ENM-01.jpeg | Imagenes/Apariencias/ENM-01.png |

```text
Use case: precise-object-edit / background-extraction. Edit target: supplied ${file}, exact tank identity, painted colors, insignia and silhouette. Create ONE clean production sprite atlas, square 1024x1024 transparent RGBA. Do NOT invent a different tank. Two separated sprites only, no words outside the original tank markings. TOP HALF y=0..620: complete side-view tank hull, tracks and turret, facing RIGHT, with its MAIN GUN TUBE REMOVED flush at the turret mount. Reconstruct behind tube cleanly, preserve turret and markings, remove background, ground line and border/watermark artifacts. Keep entire tank between x=60..960, y=40..600, no cropped antennas or tracks. BOTTOM HALF y=720..950: the main gun tube ONLY as a separate clean sprite, horizontal pointing RIGHT, breech/root on LEFT, muzzle on RIGHT; no turret, no chassis, no background. Keep barrel between x=120..900. True transparency outside both sprites, including enclosed gaps. Preserve the reference illustration style and tank-specific geometry. Large empty transparent horizontal gap y=630..710 between the two sprites, necessary for AtlasTexture regions. No checkerboard painted into pixels, no cast shadow, no ground, no extra objects. This is an animated 2D game's tank skin; preserve reference identity rather than redesign.
```

La salida real fue de 1254×1254, con alfa residual en márgenes. El catálogo calcula regiones con umbral alfa 0,25 y calibra las piezas a la montura compartida.
