#!/bin/bash
# --- PASO 1: Asegurarse de que se ejecuta como root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[INFO] Este script debe ejecutarse como root (o con sudo)."
    echo "[INFO] Intentando re-ejecutar con sudo..."
    exec sudo "$0" "$@"
    exit 1
fi

# --- PASO 2: Identificar al usuario final ---
TARGET_USER=""
USER_HOME=""

if [ -n "$SUDO_USER" ]; then
    TARGET_USER=$SUDO_USER
    echo "[INFO] Ejecutado con sudo. Usuario objetivo: $TARGET_USER"
else
    echo "[INFO] Ejecutado como root. Determinando el usuario..."
    potencial_user=$(find /home -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n 1)
    
    if [ -n "$potencial_user" ]; then
        TARGET_USER=$potencial_user
        echo "[INFO] Usuario detectado en /home: $TARGET_USER"
    else
        TARGET_USER="usuario"
        echo "[WARN] No se detectó ningún usuario en /home."
        echo "[WARN] Se usará por defecto '$TARGET_USER'."
    fi
fi

USER_HOME="/home/$TARGET_USER"

# --- PASO 3: Instalación de paquetes del sistema ---
echo "--- [INFO] Actualizando paquetes de Ubuntu... ---"
apt-get update
apt-get upgrade -y

echo "--- [INFO] Instalando dependencias... ---"
apt-get install -y python3-pip python3.10-venv build-essential git \
    autoconf libtool libgmp-dev libreadline-dev zlib1g-dev wget

if [ $? -ne 0 ]; then
    echo "[ERROR] Falló la instalación de paquetes. Abortando."
    exit 1
fi

# --- PASO 4: Instalar GAP en /opt ---
GAP_DIR="/opt/gap-4.15.1"
echo "--- [INFO] Instalando GAP en $GAP_DIR... ---"

cd /tmp
wget https://github.com/gap-system/gap/releases/download/v4.15.1/gap-4.15.1.tar.gz
tar -xzvf gap-4.15.1.tar.gz
mv gap-4.15.1 /opt/

cd "$GAP_DIR"
./configure && make

if [ $? -ne 0 ]; then
    echo "[ERROR] Falló la compilación de GAP. Abortando."
    exit 1
fi

# --- PASO 5: Compilar paquetes de GAP (incluido JupyterKernel) ---
echo "--- [INFO] Compilando paquetes de GAP... ---"
cd "$GAP_DIR/pkg"
../bin/BuildPackages.sh

if [ $? -ne 0 ]; then
    echo "[WARN] Algunos paquetes de GAP pueden no haberse compilado correctamente."
fi

# --- PASO 6: Crear enlace simbólico para gap ---
echo "--- [INFO] Creando enlace simbólico para el comando 'gap'... ---"
ln -sf "$GAP_DIR/bin/gap.sh" /usr/local/bin/gap

# Verificar que funciona
if command -v gap &> /dev/null; then
    echo "[INFO] El comando 'gap' está disponible globalmente."
else
    echo "[WARN] El comando 'gap' no se encontró en el PATH."
fi

# --- PASO 7: Crear entorno virtual para el usuario ---
echo "--- [INFO] Creando directorio $USER_HOME/estrucal como $TARGET_USER... ---"
sudo -u $TARGET_USER mkdir -p $USER_HOME/estrucal

echo "--- [INFO] Creando entorno virtual... ---"
sudo -u $TARGET_USER python3 -m venv $USER_HOME/estrucal/gap-env

if [ $? -ne 0 ]; then
    echo "[ERROR] Falló la creación del entorno virtual. Abortando."
    exit 1
fi

# --- PASO 8: Instalar Jupyter y JupyterKernel ---
echo "--- [INFO] Instalando Jupyter y el kernel de GAP... ---"

# Ruta al JupyterKernel dentro de pkg
JUPYTER_KERNEL_DIR="$GAP_DIR/pkg/jupyterkernel"

if [ ! -d "$JUPYTER_KERNEL_DIR" ]; then
    echo "[ERROR] No se encontró JupyterKernel en $JUPYTER_KERNEL_DIR"
    echo "[ERROR] Verifica que BuildPackages.sh se ejecutó correctamente."
    exit 1
fi

VENV_CMD="source $USER_HOME/estrucal/gap-env/bin/activate && \
          pip install --upgrade pip && \
          pip install jupyterlab jupyter notebook && \
          cd $JUPYTER_KERNEL_DIR && \
          pip install ."

sudo -u $TARGET_USER /bin/bash -c "$VENV_CMD"

if [ $? -ne 0 ]; then
    echo "[ERROR] Falló la instalación de paquetes Python. Abortando."
    exit 1
fi

# --- PASO 9: Verificar instalación ---
echo "--- [INFO] Verificando kernels instalados... ---"
sudo -u $TARGET_USER /bin/bash -c "source $USER_HOME/estrucal/gap-env/bin/activate && jupyter kernelspec list"

echo ""
echo "=========================================="
echo "[SUCCESS] Instalación completada!"
echo "=========================================="
echo "El comando 'gap' está disponible globalmente."
echo ""
echo "Para usar Jupyter con GAP:"
echo "1. Activa el entorno: source $USER_HOME/estrucal/gap-env/bin/activate"
echo "2. Inicia Jupyter: jupyter notebook"
echo "3. Selecciona el kernel 'GAP' al crear un nuevo notebook"
echo "=========================================="
