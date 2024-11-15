# Caminho da chave no registro
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"

# Lendo o valor armazenado na chave (assumindo que o comando está em 'N/A')
$encodedCommand = (Get-ItemProperty -Path $registryPath -Name "N/A")."N/A"

# Executando o comando PowerShell diretamente
Invoke-Expression $encodedCommand
