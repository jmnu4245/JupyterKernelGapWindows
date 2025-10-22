#!/bin/bash
# --- PASO 1: Asegurarse de que se ejecuta como root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[INFO] Este script debe ejecutarse como root (o con sudo)."
    echo "[INFO] Intentando re-ejecutar con sudo..."
    exec sudo "$0" "$@"
    exit 1
fi
apt-get -y update
apt-get -y install build-essential autoconf libtool libgmp-dev libreadline-dev zlib1g-dev libzmq3-dev m4 python3 python3-pip python3-venv
mkdir ~/gap-env
python3 -m venv ~/gap-env
source ~/gap-env/bin/activate
pip install --upgrade pip
pip install notebook jupyter jupyterlab ipykernel

cd ~
wget https://gap-system.github.io/Download/gap-4.11.1.tar.gz
tar -xvzf gap-4.11.1.tar.gz
cd gap-4.11.1
./configure && make
cd pkg
../bin/BuildPackages.sh
cd jupyterkernel
pip install .
sudo ln -s ~/gap-4.11.1/gap /usr/local/bin/gap
echo "Prueba completada"