#Requires -Version 5.1
<#
    Setup do workshop "Professor de IA" - Windows.

        powershell -ExecutionPolicy Bypass -File setup.ps1

    Variavel de ambiente de teste:
        $env:SETUP_DRY_RUN = '1'
        Nao instala nada e nao acessa a rede: pula o pip install, a instalacao
        do OpenCode e o teste final. Serve para conferir o script numa maquina
        ja configurada (ou em CI) sem efeito colateral. Tudo o mais roda igual,
        inclusive a escrita do .env.
        Para voltar ao normal: Remove-Item Env:SETUP_DRY_RUN

    Funciona no Windows PowerShell 5.1 e no PowerShell 7: sem operador ternario,
    sem '??', sem -Encoding utf8NoBOM.

    Texto sem acento de proposito: o Windows PowerShell 5.1 le arquivo .ps1 sem
    BOM como ANSI, e o console legado usa code page 850/437. Acento viraria
    caractere quebrado na tela do aluno. O .env continua em UTF-8.
#>

$ErrorActionPreference = 'Stop'

# O script usa caminhos relativos (requirements.txt, .env.example), entao
# precisa rodar a partir da pasta dele: nao de onde o aluno chamou.
$Diretorio = $PSScriptRoot
if ([string]::IsNullOrEmpty($Diretorio)) {
    $Diretorio = Split-Path -Parent $MyInvocation.MyCommand.Path
}
Set-Location -LiteralPath $Diretorio

$ArqEnv      = Join-Path $Diretorio '.env'
$ArqExemplo  = Join-Path $Diretorio '.env.example'
$ArqRequisit = Join-Path $Diretorio 'requirements.txt'
$ArqTeste    = Join-Path $Diretorio '01_chamada_minima.py'
$DryRun      = ($env:SETUP_DRY_RUN -eq '1')

# ------------------------------------------------------------------ aparencia

# Cor so faz sentido num terminal: redirecionado para arquivo ela atrapalha,
# e NO_COLOR e a convencao para quem nao quer cor nenhuma.
$UsarCor = $true
try {
    if ([Console]::IsOutputRedirected) { $UsarCor = $false }
} catch {
    $UsarCor = $false
}
if ($env:NO_COLOR) { $UsarCor = $false }

function Escrever {
    param([string]$Texto, [string]$Cor)
    if ($UsarCor -and -not [string]::IsNullOrEmpty($Cor)) {
        Write-Host $Texto -ForegroundColor $Cor
    } else {
        Write-Host $Texto
    }
}

function Titulo {
    param([string]$T)
    Write-Host ''
    Escrever $T 'Cyan'
}
function Ok {
    param([string]$T)
    Escrever ('  ok    ' + $T) 'Green'
}
function Aviso {
    param([string]$T)
    Escrever ('  aviso ' + $T) 'Yellow'
}
function Falha {
    param([string]$T)
    Escrever ('  erro  ' + $T) 'Red'
}
function Info {
    param([string]$T)
    Write-Host ('        ' + $T)
}

# Erro fatal: primeira linha diz o que faltou, as seguintes dizem como resolver.
# Nunca deixamos uma excecao crua chegar no aluno.
function Morrer {
    param([string]$Motivo, [string[]]$Dicas = @())
    Falha $Motivo
    foreach ($d in $Dicas) { Info $d }
    Write-Host ''
    exit 1
}

$Feito  = New-Object System.Collections.Generic.List[string]
$Faltou = New-Object System.Collections.Generic.List[string]

# Roda um programa externo sem deixar o $ErrorActionPreference='Stop' virar
# excecao quando o programa escreve em stderr (classico do PowerShell 5.1).
function Rodar {
    param([string]$Exe, [string[]]$Argumentos = @())
    # -CommandType Application de proposito: chamo o programa do PATH, nunca uma
    # funcao ou alias deste script que por acaso tenha o mesmo nome.
    $app = Get-Command $Exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $app) {
        return New-Object psobject -Property @{ Codigo = 127; Saida = ("comando nao encontrado: " + $Exe) }
    }
    $caminho = $app.Source
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $codigo = 1
    $saida = ''
    try {
        $linhas = & $caminho @Argumentos 2>&1 | ForEach-Object { [string]$_ }
        $codigo = $LASTEXITCODE
        if ($null -eq $codigo) { $codigo = 0 }
        if ($null -ne $linhas) { $saida = ($linhas -join [Environment]::NewLine) }
    } catch {
        $codigo = 1
        $saida = $_.Exception.Message
    } finally {
        $ErrorActionPreference = $anterior
    }
    return New-Object psobject -Property @{ Codigo = $codigo; Saida = $saida }
}

