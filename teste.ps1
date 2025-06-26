#region INICIALIZAÇÃO E VERIFICAÇÃO DE PRIVILÉGIOS
# ----------------------------------------------------------------------------------
# Script: Ferramenta de Manutenção do Sistema - DouraGlass (Versão Robusta)
# Autor: Seu Nome (com melhorias do Ajudante de Programação)
# Versão: 2.1
# Descrição: Um script PowerShell para realizar tarefas comuns de manutenção
#            do sistema de forma segura e com logging.
# ----------------------------------------------------------------------------------

# Parâmetro para permitir a execução de uma ação específica (usado pela tarefa agendada)
param (
    [switch]$AcaoLimpezaAgendada
)

# Define o caminho do ficheiro de log de forma robusta
if ($PSScriptRoot) {
    # Se o script for executado a partir de um ficheiro, guarda o log na mesma pasta
    $LogPath = $PSScriptRoot
} else {
    # Se executado interativamente (ex: ISE ou colado na consola), usa a pasta TEMP como fallback
    $LogPath = $env:TEMP
    Write-Host "AVISO: Script a ser executado em modo interativo. O ficheiro de log será guardado em: $LogPath" -ForegroundColor Yellow
}
$LogFile = Join-Path -Path $LogPath -ChildPath "manutencao_log.txt"


# Função para escrever mensagens no console e no ficheiro de log
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO" # Níveis podem ser INFO, WARN, ERROR, GREEN
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] - $Message"
    
    # Adiciona a mensagem ao ficheiro de log
    try {
        Add-Content -Path $LogFile -Value $LogMessage -ErrorAction Stop
    } catch {
        Write-Host "ERRO CRÍTICO: Não foi possível escrever no ficheiro de log em $LogFile. Erro: $_" -ForegroundColor Red
    }
    
    # Exibe a mensagem no console com cores apropriadas
    $Color = switch ($Level) {
        "INFO"  { "White" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "GREEN" { "Green" }
        default { "White" }
    }
    Write-Host $LogMessage -ForegroundColor $Color
}

# 🚨 Verificar e solicitar elevação de privilégios se necessário
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log -Message "Permissões de administrador necessárias. A reiniciar o script com elevação..." -Level "WARN"
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Se o script foi chamado com o parâmetro de limpeza, executa e sai
if ($AcaoLimpezaAgendada.IsPresent) {
    Write-Log -Message "Executando limpeza agendada..."
    Executar-Limpeza -Silencioso
    Write-Log -Message "Limpeza agendada concluída."
    exit
}

# Configuração da Janela
$Host.UI.RawUI.WindowTitle = "🔧 Ferramenta de Manutenção do Sistema - DouraGlass v2.1"
$Host.UI.RawUI.ForegroundColor = "Yellow"
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
Clear-Host

Write-Log -Message "Ferramenta iniciada. Log sendo gravado em: $LogFile" -Level "INFO"

#endregion

#region FUNÇÕES DE MENU E AÇÕES (As funções permanecem as mesmas da versão anterior)

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
    Write-Host "[3] 💾 Agendar verificação de disco (CHKDSK C:)"
    Write-Host "[4] 🧹 Limpeza de arquivos temporários"
    Write-Host "[5] 🧪 Verificar status SMART do disco"
    Write-Host ""
    Write-Host "--- REDE E ATUALIZAÇÕES ---" -ForegroundColor Green
    Write-Host "[6] 🌐 Diagnóstico de rede"
    Write-Host "[7] ♻️  Redefinir componentes do Windows Update"
    Write-Host ""
    Write-Host "--- OUTROS ---" -ForegroundColor Green
    Write-Host "[9] 📅 Agendar limpeza diária"
    Write-Host ""
    Write-Host "--- SAIR ---"
    Write-Host "[8] ❌ Sair"
    Write-Host ""
}

