#Requires -Version 5.1
<#
.SYNOPSIS
    Gate 2 Pester (v3.4+ / v5+) Smoke & AST/XAML/Security Regression Suite for ps_deploy.ps1 and build_exe.ps1 (v4.3.2-win).
#>

Describe 'ps_deploy.ps1 & build_exe.ps1 Gate 1/2 Verification (v4.3.2-win)' {
    $RepoRoot      = Split-Path -Parent $PSScriptRoot
    $DeployScript  = Join-Path $RepoRoot 'ps_deploy.ps1'
    $BuildScript   = Join-Path $RepoRoot 'build_exe.ps1'
    $IconPath      = Join-Path $RepoRoot 'ps_deploy.ico'
    $IndexerScript = Join-Path $RepoRoot '.agents\skills\windows-team-orchestrator\scripts\Get-PsAstGraph.ps1'
    $ReceiptPath   = Join-Path $RepoRoot '.agents\state\ast-receipt-latest.json'

    & $IndexerScript -LiteralPath $DeployScript -Query 'Update-ConfigPaths' -ExportGraphify | Out-Null
    $Receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json

    It 'Verifies ps_deploy.ps1 Dual-Engine AST (PS 7 + PS 5.1), HeaderGuard, and SHA256 Receipt (WL-009, WL-011)' {
        ($Receipt.ast_receipt.verified -eq $true) | Should Be $true
        ($Receipt.ast_receipt.ps51_verified -eq $true) | Should Be $true
        ($Receipt.ast_receipt.header_clean -eq $true) | Should Be $true
        ($Receipt.sha256 -match '^[0-9A-F]{64}$') | Should Be $true
    }

    It 'Verifies all embedded [xml] XAML blocks and FindName control bindings in ps_deploy.ps1 (Gate 2 XAML Check)' {
        ($Receipt.ast_receipt.xaml_verified -eq $true) | Should Be $true
        ($Receipt.ast_receipt.xaml_block_count -ge 10) | Should Be $true
        $Receipt.xaml_control_check.unresolved_controls.Count | Should Be 0
    }

    It 'Enforces zero WL-001 (missing -LiteralPath on Get-ChildItem) and zero WL-005 (Invoke-Expression) violations' {
        $Receipt.security_and_wl_audit.gci_missing_literalpath_lines.Count | Should Be 0
        $Receipt.security_and_wl_audit.invoke_expression_lines.Count | Should Be 0
        ($Receipt.security_and_wl_audit.has_sta_guard -eq $true) | Should Be $true
        ($Receipt.security_and_wl_audit.has_runspace_pool -eq $true) | Should Be $true
    }

    It 'Verifies build_exe.ps1 and ps_deploy.ico exist and Get-PsAstGraph.ps1 complies with the <=500-line ceiling (WL-004, WL-007)' {
        (Test-Path -LiteralPath $BuildScript) | Should Be $true
        (Test-Path -LiteralPath $IconPath) | Should Be $true
        $indexerLines = @(Get-Content -LiteralPath $IndexerScript).Count
        ($indexerLines -le 500) | Should Be $true
    }
}
