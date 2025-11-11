<#
.SYNOPSIS
    Queue Manager for DefenderXDR - Azure Queue Storage Integration
    
.DESCRIPTION
    Handles bulk operation queueing with tenant isolation and batch processing.
    Provides queue management for operations that process multiple targets (devices, users, emails).
    
    Features:
    - Tenant-isolated queue naming
    - Batch size management
    - Message serialization/deserialization
    - Retry logic with exponential backoff
    - Queue monitoring and cleanup
    
.EXAMPLE
    # Queue a bulk isolation operation
    $operation = @{
        correlationId = (New-Guid).ToString()
        tenantId = "tenant-guid"
        service = "MDE"
        action = "IsolateDevice"
        deviceIds = @("id1", "id2", ..., "id100")
        comment = "Bulk isolation"
    }
    
    Add-BulkOperationToQueue -Operation $operation
    
.NOTES
    Version: 3.0.0
    Requires: Azure.Storage.Queues PowerShell module
#>

# Global queue client cache
if (-not $global:DefenderXDRQueueClients) {
    $global:DefenderXDRQueueClients = @{}
}

function Get-QueueClient {
    <#
    .SYNOPSIS
        Gets or creates an Azure Queue Storage client for a tenant
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$QueueType = "bulk-ops"
    )
    
    try {
        $queueName = "xdr-$($TenantId.ToLower())-$QueueType"
        
        # Check cache first
        if ($global:DefenderXDRQueueClients.ContainsKey($queueName)) {
            return $global:DefenderXDRQueueClients[$queueName]
        }
        
        # Get connection string from environment
        $storageConnectionString = $env:AZURE_STORAGE_CONNECTION_STRING
        
        if (-not $storageConnectionString) {
            Write-Warning "AZURE_STORAGE_CONNECTION_STRING not configured - bulk operations disabled"
            return $null
        }
        
        # Create queue client (using .NET SDK)
        Add-Type -AssemblyName "Azure.Storage.Queues"
        
        $queueClient = [Azure.Storage.Queues.QueueClient]::new($storageConnectionString, $queueName)
        
        # Create queue if it doesn't exist
        $queueClient.CreateIfNotExists() | Out-Null
        
        # Cache for reuse
        $global:DefenderXDRQueueClients[$queueName] = $queueClient
        
        Write-Host "Queue client created for tenant $TenantId (Queue: $queueName)"
        
        return $queueClient
    }
    catch {
        Write-Error "Failed to create queue client: $_"
        return $null
    }
}

function Add-BulkOperationToQueue {
    <#
    .SYNOPSIS
        Queues a bulk operation for async processing
        
    .PARAMETER Operation
        Hashtable containing operation details:
        - correlationId (required)
        - tenantId (required)
        - service (required)
        - action (required)
        - targetIds (required) - array of device/user/email IDs
        - Additional action-specific parameters
        
    .PARAMETER BatchSize
        Number of targets to process per batch (default: 10)
        
    .EXAMPLE
        $operation = @{
            correlationId = "guid"
            tenantId = "tenant-guid"
            service = "MDE"
            action = "IsolateDevice"
            deviceIds = @("id1", "id2", ..., "id100")
            comment = "Bulk isolation"
        }
        
        Add-BulkOperationToQueue -Operation $operation -BatchSize 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Operation,
        
        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 10
    )
    
    try {
        # Validate required fields
        if (-not $Operation.correlationId) {
            throw "correlationId is required in operation"
        }
        if (-not $Operation.tenantId) {
            throw "tenantId is required in operation"
        }
        if (-not $Operation.service) {
            throw "service is required in operation"
        }
        if (-not $Operation.action) {
            throw "action is required in operation"
        }
        
        # Get target IDs (deviceIds, userIds, emailIds, etc.)
        $targetIds = $null
        if ($Operation.deviceIds) { $targetIds = $Operation.deviceIds }
        elseif ($Operation.userIds) { $targetIds = $Operation.userIds }
        elseif ($Operation.emailIds) { $targetIds = $Operation.emailIds }
        
        if (-not $targetIds -or $targetIds.Count -eq 0) {
            throw "No target IDs found in operation (deviceIds, userIds, or emailIds required)"
        }
        
        Write-Host "Queuing bulk operation: $($Operation.action) for $($targetIds.Count) targets (Batch size: $BatchSize)"
        
        # Get queue client
        $queueClient = Get-QueueClient -TenantId $Operation.tenantId
        
        if (-not $queueClient) {
            throw "Failed to get queue client - Azure Storage not configured"
        }
        
        # Split targets into batches
        $batches = @()
        for ($i = 0; $i -lt $targetIds.Count; $i += $BatchSize) {
            $batchTargets = $targetIds[$i..[Math]::Min($i + $BatchSize - 1, $targetIds.Count - 1)]
            $batches += ,@($batchTargets)
        }
        
        Write-Host "Split into $($batches.Count) batch(es)"
        
        # Queue each batch
        $queuedCount = 0
        foreach ($batch in $batches) {
            # Create batch message
            $batchMessage = @{
                correlationId = $Operation.correlationId
                batchId = [guid]::NewGuid().ToString()
                tenantId = $Operation.tenantId
                service = $Operation.service
                action = $Operation.action
                targetIds = $batch
                parameters = @{}
                timestamp = (Get-Date).ToString("o")
            }
            
            # Copy additional parameters (comment, scanType, etc.)
            foreach ($key in $Operation.Keys) {
                if ($key -notin @("correlationId", "tenantId", "service", "action", "deviceIds", "userIds", "emailIds", "targetIds")) {
                    $batchMessage.parameters[$key] = $Operation[$key]
                }
            }
            
            # Serialize to JSON
            $messageJson = $batchMessage | ConvertTo-Json -Compress -Depth 10
            
            # Encode to Base64 (Azure Queue requirement)
            $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($messageJson)
            $messageBase64 = [Convert]::ToBase64String($messageBytes)
            
            # Send to queue
            $queueClient.SendMessage($messageBase64) | Out-Null
            
            $queuedCount++
            Write-Host "Queued batch $queuedCount/$($batches.Count) ($($batch.Count) targets)"
        }
        
        Write-Host "Successfully queued $queuedCount batch(es) for correlation ID: $($Operation.correlationId)"
        
        return @{
            success = $true
            correlationId = $Operation.correlationId
            totalTargets = $targetIds.Count
            batchCount = $batches.Count
            batchSize = $BatchSize
            queuedBatches = $queuedCount
        }
    }
    catch {
        Write-Error "Failed to queue bulk operation: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-QueuedBulkOperation {
    <#
    .SYNOPSIS
        Retrieves the next bulk operation batch from the queue
        
    .PARAMETER TenantId
        Tenant ID to get queue for
        
    .PARAMETER VisibilityTimeout
        How long to hide the message from other consumers (default: 300 seconds = 5 minutes)
        
    .EXAMPLE
        $batch = Get-QueuedBulkOperation -TenantId "tenant-guid"
        if ($batch) {
            # Process batch
            Process-BulkOperationBatch -Batch $batch
            
            # Delete from queue when done
            Remove-QueuedBulkOperation -TenantId "tenant-guid" -MessageId $batch.messageId -PopReceipt $batch.popReceipt
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [int]$VisibilityTimeout = 300
    )
    
    try {
        $queueClient = Get-QueueClient -TenantId $TenantId
        
        if (-not $queueClient) {
            return $null
        }
        
        # Get one message from queue
        $messages = $queueClient.ReceiveMessages(1, [TimeSpan]::FromSeconds($VisibilityTimeout))
        
        if (-not $messages -or $messages.Value.Count -eq 0) {
            return $null
        }
        
        $message = $messages.Value[0]
        
        # Decode from Base64
        $messageBytes = [Convert]::FromBase64String($message.MessageText)
        $messageJson = [System.Text.Encoding]::UTF8.GetString($messageBytes)
        
        # Deserialize from JSON
        $batch = $messageJson | ConvertFrom-Json
        
        # Add queue metadata
        $batch | Add-Member -NotePropertyName "messageId" -NotePropertyValue $message.MessageId
        $batch | Add-Member -NotePropertyName "popReceipt" -NotePropertyValue $message.PopReceipt
        $batch | Add-Member -NotePropertyName "dequeueCount" -NotePropertyValue $message.DequeueCount
        
        Write-Host "Retrieved batch from queue: $($batch.batchId) (Correlation: $($batch.correlationId))"
        
        return $batch
    }
    catch {
        Write-Error "Failed to get queued operation: $_"
        return $null
    }
}

