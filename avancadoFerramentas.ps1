#region Script Configuration
# ======================================================================================================================
# 🔧 Ferramenta de Manutenção do Sistema - DouraGlass v2.0
# Descrição: Script para realizar tarefas comuns de manutenção e reparo do Windows.
# Autor: Seu Nome (com ajuda do Parceiro de Programacao)
# Versão: 2.0
# ======================================================================================================================

# Define o comportamento do script, como tratamento de erros.
[CmdletBinding()]
param (
    # Parâmetro para executar a limpeza de forma silenciosa quando agendado.
    [Switch]$ScheduledClean
)
#endregion

#region Funções Auxiliares

# Função para registrar logs e exibir mensagens na tela.
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$ForegroundColor = 'White'
    )
    # Exibe a mensagem no console.
    Write-Host $Message -ForegroundColor $ForegroundColor
    # (Opcional) Adiciona a mensagem a um arquivo de log.
    # Add-Content -Path "Caminho\Para\Seu\Log.txt" -Value "$(Get-Date) - $Message"
}

#endregion

#region Verificação de Privilégios e Configuração Inicial

# 🚨 Verifica se o script está sendo executado como Administrador.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Log "⏫ Permissões de administrador necessárias. Reabrindo o script..." -ForegroundColor Yellow
    # Reinicia o script com privilégios elevados.
    Start-Process powershell.exe "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Configura a janela do PowerShell.
$Host.UI.RawUI.WindowTitle = "🔧 Ferramenta de Manutenção do Sistema - DouraGlass v2.0"
$Host.UI.RawUI.ForegroundColor = "White"
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
Clear-Host

#endregion

#region Funções do Menu

function Mostrar-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "    🔧 FERRAMENTA DE MANUTENÇÃO DO SISTEMA" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "--- SISTEMA ---" -ForegroundColor Green
    Write-Host "[1] 🔍 Verificar arquivos do sistema (SFC)"
    Write-Host "[2] 🛠️  Reparo da imagem do sistema (DISM)"
    Write-Host
    Write-Host "--- DISCO ---" -ForegroundColor Green
    Write-Host "[3] 💾 Agendar verificação de disco (CHKDSK)"
    Write-Host "[4] 🧹 Limpeza de arquivos temporários"
    Write-Host "[5] 🧪 Verificar status SMART do disco"
    Write-Host
    Write-Host "--- REDE E ATUALIZAÇÕES ---" -ForegroundColor Green
    Write-Host "[6] 🌐 Diagnóstico de rede"
    Write-Host "[7] ♻️  Reiniciar componentes do Windows Update"
    Write-Host
    Write-Host "--- OUTROS ---" -ForegroundColor Green
    Write-Host "[8] 📅 Agendar tarefa de limpeza diária"
    Write-Host "[9] 🖨️ Limpar fila de impressão"
    Write-Host
    Write-Host "--- SAIR ---"
    Write-Host "[0] ❌ Sair"
    Write-Host
}

function Executar-SFC {
    Clear-Host
    Write-Log "🔍 Executando verificação de arquivos do sistema (SFC)..." -ForegroundColor Yellow
    Write-Log "Este processo pode demorar alguns minutos. Por favor, aguarde."

    # Inicia o processo e aguarda sua conclusão.
    $process = Start-Process sfc.exe -ArgumentList "/scannow" -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Log "`n✔️ Verificação SFC concluída com sucesso." -ForegroundColor Green
    } else {
        Write-Log "`n❌ Ocorreu um erro durante a execução do SFC. Código de saída: $($process.ExitCode)" -ForegroundColor Red
        Write-Log "Consulte o log em C:\Windows\Logs\CBS\CBS.log para mais detalhes." -ForegroundColor Yellow
    }
    Read-Host "`nPressione ENTER para voltar ao menu"
}