function Existe {
    param([string]$Nome)
    $c = Get-Command $Nome -CommandType Application -ErrorAction SilentlyContinue
    return ($null -ne $c)
}

function UltimasLinhas {
    param([string]$Texto, [int]$Quantas = 8)
    if ([string]::IsNullOrEmpty($Texto)) { return }
    $linhas = $Texto -split "`r?`n"
    $inicio = $linhas.Count - $Quantas
    if ($inicio -lt 0) { $inicio = 0 }
    for ($i = $inicio; $i -lt $linhas.Count; $i++) { Info $linhas[$i] }
}

Write-Host '================================================================'
Write-Host ' Professor de IA - setup (Windows)'
Write-Host '================================================================'
if ($DryRun) { Aviso 'SETUP_DRY_RUN=1: nada sera instalado e a rede nao sera usada.' }

# ------------------------------------------------------------ 1. Python 3.9+

Titulo '1. Python 3.9 ou mais novo'

# 'py' e o launcher que a instalacao oficial do Windows deixa; 'python' pode ser
# o atalho falso da Microsoft Store, que nao responde a -c e por isso cai fora.
$tentativas = @(
    (New-Object psobject -Property @{ Exe = 'py';      Fixos = @('-3') }),
    (New-Object psobject -Property @{ Exe = 'python';  Fixos = @() }),
    (New-Object psobject -Property @{ Exe = 'python3'; Fixos = @() })
)

$PyExe = $null
$PyFixos = @()
$versaoVelha = ''

