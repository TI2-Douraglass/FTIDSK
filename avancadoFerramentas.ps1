# 🔧 Ferramenta de Manutenção do Sistema - DouraGlass

# 🚨 Verificar e solicitar elevação se necessário
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "⏫ Reabrindo o script como administrador..." -ForegroundColor Yellow
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

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
    Write-Host "--- OUTROS ---" -ForegroundColor Green
    Write-Host "[9] 📅 Agendar tarefa"
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
    "S" | cmd /c "chkdsk C: /F /R"
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
            Write-Host ("❌ Falha ao limpar {0}: {1}" -f $pasta, $_) -ForegroundColor Red
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

function Agendar-Tarefa {
    Clear-Host
    Write-Host "📅 MENU DE AGENDAMENTO DE TAREFAS" -ForegroundColor Cyan
    Write-Host "`n[1] Agendar limpeza diária do TEMP às 04:00"
    Write-Host "[0] Voltar ao menu principal"
    $escolha = Read-Host "`nEscolha uma opção"

    switch ($escolha) {
        "1" {
            $pastaAgendada = "C:\Agendati"
            if (-not (Test-Path $pastaAgendada)) {
                New-Item -Path $pastaAgendada -ItemType Directory | Out-Null
            }

            $scriptLimpeza = @"
`$pastas = @(
    `"`$env:TEMP`",
    `"`$env:windir\Temp`"
)
foreach (`$pasta in `$pastas) {
    try {
        Get-ChildItem -Path `$pasta -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    } catch {}
}
"@

            $scriptPath = "$pastaAgendada\limpeza.ps1"
            Set-Content -Path $scriptPath -Value $scriptLimpeza -Encoding UTF8

            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
            $trigger = New-ScheduledTaskTrigger -Daily -At 4:00AM
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
            $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

            Register-ScheduledTask -TaskName "Limpeza_TEMP_Diaria" -InputObject $task -Force

            Write-Host "`n✔️  Tarefa agendada com sucesso! Será executada todos os dias às 04:00." -ForegroundColor Green
            Pause
        }
        "0" { return }
        Default {
            Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
            Agendar-Tarefa
        }
    }
}

# Loop principal
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção [1-9]"

    switch ($opcao) {
        "1" { Executar-SFC }
        "2" { Executar-DISM }
        "3" { Executar-CHKDSK }
        "4" { Executar-Limpeza }
        "5" { Verificar-SMART }
        "6" { Diagnostico-Rede }
        "7" { Reiniciar-WU }
        "8" { exit }
        "9" { Agendar-Tarefa }
        Default {
            Write-Host ""; Write-Host "❗ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
