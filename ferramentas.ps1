# 🔧 Ferramenta de Manutenção do Sistema - DouraGlass
# Script refatorado: robustez, segurança e logging

# 1. Modo estrito e declaração de erros
Set-StrictMode -Version Latest

# 2. Verificar assinatura digital do script
if ((Get-AuthenticodeSignature $PSCommandPath).Status -ne 'Valid') {
    Write-Error "Script não está assinado digitalmente. Abortando."
    exit 1
}

# 3. Configurar fonte de Event Log
$source = 'ManutencaoSistema'
if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
    New-EventLog -LogName Application -Source $source
}

# 4. Iniciar transcript para auditoria
$scriptName = Split-Path -Path $PSCommandPath -Leaf
$logPath = Join-Path $env:TEMP ("{0}_{1:yyyyMMdd_HHmmss}.log" -f $scriptName, (Get-Date))
Start-Transcript -Path $logPath -Append

# 5. Elevação automática se não for Administrador
if (-not ([Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent())
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⏫ Reabrindo script como Administrador..." -ForegroundColor Yellow
    Start-Process pwsh -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`"" -Verb RunAs
    Stop-Transcript
    exit
}

# 6. Verificar versão mínima do PowerShell
if ($PSVersionTable.PSVersion -lt [Version]"5.1") {
    Write-Error "PowerShell 5.1 ou superior é necessário."
    Stop-Transcript
    exit 1
}

# 7. Definição do menu
function Mostrar-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    🔧 FERRAMENTA DE MANUTENÇÃO DO SISTEMA" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] 🔍 Verificar arquivos do sistema (SFC)"
    Write-Host "[2] 🛠️  Reparo da imagem do sistema (DISM)"
    Write-Host "[3] 💾 Agendar CHKDSK no boot (CHKDSK /F /R)"
    Write-Host "[4] 🧹 Limpeza de arquivos temporários"
    Write-Host "[5] 🧪 Verificar status SMART dos discos"
    Write-Host "[6] 🌐 Diagnóstico de rede"
    Write-Host "[7] ♻️  Reiniciar Windows Update"
    Write-Host "[8] ❌ Sair"
    Write-Host "[9] 🖨️  Limpar fila de impressão"
    Write-Host ""
}

# 8. Funções de manutenção
function Executar-SFC {
    [CmdletBinding()]
    param()
    try {
        Write-Host "🔍 Iniciando SFC..." -ForegroundColor Yellow
        sfc /scannow -ErrorAction Stop
        Write-Host "✅ SFC concluído." -ForegroundColor Green
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 1001 -Message "SFC concluído com sucesso."
    } catch {
        Write-Error "❌ Erro no SFC: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 1002 -Message $_
    }
    Pause
}

function Executar-DISM {
    [CmdletBinding()]
    param()
    try {
        Write-Host "🛠️  Iniciando DISM..." -ForegroundColor Yellow
        Start-Process -FilePath dism.exe -ArgumentList '/Online','/Cleanup-Image','/RestoreHealth' -Verb RunAs -Wait
        Write-Host "✅ DISM concluído." -ForegroundColor Green
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 2001 -Message "DISM concluído com sucesso."
    } catch {
        Write-Error "❌ Erro no DISM: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 2002 -Message $_
    }
    Pause
}

function Executar-CHKDSK {
    [CmdletBinding()]
    param()
    try {
        Write-Host "💾 Agendando CHKDSK no próximo boot..." -ForegroundColor Yellow
        "Y" | cmd /c "chkdsk C: /F /R"
        Write-Host "✅ CHKDSK agendado." -ForegroundColor Green
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 3001 -Message "CHKDSK agendado para próximo boot."
    } catch {
        Write-Error "❌ Erro ao agendar CHKDSK: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 3002 -Message $_
    }
    Pause
}

function Executar-Limpeza {
    [CmdletBinding()]
    param()
    $pastas = @($env:TEMP, "$env:windir\Temp")
    foreach ($pasta in $pastas) {
        try {
            Write-Host "🧹 Limpando: $pasta" -ForegroundColor Yellow
            Get-ChildItem -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue `
                | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "✅ Limpeza de $pasta concluída." -ForegroundColor Green
            Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 4001 -Message "Limpeza de $pasta concluída."
        } catch {
            Write-Error "❌ Erro ao limpar ${pasta}: $_"
            Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 4002 -Message $_
        }
    }
    Pause
}

