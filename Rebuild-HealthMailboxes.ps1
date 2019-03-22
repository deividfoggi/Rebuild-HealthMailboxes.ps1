#################################################################################################################################
# This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment. #
# THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,  #
# INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. We grant You  #
# a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of  #
# the Sample Code, provided that. You agree: (i) to not use Our name, logo, or trademarks to market Your software product in    #
# which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code #
# is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits,  #
# including attorneys’ fees, that arise or result from the use or distribution of the Sample Code                               #
#################################################################################################################################

#Get all Exchange servers but edge transport server role
$exchangeServers = Get-ExchangeServer | Where-Object{$_.ServerRole -notmatch "edge" -and $_.AdminDisplayVersion -match "15"}

#Progress bar counter
$i = 0

#Stop Health Manager on all servers
foreach($exchange in $exchangeServers){
    $serverName = $exchange.Name
    Write-Progress -Activity "Stopping MSExchange HM service on all servers" -Status "Stopping on server $serverName" -PercentComplete (($i / $exchangeServers.length) * 100)
    Try{
        Invoke-Command -ComputerName $exchange.Name -ScriptBlock {Stop-Service MSExchangeHM | Out-Null}
    }
    catch{
        Write-Host $_.Exception.Message
    }
    $i++
}

#Disable health mailboxes'
Get-Mailbox -Monitoring | Disable-Mailbox -Confirm:$false

#Remove all accounts from AD with name starting as "HealthMailbox"
$healthMailboxUsers = Get-ADUser -Filter {DisplayName -like "HealthMailbox*"}

#Progress bar counter
$i = 0

foreach($user in $healthMailboxUsers){
    $userName = $user.Name
    Write-Progress -Activity "Wiping user accounts from AD" -Status "Wiping user $userName" -PercentComplete (($i / $healthMailboxUsers.length) * 100)
    Try{
        Get-ADUser $user | Remove-ADObject -Recursive -Confirm:$false
    }
    catch{
        Write-Host $_.Exception.Message
    }
    $i++
}

#Progress bar counter
$i = 0

#Start Health Manager on all servers
foreach($exchange in $exchangeServers){
    $serverName = $exchange.Name
    Write-Progress -Activity "Starting MSExchange HM service on all servers" -Status "Starting on server $serverName" -PercentComplete (($i / $exchangeServers.length) * 100)

    Try{
        Invoke-Command -ComputerName $exchange.Name -ScriptBlock {Start-Service MSExchangeHM | Out-Null}
    }
    catch{
        Write-Host $_.Exception.Message
    }
    $i++
}