function Executar-SFC {
    Clear-Host
    Write-Log -Message "Executando verificação do sistema (SFC /scannow)..."
    try {
        $process = Start-Process sfc.exe -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Log -Message "SFC /scannow concluído com sucesso." -Level "GREEN"
        } else {
            Write-Log -Message "SFC /scannow encontrou problemas. Código de saída: $($process.ExitCode)" -Level "WARN"
        }
    } catch {
        Write-Log -Message "Falha ao executar o SFC. Erro: $_" -Level "ERROR"
    }
    Read-Host "Pressione ENTER para continuar..."
}

function Executar-DISM {
    Clear-Host
    Write-Log -Message "Executando DISM /Online /Cleanup-Image /RestoreHealth..."
    try {
        $process = Start-Process DISM.exe -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Log -Message "DISM concluído com sucesso." -Level "GREEN"
        } else {
            Write-Log -Message "DISM encontrou problemas. Código de saída: $($process.ExitCode)" -Level "WARN"
        }
    } catch {
        Write-Log -Message "Falha ao executar o DISM. Erro: $_" -Level "ERROR"
    }
    Read-Host "Pressione ENTER para continuar..."
}

function Executar-CHKDSK {
    Clear-Host
    Write-Log -Message "Agendando verificação do disco (CHKDSK C: /F /R) na próxima reinicialização." -Level "WARN"
    Write-Host "Esta operação requer uma reinicialização para ser executada."
    
    try {
        chkdsk C: /f /r
        Write-Log -Message "O CHKDSK foi agendado. Por favor, reinicie o computador para iniciar a verificação." -Level "GREEN"
    } catch {
        Write-Log -Message "Falha ao agendar o CHKDSK. Erro: $_" -Level "ERROR"
    }
    Read-Host "Pressione ENTER para continuar..."
}

function Executar-Limpeza {
    param (
        [switch]$Silencioso # Parâmetro para não pausar no final (para tarefas agendadas)
    )
    Clear-Host
    Write-Log -Message "Iniciando limpeza de arquivos temporários..."
    
    $pastas = @(
        $env:TEMP,
        "$env:windir\Temp"
    )
    $totalRemovido = 0
    
    foreach ($pasta in $pastas) {
        if (Test-Path $pasta) {
            Write-Log -Message "Limpando pasta: $pasta"
            $arquivos = Get-ChildItem -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($arquivo in $arquivos) {
                try {
                    $totalRemovido += $arquivo.Length
                    Remove-Item -Path $arquivo.FullName -Force -Recurse -ErrorAction Stop
                } catch {
                    Write-Log -Message "Não foi possível remover '$($arquivo.FullName)'. Pode estar em uso. Erro: $($_.Exception.Message)" -Level "WARN"
                }
            }
        } else {
            Write-Log -Message "Pasta não encontrada: $pasta" -Level "WARN"
        }
    }
    
    # Converte o total para um formato legível
    $totalMB = [math]::Round($totalRemovido / 1MB, 2)
    Write-Log -Message "Limpeza concluída. Total de espaço potencialmente liberado: $totalMB MB." -Level "GREEN"

    if (-not $Silencioso) {
        Read-Host "Pressione ENTER para continuar..."
    }
}

function Verificar-SMART {
    Clear-Host
    Write-Log -Message "Verificando status SMART dos discos..."
    try {
        $discos = Get-PhysicalDisk | Select-Object DeviceId, Model, @{Name="Status"; Expression = {$_.HealthStatus}}, Size
        $discos | Format-Table -AutoSize
        
        foreach ($disco in $discos) {
            Write-Log -Message "Disco $($disco.DeviceId) ($($disco.Model)): Status $($disco.Status)"
            if ($disco.Status -ne 'Healthy') {
                Write-Log -Message "Atenção: O disco $($disco.Model) reporta um status preocupante: $($disco.Status)." -Level "WARN"
            }
        }
    } catch {
        Write-Log -Message "Não foi possível obter o status SMART. Este comando requer PowerShell 5+ e sistemas modernos. Erro: $_" -Level "ERROR"
    }
    Read-Host "Pressione ENTER para continuar..."
}