foreach ($t in $tentativas) {
    if (-not (Existe $t.Exe)) { continue }
    $r = Rodar $t.Exe ($t.Fixos + @('-c', 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)'))
    if ($r.Codigo -eq 0) {
        $PyExe = $t.Exe
        $PyFixos = $t.Fixos
        break
    }
    $v = Rodar $t.Exe ($t.Fixos + @('-c', 'import sys; print("%d.%d" % sys.version_info[:2])'))
    if ($v.Codigo -eq 0 -and $v.Saida.Trim() -match '^\d+\.\d+$') { $versaoVelha = $v.Saida.Trim() }
}

if ($null -eq $PyExe) {
    if ($versaoVelha -ne '') {
        Morrer ("Python encontrado, mas e a versao $versaoVelha - o workshop precisa de 3.9 ou mais novo.") @(
            'Baixe uma versao nova em https://www.python.org/downloads/',
            'Marque "Add Python to PATH" no instalador.',
            'Depois feche e abra o PowerShell e rode o setup.ps1 de novo.'
        )
    }
    Morrer "Python nao encontrado (procurei por 'py', 'python' e 'python3')." @(
        'Instale em https://www.python.org/downloads/',
        'IMPORTANTE: marque "Add Python to PATH" no instalador.',
        'Depois feche e abra o PowerShell e rode o setup.ps1 de novo.'
    )
}

# Como chamar o Python daqui para frente: executavel + argumentos fixos.
function RodarPython {
    param([string[]]$Argumentos = @())
    return (Rodar $PyExe ($PyFixos + $Argumentos))
}
$ComandoPython = ($PyExe + ' ' + ($PyFixos -join ' ')).Trim()

$rv = RodarPython @('-c', 'import sys; print("%d.%d.%d" % sys.version_info[:3])')
Ok ($ComandoPython + ' ' + $rv.Saida.Trim())

# ------------------------------------------------------------------- 2. Git

Titulo '2. Git'

if (-not (Existe 'git')) {
    Morrer 'Git nao encontrado.' @(
        'Instale em https://git-scm.com/downloads',
        'Depois feche e abra o PowerShell e rode o setup.ps1 de novo.'
    )
}
$rg = Rodar 'git' @('--version')
Ok $rg.Saida.Trim()

# ----------------------------------------------------------- 3. dependencias

Titulo '3. Dependencias do Python (requirements.txt)'

$PipDescricao = "$ComandoPython -m pip"

if (-not (Test-Path -LiteralPath $ArqRequisit)) {
    Morrer "Nao achei o requirements.txt em $Diretorio" @(
        'Rode o setup.ps1 de dentro da pasta clonada do repositorio.'
    )
}

# Procuro na ordem que o README ensina: pip, pip3 e, por ultimo, 'python -m pip'
# (que e o que sempre casa com o interpretador certo).
$pipExe = $null
$pipFixos = @()
foreach ($nome in @('pip', 'pip3')) {
    if (Existe $nome) { $pipExe = $nome; break }
}
if ($null -eq $pipExe) {
    $teste = RodarPython @('-m', 'pip', '--version')
    if ($teste.Codigo -eq 0) { $pipExe = $PyExe; $pipFixos = ($PyFixos + @('-m', 'pip')) }
}

if ($null -eq $pipExe) {
    Aviso 'Nao achei o pip.'
    Info  "Instale com: $ComandoPython -m ensurepip --upgrade"
    Info  "Depois rode: $ComandoPython -m pip install -r requirements.txt"
    $Faltou.Add('dependencias do Python (pip nao encontrado)')
} else {
    $PipDescricao = ($pipExe + ' ' + ($pipFixos -join ' ')).Trim()
    if ($DryRun) {
        Aviso "pulado (SETUP_DRY_RUN=1). Comando que seria usado: $PipDescricao install -r requirements.txt"
    } else {
        $r = Rodar $pipExe ($pipFixos + @('install', '-r', 'requirements.txt'))
        if ($r.Codigo -eq 0) {
            Ok "dependencias instaladas ($PipDescricao)"
            $Feito.Add('dependencias do requirements.txt')
        } else {
            Aviso 'o pip falhou; tentando de novo com --user'
            $r2 = Rodar $pipExe ($pipFixos + @('install', '--user', '-r', 'requirements.txt'))
            if ($r2.Codigo -eq 0) {
                Ok 'dependencias instaladas com --user'
                $Feito.Add('dependencias do requirements.txt (--user)')
            } else {
                Falha 'nao consegui instalar as dependencias.'
                UltimasLinhas $r2.Saida 8
                Info ''
                Info 'Saidas possiveis:'
                Info "  1) ambiente isolado:  $ComandoPython -m venv .venv"
                Info '                        .\.venv\Scripts\Activate.ps1'
                Info '                        pip install -r requirements.txt'
                Info "  2) so para voce:      $PipDescricao install --user -r requirements.txt"
                $Faltou.Add('dependencias do Python (veja o erro do pip acima)')
            }
        }
    }
}

# --------------------------------------------------------------- 4. OpenCode

Titulo '4. OpenCode'

# O npm instala binario global em %APPDATA%\npm, que pode ainda nao estar no
# PATH desta sessao: por isso acrescento antes de procurar.
$BinNpm = ''
if (-not [string]::IsNullOrEmpty($env:APPDATA)) { $BinNpm = Join-Path $env:APPDATA 'npm' }
function AcrescentarBinNpmAoPath {
    if ([string]::IsNullOrEmpty($BinNpm)) { return }
    if (-not (Test-Path -LiteralPath $BinNpm)) { return }
    if ($env:Path -like "*$BinNpm*") { return }
    $env:Path = $BinNpm + [System.IO.Path]::PathSeparator + $env:Path
}
AcrescentarBinNpmAoPath

function TemOpenCode {
    if (-not (Existe 'opencode')) { return $false }
    $r = Rodar 'opencode' @('--version')
    return ($r.Codigo -eq 0)
}

if (TemOpenCode) {
    $rv = Rodar 'opencode' @('--version')
    Ok ('OpenCode ja instalado (versao ' + $rv.Saida.Trim() + ')')
} elseif ($DryRun) {
    Aviso 'pulado (SETUP_DRY_RUN=1). Comando que seria usado: npm install -g opencode-ai'
    $Faltou.Add('OpenCode (nao instalado por causa do SETUP_DRY_RUN)')
} else {
    # No Windows o caminho do OpenCode e o npm, e npm exige Node. Sem Node nao
    # ha o que tentar: paro aqui com o link, como pede o README.
    if (-not (Existe 'npm')) {
        Write-Host ''
        Falha 'Node.js nao encontrado - e ele que traz o npm, usado para instalar o OpenCode.'
        Info  'Instale o Node.js em https://nodejs.org (versao LTS).'
        Info  'Depois feche e abra o PowerShell e rode o setup.ps1 de novo:'
        Info  '  powershell -ExecutionPolicy Bypass -File setup.ps1'
        Info  'O que ja esta pronto (Python, Git, dependencias) sera reaproveitado.'
        Write-Host ''
        exit 1
    }
    Write-Host '  instalando o OpenCode com npm (pode levar um minuto)...'
    $r = Rodar 'npm' @('install', '-g', 'opencode-ai')
    AcrescentarBinNpmAoPath
    if (TemOpenCode) {
        Ok 'opencode instalado'
        $Feito.Add('OpenCode')
    } else {
        Aviso 'a instalacao do OpenCode nao terminou bem.'
        UltimasLinhas $r.Saida 8
        Info ''
        Info 'Tente na mao: npm install -g opencode-ai'
        Info 'Se o comando instalar mas o "opencode" nao for achado, feche e abra o PowerShell.'
        $Faltou.Add('OpenCode (instale com: npm install -g opencode-ai)')
    }
}

# ------------------------------------------------------------- 5. as chaves

Titulo '5. Chaves de API'

if (-not (Test-Path -LiteralPath $ArqEnv)) {
    if (-not (Test-Path -LiteralPath $ArqExemplo)) {
        Morrer "Nao achei nem .env nem .env.example em $Diretorio" @(
            'Rode o setup.ps1 de dentro da pasta clonada do repositorio.'
        )
    }
    # Copy-Item em vez de ler e reescrever: preserva os bytes (e os acentos).
    Copy-Item -LiteralPath $ArqExemplo -Destination $ArqEnv
    Ok '.env criado a partir do .env.example'
} else {
    Ok '.env ja existia (vou manter o que ja esta dentro)'
}

function LerEnv {
    param([string]$Nome)
    if (-not (Test-Path -LiteralPath $ArqEnv)) { return '' }
    $padrao = '^\s*' + [regex]::Escape($Nome) + '\s*=(.*)$'
    $valor = ''
    foreach ($linha in (Get-Content -LiteralPath $ArqEnv -Encoding UTF8)) {
        if ($linha -match '^\s*#') { continue }
        $m = [regex]::Match($linha, $padrao)
        if ($m.Success) { $valor = $m.Groups[1].Value }   # ultima definicao vence
    }
    return $valor.Trim().Trim('"').Trim("'")
}

# Upsert: se a linha existe, troca; se nao, acrescenta. E o que garante que
# rodar o setup duas vezes nao duplique chave nenhuma.
function GravarEnv {
    param([string]$Nome, [string]$Valor)
    $padrao = '^\s*' + [regex]::Escape($Nome) + '\s*='
    $novas = New-Object System.Collections.Generic.List[string]
    $achou = $false
    foreach ($linha in (Get-Content -LiteralPath $ArqEnv -Encoding UTF8)) {
        if ((-not $achou) -and ($linha -notmatch '^\s*#') -and ($linha -match $padrao)) {
            $novas.Add($Nome + '=' + $Valor)
            $achou = $true
        } else {
            $novas.Add($linha)
        }
    }
    if (-not $achou) { $novas.Add($Nome + '=' + $Valor) }
    # UTF-8 sem BOM e fim de linha LF: BOM ou CR vazam para dentro do valor da
    # chave quando o .env e lido por outras ferramentas (Git Bash, WSL).
    $semBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ArqEnv, (($novas -join "`n") + "`n"), $semBom)
}

