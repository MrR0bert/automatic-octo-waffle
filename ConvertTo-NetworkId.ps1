<#
Expected input:
    IPAddress = 10.1.134.42
    SubnetMask = 255.255.255.224 || 27 with /AsCidr

Expected output:
    10.1.134.32
#>
Function ConvertTo-NetworkId {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String]$IPAddress,
        [Parameter(Mandatory=$True)]
        [String]$SubnetMask
    )

    Write-Verbose "Calculating network ID from IPAddress $IPAddress ($SubnetMask)"
 
    If( $SubnetMask -match "(^\/?[1-9]{1,2}$)" ) {
        Write-Verbose "Converting subnetmask from CIDR"
        $CIDR = $SubnetMask.Replace('/','')
        $counter = 1
        $SubnetMask = ""

    }
    Return
    $objIPAddress = [Net.IPAddress]::Parse($IPAddress)
    $objSubnetMask = [Net.IPAddress]::Parse($SubnetMask)

    $objNetwork = New-Object System.Net.IPAddress ($objSubnetMask.Address -band $objIPAddress.Address)
    $objNetwork.IPAddressToString
}

ConvertTo-NetworkId -IPAddress 10.1.134.42 -SubnetMask 255.255.255.224 -Verbose
ConvertTo-NetworkId -IPAddress 10.1.134.42 -SubnetMask 24 -Verbose
ConvertTo-NetworkId -IPAddress 10.1.134.42 -SubnetMask /24 -Verbose
