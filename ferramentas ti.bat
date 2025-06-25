@echo off
title Manutenção do Sistema
color 1F
chcp 65001 >nul

:MENU
cls
echo ===============================
echo      MANUTENÇÃO DO SISTEMA
echo ===============================
echo.
echo 1 - Verificar arquivos do sistema (SFC)
echo 2 - Reparo da imagem do sistema (DISM)
echo 3 - Verificar disco rígido (CHKDSK C:)
echo 4 - Sair
echo.
set /p opcao=Escolha uma opção [1-4]: 

if "%opcao%"=="1" goto SFC
if "%opcao%"=="2" goto DISM
if "%opcao%"=="3" goto CHKDSK
if "%opcao%"=="4" exit
goto MENU

:SFC
cls
echo Executando verificação do sistema...
sfc /scannow
pause
goto MENU

:DISM
cls
echo Executando DISM com privilégios elevados...
powershell -Command "Start-Process powershell -ArgumentList '/c DISM /Online /Cleanup-Image /RestoreHealth' -Verb RunAs"
pause
goto MENU

:CHKDSK
cls
echo =========================================
echo CHKDSK será executado no disco C:
echo Isso pode requerer reinicialização.
echo =========================================
echo y | chkdsk /F /R
pause
goto MENU