# Le uma linha digitada. Com a entrada vindo de pipe ou arquivo, Read-Host nao
# serve: [Console]::ReadLine() devolve $null no fim da entrada, que tratamos
# como "pular".
function LerLinha {
    Write-Host '    cole a chave: ' -NoNewline
    $entrada = $null
    $redirecionada = $false
    try { $redirecionada = [Console]::IsInputRedirected } catch { $redirecionada = $false }
    if ($redirecionada) {
        $entrada = [Console]::ReadLine()
        Write-Host ''
    } else {
        try { $entrada = Read-Host } catch { $entrada = $null }
    }
    if ($null -eq $entrada) { return '' }
    return $entrada.Trim()
}

function PerguntarChave {
    param([string]$Nome, [string]$Link, [string]$Prefixo)

    if ((LerEnv $Nome) -ne '') {
        Ok "$Nome ja esta preenchida no .env"
        return
    }

    Write-Host ''
    Write-Host ('  ' + $Nome)
    Write-Host ('    pegue a sua em ' + $Link + ' (gratis, sem cartao)')
    Write-Host ('    comeca com "' + $Prefixo + '" - ou aperte Enter para pular e preencher depois')

    for ($tentativa = 1; $tentativa -le 3; $tentativa++) {
        $digitado = LerLinha

        if ($digitado -eq '') {
            Aviso "$Nome pulada."
            $Faltou.Add("$Nome - pegue em $Link e ponha no .env")
            return
        }

        # Recuso caractere estranho porque chave colada com aspas ou espaco vira
        # um .env quebrado e um erro confuso depois.
        if ($digitado -notmatch '^[A-Za-z0-9_.\-]+$') {
            Falha 'essa chave tem caractere que nao parece de chave (aspas, espaco ou acento?).'
            Info  'Cole so a chave, sem aspas e sem espaco em volta.'
            continue
        }

        if (-not $digitado.StartsWith($Prefixo)) {
            Aviso ('normalmente essa chave comeca com "' + $Prefixo + '" - confira se copiou a certa.')
        }

        GravarEnv $Nome $digitado
        Ok "$Nome gravada no .env"
        $Feito.Add("$Nome no .env")
        return
    }

    Aviso "$Nome nao foi preenchida (tres tentativas invalidas)."
    $Faltou.Add("$Nome - pegue em $Link e ponha no .env")
}

