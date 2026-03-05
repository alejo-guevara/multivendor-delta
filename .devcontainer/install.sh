#!/bin/bash
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ContainerLab Multivendor Delta — Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── System packages ──────────────────────────────────────
echo "→ Installing system packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  curl wget git jq tree \
  iproute2 iputils-ping \
  python3 python3-pip

# ── ContainerLab ─────────────────────────────────────────
echo "→ Installing ContainerLab..."
bash -c "$(curl -sL https://get.containerlab.dev)"
containerlab version

# ── gNMIc CLI ────────────────────────────────────────────
echo "→ Installing gNMIc CLI..."
bash -c "$(curl -sL https://get-gnmic.openconfig.net)"
gnmic version

# ── Pre-pull Docker images ────────────────────────────────
echo "→ Pre-pulling lab images (this takes a few minutes)..."

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
echo "→ Setting up aliases..."
cat >> ~/.bashrc << 'ALIASES'

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
echo "  Deploy the lab:"
echo "    sudo containerlab deploy -t multivendor-delta.clab.yml"
echo ""
echo "  Grafana:    http://localhost:3000  (admin/admin)"
echo "  Prometheus: http://localhost:9090"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