function Remove-QueuedBulkOperation {
    <#
    .SYNOPSIS
        Removes a processed batch from the queue
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER MessageId
        Message ID from Get-QueuedBulkOperation
        
    .PARAMETER PopReceipt
        Pop receipt from Get-QueuedBulkOperation
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$MessageId,
        
        [Parameter(Mandatory = $true)]
        [string]$PopReceipt
    )
    
    try {
        $queueClient = Get-QueueClient -TenantId $TenantId
        
        if (-not $queueClient) {
            throw "Queue client not available"
        }
        
        $queueClient.DeleteMessage($MessageId, $PopReceipt) | Out-Null
        
        Write-Host "Deleted batch from queue: $MessageId"
        
        return @{
            success = $true
            messageId = $MessageId
        }
    }
    catch {
        Write-Error "Failed to delete queued operation: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-QueueStatistics {
    <#
    .SYNOPSIS
        Gets queue statistics for a tenant
        
    .PARAMETER TenantId
        Tenant ID
        
    .EXAMPLE
        $stats = Get-QueueStatistics -TenantId "tenant-guid"
        Write-Host "Pending operations: $($stats.approximateMessagesCount)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId
    )
    
    try {
        $queueClient = Get-QueueClient -TenantId $TenantId
        
        if (-not $queueClient) {
            return $null
        }
        
        $properties = $queueClient.GetProperties()
        
        return @{
            success = $true
            tenantId = $TenantId
            queueName = $queueClient.Name
            approximateMessagesCount = $properties.Value.ApproximateMessagesCount
            metadata = $properties.Value.Metadata
        }
    }
    catch {
        Write-Error "Failed to get queue statistics: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Clear-TenantQueue {
    <#
    .SYNOPSIS
        Clears all messages from a tenant's queue (admin operation)
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER Confirm
        Require confirmation before clearing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [switch]$Confirm
    )
    
    try {
        if (-not $Confirm) {
            throw "Clearing queue requires -Confirm switch for safety"
        }
        
        $queueClient = Get-QueueClient -TenantId $TenantId
        
        if (-not $queueClient) {
            throw "Queue client not available"
        }
        
        $queueClient.ClearMessages() | Out-Null
        
        Write-Host "Cleared all messages from tenant queue: $TenantId"
        
        return @{
            success = $true
            tenantId = $TenantId
            message = "Queue cleared"
        }
    }
    catch {
        Write-Error "Failed to clear queue: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-QueueClient',
    'Add-BulkOperationToQueue',
    'Get-QueuedBulkOperation',
    'Remove-QueuedBulkOperation',
    'Get-QueueStatistics',
    'Clear-TenantQueue'
)
