Start-Transcript -Path "$($env:TEMP)\WindowsSearchFix.log" -Append

$Keys = @{
    "BingSearchEnabled" = @{
        "path" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        "type" = "DWORD"
        "value" = 0
    }
    "CortanaConsent" = @{
        "path" = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
        "type" = "DWORD"
        "value" = 0
    }
}

$Keys.Keys | % {
    Write-Output "Start processing item $($_)"

    if( $null -ne (Get-ItemProperty -Path $Keys.Item($_).path -Name $_ -ErrorAction SilentlyContinue ) ) {
        Write-Output "Item $($_) already exists, setting value to $($Keys.Item($_).value)"
        Set-ItemProperty -Path $Keys.Item($_).path -Name $_ -Value $Keys.Item($_).value
    }
    else {
        Write-Output "Item $($_) not found, attempting to create it"
        New-ItemProperty -Path $Keys.Item($_).path -Name $_ -PropertyType $Keys.Item($_).type -Value $Keys.Item($_).value
    }

    Write-Output "Finished processing item $($_)"
}

Stop-Transcript