function Verificar-SMART {
    [CmdletBinding()]
    param()
    try {
        Write-Host "🧪 Verificando SMART dos discos..." -ForegroundColor Yellow
        Get-WmiObject -Class Win32_DiskDrive | Select-Object Model, Status
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 5001 -Message "Verificação SMART concluída."
    } catch {
        Write-Error "❌ Erro no SMART: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 5002 -Message $_
    }
    Pause
}

function Diagnostico-Rede {
    [CmdletBinding()]
    param()
    try {
        Write-Host "🌐 Iniciando diagnóstico de rede..." -ForegroundColor Yellow
        ipconfig /release
        ipconfig /renew
        ipconfig /flushdns
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 6001 -Message "Diagnóstico de rede concluído."
    } catch {
        Write-Error "❌ Erro no diagnóstico de rede: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 6002 -Message $_
    }
    Pause
}

function Reiniciar-WU {
    [CmdletBinding()]
    param()
    try {
        Write-Host "♻️  Reiniciando Windows Update..." -ForegroundColor Yellow
        $services = "wuauserv","cryptSvc","bits","msiserver"
        foreach ($svc in $services) { Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue }
        Rename-Item "$env:windir\SoftwareDistribution" "SoftwareDistribution.old" -ErrorAction SilentlyContinue
        Rename-Item "$env:windir\System32\catroot2" "catroot2.old" -ErrorAction SilentlyContinue
        foreach ($svc in $services) { Start-Service -Name $svc -ErrorAction SilentlyContinue }
        Write-Host "✅ Windows Update reiniciado." -ForegroundColor Green
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 7001 -Message "Windows Update reiniciado."
    } catch {
        Write-Error "❌ Erro ao reiniciar Windows Update: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 7002 -Message $_
    }
    Pause
}

function Resetar-Spooler {
    [CmdletBinding()]
    param(
        [string] $PrinterName  # opcional, se quiser focar em só uma impressora
    )
    try {
        Write-Host "🖨️  Parando serviço de impressão..." -ForegroundColor Yellow
        Stop-Service Spooler -Force

        Write-Host "🔪 Matando processos remanescentes..." -ForegroundColor Yellow
        Get-Process spoolsv -ErrorAction SilentlyContinue | Stop-Process -Force

        Write-Host "🗑️  Limpando arquivos de spool..." -ForegroundColor Yellow
        Remove-Item -Path "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

        if ($PrinterName) {
            Write-Host "❌ Removendo driver da impressora $PrinterName..." -ForegroundColor Yellow
            # Remove-Printer só existe no Windows 8+/Server 2012+
            Remove-Printer -Name $PrinterName -ErrorAction SilentlyContinue
            # (re)instalar driver pode ser feito aqui se você tiver o INF disponível:
            # Add-Printer -Name $PrinterName -DriverName "NomeDoDriver" -PortName "PORTA"
        }

        Write-Host "▶️  Reiniciando serviço de impressão..." -ForegroundColor Yellow
        Start-Service Spooler

        Write-Host "✅ Spooler resetado." -ForegroundColor Green
    } catch {
        Write-Error "❌ Falha ao resetar spooler: $_"
    }
    Pause
}


function Agendar-Tarefa {
    [CmdletBinding()]
    param()
    try {
        Write-Host "📅 Agendando limpeza diária..." -ForegroundColor Yellow
        $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command \`"Get-ChildItem -Path `$env:TEMP -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue; Get-ChildItem -Path `$env:windir\Temp -Recurse -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue\`""
        $trigger = New-ScheduledTaskTrigger -Daily -At 4am
        $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal
        Register-ScheduledTask -TaskName 'LimpezaDiaria_TEMP' -InputObject $task -Force
        Write-Host "✅ Tarefa agendada: LimpezaDiaria_TEMP" -ForegroundColor Green
        Write-EventLog -LogName Application -Source $source -EntryType Information -EventId 8001 -Message "Tarefa LimpezaDiaria_TEMP agendada."
    } catch {
        Write-Error "❌ Falha ao agendar tarefa: $_"
        Write-EventLog -LogName Application -Source $source -EntryType Error -EventId 8002 -Message $_
    }
    Pause
}

# Loop principal
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção"

    switch ($opcao) {
        '1' { Executar-SFC }
        '2' { Executar-DISM }
        '3' { Executar-CHKDSK }
        '4' { Executar-Limpeza }
        '5' { Verificar-SMART }
        '6' { Diagnostico-Rede }
        '7' { Reiniciar-WU }
        '8' { Stop-Transcript; exit }
        '9' { Limpar-FilaImpressao }
        Default {
            Write-Host "❗ Opção inválida." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
