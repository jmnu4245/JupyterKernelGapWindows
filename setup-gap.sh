#!/bin/bash

# --- PASO 1: Asegurarse de que se ejecuta como root ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[INFO] Este script debe ejecutarse como root (o con sudo)."
    echo "[INFO] Intentando re-ejecutar con sudo..."
    # 'exec' reemplaza el proceso actual con el nuevo
    # "$0" es el nombre del script, "$@" son todos los argumentos
    exec sudo "$0" "$@"
    exit 1 # Salir si exec falla por alguna razon
fi

# A PARTIR DE AQUI, SABEMOS QUE SOMOS ROOT

# --- PASO 2: Identificar al usuario final ---
TARGET_USER=""
USER_HOME=""

if [ -n "$SUDO_USER" ]; then
    # Escenario A: Ejecutado con 'sudo ./setup-gap.sh'
    # El usuario es quien ejecuto sudo.
    TARGET_USER=$SUDO_USER
    echo "[INFO] Ejecutado con sudo. Usuario objetivo: $TARGET_USER"
else
    # Escenario B: Ejecutado como root (probablemente desde el .bat)
    # Debemos adivinar el usuario.
    echo "[INFO] Ejecutado como root. Determinando el usuario..."
    
    # Intenta encontrar el primer usuario en /home
    potencial_user=$(find /home -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n 1)
    
    if [ -n "$potencial_user" ]; then
        TARGET_USER=$potencial_user
        echo "[INFO] Usuario detectado en /home: $TARGET_USER"
    else
        # Plan C: Fallback para la automatizacion del .bat
        # Si /home esta vacio (instalacion nueva), asumimos 'usuario'.
        TARGET_USER="usuario"
        echo "[WARN] No se detecto ningun usuario en /home."
        echo "[WARN] Se usara por defecto '$TARGET_USER'. Asegurate de crear un usuario con este nombre."
    fi
fi

USER_HOME="/home/$TARGET_USER"

# --- PASO 3: Instalacion de paquetes del sistema (como root) ---
echo "--- [INFO] Actualizando paquetes de Ubuntu... ---"
apt-get update
apt-get upgrade -y

echo "--- [INFO] Instalando GAP, Python3, venv, build-essential y git... ---"
apt-get install -y python3-pip python3.10-venv build-essential git build-essential autoconf libtool libgmp-dev libreadline-dev zlib1g-dev

if [ $? -ne 0 ]; then
    echo "[ERROR] Fallo la instalacion de paquetes de apt. Abortando."
    exit 1
fi
cd 
wget https://github.com/gap-system/gap/releases/download/v4.15.1/gap-4.15.1.tar.gz
tar -xzvf gap-4.15.1.tar.gz
cd gap-4.15.1.tar.gz
./configure && make
cd pkg
../bin/BuildPackages.sh


# --- PASO 4: Creacion de entorno y carpetas (como TARGET_USER) ---
echo "--- [INFO] Creando directorio $USER_HOME/estrucal como $TARGET_USER... ---"
# 'sudo -u $TARGET_USER' ejecuta el comando como ese usuario
sudo -u $TARGET_USER mkdir -p $USER_HOME/estrucal

echo "--- [INFO] Creando entorno virtual en $USER_HOME/estrucal/gap-env... ---"
sudo -u $TARGET_USER python3 -m venv $USER_HOME/estrucal/gap-env

if [ $? -ne 0 ]; then
    echo "[ERROR] Fallo la creacion del entorno virtual. Abortando."
    exit 1
fi

# --- PASO 5: Instalacion de paquetes de Python (como TARGET_USER) ---
echo "--- [INFO] Instalando Jupyter y el kernel de GAP en el venv... ---"

# Creamos un bloque de comandos para ejecutar como el usuario
# 'source' DEBE ejecutarse dentro del mismo shell que 'pip'
VENV_CMD="source $USER_HOME/estrucal/gap-env/bin/activate && \
          pip install jupyterlab jupyter notebook && cd JupyterKernel && pip install ."

# Ejecutamos todo el bloque de comandos como el usuario
sudo -u $TARGET_USER /bin/bash -c "$VENV_CMD"

if [ $? -ne 0 ]; then
    echo "[ERROR] Fallo la instalacion de paquetes de Python (pip). Abortando."
    exit 1
fi

jupyter kernelspec list
