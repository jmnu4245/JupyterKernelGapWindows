#!/bin/bash

progress_bar() {
    local duration=$1
    local elapsed=0
    while [ $elapsed -lt $duration ]; do
        local percent=$((elapsed * 100 / duration))
        local filled=$((percent / 2))
        local empty=$((50 - filled))
        printf "\r["
        printf "%0.s#" $(seq 1 $filled)
        printf "%0.s-" $(seq 1 $empty)
        printf "] %s%%" "$percent"
        sleep 0.1
        ((elapsed++))
    done
    printf "\r[##################################################] 100%%\n"
}
# --- PASO 1: Asegurarse de que se ejecuta como root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[INFO] Este script debe ejecutarse como root (o con sudo)."
    echo "[INFO] Intentando re-ejecutar con sudo..."
    exec sudo "$0" "$@"
    exit 1
fi
# --- Detectar carpeta de usuario principal ---
#Si se quiere configurar para un usuario específico, cambiar esta parte
USER_HOME=$(ls -d /home/* 2>/dev/null | head -n 1)

# Si no se encuentra, usar /root como fallback
if [ -z "$USER_HOME" ]; then
    USER_HOME="/root"
fi

echo "[INFO] Carpeta de usuario detectada: $USER_HOME"

# --- PASO 2: Instalar dependencias ---
echo "[INFO] Instalando dependencias del sistema..."
apt-get -y update > /dev/null 2>&1
apt-get -y install build-essential autoconf libtool libgmp-dev libreadline-dev zlib1g-dev libzmq3-dev m4 python3 python3-pip python3-venv > /dev/null 2>&1 &
progress_bar 30
# --- PASO 3: Crear entorno Python ---
echo "[INFO] Configurando entorno virtual de Python..."
mkdir -p "$USER_HOME/gap-env"
python3 -m venv "$USER_HOME/gap-env"
source $USER_HOME/gap-env/bin/activate
pip install --upgrade pip > /dev/null 2>&1 &
progress_bar 20
pip install notebook jupyter jupyterlab ipykernel > /dev/null 2>&1 &
progress_bar 20
# --- PASO 4: Descargar y compilar GAP ---
cd "$USER_HOME"
echo "[INFO] Descargando y descomprimiendo GAP..."
wget https://github.com/gap-system/gap/releases/download/v4.15.1/gap-4.15.1.tar.gz
tar -xzf "$USER_HOME/gap-4.15.1.tar.gz" > /dev/null 2>&1
progress_bar 15

echo "[INFO] Compilando GAP y el kernel de Jupyter..."
cd "$USER_HOME/gap-4.15.1"
./configure && make 

# --- PASO 5: Compilar paquetes y kernel ---
cd "$USER_HOME/gap-4.15.1/pkg"
echo "[INFO] Construyendo paquetes de GAP..."
../bin/BuildPackages.sh #> /dev/null 2>&1 &

cd jupyterkernel
echo "[INFO] Instalando JupyterKernel para GAP..."
pip install . #> /dev/null 2>&1 &
progress_bar 10
# --- PASO 6: Crear enlace simbólico ---
sudo ln -s $USER_HOME/gap-4.15.1/gap /usr/local/bin/gap
echo "Instalación completada"

