# 🌐 El Lab Multivendor que Siempre Soñaste

> Red multivendor con stack de telemetría completo — ContainerLab lo descarga todo

Lab multivendor con topología en delta, generación de tráfico profesional con Ixia-c-one,
pruebas simples con Alpine + iPerf3, y telemetría completa con gNMI → Prometheus → Grafana.
Sin licencias. Sin registro. Un solo comando.

---

## 📐 Topología

```
                    [FRR — 10.255.0.2]
                   /  AS65000 (iBGP)  \
         10.0.2.1──                ──10.0.2.6
                 /   10.0.2.0/30    \
        [SR Linux D2L]──10.0.2.8/30──[Cumulus VX]
         10.255.0.1                   10.255.0.3
          e1-3 | e1-4           swp3 | swp4
               |                     |
         ┌─────┴──────────────────────┴─────┐
         │        ixia-c-one                │
         │  eth1 (TX)        eth2 (RX)      │
         │  10.0.1.2/30      10.0.3.2/30    │
         └──────────────────────────────────┘
         [Alpine TX]              [Alpine RX]
          10.0.10.2/30             10.0.11.2/30
          (iPerf client)           (iPerf server)
```

### Rutas disponibles
| Ruta | Saltos | Camino |
|------|--------|--------|
| **1-hop** | 1 | SR Linux → Cumulus (directo, 10.0.2.8/30) |
| **2-hop** | 2 | SR Linux → FRR → Cumulus (vía 10.0.2.0/30 + 10.0.2.4/30) |

### Protocolo de enrutamiento
- **OSPF** (Area 0) como underlay — proporciona alcanzabilidad entre loopbacks
- **iBGP** (AS 65000) como overlay — distribuye prefijos de endpoints
- Loopbacks: 10.255.0.x/32 como router-IDs y endpoints de sesiones iBGP

---

## 🚀 Despliegue

### Prerequisitos
```bash
# Instalar ContainerLab
bash -c "$(curl -sL https://get.containerlab.dev)"

# Verificar Docker
docker --version
```

### Desplegar el lab
```bash
cd multivendor-delta
sudo containerlab deploy -t multivendor-delta.clab.yml
```

ContainerLab descarga automáticamente todas las imágenes — no se requiere registro ni licencia.

### Verificar nodos
```bash
sudo containerlab inspect -t multivendor-delta.clab.yml
```

---

## 🔌 Acceso a los nodos

| Nodo | Tipo | Acceso |
|------|------|--------|
| SR Linux | Nokia 7220 IXR-D2L | `ssh admin@172.100.100.11` (pass: `NokiaSrl1!`) |
| FRR | Linux + FRR | `docker exec -it clab-multivendor-delta-frr1 vtysh` |
| Cumulus VX | NVIDIA Cumulus | `docker exec -it clab-multivendor-delta-cvx1 vtysh` |
| Alpine TX | iPerf cliente | `docker exec -it clab-multivendor-delta-alpine-tx sh` |
| Alpine RX | iPerf servidor | `docker exec -it clab-multivendor-delta-alpine-rx sh` |
| Grafana | Dashboard | http://localhost:3000 (admin/admin) |
| Prometheus | Métricas | http://localhost:9090 |

---

## 📊 Telemetría

La telemetría cubre dos perspectivas complementarias:

| Fuente | Protocolo | Métricas |
|--------|-----------|----------|
| **SR Linux** | gNMI → gNMIc → Prometheus | Interfaces, BGP, OSPF |
| **Ixia-c-one** | REST API → Prometheus | TX/RX frames, pérdida, latencia |

Ambas fuentes alimentan el dashboard de Grafana, auto-provisionado en el despliegue.

---

## 🧪 Demo 1 — iPerf (Prueba simple)

### Desde Alpine TX hacia Alpine RX
```bash
# En Alpine TX
docker exec -it clab-multivendor-delta-alpine-tx sh
iperf3 -c 10.0.11.2 -u -b 10M -t 60

# Ver ruta activa
ip route get 10.0.11.2
```

### Demostración de failover
```bash
# Bajar el enlace directo SR Linux ↔ Cumulus (1-hop)
docker exec -it clab-multivendor-delta-srl-d2l \
  sr_cli "interface ethernet-1/2 admin-state disable"

# El tráfico toma el camino de 2 saltos automáticamente
# Restaurar
docker exec -it clab-multivendor-delta-srl-d2l \
  sr_cli "interface ethernet-1/2 admin-state enable"
```

---

## 🎯 Demo 2 — Ixia-c-one (Tráfico Profesional)

### Instalar otgen CLI
```bash
bash -c "$(curl -sL https://get.otgcdn.net/otgen)"
```

### Iniciar flujo continuo de tráfico
```bash
export OTG_API="https://172.100.100.20:8443"

otgen run --insecure \
  --file ixia/otg-flow.yaml \
  --json --metrics flow | \
otgen transform --metrics flow | \
otgen display --mode table
```

### Forzar tráfico por el camino de 2 saltos (ingeniería de tráfico)
```bash
docker exec -it clab-multivendor-delta-srl-d2l sr_cli << 'EOF'
enter candidate
set network-instance default protocols ospf instance main area 0.0.0.0 interface ethernet-1/2.0 metric 1000
commit now
EOF
```

---

## 📈 Grafana — Visualización

Abrir en el navegador: **http://localhost:3000**
- Usuario: `admin`
- Contraseña: `admin`
- Dashboard: `ContainerLab → Multivendor Delta Lab — Traffic & Telemetry`

### Paneles disponibles
| Panel | Fuente | Descripción |
|-------|--------|-------------|
| Path Selection | SR Linux | Camino activo (1-hop vs 2-hop) |
| Ixia TX vs RX | Ixia | Frames/s transmitidos vs recibidos |
| SR Linux Interface Traffic | SR Linux | Tráfico en bps por interfaz |
| BGP Session States | SR Linux | Estado de sesiones iBGP |
| OSPF Neighbor Count | SR Linux | Vecinos OSPF activos |
| Packet Loss | Ixia | Pérdida de paquetes por flujo (%) |
| 1-hop vs 2-hop Comparison | SR Linux | Carga comparada entre los dos caminos |

---

## 🗑️ Destruir el lab
```bash
sudo containerlab destroy -t multivendor-delta.clab.yml --cleanup
```

---

## 📁 Estructura del proyecto
```
multivendor-delta/
├── multivendor-delta.clab.yml    # Topología principal
├── frr1/
│   ├── daemons                   # FRR daemons habilitados
│   └── frr.conf                  # Config OSPF + iBGP
├── srl-d2l/
│   ├── config.json               # SR Linux startup config
│   └── gnmic.yml                 # Colector gNMI → Prometheus
├── cvx1/
│   └── frr.conf                  # Config OSPF + iBGP Cumulus
├── ixia/
│   └── otg-flow.yaml             # Definición de flujos Ixia-c-one
├── prometheus/
│   └── prometheus.yml            # Config scraping
└── grafana/
    └── provisioning/
        ├── datasources/
        │   └── datasource.yml    # Prometheus como datasource
        └── dashboards/
            ├── dashboard.yml     # Proveedor de dashboards
            └── multivendor-delta.json  # Dashboard principal
```
