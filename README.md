# Remote Deployment Console (`ps_deploy.exe` / `ps_deploy.ps1` — Version 1.4.0.16)

A lightweight, standalone Windows GUI utility (**Version 1.4.0.16**) designed for system administrators to build, manage, and deploy multi-step deployment packages (PowerShell scripts, Command-Line Batch files, and Software Installers) to remote Active Directory domain-joined computers.

---

## 📑 Table of Contents
1. [Overview & Core Capabilities](#-overview--core-capabilities)
2. [What It Can Do](#-what-it-can-do)
3. [What It Cannot Do (Limitations & Non-Goals)](#-what-it-cannot-do-limitations--non-goals)
4. [Prerequisites & Requirements](#-prerequisites--requirements)
5. [Step-by-Step User Guide](#-step-by-step-user-guide)
   - [Step 1: Launch the Application & Theme Overview](#step-1-launch-the-application--theme-overview)
   - [Step 2: Manage Packages with the Package Library](#step-2-manage-packages-with-the-package-library)
   - [Step 3: Build & Configure Package Steps](#step-3-build--configure-package-steps)
   - [Step 4: Configure Authentication & Remote Staging (Settings Menu)](#step-4-configure-authentication--remote-staging-settings-menu)
   - [Step 5: Target Discovery & Management](#step-5-target-discovery--management)
   - [Step 6: Deploy, Monitor & Manage Live Execution](#step-6-deploy-monitor--manage-live-execution)
   - [Step 7: Save & Download Status Logs](#step-7-save--download-status-logs)
6. [Live Polling Step Example (BitLocker Monitoring)](#-live-polling-step-example-bitlocker-monitoring)
7. [Architecture & Troubleshooting](#-architecture--troubleshooting)

---

## 🚀 Overview & Core Capabilities

`ps_deploy.exe` acts as an agentless, package-driven remote execution orchestrator styled with a high-contrast **Catppuccin Mocha** dark theme adhering to WCAG 2.1 AA readability standards. Instead of requiring local client agents or complex server infrastructure, it communicates with target endpoints over standard Windows Remote Management (**WinRM** / WS-Management), stages payloads seamlessly into a dedicated remote staging folder (`C:\Temp\PSDeploy`), runs multi-step packages in isolated child processes on each target, and streams execution output, installation progress, and duration back to the console in real time.

---

## ✅ What It Can Do

* **Deployment Package Library (Full-Height Left Sidebar Alongside Target Computers & Package Steps):**
  * The **Package Library** spans the full left column of the upper workspace alongside the stacked **Target Computers** (top-right) and **Package Steps** (bottom-right) panels, separated by interactive vertical and horizontal `GridSplitter` bars so you can resize each pane on the fly.
  * Organize packages into a hierarchical folder tree via the dedicated **`📁 Folder`** (`btnNewFolder`) toolbar button or inline right-click context menu actions on the `tvLibrary` TreeView (**`➕ New Folder...`**, **`➕ New Subfolder...`**).
  * **Fixed `Library Folder` Drop-Down Selector (`ComboBox`):** The **`Library Folder`** selector in **Package Steps** is a non-editable drop-down (`IsEditable="False"`) that displays only existing folders in the Package Library, preventing accidental creation of ad-hoc folders while typing.
  * Right-click any folder or package in the tree to perform inline operations (`New Subfolder`, `Rename`, `Delete`, `Export`).
  * Easily **drag and drop** any deployment package onto another folder (or onto another package to move/reorder it) in the Package Library tree (`tvLibrary`), automatically updating its folder while preserving empty folders.
  * Library structure is automatically persisted across sessions in `%LOCALAPPDATA%\PSDeploy\package_library.json`.
* **Multi-Format Package Steps:**
  * **PowerShell Scripts (`Script`):** Execute custom PowerShell code or import existing `.ps1` files directly from disk.
  * **Command Line Batch Scripts (`Batch`):** Run native `.bat` / `.cmd` scripts remotely with automatic exit code tracking and live stdout streaming.
  * **Software Installer Payloads (`Installer`):** Stage standalone installers (`.msi`, `.exe`, `.msp`, `.msu`) or entire source payload directories remotely via WinRM (`Copy-Item -ToSession`) into `C:\Temp\PSDeploy`. Includes silent-by-default execution flags (`/qn /norestart` for MSI, `/S /quiet /norestart` for EXE) with fully customizable arguments, and live `0% -> 100%` installation progress reporting in the status grid.
  * **Timed Pauses (`Pause`):** Insert pauses (in seconds) between steps for service stabilization, reboot cycles, or Active Directory replication.
* **Streamlined Steps Toolbar, Canned-Scripts Library & Right-Click Context Menu:**
  * Compact, anti-clipping toolbar with intuitive tooltips: **`＋ PowerShell`**, **`＋ Batch / CMD`**, **`📚 Canned-Scripts`**, **`＋ Installer`**, **`⏱ Pause`**, and **`🧹 Clear Steps`**.
  * **Built-In SysAdmin & IT Troubleshooting Canned-Scripts Library (`📚 Canned-Scripts`):** Browse, filter, search, customize, and insert **36 pre-built, non-interactive PowerShell and Batch/CMD troubleshooting, lookup, and remediation scripts** organized across 6 administrative categories (*System & OS Lookup*, *AD, Users & Group Policy*, *Network & Connectivity*, *Disk, Storage & BitLocker*, *Services, Processes & Event Logs*, and *Security, Defender & OS Repair*).
  * **Quick Step Clearing:** Click **`🧹 Clear Steps`** (or right-click and select **`🗑 Clear All Steps`**) to instantly wipe steps from the active package workspace without clearing or resetting your active **Package Name** or destination **Library Folder**.
  * Right-click any step in the table to execute context actions: **`✎ Edit Step`**, **`↑ Move Up`**, **`↓ Move Down`**, **`✕ Remove Step`**, and **`🗑 Clear All Steps`**.
* **Live Target Discovery Table, Column Header Sorting/Filtering, Asynchronous Background Probe & Resizable Panes:**
  * The **Target Computers** panel (`dgTargets`) and **Package Steps** panel are equally sized vertically by default (`Height="1*"` / `Height="1*"`), while the lower **Status Log** console defaults to a compact ~5-row height (`2.6*` vs `1*`)—all separated by interactive horizontal and vertical `GridSplitter` bars so you can freely drag to resize any pane.
  * **Per-Column Sorting & Inline Filtering (`Target Computers` & `Status Log`):** Every column header in both the **Target Computers** panel (`Deploy`, `Computer Name`, `Online Status`, `IP Address`, `Current Logon User`) and the **Status Log** window (`Computer Name`, `Deployment Package`, `Current / Last Step`, `Status`, `Total Duration`, `Details / Live Output`) includes:
    * Clickable column header sorting (`⇅` ascending/descending),
    * A **`▾` Windows 11 Fluent column header flyout menu** featuring a top **Quick-Action Icon Bar** (`↑ Sort A-Z`, `↓ Sort Z-A`, `🧹 Clear Col`, `✕ Reset All`), rounded pill hover states, right-aligned shortcut hints, and a **distinct-value quick-filter checklist** with rounded checkmark badges, and
    * An **inline filter bar** (`All / Checked / Unchecked` selector or live text filter supporting substring search, `=ExactValue`, `=(Blank)`, and `val1|val2` OR matching) plus **`🧹 Clear Filters`** / **`🧹 Clear Log Filters`** toolbar buttons.
  * Target computers are added to a live discovery DataGrid displaying:
    * **Deploy Selection:** Checkbox to include or exclude specific computers from execution.
    * **Computer Name:** Target hostname or FQDN.
    * **Live Online Status:** Fast reachability probe (`⏳ Probing...` → `Online` / `Offline`).
    * **IP Address:** Resolved IPv4 address (`Scanning...` → IPv4 or `Unreachable`).
    * **Current Logon User:** Interrogates active console user session over WMI/CIM (`Scanning...` → `DOMAIN\User` or `None (Console)`).
  * **Live Checked / Imported Counter (`Checked / Imported: X/Y`):** Displays a live counter at the bottom of the **Target Computers** list (`lblTargetCount`, e.g., `1/100 (1 checked of 100 imported | showing N filtered)`) that updates immediately as computers are imported, filtered, checked/unchecked, toggled via **`☑ All / None`**, or removed.
  * **Full Window & Panel Size Persistence (`ui_layout.json`):** Automatically saves and restores all window dimensions, screen positions, maximized states, and internal `GridSplitter` ratios/widths across application restarts for the **Main Console Window** (`Package Library` width, `Target Computers` vs `Package Steps` split, `Upper Workspace` vs `Status Log` split) as well as child modals (**`Deployment Details`**, **`Active Directory Browser`**, **`Canned-Scripts`**, **`Edit Step`**, and **`Settings`**).
  * **Zero-Freeze Asynchronous Background Probing (`RunspacePool`):** Adding or importing computers (via **`🌐 Import AD`**, **`📂 Import CSV`**, or **`＋ Add`**) or clicking **`🔄 Probe`** immediately adds the targets as `⏳ Probing...` in `< 100ms` and runs DNS, TCP 5985/5986, ICMP Ping, and CIM logon-user checks concurrently across a background `RunspacePool` (`1..10` threads) polled by a 180ms UI `DispatcherTimer`—keeping the UI 100% responsive even when importing dozens of machines.
  * **Auto-Remove Target on Success:** Automatically removes machines from the target list as soon as their deployment finishes with `Success` (enabled by default via the `Auto-remove target on Success` checkbox), leaving only pending or failed machines for clear batch tracking.
* **Append-Only Per-Deployment Status Rows & Live Cumulative Duration:**
  * Every deployment execution appends a **new row** in the Status log window (`dgResults`) showing `Computer Name`, `Package`, `Current / Last Step`, `Status`, `Total Duration`, and `Details / Live Output`—preserving full status and step history for past deployments when multiple different packages or runs are deployed to the same computer.
* **Double-Click Multi-Step Drilldown & Flexible Diagnostic Console:**
  * Double-clicking anywhere on a computer row opens the **Deployment Details Modal**, presenting a step-by-step history grid (`Step #`, `Step Name`, `Type`, `Status`, `Duration`, `Timestamp`, `Details`) and a flexible, resizable **Step Output & Diagnostic Details** pane separated by a draggable horizontal `GridSplitter`, plus a 1-click **Copy Diagnostic Log** button.
* **Persistent Status Window Across App Restarts:**
  * Deployment results and step histories are automatically saved to `%LOCALAPPDATA%\PSDeploy\deployment_status_state.json` (after each host completes, on row deletion/clearing, and on window close) and seamlessly restored whenever `ps_deploy.exe` is reopened.
* **Interactive Row Management & Column Sorting:**
  * Click the **`Computer Name`** or **`Status`** column headers to toggle ascending/descending sorts. Remove individual hosts via **`🗑 Delete Row`** (or press the `Delete` key / right-click) or clear the entire window via **`🧹 Clear Status`**.
* **Windows 11 Fluent Right-Click Context Menus & Smart Re-Deployment:**
  * All right-click action menus (**Target Computers**, **Deployment Status Log**, **Package Library TreeView**, and **Package Steps**) use a Windows 11 Fluent Acrylic-Dark flyout (`CornerRadius="8"`, soft drop shadow, zero legacy white left gutter, top Quick-Action icon bars, rounded pill hover states, and right-aligned keyboard shortcut hints). Right-click any computer row in the Status Log to quickly run **`🔄 Re-deploy Package (All Steps)`** (restarts from Step 1) or **`⏭ Re-deploy From Failed Step`** (intelligently resumes starting at the exact step that failed while preserving prior completed step history and cumulative duration).
* **Live Real-Time Status Streaming:**
  * Remote scripts emitting output via `Write-Output` or console stdout stream their progress line-by-line back to the console table in real time (e.g., live BitLocker encryption percentage `8% -> 25% -> 100%`).
* **Flexible Target Selection & Native Active Directory (`🌐 Import AD`) Browser:**
  * Single computer name or FQDN (e.g., `pc01.domain.local`).
  * Comma-, semicolon-, or space-separated lists of hostnames in the single-target field.
  * Bulk CSV file import (supports CSV files with a `ComputerName` header, or falls back to the first column).
  * **Interactive Active Directory Computer & OU Browser (`🌐 Import AD`):** Browse your Active Directory domain hierarchy (`organizationalUnit` and `CN=Computers` containers) in an expandable tree view without requiring the RSAT `ActiveDirectory` PowerShell module. Filter computers by name/hostname/description, OS type (`All OS Types`, `Workstations Only`, `Servers Only`), or account status (`Enabled accounts only`), and import either an **entire selected OU** (`📥 Import Entire Selected OU`) or **individual / multi-selected computer objects** (`✔ Import Selected Computers` via checkboxes or `Ctrl`/`Shift` multi-row selection).
* **Centralized Settings, Domain Authentication & Config Directory:**
  * **Dedicated Settings Modal (`⚙️ Settings`):** Admin credentials, remote staging paths, and centralized application data directories are managed in a dedicated modal dialog accessible from the top-right header bar (alongside live status badges for current auth mode, staging path, and config directory), keeping the main deployment workflow clutter-free.
  * **Current Logon Token:** Toggle *"Use my current Windows logon"* to deploy seamlessly using your active Kerberos session without entering credentials.
  * **Saved Domain Credentials (DPAPI Encrypted):** Save Domain, Username, and Password across sessions. Passwords are securely encrypted at rest using Windows DPAPI (`ConvertFrom-SecureString` / `ConvertTo-SecureString` scoped to the current user) inside `settings.json`. A 1-click **"🧹 Clear Saved Credentials"** button securely purges stored credentials at any time.
  * **Configurable Application Configuration & Library Directory (`ConfigDirectory`):** Choose any local folder or shared network directory under **`💾 APPLICATION CONFIGURATION & LIBRARY DIRECTORY (Local / Shared)`** (`txtDlgConfigDir` + `📂 Browse...`). Changing this directory automatically migrates existing `settings.json`, `package_library.json`, `status_state.json`, `packages\*.json`, and `logs\*.*` into the new directory. The tool routes all configuration files (`settings.json`), persistent deployment state logs (`status_state.json` and exported `logs\`), and package library definitions (`package_library.json` and individual `packages\*.json` files) to this directory, tracked via `%LOCALAPPDATA%\PSDeploy\bootstrap.json`. This enables multi-administrator team sharing and portable package management across workstations.
  * **Configurable Remote Machine Staging & Log Directory:** Specify a custom remote staging directory (defaults to `C:\Temp\PSDeploy`). The deployment engine automatically ensures this folder exists on targets, executes scripts with it as the working directory (`$env:PSDEPLOY_STAGING_DIR`), and writes per-step execution logs (`<ComputerName>_Step<Order>_<StepName>_<Timestamp>.log`) directly on the remote machine for forensic and compliance auditing.
* **Smart Dual-Mode Reachability Probing:**
  * Probes TCP ports **5985** (WinRM HTTP) and **5986** (WinRM HTTPS) with a fast socket timeout before falling back to ICMP ping, preventing false "Offline" skips on machines where Windows Firewall blocks ICMP Echo.
* **Isolated Script Execution:**
  * Each step is transmitted securely over WinRM, written to temporary files in the remote staging folder, executed inside dedicated child processes (`powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass` or `cmd.exe /c`), and cleaned up upon exit.
* **Script & Installer Parameters:**
  * Pass custom parameters/arguments (e.g., `-Silent -Force` or `/qn /norestart`) directly into individual steps.
* **Status Log Saving & Downloading:**
  * Save and export complete deployment status records at any time using the **`💾 Save Status Logs`** button (located next to **`🚀 Deploy Package`**) into structured **CSV**, formatted **Text/Log**, or machine-readable **JSON** files for compliance and audit trails.
* **Real-Time Local Diagnostic Trace Log (`psdeploy_diagnostic.log`):**
  * Automatically records detailed, millisecond-timestamped trace events to `<ConfigDirectory>\logs\psdeploy_diagnostic.log` (default: `%LOCALAPPDATA%\PSDeploy\logs\psdeploy_diagnostic.log`). Logs target reachability probes, WinRM session handshakes, payload staging operations, 10-second step execution heartbeats, and error stack traces for immediate local troubleshooting.
* **High-Contrast Catppuccin Mocha Theme:**
  * Fully formatted with an accessible palette (`#CDD6F4` light text on dark surfaces, `#11111B` dark text on light accent buttons) across all primary screens, trees, grids, and modal dialogs.

---

## ❌ What It Cannot Do (Limitations & Non-Goals)

* **Payload Staging Bandwidth for Multi-Gigabyte Media:**
  * While `ps_deploy.exe` automatically stages `.msi`, `.exe`, `.msp`, and `.msu` installers and supporting folders over WinRM via `Copy-Item -ToSession`, transfer speeds are subject to WSMan buffer constraints. For multi-gigabyte files (e.g., massive CAD suites or OS ISO images), hosting payloads on a network file share (UNC path) remains the recommended approach.
* **WinRM Double-Hop Restriction (Single-Hop Kerberos):**
  * By default, credentials passed via standard WinRM cannot be delegated to a second network hop (e.g., accessing a `\\fileserver\share` from the remote target) unless:
    1. The network share allows anonymous/read access to `Domain Computers`, or
    2. CredSSP / Kerberos Resource-Based Constrained Delegation (RBCD) is configured in your domain, or
    3. The script passes credentials explicitly inside the remote session.
* **Requires WinRM (Port 5985/5986) Enabled:**
  * Target endpoints must have WinRM enabled (standard for domain environments via Active Directory GPO: `Enable-PSRemoting -Force` or Group Policy *Windows Remote Management* service). The tool does not use RPC/DCOM, WMI process creation, or SMB PsExec services.
* **Offline Machines Cannot Be Queued:**
  * The tool executes immediately against targets. It does not maintain a background database or persistent daemon service to retry offline machines hours or days later.
* **Target Processing is Sequential:**
  * Targets in the deployment list are processed one computer at a time to ensure clear per-host tracking and predictable network usage.

---

## 📋 Prerequisites & Requirements

### On the Admin Machine (Running `ps_deploy.exe`):
- **Operating System:** Windows 10, Windows 11, or Windows Server 2016/2019/2022/2025.
- **Runtimes:** Built-in .NET Framework 4.5+ and Windows PowerShell 5.1 (included by default on modern Windows). No external dependencies or PowerShell 7 installation required.

### On Target Endpoints (Remote Computers):
- Domain-joined to the same or trusted Active Directory domain.
- WinRM service running and Windows Firewall permitting inbound traffic on TCP port **5985** (WinRM HTTP) or **5986** (HTTPS).
- The executing account must be a member of the remote machine's local `Administrators` group.

---

## 📖 Step-by-Step User Guide

### Step 1: Launch the Application & Theme Overview

You can launch the **Remote Deployment Console** either as the standalone executable (`ps_deploy.exe`) or directly from the PowerShell source script (`ps_deploy.ps1`).

#### Option A: Launching `ps_deploy.exe` (Expected Windows Security Warning — `Unknown Publisher`)
Double-click [ps_deploy.exe](file:///c:/%23Project/software-deployment-tool/ps_deploy.exe).

> [!NOTE]
> **Expected Windows Security Warning (`Publisher: Unknown Publisher`):**
> Because `ps_deploy.exe` is an internal administrative utility that has **not** been commercially code-signed with a public Certificate Authority (CA) digital certificate, Windows will display the standard **Open File - Security Warning** dialog when you launch a downloaded copy:
>
> ```text
> +-----------------------------------------------------------------------+
> | Open File - Security Warning                                        X |
> +-----------------------------------------------------------------------+
> | The publisher could not be verified. Are you sure you want to run     |
> | this software?                                                        |
> |                                                                       |
> |        Name: C:\Users\<Username>\Downloads\ps_deploy.exe              |
> |   Publisher: Unknown Publisher                                        |
> |        Type: Application                                              |
> |        From: C:\Users\<Username>\Downloads\ps_deploy.exe              |
> |                                                                       |
> |                                           [   Run   ]   [  Cancel  ]  |
> +-----------------------------------------------------------------------+
> | [!] This file does not have a valid digital signature that verifies   |
> |     its publisher. You should only run software from publishers you   |
> |     trust.                                                            |
> +-----------------------------------------------------------------------+
> ```
>
> - **This message is completely normal and expected** because the `.exe` is unsigned.
> - Click **`Run`** to launch the console.
> - **Tip (Prevent the warning on future launches):** Right-click `ps_deploy.exe` (or the downloaded `.zip` archive before extracting) → select **Properties** → check **Unblock** at the bottom of the **General** tab → click **Apply** / **OK**, or run `Unblock-File -LiteralPath .\ps_deploy.exe` in PowerShell.

#### Option B: Alternative — Run `ps_deploy.ps1` Directly in PowerShell (No `.exe` Security Warning)
If you prefer to avoid executable security prompts (`Unknown Publisher` / SmartScreen) or endpoint antivirus restrictions on packaged `.exe` files, you can run the native PowerShell source script [ps_deploy.ps1](file:///c:/%23Project/software-deployment-tool/ps_deploy.ps1) directly with identical functionality:

1. **From a PowerShell Prompt (Recommended):**
   Open **Windows PowerShell** (`powershell.exe`) and run:
   ```powershell
   cd "C:\Path\To\software-deployment-tool"
   Unblock-File -LiteralPath .\ps_deploy.ps1
   powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\ps_deploy.ps1
   ```
2. **Via Right-Click in File Explorer:**
   - *(First time only after downloading)* Right-click `ps_deploy.ps1` → **Properties** → check **Unblock** → **OK**.
   - Right-click `ps_deploy.ps1` and select **`Run with PowerShell`**.
3. **Via a Custom Desktop Shortcut (Console-Free Launch):**
   Create a Windows shortcut with the following **Target**:
   ```text
   powershell.exe -NoProfile -WindowStyle Hidden -STA -ExecutionPolicy Bypass -File "C:\Path\To\software-deployment-tool\ps_deploy.ps1"
   ```

The application runs with a dark, high-contrast **Catppuccin Mocha** WPF interface (`#CDD6F4` light text on dark `#1E1E2E` surfaces, `#11111B` dark text on pastel accent buttons) engineered for WCAG 2.1 AA readability across all screens, tree views, grids, and modal dialogs.

### Step 2: Manage Packages with the Package Library
The left sidebar contains the **Package Library** spanning the full height alongside **Target Computers** (top-right) and **Package Steps** (bottom-right), providing folder-based package management persisted in `%LOCALAPPDATA%\PSDeploy\package_library.json`:
* **Create Folders & Subfolders:** Click the dedicated **`📁 Folder`** (`btnNewFolder`) toolbar button above the library tree to create a category folder, or right-click any item in the `tvLibrary` tree view and select **`➕ New Folder...`** (or **`➕ New Subfolder...`**). Select any existing library folder from the fixed **`Library Folder`** drop-down selector in the **Package Steps** panel when saving a package.
* **Drag-and-Drop Organization:** Drag and drop any package onto another folder (or onto another package to move or reorder it) in the Package Library tree (`tvLibrary`). The package's folder path is automatically updated, and any empty folders are preserved.
* **Save Package to Library:** Configure your package steps, enter a package name, select the destination folder in the tree, and click **`💾 Save Package`** (or right-click the folder and choose **`💾 Save Current Package Here`**).
* **Load Package:** Select any package in the tree and click **`📂 Load`** (or double-click the package node) to populate your workspace with its steps.
* **Import / Export Packages:**
  * **`📥 Import`**: Import standalone package JSON files from disk directly into your selected library folder.
  * **`📤 Export`**: Export your active package (or right-click an item in the library) to save a portable JSON definition to disk.
* **Delete Items:** Click **`🗑 Delete`** (or right-click an item and select **`🗑 Delete`**) to remove packages or folders.

### Step 3: Build & Configure Package Steps
Under **PACKAGE STEPS**, use the streamlined top toolbar to compose your deployment workflow:
* **Add a Custom PowerShell Step:**
  1. Click **`＋ PowerShell`**.
  2. Enter a **Name** (e.g., `Enable BitLocker`).
  3. *(Optional)* Enter **Parameters** to pass to the script (e.g., `-Verbose -Force`).
  4. Enter your script code into the high-contrast script editor (or click **`📂 Insert Script File...`** inside the dialog to load an existing `.ps1` file from disk).
  5. Click **OK**.
* **Add a Command Line Batch Step:**
  1. Click **`＋ Batch / CMD`**.
  2. Enter a **Name** (e.g., `Flush DNS & Reset Netsh`).
  3. *(Optional)* Enter **Parameters** (e.g., `/y`).
  4. Type your command-line batch script (e.g., `ipconfig /flushdns` or `net stop spooler`).
  5. Click **OK**. During deployment, scripts are executed remotely via `cmd.exe /c` with full exit code validation and live output streaming.
* **Insert a Pre-Built SysAdmin / IT Troubleshooting Step (`📚 Canned-Scripts`):**
  1. Click **`📚 Canned-Scripts`** on the Step Creation toolbar to open the **Canned Scripts Library** modal.
  2. Filter by **Category** (*System & OS Lookup*, *AD, Users & Group Policy*, *Network & Connectivity*, *Disk, Storage & BitLocker*, *Services, Processes & Event Logs*, *Security, Defender & OS Repair*), filter by **Shell Type** (`All Types`, `PowerShell`, `Batch`), or type any keyword in **🔍 Search** (e.g., `ipconfig`, `gpupdate`, `bitlocker`, `quser`, `spooler`, `sfc`, `hotfix`, `reboot`).
  3. Select any of the **36 pre-built scripts** in the left table to inspect its description, parameters, and full script body in the right-hand preview pane. You can customize the **Step Name**, **Parameters**, or **Script Content** inline before inserting.
  4. Click **`✔ Add to Package Steps`** (or double-click a row) to insert the step and close the dialog, click **`＋ Add & Keep Open`** to chain multiple diagnostic/remediation steps in one pass, or click **`✏️ Open in Step Editor...`** to open it inside the full Step Editor.
* **Add a Software Installer Payload Step:**
  1. Click **`＋ Installer`**.
  2. Enter a **Name** (e.g., `Install Chrome Enterprise`).
  3. Click **Browse** next to **Installer File** and choose an installer (`.msi`, `.exe`, `.msp`, or `.msu`).
  4. *(Optional)* If the installer requires supporting files, dependencies, or transform `.mst` files, check **Include entire directory** and select the source payload directory.
  5. **Silent Arguments:** Default arguments are automatically populated (`/qn /norestart` for MSI, `/S /quiet /norestart` for EXE). Customize parameters as needed.
  6. Click **OK**. During deployment, the installer file and supporting payload folder are staged directly into the remote staging directory (`C:\Temp\PSDeploy`) via `Copy-Item -ToSession`, executed silently, and monitored in real time with progressive `0% -> 100%` status updates.
* **Add a Pause Step:**
  1. Click **`⏱ Pause`**.
  2. Specify the duration in seconds (e.g., `60` seconds to wait for reboot completion or service initialization).
* **Clear Steps Without Resetting Package Metadata:**
  * Click **`🧹 Clear Steps`** on the toolbar (or right-click the steps table and select **`🗑 Clear All Steps`**) to instantly empty the step list while preserving your active **Package Name** and selected **Library Folder**. This allows you to quickly re-author or replace steps in an existing package without having to click **`＋ New`** and re-enter your package details.
* **Right-Click Step Context Actions:**
  * Right-click any step row in the grid to access quick management actions:
    * **`✎ Edit Step`**: Reopen the step modal editor to update scripts, installers, or arguments.
    * **`↑ Move Up`** / **`↓ Move Down`**: Reorder execution priority.
    * **`✕ Remove Step`**: Delete the selected step from the current package.
    * **`🗑 Clear All Steps`**: Remove all steps from the grid while keeping the active Package Name and Library Folder intact.

### Step 4: Configure Authentication, Remote Staging & Configuration Directory (Settings Menu)
Click the **`⚙️ Settings`** button located in the top-right corner of the window (next to the live Auth Mode and Staging Path summary badges):

1. **Authentication Mode:**
   * **Using Current Windows Account:**
     * Check **"Use my current Windows logon (Kerberos) — no password needed"**.
     * No username or password input is required; WinRM authenticates using your active logon session.
   * **Using Explicit Domain Admin Credentials:**
     * Uncheck the Windows logon option.
     * **Domain:** Enter your Active Directory domain (e.g., `domain.local` or `CORP`).
     * **Username:** Enter your administrative account (e.g., `admin_account`, `DOMAIN\admin_account`, or `admin_account@domain.local`).
     * **Password:** Enter the administrative password.
   * **Credential Persistence & Security:**
     * Check **"Remember credentials across sessions"** to retain Domain, Username, and Password.
     * Credentials are encrypted at rest using **Windows DPAPI** (`ConvertFrom-SecureString` scoped strictly to your current Windows user profile) and stored in `settings.json` within your active Configuration Directory.
     * Click **"🧹 Clear Saved Credentials"** at any time to immediately purge saved credentials from disk.
2. **Remote Staging & Output Log Directory:**
   * Enter or browse for the remote directory path where scripts, installer payloads, and execution logs should reside (default: `C:\Temp\PSDeploy`).
   * When deploying, the engine automatically creates this folder on each target machine, sets it as the working directory and `$env:PSDEPLOY_STAGING_DIR`, stages installer payloads there, and writes individual step log files (`<ComputerName>_Step<Order>_<StepName>_<Timestamp>.log`) for auditing.
3. **Application Configuration & Library Directory (Local or Network Share):**
   * Under **`💾 APPLICATION CONFIGURATION & LIBRARY DIRECTORY (Local / Shared)`**, configure the centralized folder location for all settings, package definitions, and logs:
     * Click **`📂 Browse...`** to select any local path (e.g., `C:\PSDeploy_Data`) or shared UNC network directory (e.g., `\\Server\Share\PSDeploy_Config`).
     * **Automatic Data Migration:** Changing the Application Configuration Directory (`ConfigDirectory`) automatically migrates existing `settings.json`, `package_library.json`, `status_state.json`, `packages\*.json`, and `logs\*.*` into the newly selected directory, ensuring zero data loss and seamless transitions between local and network storage.
     * The configured directory centralizes:
       * `settings.json`: User preferences, DPAPI-encrypted credentials, and staging path configurations.
       * `package_library.json`: The hierarchical package folder tree and package index.
       * `packages\*.json`: Individual JSON package step definitions.
       * `status_state.json`: Saved deployment status and results table states.
       * `logs\psdeploy_diagnostic.log`: Real-time diagnostic trace log recording millisecond-timestamped trace events for target probing, WinRM handshakes, file staging, 10-second step heartbeats, and errors.
       * `logs\`: Exported deployment execution transcripts and CSV reports.
     * **Bootstrap Pointer:** The path to this configuration directory is persisted in `%LOCALAPPDATA%\PSDeploy\bootstrap.json`. Pointing multiple administrators or workstations to a shared network folder allows team-wide package library and configuration sharing.
4. Click **Save & Close** to apply your settings. The top-right status badges will immediately update to reflect your active configuration.

### Step 5: Target Discovery & Management
In the **TARGET COMPUTERS** section:
1. **Adding Computers:**
   * **Single / List Input:** Type one or more hostnames or FQDNs (comma-, semicolon-, or space-separated, e.g., `pc01, pc02, server01.domain.local`) and click **`＋ Add`**.
   * **CSV / TXT Import:** Click **`📂 Import CSV`** and choose a `.csv` or `.txt` file. Computer names are automatically extracted from the `ComputerName` header (or the first column).
   * **Active Directory Browser & Import (`🌐 Import AD`):** Click **`🌐 Import AD`** to open the **Import Computers from Active Directory** modal:
     * **Connect to Domain:** Automatically detects your current AD domain (or uses the Domain & Admin Credentials saved in **`⚙️ Settings`**). Click **`🔗 Connect / Load OUs`** to load the domain's Organizational Unit (`OU`) tree.
     * **Browse & Import by OU:** Click any Organizational Unit or container in the left-hand **`📂 ACTIVE DIRECTORY CONTAINERS & OUs`** tree to list its computers (toggle **`Include sub-OUs when loading computers`** to include or exclude nested child OUs). Click **`📥 Import Entire Selected OU`** to import every computer in that OU in one click.
     * **Filter & Multi-Select Individual Computers:** In the right-hand **`💻 AD COMPUTER OBJECTS`** pane, filter by keyword (`🔍 Filter`), operating system (`All OS Types`, `Workstations Only`, `Servers Only`), or **`Enabled accounts only`**. Select individual or multiple computers using checkboxes, double-click, **`☑ Check All`**, or standard `Ctrl+Click` / `Shift+Click` multi-row selection (`✔ Toggle Highlighted`), then click **`✔ Import Selected Computers`**.
2. **Target List Management:**
   * **`☑ All / None`**: Quickly select or deselect all computers in the list.
   * **`✕ Remove`**: Remove selected targets from the active list.
3. **Resizable Live Target Discovery Grid (`dgTargets`):**
   * Drag the horizontal splitter bar below **TARGET COMPUTERS** (or between the upper workspace and the lower deployment status table) to expand or collapse the Target Computers table at any time. The **Active Directory Import** modal is also fully resizable (`CanResizeWithGrip`) with a draggable vertical splitter between the OU tree and computer list.
   * Added computers immediately populate the live target table with:
     * **Deploy Checkbox:** Toggle deployment inclusion per target.
     * **Computer Name:** Target hostname or FQDN.
     * **Live Status:** Transitions asynchronously from `⏳ Probing...` to `Online` or `Offline`.
     * **IP Address:** Resolved IPv4 address (`Scanning...` → IPv4 or `Unreachable`).
     * **Current Logon User:** Interrogates active console user session over WMI/CIM (`Scanning...` → `DOMAIN\User` or `None (Console)`).
4. **Non-Blocking Background Status Probing (`RunspacePool`):**
   * Whenever you import computers from Active Directory (`🌐 Import AD`), CSV (`📂 Import CSV`), or manual entry (`＋ Add`), or click **`🔄 Probe`**, the dialog closes immediately without UI freeze and dispatches all reachability/logon-user checks to a 10-thread background `RunspacePool` polled every 180ms by a UI `DispatcherTimer`.
5. **Auto-Remove Target on Success:**
   * Keep **"Auto-remove target on Success"** checked (default) to automatically purge machines from the target list as soon as their deployment finishes successfully. This ensures the target list continuously displays only remaining or failed machines.

### Step 6: Deploy, Monitor & Manage Live Execution
1. *(Optional)* Check or uncheck **"Continue on step failure"** (checked = continues remaining steps if one step errors; unchecked = aborts remaining steps for that specific computer).
2. Click **🚀 Deploy Package**.
3. **Consolidated Results Console:**
   * The status table displays one row per target computer:
     * **Computer Name:** The target hostname or FQDN. Click the header to sort ascending or descending.
     * **Current / Last Step:** Shows the active step number and name (e.g., `Step 2: Install Chrome Enterprise`), transitioning to the final step upon completion.
     * **Status:** Dynamically updates (`Pending` → `Running...` → `Success` or `Failed`). Click the header to sort ascending or descending.
     * **Total Duration:** Displays cumulative time spent across all executed steps for that computer (e.g., `1m 24s`).
     * **Details / Live Output:** Streams real-time script output, batch stdout, and installer progress (`0% -> 100%`) line-by-line, and displays error traces if a step fails.
4. **Column Sorting:** Click the **`Computer Name`** or **`Status`** column header to instantly sort rows ascending or descending.
5. **Double-Click for Full Multi-Step Drilldown Modal:**
   * Double-clicking anywhere on a computer row opens the **Deployment Details Modal**:
     * **Step History Grid:** View every individual step's `Step #`, `Step Name`, `Type`, `Status`, `Duration`, `Timestamp`, and `Details`.
     * **Flexible / Draggable Diagnostic Console Log:** Drag the horizontal splitter bar between the Step History table and **Step Output & Diagnostic Details** up or down (or resize/maximize the window) to expand the raw stdout/stderr output pane.
     * **Copy Diagnostic Log:** Click to copy the full diagnostic console log directly to your clipboard for troubleshooting or incident ticketing.
6. **Right-Click Context Menu & Smart Re-Deployment:**
   * Right-click any computer row in the results table to access quick context actions:
     * **`🔄 Re-deploy Package (All Steps)`**: Re-executes the entire package from Step 1 against that target computer.
     * **`⏭ Re-deploy From Failed Step`**: Intelligently resumes deployment starting at the exact step that failed, retaining prior successful step history and cumulative duration.
     * **`📋 View Full Deployment Details`**: Opens the step-by-step drilldown modal.
     * **`🗑 Delete Row`**: Removes the selected computer row from the status window.
7. **Pruning & Clearing Rows:**
   * Select a row and click **`🗑 Delete Row`** (or press the `Delete` key) to remove an individual computer.
   * Click **`🧹 Clear Status`** to clear all rows from the console.
8. **Automatic State Persistence Across App Restarts:**
   * Deployment results and step histories are automatically saved to `status_state.json` inside your active Configuration Directory (or `%LOCALAPPDATA%\PSDeploy\status_state.json` by default) after each host completes, when rows are deleted or cleared, and when the application closes.
   * When `ps_deploy.exe` is reopened, prior deployment results and drilldown histories are automatically restored so you can pick up where you left off.

### Step 7: Save & Download Status Logs
Once a deployment run finishes (or is currently executing), you can save and download the complete status log by clicking **`💾 Save Status Logs`** (located directly next to **`🚀 Deploy Package`**):
* **CSV Status Log (`*.csv`)**:
  * Structured tabular export (`Timestamp`, `ComputerName`, `Step`, `Status`, `Duration`, `Details`).
  * Ideal for auditing in Excel, Power BI, or compliance tracking sheets.
* **Text Status Report (`*.txt`, `*.log`)**:
  * Human-readable report with header timestamp, summary status (total rows, passed, failed, running), and per-step diagnostic logs.
* **JSON Status Log (`*.json`)**:
  * Machine-readable JSON payload with `GeneratedAt`, `Summary` (total, success, failed, running counts), and `Logs` array containing raw records for SIEM/API ingestion.
* Default filename pattern: `Deployment_Status_YYYYMMDD_HHmmss.<ext>` with auto-suggested desktop/working directory path.

#### Real-Time Local Diagnostic Trace Log (`psdeploy_diagnostic.log`)
In addition to on-demand manual log exports, `ps_deploy.exe` automatically writes a persistent, millisecond-timestamped diagnostic trace log to:
`<ConfigDirectory>\logs\psdeploy_diagnostic.log`
*(Default path: `%LOCALAPPDATA%\PSDeploy\logs\psdeploy_diagnostic.log`)*

This log provides continuous real-time execution telemetry for:
* **Target Reachability Probes:** Port 5985/5986 socket connection attempts, timeouts, and ICMP ping fallbacks.
* **WinRM Session Handshakes:** WS-Management session creation, credential negotiation, and connection teardowns.
* **Payload File Staging:** Remote staging folder creation (`C:\Temp\PSDeploy`) and payload file transfer events via `Copy-Item -ToSession`.
* **Execution Heartbeats:** 10-second interval status heartbeats while remote steps execute, tracking active child process runtimes.
* **Exceptions & Errors:** Full error messages, WSMan fault codes, and script failure stack traces for instant forensic troubleshooting without reproducing issues.

---

## 🔄 Live Polling Step Example (BitLocker Monitoring)

If you are deploying tasks that take time to complete on the target (such as BitLocker disk encryption), you can write a loop with `Start-Sleep`. Because `ps_deploy.exe` supports live streaming, each `Write-Output` line updates the console row in real time until complete:

```powershell
# Live BitLocker Encryption Monitor (streams live progress until 100%)
do {
    $vol = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
    $pct = [int]$vol.EncryptionPercentage
    Write-Output ("Protection: {0} | Conversion: {1} | Method: {2} | Encrypted: {3}%" -f $vol.ProtectionStatus, $vol.VolumeStatus, $vol.EncryptionMethod, $pct)

    if ($pct -ge 100 -or $vol.VolumeStatus -eq 'FullyEncrypted') {
        break
    }

    if ($vol.VolumeStatus -eq 'FullyDecrypted') {
        Write-Error "Drive $env:SystemDrive is FullyDecrypted and encryption is not running."
        exit 1
    }

    Start-Sleep -Seconds 5
} while ($true)
```

During execution, the `Details` column will dynamically update (`Encrypted: 8%` → `Encrypted: 15%` → `Encrypted: 100%`) without locking or freezing the user interface.

---

## 🛠 Architecture & Troubleshooting

### Process Isolation Model & Execution Lifecycle
```
[Admin Machine: ps_deploy.exe]
       │
       ▼ (WinRM / WSMan TCP 5985 / 5986)
[Target Machine: PSSession]
       │
       ├── Auto-creates Remote Staging Dir: C:\Temp\PSDeploy
       ├── (For Software Installers) Stages payload files via Copy-Item -ToSession
       │
       ▼ (Spawns isolated child execution process)
[powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass | cmd.exe /c]
       │
       ├── Working directory & $env:PSDEPLOY_STAGING_DIR set to C:\Temp\PSDeploy
       ├── Runs payload silently (/qn, /S, or custom arguments)
       ├── Asynchronously captures stdout/stderr without buffer deadlocks
       ├── Real-time progress monitoring (0% -> 100% in Status Console)
       ├── Saves remote step log: <ComputerName>_Step<Order>_<StepName>_<Timestamp>.log
       └── Cleans up temporary invocation scripts upon exit
```

### Common Diagnostic Hints:
| Error Message in Details | Root Cause & Resolution |
| :--- | :--- |
| `Open File - Security Warning: The publisher could not be verified (Publisher: Unknown Publisher)` | **Expected behavior:** `ps_deploy.exe` is not commercially code-signed. Click **`Run`** to proceed, check **Unblock** in `ps_deploy.exe` **Properties** to suppress future prompts, or run the script directly without `.exe` prompts via `powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\ps_deploy.ps1`. |
| `OFFLINE: Host unreachable via WinRM (ports 5985/5986) and ICMP ping.` | Target machine is powered off, disconnected from network, or Windows Firewall is blocking both port 5985 and ICMP. |
| `Access is denied (0x80070005)` | The specified credentials do not belong to the local `Administrators` group on the target machine. |
| `WinRM cannot complete the operation (0x800706BA)` | The WinRM service (`WinRM`) is stopped on the remote endpoint. Run `Start-Service WinRM` or deploy WinRM startup via Domain GPO. |
| `Script exited with non-zero code (1)` | The remote PowerShell script encountered a terminating error or called `exit 1`. Inspect the text in the `Details` column for the remote stack trace. |

---

## 📦 Project Artifacts
- **Primary Executable:** [ps_deploy.exe](file:///c:/%23Project/software-deployment-tool/ps_deploy.exe)
- **Source Script:** [ps_deploy.ps1](file:///c:/%23Project/software-deployment-tool/ps_deploy.ps1)