function Executar-DISM {
    Clear-Host
    Write-Log "🛠️  Executando reparo da imagem do sistema (DISM)..." -ForegroundColor Yellow
    Write-Log "Este processo pode demorar bastante e requer conexão com a internet. Por favor, aguarde."

    $arguments = "/Online /Cleanup-Image /RestoreHealth"
    $process = Start-Process DISM.exe -ArgumentList $arguments -Wait -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Log "`n✔️ Reparo da imagem DISM concluído com sucesso." -ForegroundColor Green
    } else {
        Write-Log "`n❌ Ocorreu um erro durante a execução do DISM. Código de saída: $($process.ExitCode)" -ForegroundColor Red
        Write-Log "Consulte o log em C:\Windows\Logs\DISM\dism.log para mais detalhes." -ForegroundColor Yellow
    }
    Read-Host "`nPressione ENTER para voltar ao menu"
}

function Executar-CHKDSK {
    Clear-Host
    Write-Log "💾 Agendando verificação de disco (CHKDSK)..." -ForegroundColor Yellow
    Write-Log "O CHKDSK será executado na próxima vez que o computador for reiniciado." -ForegroundColor Cyan

    try {
        # Usando a variável de ambiente para o disco do sistema.
        chkdsk.exe $env:SystemDrive /f /r
        Write-Log "`n✔️ CHKDSK agendado com sucesso para a unidade $env:SystemDrive." -ForegroundColor Green
        Write-Log "Reinicie o computador para iniciar a verificação." -ForegroundColor Yellow
    } catch {
        Write-Log "`n❌ Falha ao agendar o CHKDSK. Erro: $_" -ForegroundColor Red
    }
    Read-Host "`nPressione ENTER para voltar ao menu"
}

function Executar-Limpeza {
    Clear-Host
    Write-Log "🧹 Limpando arquivos temporários..." -ForegroundColor Yellow
    
    # Lista de pastas a serem limpas.
    $pastas = @(
        [System.IO.Path]::GetTempPath(), # Pasta Temp do usuário atual
        "$env:windir\Temp"               # Pasta Temp do Windows
    )

    foreach ($pasta in $pastas) {
        if (Test-Path $pasta) {
            Write-Log "`n🗂️  Limpando: $pasta" -ForegroundColor Cyan
            try {
                # Pega os itens e os remove. O -ErrorAction SilentlyContinue ignora arquivos em uso.
                Get-ChildItem -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                Write-Log "✔️  Limpeza de $pasta concluída." -ForegroundColor Green
            } catch {
                # Captura erros inesperados durante a limpeza.
                Write-Log "❌ Falha ao limpar '$pasta': $($_.Exception.Message)" -ForegroundColor Red
            }
        } else {
            Write-Log "`n⚠️ Pasta não encontrada: $pasta" -ForegroundColor Yellow
        }
    }
    Read-Host "`nPressione ENTER para voltar ao menu"
}

function Verificar-SMART {
    Clear-Host
    Write-Log "🧪 Verificando status SMART dos discos..." -ForegroundColor Yellow
    try {
        # Usando Get-CimInstance, que é o comando moderno.
        $discos = Get-CimInstance -ClassName Win32_DiskDrive
        foreach ($disco in $discos) {
            Write-Host "`nModelo: $($disco.Model)"
            $status = switch ($disco.Status) {
                "OK" { Write-Host "Status: $($disco.Status)" -ForegroundColor Green }
                default { Write-Host "Status: $($disco.Status)" -ForegroundColor Red }
            }
        }
    } catch {
        Write-Log "`n❌ Não foi possível verificar o status SMART. Erro: $($_.Exception.Message)" -ForegroundColor Red
    }
    Read-Host "`nPressione ENTER para voltar ao menu"
}

