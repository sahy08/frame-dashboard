# Frame Dashboard

Slideshow + home automation dashboard para ARZOPA Android frame con Fully Kiosk Browser.

## Arquitectura

```
Ubuntu Server 192.168.0.102
├── nginx :8080          ← sirve el dashboard
├── /opt/dashboard/      ← HTML, config, scripts
└── /opt/slideshow/      ← fotos sincronizadas desde Google Photos

ARZOPA Frame 192.168.0.21
└── Fully Kiosk Browser  ← carga http://192.168.0.102:8080/
```

## Prerequisites

- nginx instalado y corriendo
- Python 3
- rclone (setup.sh lo verifica)

## Setup

```bash
sudo cp -r ~/dashboard /opt/dashboard
chmod +x /opt/dashboard/setup.sh
sudo /opt/dashboard/setup.sh
```

El script pregunta:
1. Nombre exacto del álbum en Google Photos
2. Puerto (default: 8080)
3. Directorio base (default: /opt/dashboard)

Luego autentica rclone, hace el primer sync, genera `photos.json`, e imprime el snippet nginx listo.

## Nginx

Copiar el snippet que imprime setup.sh:

```bash
sudo nano /etc/nginx/conf.d/dashboard.conf
# pegar snippet
sudo nginx -t && sudo nginx -s reload
```

Si el puerto 8080 ya está ocupado, el snippet en `nginx.conf.snippet` incluye una alternativa con subpath `/frame/`.

## Cron (sync nocturno)

```bash
crontab -e
# agregar:
0 3 * * * /opt/dashboard/sync_and_refresh.sh >> /opt/dashboard/cron.log 2>&1
```

## Personalizar botones

Editar `/opt/dashboard/config.json`:
- Reemplazar `192.168.0.X` con la IP real de Home Assistant
- Cada `webhook_on`/`webhook_off` debe estar configurado en HA como **Webhook trigger**
- Íconos disponibles: `lightbulb`, `fan`, `tv`, `lock`, `plug`, `music`, `thermo`, `camera`, `switch`
- `is_toggle: false` → botón momentáneo (solo envía `webhook_on`)

## Fully Kiosk (frame Android)

1. Instalar **Fully Kiosk Browser** (Play Store o APK)
2. Settings → **Start URL**: `http://192.168.0.102:8080/`
3. Kiosk Mode: **ON**
4. Screen On While Plugged In: **ON**
5. Start on Boot: **ON**
6. Motion Detection (wake on motion): ON — opcional para el sensor táctil

## Troubleshooting

**Fotos no aparecen**
```bash
ls /opt/slideshow/                    # verificar que hay archivos
cat /opt/dashboard/photos.json        # verificar que el JSON tiene entradas
sudo tail -f /var/log/nginx/error.log # errores nginx
```

**Botones no responden**
- Fully Kiosk → Settings → Advanced → Remote DevTools → abrir en Chrome
- Verificar que la IP en `config.json` es correcta
- Verificar que el webhook existe en HA: Settings → Automations → buscar por webhook ID

**CORS errors en DevTools**
```bash
sudo nginx -t && sudo nginx -s reload
# verificar que el bloque del dashboard tiene los add_header Access-Control-*
```

**rclone auth expirada**
```bash
rclone config reconnect gphotos:
# o correr setup.sh de nuevo (idempotente)
```

**Fotos lentas / frame se traba**
```bash
# Redimensionar a resolución del frame (1024x600) para reducir RAM:
sudo apt install imagemagick
find /opt/slideshow -name "*.jpg" -exec mogrify -resize 1024x600\> {} \;
python3 /opt/dashboard/generate_photos_json.py  # regenerar lista
```
