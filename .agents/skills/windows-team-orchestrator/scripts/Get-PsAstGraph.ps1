<#
.SYNOPSIS
    Deterministic 0-Token PowerShell & Batch AST Function-Line Graph Indexer, XAML Control Verifier & Graphify Bridge (v4.3.2-win | WL-007..WL-012).
.DESCRIPTION
    Parses PowerShell (.ps1, .psm1, .psd1) and Windows Batch (.bat, .cmd) files using Dual-Engine AST (PS 7 + PS 5.1),
    verifies Line 1 header integrity (WL-009), validates embedded [xml] XAML + FindName control bindings, computes SHA256
    and git-diff touched_ranges (WL-011), merges into .agents/state/ast-line-graph.json & graphify-out/graph.json, and writes
    a <30-line .agents/state/ast-receipt-latest.json receipt so agents never read >500 lines.
.PARAMETER LiteralPath
    Exact literal path to the target script or directory (WL-001 compliant).
.PARAMETER Query
    Optional regex/substring filter to return matching functions, regions, or GUI controls with <=500-line read windows.
.PARAMETER MaxWindowLines
    Hard ceiling for any recommended read_file window (default: 500, per WL-007).
.PARAMETER OutJsonPath
    Output path for the AST line graph JSON (default: .agents/state/ast-line-graph.json).
.PARAMETER ExportGraphify
    Also export/merge nodes and call-graph edges into graphify-out/graph.json.
.PARAMETER NormalizeCrlf
    Normalize mixed LF/CRLF line endings to CRLF (UTF-8 with BOM) before parsing (used by build_exe.ps1).
.EXAMPLE
    pwsh -NoProfile -File .agents/skills/windows-team-orchestrator/scripts/Get-PsAstGraph.ps1 -LiteralPath .\ps_deploy.ps1 -Query "Update-ConfigPaths" -ExportGraphify
#>
[CmdletBinding(SupportsShouldProcess = $false)]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$LiteralPath,

    [Parameter(Mandatory = $false)]
    [string]$Query = '',

    [Parameter(Mandatory = $false)]
    [ValidateRange(50, 500)]
    [int]$MaxWindowLines = 500,

    [Parameter(Mandatory = $false)]
    [string]$OutJsonPath = '.agents/state/ast-line-graph.json',

    [Parameter(Mandatory = $false)]
    [switch]$ExportGraphify,

    [Parameter(Mandatory = $false)]
    [switch]$NormalizeCrlf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-SafeLineChunks {
    param([int]$StartLine, [int]$EndLine, [int]$MaxLines = 500)
    $chunks = New-Object System.Collections.Generic.List[object]
    $cur = $StartLine
    while ($cur -le $EndLine) {
        $chunkEnd = [Math]::Min($EndLine, $cur + $MaxLines - 1)
        $chunks.Add([ordered]@{ start_line = $cur; end_line = $chunkEnd; line_count = ($chunkEnd - $cur + 1) })
        $cur = $chunkEnd + 1
    }
    return ,$chunks.ToArray()
}

function Get-FileSha256AndTouchedRanges {
    param([string]$ResolvedPath)
    $bytes = [System.IO.File]::ReadAllBytes($ResolvedPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { $hashHex = ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '') }
    finally { $sha.Dispose() }

    $ranges = New-Object System.Collections.Generic.List[string]
    try {
        $workDir = Split-Path -Parent $ResolvedPath
        $gitOut = & git -C $workDir diff -U0 --ignore-cr-at-eol -- $ResolvedPath 2>$null
        if ($LASTEXITCODE -eq 0 -and $gitOut) {
            foreach ($gl in @($gitOut)) {
                if ([string]$gl -match '^@@\s+\-\d+(?:,\d+)?\s+\+(\d+)(?:,(\d+))?\s+@@') {
                    $sL = [int]$Matches[1]
                    $cnt = if ($Matches[2]) { [Math]::Max(1, [int]$Matches[2]) } else { 1 }
                    $ranges.Add("L${sL}-L$($sL + $cnt - 1)")
                }
            }
        }
    } catch {}
    if ($ranges.Count -eq 0) { $ranges.Add('UNMODIFIED') }
    elseif ($ranges.Count -gt 6) {
        $extra = $ranges.Count - 5
        $top5 = @($ranges | Select-Object -First 5) + "+${extra}_more_hunks"
        $ranges.Clear(); foreach ($r in $top5) { $ranges.Add($r) }
    }
    return [ordered]@{ sha256 = $hashHex; touched_ranges = @($ranges -join ', ') }
}