PerguntarChave 'GEMINI_API_KEY'     'https://aistudio.google.com/apikey' 'AIza'
PerguntarChave 'OPENROUTER_API_KEY' 'https://openrouter.ai/keys'         'sk-or-v1-'

Write-Host ''
Info 'O .env esta no .gitignore: ele nao vai para o repositorio. Mesmo assim,'
Info 'nunca cole uma chave em commit, print, slide ou mensagem.'
Info 'Para usar as chaves num PowerShell novo, sem repetir a cada aula:'
Info '  [Environment]::SetEnvironmentVariable(''GEMINI_API_KEY'',''sua-chave'',''User'')'

# ----------------------------------------------------------- 6. teste real

Titulo '6. Teste final'

$ChaveGemini = LerEnv 'GEMINI_API_KEY'
$TestePassou = $false

if ($ChaveGemini -eq '') {
    Aviso 'sem GEMINI_API_KEY no .env - pulei o teste.'
    Info  "Preencha a GEMINI_API_KEY no .env e rode: $ComandoPython 01_chamada_minima.py"
} elseif (-not (Test-Path -LiteralPath $ArqTeste)) {
    Aviso 'nao achei o 01_chamada_minima.py - pulei o teste.'
} elseif ($DryRun) {
    Aviso 'pulado (SETUP_DRY_RUN=1): o teste faz uma chamada de rede de verdade.'
} else {
    Write-Host '  chamando o modelo uma vez...'
    $antes = $env:GEMINI_API_KEY
    $env:GEMINI_API_KEY = $ChaveGemini
    try {
        $r = RodarPython @('01_chamada_minima.py')
    } finally {
        # O .env e a fonte da verdade; nao deixo a chave vazando na sessao.
        $env:GEMINI_API_KEY = $antes
    }
    if ($r.Codigo -eq 0) {
        Ok 'o teste passou - a chave do Gemini funciona.'
        $TestePassou = $true
        $Feito.Add('teste 01_chamada_minima.py passou')
    } else {
        Falha 'o teste nao passou.'
        UltimasLinhas $r.Saida 12
        Info ''
        $s = $r.Saida
        if ($s -match "No module named 'requests'") {
            Info "Faltou a dependencia: $PipDescricao install -r requirements.txt"
        } elseif ($s -match 'API_KEY_INVALID|API key not valid|valid API key|\b401\b|\b403\b') {
            Info 'A chave parece invalida. Crie outra em https://aistudio.google.com/apikey'
        } elseif ($s -match '\b429\b') {
            Info 'Limite por minuto do Gemini. Espere um minuto e rode de novo.'
        } elseif ($s -match 'ConnectionError|getaddrinfo|Max retries') {
            Info 'Parece problema de rede/internet. Confira a conexao e tente de novo.'
        } else {
            Info "Leia o erro acima. A secao 'Problemas' do README cobre os casos comuns."
        }
        $Faltou.Add('teste 01_chamada_minima.py (veja o erro acima)')
    }
}

# ------------------------------------------------------------------- resumo

Write-Host ''
Write-Host '================================================================'
Write-Host ' Resumo'
Write-Host '================================================================'

Write-Host ''
Escrever 'Pronto:' 'Green'
if ($Feito.Count -gt 0) {
    foreach ($f in $Feito) { Write-Host ('  - ' + $f) }
} else {
    Write-Host '  - nada novo: tudo o que precisava ja estava no lugar'
}

if ($Faltou.Count -gt 0) {
    Write-Host ''
    Escrever 'Falta voce:' 'Yellow'
    foreach ($f in $Faltou) { Write-Host ('  - ' + $f) }
}

Write-Host ''
Escrever 'Proximo comando:' 'Cyan'
if ($ChaveGemini -eq '') {
    Write-Host '  1) abra o .env e preencha a GEMINI_API_KEY (https://aistudio.google.com/apikey)'
    Write-Host ("  2) $ComandoPython 01_chamada_minima.py")
} elseif ($TestePassou) {
    Write-Host '  opencode        # aula 2: converse com o agente professor (Tab troca de agente)'
} else {
    Write-Host ("  $ComandoPython 01_chamada_minima.py        # resolva o erro acima e rode de novo")
}
Write-Host ''
