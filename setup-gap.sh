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

# --- PASO 1: Verificar root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Este script debe ejecutarse como root."
    echo "[INFO] Usa: sudo $0"
    exit 1
fi

# --- PASO 2: Crear usuario 'user' con contraseña 'admin' ---
USERNAME="user"
PASSWORD="admin"

EXISTING_USER=$(ls /home 2>/dev/null | head -n 1)
if [ -n "$EXISTING_USER" ]; then
    USERNAME="$EXISTING_USER"
    echo "[INFO] Se ha detectado un usuario existente: '$USERNAME'."
else
    echo "[INFO] No se ha encontrado ningún usuario con carpeta en /home."
    echo "[INFO] Creando usuario '$USERNAME'..."
    useradd -m -s /bin/bash "$USERNAME"
    echo "${USERNAME}:${PASSWORD}" | chpasswd
    usermod -aG sudo "$USERNAME"
    echo "[OK] Usuario '$USERNAME' creado con contraseña '$PASSWORD'"
fi

USER_HOME=$(eval echo "~$USERNAME")
echo "[INFO] Carpeta de usuario: $USER_HOME"

# --- PASO 3: Instalar dependencias del sistema (como root) ---
echo "[INFO] Instalando dependencias del sistema..."
apt-get -y update > /dev/null 2>&1
apt-get -y install build-essential autoconf libtool libgmp-dev libreadline-dev zlib1g-dev libzmq3-dev m4 python3 python3-pip python3-venv wget > /dev/null 2>&1 &
progress_bar 30

# --- RESTO DE OPERACIONES COMO USUARIO NO PRIVILEGIADO ---
echo "[INFO] Cambiando a usuario '$USERNAME' para el resto de la instalación..."

# Ejecutar comandos directamente con su shell sin archivo temporal
su - "$USERNAME" << 'EOFSCRIPT'

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

USER_HOME="$HOME"

# --- PASO 4: Crear entorno Python ---
echo "[INFO] Configurando entorno virtual de Python..."
mkdir -p "$USER_HOME/gap-env"
python3 -m venv "$USER_HOME/gap-env"
source "$USER_HOME/gap-env/bin/activate"

pip install --upgrade pip > /dev/null 2>&1 &
progress_bar 20

pip install notebook jupyter jupyterlab ipykernel > /dev/null 2>&1 &
progress_bar 20

# --- PASO 5: Descargar y compilar GAP ---
cd "$USER_HOME"
echo "[INFO] Descargando y descomprimiendo GAP..."
wget -q https://github.com/gap-system/gap/releases/download/v4.15.1/gap-4.15.1.tar.gz
tar -xzf gap-4.15.1.tar.gz > /dev/null 2>&1 &
progress_bar 15

echo "[INFO] Compilando GAP..."
cd "$USER_HOME/gap-4.15.1"
./configure > /dev/null 2>&1 && make > /dev/null 2>&1 &
progress_bar 60

# --- PASO 6: Compilar paquetes y kernel ---
echo "[INFO] Construyendo paquetes de GAP..."
cd "$USER_HOME/gap-4.15.1/pkg"
../bin/BuildPackages.sh > /dev/null 2>&1 &
progress_bar 30

cd jupyterkernel
echo "[INFO] Instalando JupyterKernel para GAP..."
source "$USER_HOME/gap-env/bin/activate"
pip install . > /dev/null 2>&1 &
progress_bar 10

echo "[OK] Instalación completada para el usuario"
EOFSCRIPT

# --- PASO 7: Crear enlace simbólico (requiere root) ---
echo "[INFO] Creando enlace simbólico a GAP..."
ln -sf "$USER_HOME/gap-4.15.1/gap" /usr/local/bin/gap

echo "[OK] Instalación completada"

SCRIPT_PATH=$(realpath "$0")
echo "[INFO] Eliminando script: $SCRIPT_PATH"
rm -f "$SCRIPT_PATH"