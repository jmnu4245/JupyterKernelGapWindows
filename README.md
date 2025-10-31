## INSTRUCCIONES DE USO
Una ejecución correcta consiste simplemente en ejecutar install.bat con permisos de administrador y seguir las indicaciones, el proceso puede llevar varios reinicios.

El script tiene 3 partes importantes: 
- Comprueba que las características de windows para ejecutar WSl están activadas.
    - Si estan activadas no hace nada
    - Si no estan activadas las activa y reinicia
- Comprueba que WSL este instalado
    - Si esta instalado no hace nada
    - Si no esta instalado lo instala y reinicia
- Abre WSL e instala gap y configura jupyter.

La ejecución sigue este proceso:
install.bat -> activarCaracteristicas.ps1 -> (Reinicia si no estaban activadas) -> install.bat -> instalarWsl.ps1 -> (Reiniciar si no estaba instalado) -> finalgap.bat -> setup-gap.sh

## Verificación de la instalación
Todo esta instalado dentro del Windows Subsystem for Linux, se puede acceder ejecutando: 
```cmd
wsl
```
La aplicación se instala en la carpeta del primer usuario **gap**, junto con un *environment* de **Python** donde está instalado el **kernel de GAP**.

---

### Comprobar la instalación de GAP

Ejecutar en una terminal:

```bash
gap
```
Debería abrirse la consola interactiva de GAP, mostrando algo similar a:
```bash
 ┌───────┐   GAP 4.12.2, 64-bit
 │  GAP  │   https://www.gap-system.org
 └───────┘   Architecture: x86_64-pc-linux-gnu-gcc-default64
 Type ? for help. 
gap>
```
Para salir de gap escribir:
```bash
quit;
```

### Comprobar la instalación del kernel de GAP
```bash
jupyter kernelspec list
```

Debería aparecer: 

```bash
Available kernels:
  python3                -> .../share/jupyter/kernels/python3
  gap                    -> .../share/jupyter/kernels/gap
```
## Usar GAP en Visual Studio Code

Hay cuatro partes importantes para un funcionamiento adecuado:

- Instala la extensión Jupyter desde el marketplace de VS Code.
- Conecta VSCode a WSL en la esquina izquerda inferior.
- Abre el directorio /user en VSCode de forma que te aparezca el directorio /env_gap a la izquierda

Ahora abre un archivo .ipynb o crea uno nuevo.

- En la parte arriba a la izquierda debes seleccionar GAP. En caso de que no lo detecte, revisa el paso anterior.

Escribe y ejecuta código GAP directamente en las celdas.
Por ejemplo:
```gap
G := SymmetricGroup(4);
Size(G);
```
## Desinstalar

### Eliminar la instalación completa de Ubuntu en WSL

Si deseas eliminar completamente la distribución de Ubuntu que instalaste en WSL (junto con GAP y todos sus datos), puedes ejecutar:
```bash
wsl --unregister Ubuntu
```
⚠️ Esto eliminará toda la instalación de Ubuntu en WSL, incluyendo todos los archivos, entornos y configuraciones internas. Usa este comando solo si quieres hacer una desinstalación total.

### Eliminar solo los archivos de GAP y su entorno

Si solo quieres borrar los archivos descargados e instalados por el script (por ejemplo: gap-4.15.1.tar.gz, gap-4.15.1, gap-env), puedes hacerlo manualmente desde tu carpeta de usuario o desde la ruta donde se instaló GAP:
```bash
rm -rf ~/gap-4.15.1.tar.gz ~/gap-4.15.1 ~/gap-env

```
## Problemas
Puedes abrir un issue o mandar un correo a juanmanuelfloresdelacruz@gmail.com
### Tareas irealizadas
En caso de que algún error haga que el script no se realice de forma adecuada y se quiera eliminar las tareas basta con ejecutar eliminarTareas.bat 

