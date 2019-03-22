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