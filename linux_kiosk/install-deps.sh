#!/usr/bin/env bash
# FASE 6 — Instala las dependencias nativas para compilar/correr La Tercia POS
# en Linux (probado en Ubuntu/Lubuntu 24.04 "noble").
#
# Uso:   bash linux_kiosk/install-deps.sh
#
# Evita teclear los nombres de paquete a mano (los guiones antes de "-dev"
# se pierden fácil). Si algún paquete cambia de nombre en tu distro, ajústalo.
set -euo pipefail

echo "==> Actualizando índice de paquetes…"
sudo apt update

echo "==> Toolchain de build + GTK…"
sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

echo "==> GStreamer (build de audioplayers)…"
sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev

echo "==> GStreamer runtime (sonidos del KDS) — opcional…"
sudo apt install -y gstreamer1.0-plugins-base gstreamer1.0-plugins-good || true

echo "==> CUPS (impresión, plugin printing) — por si acaso…"
sudo apt install -y libcups2-dev || true

echo "==> Habilitando el escritorio Linux en Flutter…"
flutter config --enable-linux-desktop

echo
echo "Listo. Ahora:  flutter build linux --release"
