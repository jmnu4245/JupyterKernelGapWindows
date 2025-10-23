#!/bin/bash

# Spinner animado que se ejecuta mientras un proceso está corriendo
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r[✓] "
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

# --- LIMPIEZA: Eliminar instalaciones previas ---
echo "[INFO] Limpiando instalaciones previas..."
rm -rf "$USER_HOME/gap-env"
rm -rf "$USER_HOME/gap-4.15.1"
rm -f "$USER_HOME/gap-4.15.1.tar.gz"

# --- PASO 3: Instalar dependencias del sistema (como root) ---
echo -n "[INFO] Instalando dependencias del sistema..."
apt-get -y update > /dev/null 2>&1
apt-get -y install build-essential autoconf libtool libgmp-dev libreadline-dev zlib1g-dev libzmq3-dev m4 python3 python3-pip python3-venv wget > /dev/null 2>&1 &
spinner $!
echo ""

# --- RESTO DE OPERACIONES COMO USUARIO NO PRIVILEGIADO ---
echo "[INFO] Cambiando a usuario '$USERNAME' para el resto de la instalación..."

# Ejecutar directamente con sudo -u
sudo -u "$USERNAME" bash <<'EOFSCRIPT'

# Spinner animado
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -n " "
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r[%c] " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r[✓] "
}

# --- PASO 4: Crear entorno Python ---
echo "[INFO] Configurando entorno virtual de Python..."
cd "$HOME"
python3 -m venv "$HOME/gap-env"
source "$HOME/gap-env/bin/activate"

echo -n "[INFO] Actualizando pip..."
pip install --upgrade pip > /dev/null 2>&1 &
spinner $!
echo ""

echo -n "[INFO] Instalando paquetes de Jupyter..."
pip install notebook jupyter jupyterlab ipykernel > /dev/null 2>&1 &
spinner $!
echo ""

# --- PASO 5: Descargar y compilar GAP ---
echo -n "[INFO] Descargando GAP..."
wget -q https://github.com/gap-system/gap/releases/download/v4.15.1/gap-4.15.1.tar.gz &
spinner $!
echo ""

echo -n "[INFO] Descomprimiendo GAP..."
tar -xzf gap-4.15.1.tar.gz &
spinner $!
echo ""

echo -n "[INFO] Compilando GAP (esto puede tardar varios minutos)..."
cd "$HOME/gap-4.15.1"
(./configure > /dev/null 2>&1 && make > /dev/null 2>&1) &
spinner $!
echo ""

# --- PASO 6: Compilar paquetes y kernel ---
echo -n "[INFO] Construyendo paquetes de GAP (esto puede tardar muchos minutos)"
cd "$HOME/gap-4.15.1/pkg"
../bin/BuildPackages.sh > /dev/null 2>&1 &
spinner $!
echo ""

echo -n "[INFO] Instalando JupyterKernel para GAP..."
cd "$HOME/gap-4.15.1/pkg/jupyterkernel"
source "$HOME/gap-env/bin/activate"
pip install . > /dev/null 2>&1 &
spinner $!
echo ""

echo "[OK] Instalación completada para el usuario"
EOFSCRIPT

# --- PASO 7: Crear enlace simbólico (requiere root) ---
echo "[INFO] Creando enlace simbólico a GAP..."
ln -sf "$USER_HOME/gap-4.15.1/gap" /usr/local/bin/gap

echo "[OK] Instalación completada"

SCRIPT_PATH=$(realpath "$0")
echo "[INFO] Eliminando script: $SCRIPT_PATH"
rm -f "$SCRIPT_PATH"

[INFO] Compilando GAP... . . . 