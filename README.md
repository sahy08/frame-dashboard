# Frame Dashboard

Slideshow + home automation dashboard for ARZOPA Android photo frame with Fully Kiosk Browser.

## Architecture

```
Ubuntu Server 192.168.0.X
├── nginx :80            ← serves the dashboard (slideshow.appears.cl)
├── /opt/dashboard/      ← HTML, config, scripts
└── /opt/slideshow/      ← photos synced via Syncthing

ARZOPA Frame 192.168.0.Y
└── Fully Kiosk Browser  ← loads http://slideshow.appears.cl
```

## Prerequisites

- nginx installed and running
- Python 3
- Syncthing (for photo sync from phone/PC)

## Setup

```bash
sudo mkdir -p /opt/dashboard /opt/slideshow
sudo chown $USER:$USER /opt/dashboard /opt/slideshow
sudo cp -r /path/to/repo/* /opt/dashboard/
```

Copy the nginx snippet to your server:

```bash
sudo cp /opt/dashboard/nginx.conf.snippet /etc/nginx/conf.d/dashboard.conf
sudo nginx -t && sudo nginx -s reload
```

## Photo sync (Syncthing)

Install Syncthing on the server and on your PC/phone. Share a folder pointing to `/opt/slideshow/` on the server. Photos dropped into the paired folder on your device sync automatically.

The watcher service (`watch_slideshow.sh`) detects new files and regenerates `photos.json` automatically.

Install the watcher as a systemd service:

```bash
sudo cp /opt/dashboard/watch_slideshow.sh /opt/dashboard/
sudo tee /etc/systemd/system/slideshow-watcher.service > /dev/null <<EOF
[Unit]
Description=Slideshow photo watcher
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=/opt/dashboard/watch_slideshow.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now slideshow-watcher
```

## Weather overlay

`fetch_weather.sh` pulls current temperature and city from wttr.in and saves to `weather.json`. Add a cron job to keep it updated:

```bash
*/30 * * * * /opt/dashboard/fetch_weather.sh >> /opt/dashboard/cron.log 2>&1
```

## Customize buttons

Edit `/opt/dashboard/config.json`:
- Replace `192.168.0.X:8123` with your Home Assistant IP
- Each `webhook_on`/`webhook_off` must be configured in HA as a **Webhook trigger**
- Available icons: `lightbulb`, `fan`, `tv`, `lock`, `plug`, `music`, `thermo`, `camera`, `switch`
- `is_toggle: false` → momentary button (only fires `webhook_on`)

## Fully Kiosk (Android frame)

1. Install **Fully Kiosk Browser**
2. Settings → **Start URL**: `http://slideshow.appears.cl` (or your server IP/port)
3. Kiosk Mode: **ON**
4. Screen On While Plugged In: **ON**
5. Start on Boot: **ON**

## Usage

| Action | Result |
|---|---|
| Tap / click | Open dashboard |
| Swipe left | Next photo |
| Swipe right | Previous photo |
| 60s idle on dashboard | Return to slideshow |
| "Ver Fotos" button | Return to slideshow |

## Troubleshooting

**No photos showing**
```bash
ls /opt/slideshow/
cat /opt/dashboard/photos.json
sudo tail -f /var/log/nginx/error.log
```

**Buttons not responding**
- Open Fully Kiosk Remote DevTools in Chrome
- Verify webhook URLs in `config.json`
- Verify the webhook exists in HA

**CORS errors**
```bash
sudo nginx -t && sudo nginx -s reload
# Ensure dashboard nginx block has Access-Control-Allow-Origin headers
```

**Photos slow to load**
```bash
# Resize to frame resolution to reduce RAM usage
sudo apt install imagemagick
find /opt/slideshow -name "*.jpg" -exec mogrify -resize 1024x600\> {} \;
python3 /opt/dashboard/generate_photos_json.py
```
