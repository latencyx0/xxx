# Parte 1
function MagicBypass {
<#
.SYNOPSIS
    This script demonstrates taking arguments with named parameters.

.DESCRIPTION
    This script takes 4 arguments with names and displays them.

.PARAMETER InitialStart
    The negative offset from ScanContent that indicates where the search starts, it should be 0x50000 that indicates we will start searching -0x50000 bytes from ScanContent which is the universal and default value.

.PARAMETER NegativeOffset
    The offset to substract in each loop to the $InitialStart which is 0x50000 by default => In each loop we will read another 0x50000 (Going Backwards)

.PARAMETER MaxOffset
    The total number of bytes you want to search

.PARAMETER ReadBytes
  The number of bytes to read with ReadProcessMemory at once. as we are going with chunks of 50k in each loop, we will as well read 50k at a time.
#>

# Define named parameters
param(
    $InitialStart = 0x50000,
    $NegativeOffset= 0x50000,
    $MaxOffset = 0x1000000,
    $ReadBytes = 0x50000
)
