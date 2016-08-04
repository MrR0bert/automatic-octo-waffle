[CmdLetBinding()]
Param(
    [Parameter(ParameterSetName='InitializeTaskSequence')]
    [Switch]$initializeTS,

    [Parameter(ParameterSetName='EnableTPM')]
    [Switch]$enableTPM
)

Switch( $PSCmdlet.ParameterSetName )
{
    'InitializeTaskSequence' {
        $Tpm = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm

        $oTsEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
        $bHasTpm = $oTsEnv.Value( "bHasTPM" )
        $bGoEnableTpm = $oTsEnv.Value( 'bGoEnableTpm' )
        $bPrepareVolume = $oTsEnv.Value( 'bPrepareVolume' )
        $bGoEncrypt = $oTsEnv.Value( 'bGoEncrypt' )

        # Initialize all veriables
        $bHasTpm = $false
        $bGoEnableTpm = $false
        $bPrepareVolume = $false
        $bGoEncrypt = $false


        If( $Tpm -eq $null ) # Computer has no TPM chip, we cannot continue
        {
            $bHasTpm = $false
        }
        Else # Computer has a TPM, we need to verify the status
        {
            # If all is true than we proceed to the encryption part
            If( ($Tpm.IsEnabled().isenabled -eq $true) -and ($Tpm.IsActivated().isactivated -eq $true) -and ($Tpm.IsOwned().isowned -eq $true) )
            {
                # Check if a volume is available for encrypting, if not we need to prepare the system volume
                $oVolumeC = Get-WmiObject -Namespace Root\Cimv2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume -Filter "DriveLetter = 'C:'"

                If( $oVolumeC -eq $null ) # No volume found, go and prepare the volume
                {
                    $bPrepareVolume = $true
                }
                Else # The is a valid volume available, let us go and encrypt it!
                {
                    $bGoEncrypt = $true
                }
            }
            Else # If not, we try to enable the TPM
            {
                $bGoEnableTpm = $True
            }
        }
    }

    'EnableTPM' {
        $oTpm = Get-Wmiobject -Namespace Root\Cimv2\Security\MicrosoftTpm -Class Win32_Tpm
        $oTpm.SetPhysicalPresenceRequest(6) | out-null
    }

    'StartEncryption' {
        $oVolumeC = Get-WmiObject -Namespace Root\Cimv2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume -Filter "DriveLetter = 'C:'"
        $oVolumeC.ProtectKeyWithTPM()
        $oVolumeC.Encrypt()
    }
}
