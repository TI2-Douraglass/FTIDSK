# Ferramenta de Manutenção do Sistema - DouraGlass
$Host.UI.RawUI.WindowTitle = "🔧 Ferramenta de Manutenção do Sistema - DouraGlass"
$Host.UI.RawUI.ForegroundColor = "Yellow"
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
Clear-Host

function Mostrar-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    🔧 FERRAMENTA DE MANUTENÇÃO DO SISTEMA" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "--- SISTEMA ---" -ForegroundColor Green
    Write-Host "[1] 🔍 Verificar arquivos do sistema (SFC)"
    Write-Host "[2] 🛠️  Reparo da imagem do sistema (DISM)"
    Write-Host ""
    Write-Host "--- DISCO ---" -ForegroundColor Green
    Write-Host "[3] 💾 Verificar disco rígido (CHKDSK C:)"
    Write-Host ""
    Write-Host "--- SAIR ---"
    Write-Host "[4] ❌ Sair"
    Write-Host ""
}

function Executar-SFC {
    Clear-Host
    Write-Host "============================================"
    Write-Host "🔍 Executando verificação do sistema (SFC)..."
    Write-Host "============================================"
    sfc /scannow
    Pause
}

function Executar-DISM {
    Clear-Host
    Write-Host "==============================================="
    Write-Host "🛠️  Executando DISM com privilégios elevados..."
    Write-Host "==============================================="
    Start-Process powershell -Verb RunAs -ArgumentList '/c DISM /Online /Cleanup-Image /RestoreHealth'
    Pause
}

function Executar-CHKDSK {
    Clear-Host
    Write-Host "====================================================="
    Write-Host "💾 CHKDSK será executado no disco C:"
    Write-Host "Isso pode requerer reinicialização do sistema."
    Write-Host "====================================================="
    "S" | cmd /c "chkdsk C: /F /R"
    Pause
}

# Loop principal
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção [1-4]"

    switch ($opcao) {
        "1" { Executar-SFC }
        "2" { Executar-DISM }
        "3" { Executar-CHKDSK }
        "4" { break }
        Default {
            Write-Host ""
            Write-Host "❗ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