function Diagnostico-Rede {
    Clear-Host
    Write-Log -Message "Executando diagnóstico de rede..."
    try {
        Write-Log -Message "Liberando concessão de IP..."
        ipconfig /release | Out-Null
        Write-Log -Message "Renovando concessão de IP..."
        ipconfig /renew | Out-Null
        Write-Log -Message "Limpando cache DNS..."
        ipconfig /flushdns | Out-Null
        Write-Log -Message "Diagnóstico de rede concluído com sucesso." -Level "GREEN"
    } catch {
        Write-Log -Message "Ocorreu um erro durante o diagnóstico de rede. Erro: $_" -Level "ERROR"
    }
    Read-Host "Pressione ENTER para continuar..."
}

function Reiniciar-WU {
    Clear-Host
    Write-Log -Message "Redefinindo componentes do Windows Update..."
    $servicos = "wuauserv", "cryptSvc", "bits", "msiserver"
    
    try {
        Write-Log -Message "Parando serviços do Windows Update..."
        Stop-Service -Name $servicos -Force -ErrorAction Stop
        
        Write-Log -Message "Renomeando pastas de cache do Windows Update..."
        $sdOld = "C:\Windows\SoftwareDistribution.old"
        $crOld = "C:\Windows\System32\catroot2.old"
        if (Test-Path $sdOld) { Remove-Item $sdOld -Recurse -Force }
        if (Test-Path $crOld) { Remove-Item $crOld -Recurse -Force }
        Rename-Item -Path "C:\Windows\SoftwareDistribution" -NewName "SoftwareDistribution.old" -ErrorAction Stop
        Rename-Item -Path "C:\Windows\System32\catroot2" -NewName "catroot2.old" -ErrorAction Stop
        
        Write-Log -Message "Iniciando serviços do Windows Update..."
        Start-Service -Name $servicos -ErrorAction Stop
        
        Write-Log -Message "Componentes do Windows Update redefinidos com sucesso." -Level "GREEN"
    } catch {
        Write-Log -Message "Falha ao redefinir o Windows Update. Erro: $_. Pode ser necessário reiniciar e tentar novamente." -Level "ERROR"
    }
    
    Read-Host "Pressione ENTER para continuar..."
}

function Agendar-Tarefa {
    Clear-Host
    Write-Log -Message "Agendamento de tarefa de limpeza diária."
    
    $taskName = "Limpeza_TEMP_Diaria_DouraGlass"
    # Esta verificação é crucial para o agendamento de tarefas.
    # $PSCommandPath só funciona quando executado de um ficheiro.
    if (-not $PSCommandPath) {
        Write-Log -Message "ERRO: Para agendar uma tarefa, este script DEVE ser salvo como um ficheiro .ps1 e executado a partir dele." -Level "ERROR"
        Read-Host "Pressione ENTER para continuar..."
        return
    }
    $scriptParaExecutar = $PSCommandPath # O caminho completo deste script

    try {
        # Ação: Executar este mesmo script com o parâmetro -AcaoLimpezaAgendada
        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptParaExecutar`" -AcaoLimpezaAgendada"
        
        # Gatilho: Diariamente às 04:00
        $trigger = New-ScheduledTaskTrigger -Daily -At 4:00AM
        
        # Principal: Executar como SYSTEM para garantir permissões, mesmo que ninguém esteja logado
        $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest
        
        # Configurações: Não iniciar se estiver em bateria, parar se a bateria for usada
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries:$false -StopIfGoingOnBatteries:$true
        
        Write-Log -Message "A registar a tarefa agendada '$taskName'..."
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
        
        Write-Log -Message "Tarefa '$taskName' agendada com sucesso! Será executada todos os dias às 04:00." -Level "GREEN"
    } catch {
        Write-Log -Message "Falha ao agendar a tarefa. Erro: $_" -Level "ERROR"
    }
    
    Read-Host "Pressione ENTER para continuar..."
}

#endregion

#region LOOP PRINCIPAL DO MENU

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
        "8" { Write-Log -Message "Saindo da ferramenta."; break } # Usar 'break' é uma prática mais limpa para sair de loops
        "9" { Agendar-Tarefa }
        Default {
            Write-Host ""; Write-Host "❗ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)

#endregion
