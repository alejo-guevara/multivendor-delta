#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ContainerLab Multivendor Delta — Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Groups (ensure current user has access) ───────────────
echo "→ Configuring groups..."
sudo groupadd -f clab_admins
sudo usermod -aG clab_admins,docker "$(whoami)"

# ── Versions ──────────────────────────────────────────────
echo "→ ContainerLab: $(containerlab version 2>/dev/null | grep -i version | head -1 || echo 'installed')"
echo "→ Docker:       $(docker --version)"

# ── Pre-pull Docker images ────────────────────────────────
echo "→ Pre-pulling lab images..."
images=(
  "ghcr.io/nokia/srlinux:latest"
  "frrouting/frr:latest"
  "networkop/cx:4.4.0"
  "alpine:latest"
  "prom/prometheus:latest"
  "grafana/grafana:latest"
  "ghcr.io/openconfig/gnmic:latest"
)
for img in "${images[@]}"; do
  echo "  pulling $img..."
  docker pull "$img" || echo "  ⚠ Failed to pull $img — will pull on deploy"
done

# ── Handy aliases ─────────────────────────────────────────
grep -q 'clab-deploy' ~/.bashrc || cat >> ~/.bashrc << 'ALIASES'

# ContainerLab shortcuts
alias clab-deploy='sudo containerlab deploy -t multivendor-delta.clab.yml'
alias clab-destroy='sudo containerlab destroy -t multivendor-delta.clab.yml --cleanup'
alias clab-inspect='sudo containerlab inspect -t multivendor-delta.clab.yml'
alias clab-redeploy='sudo containerlab deploy -t multivendor-delta.clab.yml -c'

# Quick node access
alias srl='ssh admin@clab-multivendor-delta-srl-d2l'
alias frr='docker exec -it clab-multivendor-delta-frr1 vtysh'
alias cvx='docker exec -it clab-multivendor-delta-cvx1 vtysh'
alias iperf-tx='docker exec -it clab-multivendor-delta-alpine-tx sh'
alias iperf-rx='docker exec -it clab-multivendor-delta-alpine-rx sh'
ALIASES

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Setup complete!"
echo ""
echo "  Deploy:     sudo containerlab deploy -t multivendor-delta.clab.yml"
echo "  Grafana:    http://localhost:3000  (admin/admin)"
echo "  Prometheus: http://localhost:9090"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
