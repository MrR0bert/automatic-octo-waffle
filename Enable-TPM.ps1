Try {
    # Get the TPM chip WMI instance
    $oTpm = Get-Wmiobject -Namespace Root\Cimv2\Security\MicrosoftTpm -Class Win32_Tpm

    # If no TPM was found, we can't continue
    If( $oTpm -eq $null ) {
        Exit -1
    }

    If( ($oTpm.IsEnabled_InitialValue -eq $False) -or ($oTpm.IsActivated_InitialValue -eq $False) ) {
        # Set request to 6: Enable and Activate TPM, computer should reboot after this
        $oTpm.SetPhysicalPresenceRequest(6) | Out-Null
    }

    # TPM was found and enabled, so no need to do anything.
    
}
Catch {
    Exit -1
}