# 🔧 Ferramenta de Manutenção do Sistema - TI DouraGlass
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
    Write-Host "[5] 🧪 Verificar status SMART do disco"
    Write-Host ""
    Write-Host "--- LIMPEZA ---" -ForegroundColor Green
    Write-Host "[4] 🧹 Limpeza de arquivos temporários"
    Write-Host ""
    Write-Host "--- REDE E ATUALIZAÇÕES ---" -ForegroundColor Green
    Write-Host "[6] 🌐 Diagnóstico de rede"
    Write-Host "[7] ♻️  Reiniciar Windows Update"
    Write-Host ""
    Write-Host "--- SAIR ---"
    Write-Host "[8] ❌ Sair"
    Write-Host ""
}

function Executar-SFC {
    Clear-Host
    Write-Host "🔍 Executando verificação do sistema (SFC)..." -ForegroundColor Yellow
    sfc /scannow
    Pause
}

function Executar-DISM {
    Clear-Host
    Write-Host "🛠️  Executando DISM com privilégios elevados..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList '/c DISM /Online /Cleanup-Image /RestoreHealth'
    Pause
}

function Executar-CHKDSK {
    Clear-Host
    Write-Host "💾 Verificando disco (CHKDSK /F /R)..." -ForegroundColor Yellow
    "S" | cmd /c "chkdsk /F /R"
    Pause
}

function Executar-Limpeza {
    Clear-Host
    Write-Host "🧹 Limpando arquivos temporários..." -ForegroundColor Yellow

    $pastas = @(
        $env:TEMP,
        "$env:windir\Temp"
    )

    foreach ($pasta in $pastas) {
        try {
            Write-Host "`n🗂️  Limpando: $pasta" -ForegroundColor Cyan
            Get-ChildItem -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "✔️  Limpeza de $pasta concluída." -ForegroundColor Green
        } catch {
            Write-Host "❌ Falha ao limpar $pasta: $_" -ForegroundColor Red
        }
    }

    Pause
}

function Verificar-SMART {
    Clear-Host
    Write-Host "🧪 Verificando status SMART dos discos..." -ForegroundColor Yellow
    Get-WmiObject -Class Win32_DiskDrive | Select-Object Model, Status
    Pause
}

function Diagnostico-Rede {
    Clear-Host
    Write-Host "🌐 Executando diagnóstico de rede..." -ForegroundColor Yellow
    ipconfig /release
    ipconfig /renew
    ipconfig /flushdns
    Pause
}

function Reiniciar-WU {
    Clear-Host
    Write-Host "♻️  Reiniciando componentes do Windows Update..." -ForegroundColor Yellow
    $services = "wuauserv","cryptSvc","bits","msiserver"
    foreach ($svc in $services) { net stop $svc >$null 2>&1 }
    
    Rename-Item "C:\Windows\SoftwareDistribution" "C:\Windows\SoftwareDistribution.old" -ErrorAction SilentlyContinue
    Rename-Item "C:\Windows\System32\catroot2" "C:\Windows\System32\catroot2.old" -ErrorAction SilentlyContinue

    foreach ($svc in $services) { net start $svc >$null 2>&1 }

    Write-Host "`n✔️  Windows Update redefinido com sucesso." -ForegroundColor Green
    Pause
}

# Loop principal
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção [1-8]"

    switch ($opcao) {
        "1" { Executar-SFC }
        "2" { Executar-DISM }
        "3" { Executar-CHKDSK }
        "4" { Executar-Limpeza }
        "5" { Verificar-SMART }
        "6" { Diagnostico-Rede }
        "7" { Reiniciar-WU }
        "8" { break }
        Default {
            Write-Host ""
            Write-Host "❗ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
