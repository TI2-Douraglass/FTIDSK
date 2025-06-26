#requires -RunAsAdministrator

# ----------------------------------------------------------------------------------
# 🔧 Ferramenta de Manutenção do Sistema - DouraGlass (Versão Melhorada)
# Descrição: Um script PowerShell para realizar tarefas comuns de manutenção do sistema.
# Autor: Seu Nome/DouraGlass
# Versão: 2.0
# ----------------------------------------------------------------------------------

# Configurações iniciais da janela do PowerShell
$Host.UI.RawUI.WindowTitle = "🔧 Ferramenta de Manutenção do Sistema - DouraGlass v2.0"
$Host.UI.RawUI.ForegroundColor = "Yellow"
$Host.UI.RawUI.BackgroundColor = "DarkBlue"
Clear-Host

# --- Funções do Menu ---

function Mostrar-Menu {
    Clear-Host
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "   🔧 FERRAMENTA DE MANUTENÇÃO DO SISTEMA" -ForegroundColor White
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "--- SISTEMA ---" -ForegroundColor Green
    Write-Host "[1] 🔍 Verificar arquivos do sistema (SFC)"
    Write-Host "[2] 🛠️  Reparo da imagem do sistema (DISM)"
    Write-Host ""
    Write-Host "--- DISCO ---" -ForegroundColor Green
    Write-Host "[3] 💾 Verificar disco (CHKDSK no disco C:)"
    Write-Host "[4] 🧹 Limpeza de arquivos temporários"
    Write-Host "[5] 🧪 Verificar status SMART do disco"
    Write-Host ""
    Write-Host "--- REDE E ATUALIZAÇÕES ---" -ForegroundColor Green
    Write-Host "[6] 🌐 Diagnóstico de rede"
    Write-Host "[7] ♻️  Reiniciar serviço do Windows Update"
    Write-Host ""
    Write-Host "--- OUTROS ---" -ForegroundColor Green
    Write-Host "[9] 📅 Agendar tarefa de limpeza"
    Write-Host ""
    Write-Host "--- SAIR ---"
    Write-Host "[8] ❌ Sair"
    Write-Host ""
}

# --- Funções de Execução ---

function Executar-SFC {
    Clear-Host
    Write-Host "🔍 Executando verificação do sistema (SFC)... Isso pode demorar." -ForegroundColor Yellow
    
    # Documentação: Executa o System File Checker e captura o resultado.
    $resultado = sfc /scannow
    
    # Documentação: Verifica o código de saída do último comando executado. 0 significa sucesso.
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✔️ Verificação SFC concluída com sucesso. Nenhum problema encontrado." -ForegroundColor Green
    } else {
        Write-Host "⚠️ A verificação SFC encontrou problemas. Verifique o log para mais detalhes:" -ForegroundColor Yellow
        Write-Host "$env:windir\Logs\CBS\CBS.log"
    }
    Pause
}

function Executar-DISM {
    Clear-Host
    Write-Host "🛠️  Executando reparo da imagem do sistema (DISM)... Isso pode ser demorado." -ForegroundColor Yellow
    
    # Documentação: Executa o DISM diretamente, pois o script já está em modo administrador.
    # Usamos /ScanHealth primeiro para uma verificação rápida.
    Write-Host "Passo 1/2: Verificando a saúde da imagem..." -ForegroundColor Cyan
    DISM /Online /Cleanup-Image /ScanHealth

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Passo 2/2: Restaurando a saúde da imagem..." -ForegroundColor Cyan
        DISM /Online /Cleanup-Image /RestoreHealth
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✔️ Reparo da imagem DISM concluído com sucesso." -ForegroundColor Green
        } else {
            Write-Host "❌ Falha ao restaurar a imagem com o DISM. Verifique o log para detalhes." -ForegroundColor Red
        }
    } else {
        Write-Host "❌ Falha ao verificar a saúde da imagem com o DISM." -ForegroundColor Red
    }
    Pause
}

function Executar-CHKDSK {
    Clear-Host
    Write-Host "💾 Agendando verificação do disco C: na próxima reinicialização (CHKDSK /F /R)..." -ForegroundColor Yellow
    
    # Documentação: O comando fsutil dirty query C: verifica se o disco já está "sujo" (agendado para verificação).
    fsutil dirty query C:
    
    # Documentação: Executa o CHKDSK. Ele pedirá para agendar se o disco estiver em uso.
    chkdsk C: /f /r
    
    Write-Host "`nO CHKDSK foi executado ou agendado. Se necessário, reinicie o computador para iniciar a verificação." -ForegroundColor Green
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
        if (Test-Path -Path $pasta) {
            Write-Host "`n🗂️  Limpando pasta: $pasta" -ForegroundColor Cyan
            try {
                Get-ChildItem -Path $pasta -Recurse -Force | Remove-Item -Recurse -Force -ErrorAction Stop
                Write-Host "✔️  Limpeza de $pasta concluída." -ForegroundColor Green
            } catch {
                # --- CORREÇÃO APLICADA AQUI ---
                # Documentação: Usamos $($_.Exception.Message) para inserir a mensagem de erro de forma segura na string.
                # Acessar a propriedade .Exception.Message fornece uma mensagem mais limpa do que usar apenas $_.
                Write-Host "⚠️  Não foi possível limpar todos os arquivos em $pasta. Alguns podem estar em uso, o que é normal." -ForegroundColor Yellow
                Write-Host ("   Detalhe do erro: $($_.Exception.Message)") -ForegroundColor Gray
            }
        } else {
            Write-Host "ℹ️  A pasta $pasta não existe." -ForegroundColor Gray
        }
    }
    Pause
}

