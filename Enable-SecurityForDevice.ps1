<#
.SYNOPSIS
    Enables TPM and Bitlocker for a device. Script to be used only with SCCM task sequences!
.DESCRIPTION
    Enables TPM and Bitlocker for a device. Script to be used only with SCCM task sequences!
.PARAMETER initializeTS
    Type: Switch
    Description: Initialize the Task Sequence variables required for the script
.PARAMETER enableTPM
    Type: Switch
    Description: Enable and Activate the TPM chip
.PARAMETER startEncryption
    Type: Switch
    Description: Start encrypting the disk
.NOTES
    Author: Robert Kooistra
    Date:   Aug 4, 2016
#>
[CmdLetBinding()]
Param(
    [Parameter(ParameterSetName='InitializeTaskSequence')]
    [Switch]$initializeTS,

    [Parameter(ParameterSetName='EnableTPM')]
    [Switch]$enableTPM,

    [Parameter(ParameterSetName='StartEncryption')]
    [Switch]$startEncryption,

    [Parameter(ParameterSetName='Debug')]
    [Switch]$showTSVar

)

Function New-LogEntry( $message )
{
    $LogFile = ($env:SystemDrive + "\" + ($MyInvocation.MyCommand).ToString().Replace(".ps1","") + ".log")

    # If the log file does not exist, create it
    If( (Test-Path $LogFile) -eq $False )
    {
        New-Item -Path $LogFile -ItemType File | Out-Null
    }

    # Append the message to the log file
    ("[" + (Get-Date -UFormat "%Y-%m-%d %H:%M:%S") +"] - " + $message) | Out-File -FilePath $LogFile -Append
}

Switch( $PSCmdlet.ParameterSetName )
{
    'InitializeTaskSequence' {
        New-LogEntry -message "Starting InitializeTaskSequence"

        Try {
            New-LogEntry -message "Start creating task sequence variables"

            $oTsEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
            $bHasTpm = $oTsEnv.Value( "bHasTPM" )
            $bGoEnableTpm = $oTsEnv.Value( 'bGoEnableTpm' )
            $bPrepareVolume = $oTsEnv.Value( 'bPrepareVolume' )
            $bGoEncrypt = $oTsEnv.Value( 'bGoEncrypt' )

            New-LogEntry -message "Finished creating task sequence variables"
        }
        Catch {
            # Log error
            New-LogEntry -message $_.Exception.Message 
            Return 1
        }

        # Initialize all veriables wtih default values
        New-LogEntry -message "Initialize all veriables wtih default values"
        $bHasTpm = $true
        $bGoEnableTpm = $false
        $bPrepareVolume = $false
        $bGoEncrypt = $false

        New-LogEntry -message ("bHasTpm = $bHasTpm")
        New-LogEntry -message ("bGoEnableTpm = $bGoEnableTpm")
        New-LogEntry -message ("bPrepareVolume = $bPrepareVolume")
        New-LogEntry -message ("bGoEncrypt = $bGoEncrypt")

        New-LogEntry -message "Start TPM detection"
        # Get the TPM
        $Tpm = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm

        If( $Tpm -eq $null ) # Computer has no TPM chip, we cannot continue
        {
            $bHasTpm = $false
            New-LogEntry -message "TPM detection failed, unable to proceed!"
            Return 0
        }
        Else # Computer has a TPM, we need to verify the status
        {
            New-LogEntry -message "TPM detection succesful"

            # If all is true than we proceed to the encryption part
            If( ($Tpm.IsEnabled().isenabled -eq $true) -and ($Tpm.IsActivated().isactivated -eq $true) -and ($Tpm.IsOwned().isowned -eq $true) )
            {
                # Create log entry
                New-LogEntry -message "TPM is enabled, is activated and is owned."

                # Check if a volume is available for encrypting, if not we need to prepare the system volume
                $oVolumeC = Get-WmiObject -Namespace Root\Cimv2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume -Filter "DriveLetter = 'C:'"

                If( $oVolumeC -eq $null ) # No volume found, go and prepare the volume
                {
                    New-LogEntry -message "Volume detection failed, attempting to fix the issue"
                    $bPrepareVolume = $true # Go to prepare
                }
                Else # The is a valid volume available, let us go and encrypt it!
                {
                    New-LogEntry -message "Found a valid volume to encrypt, go encrypt it!"
                    $bGoEncrypt = $true
                }
            }
            Else # If not, we try to enable the TPM
            {
                New-LogEntry -message "TPM is not enabled yes, trying to enable it."
                $bGoEnableTpm = $True
            }
        }
    }

    'EnableTPM' {
           
        Try {
            New-LogEntry -message "Start EnableTPM"
            # Get the TPM chip WMI instance
            $oTpm = Get-Wmiobject -Namespace Root\Cimv2\Security\MicrosoftTpm -Class Win32_Tpm
            # Set request to 6: Enable and Activate TPM, computer should reboot after this
            $oTpm.SetPhysicalPresenceRequest(6) | Out-Null
            New-LogEntry -message "Finished EnableTPM, rebooting"
        }
        Catch { 
            # Log error
            New-LogEntry -message $_.Exception.Message 
            Return 2
        }
    }

    'StartEncryption' {
        Try {
            New-LogEntry -message "Start StartEncryption"

            # Get the volume to be encrypted, we want the C: (system) drive
            $oVolumeC = Get-WmiObject -Namespace Root\Cimv2\Security\MicrosoftVolumeEncryption -Class Win32_EncryptableVolume -Filter "DriveLetter = 'C:'"
            # We want TPM protection
            $oVolumeC.ProtectKeyWithTPM()
            # Start encrypting!
            $oVolumeC.Encrypt()

            New-LogEntry -message "Finished StartEncryption"
        }
        Catch {
            # Log error
            New-LogEntry -message $_.Exception.Message 
            Return 3
        }
    }
}

Return 0