function Diagnostico-Rede-Debug {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Comando,

        [Parameter(Mandatory=$true)]
        [string]$MensagemSucesso,

        [Parameter(Mandatory=$true)]
        [string]$MensagemProgresso,
        
        [Parameter(Mandatory=$false)]
        [boolean]$PausarAoFinal = $true
    )

    try {
        Write-Host "`n$MensagemProgresso" -ForegroundColor Yellow
        
        # O comando Invoke-Expression executa uma string como se fosse um comando
        Invoke-Expression -Command $Comando

        Write-Host "`n✔️ $MensagemSucesso" -ForegroundColor Green
    }
    catch {
        Write-Host "`n❌ Ocorreu um erro ao executar o comando '$Comando'." -ForegroundColor Red
        Write-Host "   Detalhes do erro: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        # Uma pausa mais explícita para o usuário
        if($PausarAoFinal) {
            Read-Host "`nPressione Enter para continuar..." | Out-Null
        }
        
    }
}

function Diagnostico-Rede {
    
    # O loop do-until garante que o menu seja exibido pelo menos uma vez
    # e continue aparecendo até que a escolha seja "0".
    do {
        Clear-Host
        Write-Host "📅 MENU DE CONFIGURAÇÃO DE REDE" -ForegroundColor Cyan
        Write-Host "`n[1] 🌐 Renovar Configurações de Rede (Liberar, Renovar, Limpar DNS)" -ForegroundColor Yellow
        Write-Host "[2] 🔁 Reset de IP (Liberar e Renovar IP)" -ForegroundColor Yellow
        Write-Host "[3] 🧹 Limpar DNS (Limpar cache DNS)" -ForegroundColor Yellow
        Write-Host "[4] 📴 Desconectar IP (Liberar IP atual)" -ForegroundColor Yellow
        Write-Host "[5] 📶 Reconectar IP (Solicitar novo IP)" -ForegroundColor Yellow
        Write-Host "[0] ⬅️ Voltar ao menu principal" -ForegroundColor Gray

        $escolhaREDE = Read-Host "`nEscolha uma opção"

        switch ($escolhaREDE) {
            "1" {
                # Executa cada comando sem pausar
                Diagnostico-Rede-Debug  -Comando "ipconfig /release" -MensagemProgresso "Liberando IP atual..." -MensagemSucesso "IP Liberado." -PausarAoFinal $false
                Diagnostico-Rede-Debug  -Comando "ipconfig /renew" -MensagemProgresso "Renovando concessão de IP..." -MensagemSucesso "IP Renovado." -PausarAoFinal $false
                Diagnostico-Rede-Debug  -Comando "ipconfig /flushdns" -MensagemProgresso "Limpando cache DNS..." -MensagemSucesso "Cache DNS limpo." -PausarAoFinal $false
            
                # Adiciona uma mensagem final e uma única pausa
                Write-Host "`n✅ Feito!" -ForegroundColor Green
                Read-Host "`nPressione Enter para continuar..." | Out-Null
            }
            "2" {
                Diagnostico-Rede-Debug -Comando "ipconfig /release" -MensagemProgresso "Liberando IP atual..." -MensagemSucesso "IP Liberado." -PausarAoFinal $false
                Diagnostico-Rede-Debug -Comando "ipconfig /renew" -MensagemProgresso "Solicitando novo IP..." -MensagemSucesso "Reset de IP feito." -PausarAoFinal $false
                
                # Adiciona uma mensagem final e uma única pausa
                Write-Host "`n✅ Feito!" -ForegroundColor Green
                Read-Host "`nPressione Enter para continuar..." | Out-Null
            }
            "3" {
                Diagnostico-Rede-Debug -Comando "ipconfig /flushdns" -MensagemProgresso "Limpando cache DNS..." -MensagemSucesso "Cache DNS limpo." -PausarAoFinal $false

                # Adiciona uma mensagem final e uma única pausa
                Read-Host "`nPressione Enter para continuar..." | Out-Null
            }
            "4" {
                Diagnostico-Rede-Debug -Comando "ipconfig /release" -MensagemProgresso "Desconectar IP..." -MensagemSucesso "IP atual liberado." -PausarAoFinal $false
                
                # Adiciona uma mensagem final e uma única pausa
                Read-Host "`nPressione Enter para continuar..." | Out-Null
            }
            "5" {
                Diagnostico-Rede-Debug -Comando "ipconfig /renew" -MensagemProgresso "Reconectar IP..." -MensagemSucesso "IP renovado." -PausarAoFinal $false
            
                # Adiciona uma mensagem final e uma única pausa
                Read-Host "`nPressione Enter para continuar..." | Out-Null
            }
            "0" {
                Write-Host "`nSaindo do menu de rede..." -ForegroundColor Gray
            }
            Default {
                Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($escolhaREDE -ne "0")
}

function Reiniciar-WU {
    Clear-Host
    Write-Log "♻️  Redefinindo componentes do Windows Update..." -ForegroundColor Yellow
    
    $servicos = "wuauserv", "cryptSvc", "bits", "msiserver"
    $pastas = @(
        "$env:windir\SoftwareDistribution",
        "$env:windir\System32\catroot2"
    )

    try {
        Write-Log "Parando serviços do Windows Update..."
        Stop-Service -Name $servicos -Force -ErrorAction Stop

        Write-Log "Renomeando pastas de cache..."
        foreach ($pasta in $pastas) {
            if (Test-Path $pasta) {
                Rename-Item -Path $pasta -NewName "$($pasta).old" -Force -ErrorAction Stop
            }
        }

        Write-Log "Iniciando serviços do Windows Update..."
        Start-Service -Name $servicos -ErrorAction Stop

        Write-Log "`n✔️ Componentes do Windows Update redefinidos com sucesso." -ForegroundColor Green
    } catch {
        Write-Log "`n❌ Falha ao redefinir o Windows Update. Erro: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "Pode ser necessário reiniciar o computador." -ForegroundColor Yellow
    }
    
    Read-Host "`nPressione ENTER para voltar ao menu"
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

function Limpar-FilaImpressao{
    param(
        [String] $PrinterName 
    )
    try{
        Write-Host "🖨️  Parando serviço de impressão..." -ForegroundColor Yellow
        Stop-Service Spooler -Force

        Write-Host "🔪 Matando processos remanescentes..." -ForegroundColor Yellow
        Get-Process spoolsv -ErrorAction SilentlyContinue | Stop-Process -Force

        Write-Host "🗑️  Limpando arquivos de spool..." -ForegroundColor Yellow
        Remove-Item -Path "$env:WINDIR\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue

        if($PrinterName){
            Write-Host "❌ Removendo driver da impressora $PrinterName..." -ForegroundColor Yellow
            Remove-Printer -Name $PrinterName -ErrorAction SilentlyContinue
        }
        Write-Host "▶️  Reiniciando serviço de impressão..." -ForegroundColor Yellow
        Start-Service Spooler

        Write-Host "✅ Spooler resetado." -ForegroundColor Green
    } catch {
        Write-Error "❌ Falha ao resetar spooler: $_"
    }
    Pause
}

function Limpar-FilaImpressao {
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

#endregion

#region Lógica Principal de Execução

# Se o script foi chamado com o parâmetro -ScheduledClean, ele apenas executa a limpeza e sai.
if ($ScheduledClean.IsPresent) {
    # Suprime toda a saída visual para execução silenciosa
    Executar-Limpeza | Out-Null
    exit
}

# Loop principal do menu interativo
do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção"

    switch ($opcao) {
        "0" { exit }
        "1" { Executar-SFC }
        "2" { Executar-DISM }
        "3" { Executar-CHKDSK }
        "4" { Executar-Limpeza }
        "5" { Verificar-SMART }
        "6" { Diagnostico-Rede }
        "7" { Reiniciar-WU }
        "8" { Agendar-Tarefa }
        "9" { Limpar-FilaImpressao }
        default {
            Write-Log "`n❗ Opção inválida. Por favor, tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)

#endregion