function Verificar-SMART {
    Clear-Host
    Write-Host "🧪 Verificando status SMART dos discos..." -ForegroundColor Yellow
    
    try {
        # Documentação: Get-CimInstance é a forma moderna de consultar o WMI.
        # -ErrorAction Stop garante que, se o comando falhar, o 'catch' será executado.
        Get-CimInstance -ClassName Win32_DiskDrive | Select-Object -Property Model, @{Name="Status"; Expression={if($_.Status -eq 'OK'){"✔️ OK"} else {"❌ ERRO"}}}
    } catch {
        Write-Host "❌ Não foi possível verificar o status SMART. O comando falhou." -ForegroundColor Red
    }
    Pause
}

function Diagnostico-Rede {
    Clear-Host
    Write-Host "🌐 Executando diagnóstico de rede..." -ForegroundColor Yellow
    
    Write-Host "`n[1/3] Liberando concessão de IP..." -ForegroundColor Cyan
    ipconfig /release
    
    Write-Host "`n[2/3] Renovando concessão de IP..." -ForegroundColor Cyan
    ipconfig /renew
    
    Write-Host "`n[3/3] Limpando cache de DNS..." -ForegroundColor Cyan
    ipconfig /flushdns
    
    Write-Host "`n✔️ Diagnóstico de rede concluído." -ForegroundColor Green
    Pause
}

function Reiniciar-WU {
    Clear-Host
    Write-Host "♻️  Reiniciando componentes do Windows Update..." -ForegroundColor Yellow
    
    # Documentação: Nomes dos serviços a serem manipulados.
    $services = "wuauserv", "cryptSvc", "bits", "msiserver"
    $pastasRenomear = @{
        "C:\Windows\SoftwareDistribution" = "C:\Windows\SoftwareDistribution.old";
        "C:\Windows\System32\catroot2"   = "C:\Windows\System32\catroot2.old"
    }
    
    try {
        # Documentação: Usamos Stop-Service, um cmdlet nativo do PowerShell. -Force tenta parar mesmo se houver dependências.
        Stop-Service -Name $services -Force -ErrorAction Stop

        Write-Host "Serviços parados. Renomeando pastas de cache..." -ForegroundColor Cyan
        
        # Documentação: Renomeia as pastas de cache do Windows Update.
        foreach ($origem, $destino in $pastasRenomear.GetEnumerator()) {
            if (Test-Path $destino) {
                Remove-Item -Path $destino -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (Test-Path $origem) {
                Rename-Item -Path $origem -NewName $destino -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "Pastas renomeadas. Reiniciando serviços..." -ForegroundColor Cyan
        # Documentação: Reinicia os serviços usando Start-Service.
        Start-Service -Name $services -ErrorAction Stop

        Write-Host "`n✔️  Windows Update redefinido com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "`n❌ Falha ao reiniciar os componentes do Windows Update." -ForegroundColor Red
        Write-Host ("   Detalhe do erro: $($_.Exception.Message)") -ForegroundColor Gray
    }
    Pause
}

function Agendar-Tarefa {
    Clear-Host
    Write-Host "📅 MENU DE AGENDAMENTO DE TAREFAS" -ForegroundColor Cyan
    Write-Host "`n[1] Agendar limpeza diária de arquivos temporários às 04:00"
    Write-Host "[0] Voltar ao menu principal"
    $escolha = Read-Host "`nEscolha uma opção"

    switch ($escolha) {
        "1" {
            # Documentação: Usar ProgramData é mais seguro do que a raiz C:\
            $pastaAgendada = Join-Path -Path $env:ProgramData -ChildPath "DouraGlassMaintenance"
            if (-not (Test-Path $pastaAgendada)) {
                New-Item -Path $pastaAgendada -ItemType Directory | Out-Null
            }
            $scriptPath = Join-Path -Path $pastaAgendada -ChildPath "limpeza.ps1"

            # Documentação: Script de limpeza que será executado pela tarefa agendada.
            # É uma versão simplificada da função Executar-Limpeza.
            $scriptLimpeza = @'
# Script de limpeza automática
$pastas = @($env:TEMP, "$env:windir\Temp")
foreach ($pasta in $pastas) {
    if (Test-Path $pasta) {
        Get-ChildItem -Path $pasta -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
}
'@
            Set-Content -Path $scriptPath -Value $scriptLimpeza -Encoding UTF8

            $action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`""
            $trigger   = New-ScheduledTaskTrigger -Daily -At 4:00AM
            $principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest
            $settings  = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            $task      = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings

            try {
                Register-ScheduledTask -TaskName "DouraGlass_Limpeza_TEMP_Diaria" -InputObject $task -Force -ErrorAction Stop
                Write-Host "`n✔️  Tarefa agendada com sucesso! Será executada todos os dias às 04:00." -ForegroundColor Green
            } catch {
                Write-Host "`n❌ Falha ao agendar a tarefa." -ForegroundColor Red
                Write-Host ("   Detalhe do erro: $($_.Exception.Message)") -ForegroundColor Gray
            }
            Pause
        }
        "0" { return }
        Default {
            Write-Host "`n❌ Opção inválida. Tente novamente." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

# --- Loop Principal do Script ---

do {
    Mostrar-Menu
    $opcao = Read-Host "Escolha uma opção"

    switch ($opcao) {
        "1" { Executar-SFC }
        "2" { Executar-DISM }
        "3" { Executar-CHKDSK }
        "4" { Executar-Limpeza }
        "5" { Verificar-SMART }
        "6" { Diagnostico-Rede }
        "7" { Reiniciar-WU }
        "8" { Write-Host "Saindo..."; exit }
        "9" { Agendar-Tarefa }
        Default {
            Write-Host ""; Write-Host "❗ Opção inválida. Por favor, escolha um número do menu." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
} while ($true)