function Invoke-SingleFileAstIndex {
    param([string]$FilePath, [int]$MaxLines, [bool]$DoNormalizeCrlf = $false)
    $resolved = [System.IO.Path]::GetFullPath($FilePath)
    $ext = [System.IO.Path]::GetExtension($resolved).ToLowerInvariant()

    if ($DoNormalizeCrlf -and $ext -in @('.ps1', '.psm1', '.psd1')) {
        $rawBytes = [System.IO.File]::ReadAllBytes($resolved)
        $hasUtf8Bom = ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF)
        $rawTxt = [System.IO.File]::ReadAllText($resolved, [System.Text.Encoding]::UTF8)
        $hasBareLf = ($rawTxt.Contains("`n") -and ($rawTxt -replace "`r`n", "").Contains("`n"))
        if (-not $hasUtf8Bom -or $hasBareLf) {
            $rawTxt = ($rawTxt -replace "`r?`n", "`r`n")
            [System.IO.File]::WriteAllText($resolved, $rawTxt, (New-Object System.Text.UTF8Encoding($true)))
        }
    }

    $rawLines = [System.IO.File]::ReadAllLines($resolved)
    $totalLines = $rawLines.Count
    $meta = Get-FileSha256AndTouchedRanges -ResolvedPath $resolved

    if ($ext -in @('.bat', '.cmd')) {
        $labels = New-Object System.Collections.Generic.List[object]
        $hasEchoOff = $false; $hasDelayed = $false; $hasExitB = $false
        for ($i = 0; $i -lt $totalLines; $i++) {
            $ln = $rawLines[$i]
            if ($ln -match '^\s*:([A-Za-z0-9_\-]+)') { $labels.Add([ordered]@{ name = ":$($Matches[1])"; start_line = ($i + 1) }) }
            if (-not $hasEchoOff -and $ln -match '^\s*@echo\s+off') { $hasEchoOff = $true }
            if (-not $hasDelayed -and $ln -match 'EnableDelayedExpansion') { $hasDelayed = $true }
            if (-not $hasExitB   -and $ln -match 'exit\s+/b') { $hasExitB = $true }
        }
        for ($j = 0; $j -lt $labels.Count; $j++) {
            $endL = if ($j + 1 -lt $labels.Count) { $labels[$j + 1].start_line - 1 } else { $totalLines }
            $labels[$j]['end_line'] = $endL; $labels[$j]['line_count'] = ($endL - $labels[$j].start_line + 1)
            $labels[$j]['read_windows'] = Get-SafeLineChunks -StartLine $labels[$j].start_line -EndLine $endL -MaxLines $MaxLines
        }
        return [ordered]@{
            file = $resolved; type = 'Batch'; sha256 = $meta.sha256; total_lines = $totalLines
            requires_sliced_read = ($totalLines -gt $MaxLines); max_window_lines = $MaxLines
            touched_ranges = $meta.touched_ranges
            ast_receipt = [ordered]@{ cmd = 'BatchLabelIndex'; sha256 = $meta.sha256; exit_code = 0; error_count = 0; verified = $true; touched_ranges = $meta.touched_ranges }
            xaml_control_check = [ordered]@{ xaml_named_count = 0; find_name_count = 0; unresolved_controls = @() }
            regions = @(); functions = $labels.ToArray(); gui_controls_and_events = @(); edges = @()
            security_and_wl_audit = [ordered]@{ has_echo_off = $hasEchoOff; has_delayed_expansion = $hasDelayed; has_exit_b = $hasExitB }
        }
    }

    $tokens = $null; $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($resolved, [ref]$tokens, [ref]$parseErrors)

    $regions = New-Object System.Collections.Generic.List[object]
    $regionStack = New-Object System.Collections.Generic.Stack[object]
    $hasStrictMode = $false; $hasStaGuard = $false; $hasRunspacePool = $false

    for ($i = 0; $i -lt $totalLines; $i++) {
        $line = $rawLines[$i]
        if ($line.Length -gt 0) {
            if ($line -match '^\s*#region\s*(.*)$') {
                $rName = if ($Matches[1].Trim()) { $Matches[1].Trim() } else { "Region_L$($i+1)" }
                $regionStack.Push(@{ name = $rName; start_line = ($i + 1) })
            } elseif ($line -match '^\s*#endregion\b' -and $regionStack.Count -gt 0) {
                $openReg = $regionStack.Pop(); $endL = $i + 1
                $regions.Add([ordered]@{
                    name = $openReg.name; start_line = $openReg.start_line; end_line = $endL
                    line_count = ($endL - $openReg.start_line + 1)
                    read_windows = Get-SafeLineChunks -StartLine $openReg.start_line -EndLine $endL -MaxLines $MaxLines
                })
            }
            if (-not $hasStrictMode   -and $line.IndexOf('Set-StrictMode', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) { $hasStrictMode = $true }
            if (-not $hasStaGuard     -and ($line.IndexOf('GetApartmentState', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or $line.IndexOf('STAThread', [System.StringComparison]::OrdinalIgnoreCase) -ge 0)) { $hasStaGuard = $true }
            if (-not $hasRunspacePool -and ($line.IndexOf('CreateRunspacePool', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or $line.IndexOf('Synchronized', [System.StringComparison]::OrdinalIgnoreCase) -ge 0)) { $hasRunspacePool = $true }
        }
    }

    $funcAsts = New-Object System.Collections.Generic.List[System.Management.Automation.Language.FunctionDefinitionAst]
    $guiItems = New-Object System.Collections.Generic.List[object]
    $iexLines = New-Object System.Collections.Generic.List[int]
    $gciNoLit = New-Object System.Collections.Generic.List[int]
    $findNameRefs = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)

    $allAstNodes = $ast.FindAll({
        param($n)
        ($n -is [System.Management.Automation.Language.FunctionDefinitionAst]) -or
        ($n -is [System.Management.Automation.Language.CommandAst]) -or
        ($n -is [System.Management.Automation.Language.AssignmentStatementAst]) -or
        ($n -is [System.Management.Automation.Language.InvokeMemberExpressionAst])
    }, $true)

    $funcNamesSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($node in $allAstNodes) {
        if ($node -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
            $funcAsts.Add($node); [void]$funcNamesSet.Add($node.Name)
        } elseif ($node -is [System.Management.Automation.Language.CommandAst]) {
            $cName = $node.GetCommandName()
            if ($cName -in @('Invoke-Expression', 'iex')) { $iexLines.Add($node.Extent.StartLineNumber) }
            elseif ($cName -in @('Get-ChildItem', 'gci', 'dir')) {
                if ($node.Extent.Text.IndexOf('-LiteralPath', [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { $gciNoLit.Add($node.Extent.StartLineNumber) }
            }
        } elseif ($node -is [System.Management.Automation.Language.AssignmentStatementAst]) {
            if ($node.Right.Extent.EndLineNumber - $node.Right.Extent.StartLineNumber -le 5) {
                $rText = $node.Right.Extent.Text
                if ($rText.IndexOf('Windows.Forms', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                    $rText.IndexOf('System.Drawing', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -or
                    $rText.IndexOf('Windows.Controls', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $guiItems.Add([ordered]@{ kind = 'GUI_Control'; symbol = $node.Left.Extent.Text.Trim(); start_line = $node.Extent.StartLineNumber; end_line = $node.Extent.EndLineNumber })
                }
            }
        } elseif ($node -is [System.Management.Automation.Language.InvokeMemberExpressionAst]) {
            $mName = $node.Member.Extent.Text
            if ($mName.StartsWith('Add_', [System.StringComparison]::OrdinalIgnoreCase)) {
                $sL = $node.Extent.StartLineNumber; $eL = $node.Extent.EndLineNumber
                $guiItems.Add([ordered]@{
                    kind = 'GUI_EventHandler'; symbol = "$($node.Expression.Extent.Text).$mName"
                    start_line = $sL; end_line = $eL; line_count = ($eL - $sL + 1)
                    read_windows = Get-SafeLineChunks -StartLine $sL -EndLine $eL -MaxLines $MaxLines
                })
            } elseif ($mName -eq 'FindName' -and $node.Arguments -and $node.Arguments.Count -eq 1) {
                $argTxt = $node.Arguments[0].Extent.Text.Trim("'", '"')
                if ($argTxt -and -not $argTxt.Contains('$')) { [void]$findNameRefs.Add($argTxt) }
            }
        }
    }

    $functions = New-Object System.Collections.Generic.List[object]
    $edges     = New-Object System.Collections.Generic.List[object]
    foreach ($f in $funcAsts) {
        $sLine = $f.Extent.StartLineNumber; $eLine = $f.Extent.EndLineNumber; $lCount = $eLine - $sLine + 1
        $paramNames = @()
        if ($f.Body.ParamBlock -and $f.Body.ParamBlock.Parameters) {
            $paramNames = @($f.Body.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        } elseif ($f.Parameters) {
            $paramNames = @($f.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        }
        $cmdAsts = $f.Body.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
        $calledInternal = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($c in $cmdAsts) {
            $cName = $c.GetCommandName()
            if ($cName -and $funcNamesSet.Contains($cName) -and ($cName -ne $f.Name)) {
                if ($calledInternal.Add($cName)) {
                    $edges.Add([ordered]@{ source = $f.Name; target = $cName; relation = 'calls'; line = $c.Extent.StartLineNumber })
                }
            }
        }
        $functions.Add([ordered]@{
            name = $f.Name; start_line = $sLine; end_line = $eLine; line_count = $lCount
            params = $paramNames; calls = @($calledInternal)
            read_windows = Get-SafeLineChunks -StartLine $sLine -EndLine $eLine -MaxLines $MaxLines
        })
    }

    $scriptParamBlock = $null
    if ($ast.ParamBlock) {
        $scriptParamBlock = [ordered]@{
            start_line = $ast.ParamBlock.Extent.StartLineNumber; end_line = $ast.ParamBlock.Extent.EndLineNumber
            params = @($ast.ParamBlock.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
        }
    }

    $errList = New-Object System.Collections.Generic.List[object]
    if ($parseErrors -and $parseErrors.Count -gt 0) {
        foreach ($pe in $parseErrors) { $errList.Add([ordered]@{ engine = 'PS7'; line = $pe.Extent.StartLineNumber; message = $pe.Message }) }
    }

    # WL-009 Check 1: Line 1 Header Integrity & Pipeline Pollution Guard
    $headerClean = $true
    if ($totalLines -gt 0) {
        $firstNonEmpty = ''; $firstNonEmptyLine = 1
        for ($idx = 0; $idx -lt [Math]::Min(10, $totalLines); $idx++) {
            $trimmed = $rawLines[$idx].Trim()
            if ($trimmed.Length -gt 0) { $firstNonEmpty = $trimmed; $firstNonEmptyLine = $idx + 1; break }
        }
        if ($firstNonEmpty -match '^[^#<\[\$]+\s+<#' -or $firstNonEmpty -match '^(Patched|Updated|Replaced|Removed|Added|Fixed)\b') {
            $headerClean = $false
            $errList.Add([ordered]@{ engine = 'HeaderGuard'; line = $firstNonEmptyLine; message = "WL-009 Header corruption on line ${firstNonEmptyLine}: unexpected bareword prefix before script header." })
        }
    }

    # WL-009 Check 2: Windows PowerShell 5.1 Native AST Parse
    $ps51Verified = $true
    $winPsExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    if ([System.IO.File]::Exists($winPsExe)) {
        try {
            $escapedPath = $resolved.Replace("'", "''")
            $ps51Cmd = "`$t=`$null; `$e=`$null; [void][System.Management.Automation.Language.Parser]::ParseFile('$escapedPath',[ref]`$t,[ref]`$e); if (`$e -and `$e.Count -gt 0) { `$e | ForEach-Object { Write-Output ('PS51_ERR:' + `$_.Extent.StartLineNumber + ':' + `$_.Message) }; exit 1 } else { exit 0 }"
            $ps51Out = & $winPsExe -NoProfile -NonInteractive -Command $ps51Cmd 2>&1
            if ($LASTEXITCODE -ne 0) {
                $ps51Verified = $false
                foreach ($outLine in @($ps51Out)) {
                    if ([string]$outLine -match '^PS51_ERR:(\d+):(.*)$') {
                        $errList.Add([ordered]@{ engine = 'PS5.1'; line = [int]$Matches[1]; message = $Matches[2].Trim() })
                    }
                }
                if ($errList.Count -eq 0) { $errList.Add([ordered]@{ engine = 'PS5.1'; line = 1; message = 'Windows PowerShell 5.1 Parser::ParseFile failed.' }) }
            }
        } catch {
            $ps51Verified = $false
            $errList.Add([ordered]@{ engine = 'PS5.1'; line = 1; message = "PS 5.1 AST invocation error: $($_.Exception.Message)" })
        }
    }

    # WL-009 & Gate 2 Check 3: Embedded [xml] XAML Well-Formedness + Deterministic Control Name Cross-Check
    $xamlVerified = $true
    $xamlBlockCount = 0
    $xamlNamedSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $rawFullText = [System.IO.File]::ReadAllText($resolved)
    $xamlMatches = [regex]::Matches($rawFullText, '(?ms)\[xml\]\s*\$\w+\s*=\s*@"(\r?\n.*?\r?\n)"@')
    foreach ($xm in $xamlMatches) {
        $xamlBlockCount++
        $xmlContent = $xm.Groups[1].Value.Trim()
        try {
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml($xmlContent)
            foreach ($nmMatch in [regex]::Matches($xmlContent, '\b(?:x:)?Name="([^"]+)"')) {
                [void]$xamlNamedSet.Add($nmMatch.Groups[1].Value)
            }
        } catch {
            $xamlVerified = $false
            $prefixLen = $xm.Index
            $startLineNum = 1 + ([regex]::Matches($rawFullText.Substring(0, $prefixLen), '\n').Count)
            $errList.Add([ordered]@{ engine = 'XAML'; line = $startLineNum; message = "Embedded [xml] XAML parse error: $($_.Exception.Message)" })
        }
    }

    $unresolvedControls = New-Object System.Collections.Generic.List[string]
    if ($xamlBlockCount -gt 0) {
        foreach ($fnRef in $findNameRefs) {
            if (-not $xamlNamedSet.Contains($fnRef) -and $rawFullText -notmatch "if\s*\(\s*\$(?:script:)?$([regex]::Escape($fnRef))\b") {
                $unresolvedControls.Add($fnRef)
            }
        }
    }

    $allVerified = [bool](($errList.Count -eq 0) -and $ps51Verified -and $headerClean -and $xamlVerified -and ($unresolvedControls.Count -eq 0))

    return [ordered]@{
        file                    = $resolved
        type                    = 'PowerShell'
        sha256                  = $meta.sha256
        total_lines             = $totalLines
        requires_sliced_read    = ($totalLines -gt $MaxLines)
        max_window_lines        = $MaxLines
        touched_ranges          = $meta.touched_ranges
        script_param_block      = $scriptParamBlock
        ast_receipt             = [ordered]@{
            cmd              = 'Parser::ParseFile (PS7 + PS5.1 + HeaderGuard + XAML) + Get-PsAstGraph'
            sha256           = $meta.sha256
            exit_code        = if ($allVerified) { 0 } else { 1 }
            error_count      = $errList.Count
            errors           = $errList.ToArray()
            verified         = $allVerified
            ps51_verified    = $ps51Verified
            header_clean     = $headerClean
            xaml_verified    = $xamlVerified
            xaml_block_count = $xamlBlockCount
        }
        xaml_control_check      = [ordered]@{
            xaml_named_count    = $xamlNamedSet.Count
            find_name_count     = $findNameRefs.Count
            unresolved_controls = $unresolvedControls.ToArray()
        }
        regions                 = $regions.ToArray()
        functions               = $functions.ToArray()
        gui_controls_and_events = $guiItems.ToArray()
        edges                   = $edges.ToArray()
        security_and_wl_audit   = [ordered]@{
            invoke_expression_lines       = $iexLines.ToArray()
            gci_missing_literalpath_lines = $gciNoLit.ToArray()
            has_strict_mode               = $hasStrictMode
            has_sta_guard                 = $hasStaGuard
            has_runspace_pool             = $hasRunspacePool
        }
    }
}

# Collect target files safely (WL-001)
$resolvedTarget = [System.IO.Path]::GetFullPath($LiteralPath)
$targetFiles = New-Object System.Collections.Generic.List[string]
if ([System.IO.File]::Exists($resolvedTarget)) {
    $targetFiles.Add($resolvedTarget)
} elseif ([System.IO.Directory]::Exists($resolvedTarget)) {
    Get-ChildItem -LiteralPath $resolvedTarget -Force |
        Where-Object { -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) } |
        ForEach-Object {
            if (-not $_.PSIsContainer -and $_.Extension -in @('.ps1', '.psm1', '.psd1', '.bat', '.cmd')) {
                $targetFiles.Add($_.FullName)
            }
        }
} else {
    throw "LiteralPath not found: $LiteralPath"
}

$indexedFiles = New-Object System.Collections.Generic.List[object]
foreach ($tf in $targetFiles) {
    $indexedFiles.Add((Invoke-SingleFileAstIndex -FilePath $tf -MaxLines $MaxWindowLines -DoNormalizeCrlf ([bool]$NormalizeCrlf)))
}

# Merge with existing .agents/state/ast-line-graph.json entries (preserving other existing files & pruning deleted temp files)
$fullOutPath = if ([System.IO.Path]::IsPathRooted($OutJsonPath)) { $OutJsonPath } else { Join-Path (Get-Location).Path $OutJsonPath }
$outDir = Split-Path -Parent $fullOutPath
if ($outDir -and -not [System.IO.Directory]::Exists($outDir)) {
    [void][System.IO.Directory]::CreateDirectory($outDir)
}

$mergedMap = [ordered]@{}
if ([System.IO.File]::Exists($fullOutPath)) {
    try {
        $prevGraph = Get-Content -LiteralPath $fullOutPath -Raw | ConvertFrom-Json
        foreach ($pf in @($prevGraph.files)) {
            if ($pf -and $pf.file -and [System.IO.File]::Exists([string]$pf.file)) {
                $mergedMap[[string]$pf.file] = $pf
            }
        }
    } catch {}
}
foreach ($newF in $indexedFiles) {
    $mergedMap[[string]$newF.file] = $newF
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$graphPayload = [ordered]@{
    schema_version   = '4.3.2-win'
    generated_at     = [DateTimeOffset]::UtcNow.ToString('o')
    max_window_lines = $MaxWindowLines
    files            = @($mergedMap.Values)
}
[System.IO.File]::WriteAllText($fullOutPath, ($graphPayload | ConvertTo-Json -Depth 10), $Utf8NoBom)

# Write <35-line compact receipt (.agents/state/ast-receipt-latest.json) for 0ms Gate 1/2 verification (WL-011)
$latestFileObj = $indexedFiles[$indexedFiles.Count - 1]
$receiptPath = Join-Path $outDir 'ast-receipt-latest.json'
$compactReceipt = [ordered]@{
    schema_version        = '4.3.2-win'
    generated_at          = [DateTimeOffset]::UtcNow.ToString('o')
    file                  = $latestFileObj.file
    sha256                = $latestFileObj.sha256
    total_lines           = $latestFileObj.total_lines
    touched_ranges        = ($latestFileObj.touched_ranges -join ', ')
    ast_receipt           = $latestFileObj.ast_receipt
    xaml_control_check    = $latestFileObj.xaml_control_check
    security_and_wl_audit = $latestFileObj.security_and_wl_audit
}
[System.IO.File]::WriteAllText($receiptPath, ($compactReceipt | ConvertTo-Json -Depth 4 -Compress:$false), $Utf8NoBom)

# Optional Graphify Bridge (exports all merged workspace files into graphify-out/graph.json)
if ($ExportGraphify) {
    $gOutDir = Join-Path (Get-Location).Path 'graphify-out'
    if (-not [System.IO.Directory]::Exists($gOutDir)) { [void][System.IO.Directory]::CreateDirectory($gOutDir) }
    $gNodes = New-Object System.Collections.Generic.List[object]
    $gLinks = New-Object System.Collections.Generic.List[object]
    foreach ($fObj in $mergedMap.Values) {
        $shortFile = [System.IO.Path]::GetFileName([string]$fObj.file)
        foreach ($fn in @($fObj.functions)) {
            $gNodes.Add([ordered]@{
                id = "$shortFile::$($fn.name)"; label = "$($fn.name) (L$($fn.start_line)-L$($fn.end_line))"
                type = 'function'; source_file = $fObj.file; source_location = "L$($fn.start_line)-L$($fn.end_line)"
                start_line = $fn.start_line; end_line = $fn.end_line; line_count = $fn.line_count; confidence = 'EXTRACTED'
            })
        }
        foreach ($reg in @($fObj.regions)) {
            $gNodes.Add([ordered]@{
                id = "$shortFile::region::$($reg.name)"; label = "#region $($reg.name) (L$($reg.start_line)-L$($reg.end_line))"
                type = 'region'; source_file = $fObj.file; source_location = "L$($reg.start_line)-L$($reg.end_line)"
                start_line = $reg.start_line; end_line = $reg.end_line; line_count = $reg.line_count; confidence = 'EXTRACTED'
            })
        }
        foreach ($ed in @($fObj.edges)) {
            $gLinks.Add([ordered]@{
                source = "$shortFile::$($ed.source)"; target = "$shortFile::$($ed.target)"
                relation = $ed.relation; line = $ed.line; confidence = 'EXTRACTED'
            })
        }
    }
    $graphifyJson = [ordered]@{
        directed = $true; multigraph = $false
        graph = @{ generator = 'Get-PsAstGraph.ps1 (v4.3.2-win)'; file_count = $mergedMap.Count }
        nodes = $gNodes.ToArray(); links = $gLinks.ToArray()
    }
    [System.IO.File]::WriteAllText((Join-Path $gOutDir 'graph.json'), ($graphifyJson | ConvertTo-Json -Depth 8), $Utf8NoBom)
}

# Print concise summary or filtered Query output to stdout (capped at 15 items when unqueried per WL-007)
$maxItems = 15
foreach ($fObj in $indexedFiles) {
    $fnList  = @($fObj.functions)
    $regList = @($fObj.regions)
    $guiList = @($fObj.gui_controls_and_events | Where-Object { $_.kind -eq 'GUI_EventHandler' })
    if ($Query) {
        $fnList  = @($fnList  | Where-Object { $_.name -match $Query })
        $regList = @($regList | Where-Object { $_.name -match $Query })
        $guiList = @($guiList | Where-Object { $_.symbol -match $Query })
    } else {
        if ($fnList.Count -gt $maxItems)  { $fnList  = @($fnList  | Select-Object -First $maxItems) }
        if ($regList.Count -gt $maxItems) { $regList = @($regList | Select-Object -First $maxItems) }
        if ($guiList.Count -gt $maxItems) { $guiList = @($guiList | Select-Object -First $maxItems) }
    }
    [PSCustomObject][ordered]@{
        file                 = $fObj.file
        sha256               = $fObj.sha256
        total_lines          = $fObj.total_lines
        touched_ranges       = $fObj.touched_ranges
        requires_sliced_read = $fObj.requires_sliced_read
        ast_verified         = $fObj.ast_receipt.verified
        ps51_verified        = $fObj.ast_receipt.ps51_verified
        header_clean         = $fObj.ast_receipt.header_clean
        xaml_verified        = $fObj.ast_receipt.xaml_verified
        xaml_control_check   = $fObj.xaml_control_check
        error_count          = $fObj.ast_receipt.error_count
        errors               = $fObj.ast_receipt.errors
        matching_regions     = @($regList | ForEach-Object { "$($_.name) [L$($_.start_line)-L$($_.end_line) ($($_.line_count)L)]" })
        matching_functions   = @($fnList  | ForEach-Object { "$($_.name) [L$($_.start_line)-L$($_.end_line) ($($_.line_count)L)] -> calls: $($_.calls -join ',')" })
        matching_gui_events  = @($guiList | ForEach-Object { "$($_.symbol) [L$($_.start_line)-L$($_.end_line)]" })
        security_and_wl      = $fObj.security_and_wl_audit
    } | ConvertTo-Json -Depth 5
}
