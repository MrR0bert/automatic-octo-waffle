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

        $Tpm.IsEnabled().isenabled
        $Tpm.IsActivated().isactivated
        $Tpm.IsOwned().isowned
    }

    'EnableTPM' {
        Write-Host 'Were not going to! HA!'
    }
}
