schtasks /Delete /TN "InstalarGapPostReinicio" /F >nul 2>&1
wsl -u root bash -c "cd ~/ && rm -rf setup-gap* && wget https://raw.githubusercontent.com/jmnu4245/JupyterKernelGapWindows/main/setup-gap.sh && bash ./setup-gap.sh"
pause