# 🚀 HexStrike AI - Istruzioni Esecuzione Container

## ⚙️ Riavvio Container con Timeout Esteso

Il server è stato configurato con timeout esteso per scansioni lunghe (Nmap, AutoRecon, ecc.).

### 🔄 Riavvio Rapido
```bash
cd /home/argan/Desktop/WORKSPACE_AI/WORKSPACE_AGENT/hexstrike-ai/docker

# Stop container attuale
docker-compose down

# Restart con nuova configurazione
docker-compose up -d

# Verifica logs
docker-compose logs -f --tail=100
```

### 🎯 Configurazioni Applicate

#### 1. **Timeout Esteso**
- **Prima**: 300 secondi (5 minuti)
- **Dopo**: 3600 secondi (1 ora) - configurabile via COMMAND_TIMEOUT

#### 2. **Flask Threading**
- **threaded=True**: Gestione richieste concorrenti
- **use_reloader=False**: Stabilità in produzione

#### 3. **Docker Privileged Mode**
- **privileged: true**: Compatibilità garantita con tutti i 127 tool

### 🔧 Sovrascrivere Timeout (Opzionale)

Per timeout ancora più lunghi (es. AutoRecon su /16):

```bash
# Modifica docker-compose.yml aggiungendo:
environment:
  - PYTHONUNBUFFERED=1
  - COMMAND_TIMEOUT=7200  # 2 ore

# Poi riavvia
docker-compose down && docker-compose up -d
```

### ✅ Verifica Funzionamento

```bash
# 1. Verifica privileged mode
docker inspect hexstrike-mcp-server | grep -i privileged

# 2. Controlla timeout nel banner di avvio
docker-compose logs | grep "Command Timeout"

# 3. Test di base
curl http://localhost:8888/health
```

### 📊 Test Scansione LAN Completa

```bash
# Dalla chat Claude, esegui:
hexstrike-ai:nmap_scan({
  "target": "192.168.1.0/24",
  "scan_type": "-sS -sV -O",
  "ports": "",
  "additional_args": "-Pn -T3 --max-retries 3 --host-timeout 10m --max-rtt-timeout 3000ms --initial-rtt-timeout 1000ms -e wlo1"
})
```

**Tempo stimato**: 10-30 minuti per subnet /24 con parametri ottimizzati

### ⚠️ Note Importanti

1. **Host con alta latenza (>200ms)**:
   - Usa `-T3` o `-T2` invece di `-T4`
   - Aumenta `--max-rtt-timeout` a 3000-5000ms
   - Rimuovi `--min-hostgroup` (causa skip)

2. **Host che bloccano discovery**:
   - **Sempre usare `-Pn`** per skip host discovery
   - Alcuni host (es. 192.168.1.249) bloccano probe Nmap ma rispondono a ping

3. **Scansioni >1 ora**:
   - Aumenta `COMMAND_TIMEOUT` nel docker-compose.yml
   - Considera di eseguire scansioni in background

### 🐛 Troubleshooting

**Problema**: "No result received from client-side tool execution"
- **Causa**: Timeout troppo basso
- **Fix**: Aumentare COMMAND_TIMEOUT come sopra

**Problema**: "0 hosts up" in subnet /24
- **Causa**: Parametri timing troppo aggressivi
- **Fix**: Vedere guida `/docker/NMAP-SCAN-GUIDE.md`

**Problema**: Container si riavvia continuamente
- **Causa**: Errore nel server Python
- **Fix**: `docker-compose logs` per vedere l'errore

### 📁 File Modificati

1. `/docker/docker-compose.yml` - privileged: true
2. `/hexstrike_server.py` - COMMAND_TIMEOUT=3600, threaded=True
3. `/docker/NMAP-SCAN-GUIDE.md` - Guida completa scansioni

---
**Ultima modifica**: 2025-10-10
**Versione HexStrike**: v6.0
