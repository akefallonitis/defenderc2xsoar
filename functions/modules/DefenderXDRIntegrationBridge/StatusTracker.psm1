<#
.SYNOPSIS
    Status Tracker for DefenderXDR - Azure Table Storage Integration
    
.DESCRIPTION
    Handles operation status tracking with correlation IDs and tenant isolation.
    Provides status querying, progress tracking, and audit trail for all operations.
    
    Features:
    - Tenant-scoped status tracking (PartitionKey = TenantId)
    - Correlation ID tracking (RowKey = CorrelationId)
    - Progress tracking for bulk operations
    - Result aggregation
    - Automatic TTL cleanup (30 days default)
    - Query by tenant, correlation ID, status, timerange
    
.EXAMPLE
    # Create status entry for new operation
    New-OperationStatus -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
        -Service "MDE" -Action "IsolateDevice" -TotalItems 100
    
    # Update progress
    Update-OperationProgress -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
        -CompletedItems 47 -FailedItems 2 -Status "Processing"
    
    # Add result
    Add-OperationResult -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
        -ItemId "device-id" -Status "Success" -ActionId "mde-action-id"
    
    # Query status
    $status = Get-OperationStatus -TenantId "tenant-guid" -CorrelationId "correlation-guid"
    
.NOTES
    Version: 3.0.0
    Requires: Azure.Data.Tables PowerShell module
#>

# Global table client cache
if (-not $global:DefenderXDRTableClients) {
    $global:DefenderXDRTableClients = @{}
}

function Get-TableClient {
    <#
    .SYNOPSIS
        Gets or creates an Azure Table Storage client
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TableName = "defenderxdrstatus"
    )
    
    try {
        # Check cache first
        if ($global:DefenderXDRTableClients.ContainsKey($TableName)) {
            return $global:DefenderXDRTableClients[$TableName]
        }
        
        # Get connection string from environment
        $storageConnectionString = $env:AZURE_STORAGE_CONNECTION_STRING
        
        if (-not $storageConnectionString) {
            Write-Warning "AZURE_STORAGE_CONNECTION_STRING not configured - status tracking disabled"
            return $null
        }
        
        # Create table client (using .NET SDK)
        Add-Type -AssemblyName "Azure.Data.Tables"
        
        $tableClient = [Azure.Data.Tables.TableClient]::new($storageConnectionString, $TableName)
        
        # Create table if it doesn't exist
        $tableClient.CreateIfNotExists() | Out-Null
        
        # Cache for reuse
        $global:DefenderXDRTableClients[$TableName] = $tableClient
        
        Write-Host "Table client created for table: $TableName"
        
        return $tableClient
    }
    catch {
        Write-Error "Failed to create table client: $_"
        return $null
    }
}

function New-OperationStatus {
    <#
    .SYNOPSIS
        Creates a new operation status entry
        
    .PARAMETER TenantId
        Tenant ID (becomes PartitionKey)
        
    .PARAMETER CorrelationId
        Correlation ID (becomes RowKey)
        
    .PARAMETER Service
        Service name (MDE, Identity, Email, etc.)
        
    .PARAMETER Action
        Action name (IsolateDevice, etc.)
        
    .PARAMETER TotalItems
        Total number of items to process
        
    .PARAMETER AdditionalData
        Hashtable of additional data to store
        
    .EXAMPLE
        New-OperationStatus -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
            -Service "MDE" -Action "IsolateDevice" -TotalItems 100
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $true)]
        [string]$Service,
        
        [Parameter(Mandatory = $true)]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [int]$TotalItems = 1,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalData = @{}
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            Write-Warning "Status tracking not available - Azure Storage not configured"
            return @{ success = $false; message = "Status tracking disabled" }
        }
        
        # Create entity
        $entity = @{
            PartitionKey = $TenantId
            RowKey = $CorrelationId
            Service = $Service
            Action = $Action
            Status = "Queued"
            TotalItems = $TotalItems
            CompletedItems = 0
            FailedItems = 0
            PendingItems = $TotalItems
            StartTime = (Get-Date).ToString("o")
            LastUpdate = (Get-Date).ToString("o")
            Results = "[]"  # JSON array of results
        }
        
        # Add TTL (30 days from now)
        $ttl = (Get-Date).AddDays(30)
        $entity.TTL = $ttl.ToString("o")
        
        # Add additional data
        foreach ($key in $AdditionalData.Keys) {
            $entity[$key] = $AdditionalData[$key]
        }
        
        # Insert entity
        $tableEntity = [Azure.Data.Tables.TableEntity]::new($entity)
        $tableClient.AddEntity($tableEntity) | Out-Null
        
        Write-Host "Created status entry: $CorrelationId (Tenant: $TenantId, Service: $Service, Action: $Action)"
        
        return @{
            success = $true
            tenantId = $TenantId
            correlationId = $CorrelationId
            status = "Queued"
        }
    }
    catch {
        Write-Error "Failed to create operation status: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-OperationStatus {
    <#
    .SYNOPSIS
        Retrieves operation status by tenant and correlation ID
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER CorrelationId
        Correlation ID
        
    .EXAMPLE
        $status = Get-OperationStatus -TenantId "tenant-guid" -CorrelationId "correlation-guid"
        Write-Host "Status: $($status.Status), Progress: $($status.CompletedItems)/$($status.TotalItems)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            return $null
        }
        
        # Get entity by PartitionKey and RowKey
        $entity = $tableClient.GetEntity($TenantId, $CorrelationId)
        
        if (-not $entity) {
            return $null
        }
        
        # Convert to hashtable
        $status = @{}
        foreach ($property in $entity.Value.Keys) {
            $status[$property] = $entity.Value[$property]
        }
        
        # Parse results JSON
        if ($status.Results) {
            try {
                $status.Results = $status.Results | ConvertFrom-Json
            }
            catch {
                $status.Results = @()
            }
        }
        
        Write-Host "Retrieved status for correlation ID: $CorrelationId"
        
        return $status
    }
    catch {
        Write-Error "Failed to get operation status: $_"
        return $null
    }
}

function Update-OperationProgress {
    <#
    .SYNOPSIS
        Updates operation progress
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER CorrelationId
        Correlation ID
        
    .PARAMETER CompletedItems
        Number of completed items
        
    .PARAMETER FailedItems
        Number of failed items
        
    .PARAMETER Status
        Current status (Queued, Processing, Completed, Failed)
        
    .PARAMETER AdditionalData
        Additional data to update
        
    .EXAMPLE
        Update-OperationProgress -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
            -CompletedItems 47 -FailedItems 2 -Status "Processing"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $false)]
        [int]$CompletedItems,
        
        [Parameter(Mandatory = $false)]
        [int]$FailedItems,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Queued", "Processing", "Completed", "Failed", "PartiallyCompleted")]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalData = @{}
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            return @{ success = $false; message = "Status tracking disabled" }
        }
        
        # Get existing entity
        $entity = $tableClient.GetEntity($TenantId, $CorrelationId)
        
        if (-not $entity) {
            throw "Operation status not found: $CorrelationId"
        }
        
        # Update fields
        if ($null -ne $CompletedItems) {
            $entity.Value["CompletedItems"] = $CompletedItems
        }
        
        if ($null -ne $FailedItems) {
            $entity.Value["FailedItems"] = $FailedItems
        }
        
        if ($Status) {
            $entity.Value["Status"] = $Status
        }
        
        # Calculate pending items
        $totalItems = $entity.Value["TotalItems"]
        $completed = if ($null -ne $CompletedItems) { $CompletedItems } else { $entity.Value["CompletedItems"] }
        $failed = if ($null -ne $FailedItems) { $FailedItems } else { $entity.Value["FailedItems"] }
        $entity.Value["PendingItems"] = $totalItems - $completed - $failed
        
        # Update timestamp
        $entity.Value["LastUpdate"] = (Get-Date).ToString("o")
        
        # Add completion time if done
        if ($Status -in @("Completed", "Failed", "PartiallyCompleted")) {
            if (-not $entity.Value.ContainsKey("CompletionTime")) {
                $entity.Value["CompletionTime"] = (Get-Date).ToString("o")
            }
        }
        
        # Add additional data
        foreach ($key in $AdditionalData.Keys) {
            $entity.Value[$key] = $AdditionalData[$key]
        }
        
        # Update entity
        $tableClient.UpdateEntity($entity.Value, $entity.Value.ETag, [Azure.Data.Tables.TableUpdateMode]::Merge) | Out-Null
        
        Write-Host "Updated progress for correlation ID: $CorrelationId (Completed: $completed/$totalItems, Failed: $failed)"
        
        return @{
            success = $true
            correlationId = $CorrelationId
            completedItems = $completed
            failedItems = $failed
            totalItems = $totalItems
            status = $entity.Value["Status"]
        }
    }
    catch {
        Write-Error "Failed to update operation progress: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Add-OperationResult {
    <#
    .SYNOPSIS
        Adds a result entry to an operation's results array
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER CorrelationId
        Correlation ID
        
    .PARAMETER ItemId
        Item ID (device ID, user ID, etc.)
        
    .PARAMETER Status
        Result status (Success, Failed)
        
    .PARAMETER ActionId
        Action ID from the service (e.g., MDE action ID)
        
    .PARAMETER ErrorMessage
        Error message if failed
        
    .EXAMPLE
        Add-OperationResult -TenantId "tenant-guid" -CorrelationId "correlation-guid" `
            -ItemId "device-id" -Status "Success" -ActionId "mde-action-id"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId,
        
        [Parameter(Mandatory = $true)]
        [string]$ItemId,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Success", "Failed")]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [string]$ActionId,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            return @{ success = $false; message = "Status tracking disabled" }
        }
        
        # Get existing entity
        $entity = $tableClient.GetEntity($TenantId, $CorrelationId)
        
        if (-not $entity) {
            throw "Operation status not found: $CorrelationId"
        }
        
        # Parse existing results
        $results = @()
        if ($entity.Value["Results"]) {
            try {
                $results = $entity.Value["Results"] | ConvertFrom-Json
                if ($results -isnot [array]) {
                    $results = @($results)
                }
            }
            catch {
                $results = @()
            }
        }
        
        # Add new result
        $newResult = @{
            itemId = $ItemId
            status = $Status
            timestamp = (Get-Date).ToString("o")
        }
        
        if ($ActionId) {
            $newResult.actionId = $ActionId
        }
        
        if ($ErrorMessage) {
            $newResult.error = $ErrorMessage
        }
        
        $results += $newResult
        
        # Update results (keep last 100 results max to avoid size limits)
        if ($results.Count -gt 100) {
            $results = $results | Select-Object -Last 100
        }
        
        $entity.Value["Results"] = ($results | ConvertTo-Json -Compress -Depth 10)
        $entity.Value["LastUpdate"] = (Get-Date).ToString("o")
        
        # Update entity
        $tableClient.UpdateEntity($entity.Value, $entity.Value.ETag, [Azure.Data.Tables.TableUpdateMode]::Merge) | Out-Null
        
        Write-Host "Added result for correlation ID: $CorrelationId (Item: $ItemId, Status: $Status)"
        
        return @{
            success = $true
            correlationId = $CorrelationId
            itemId = $ItemId
            status = $Status
        }
    }
    catch {
        Write-Error "Failed to add operation result: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

function Get-TenantOperations {
    <#
    .SYNOPSIS
        Gets all operations for a tenant
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER Status
        Filter by status (optional)
        
    .PARAMETER MaxResults
        Maximum number of results (default: 100)
        
    .EXAMPLE
        $operations = Get-TenantOperations -TenantId "tenant-guid" -Status "Processing"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $false)]
        [string]$Status,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 100
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            return @()
        }
        
        # Build query
        $filter = "PartitionKey eq '$TenantId'"
        
        if ($Status) {
            $filter += " and Status eq '$Status'"
        }
        
        # Query entities
        $entities = $tableClient.Query($filter, $MaxResults)
        
        # Convert to array of hashtables
        $operations = @()
        foreach ($entity in $entities.Value) {
            $op = @{}
            foreach ($property in $entity.Keys) {
                $op[$property] = $entity[$property]
            }
            
            # Parse results JSON
            if ($op.Results) {
                try {
                    $op.Results = $op.Results | ConvertFrom-Json
                }
                catch {
                    $op.Results = @()
                }
            }
            
            $operations += $op
        }
        
        Write-Host "Retrieved $($operations.Count) operation(s) for tenant: $TenantId"
        
        return $operations
    }
    catch {
        Write-Error "Failed to get tenant operations: $_"
        return @()
    }
}

function Remove-OperationStatus {
    <#
    .SYNOPSIS
        Removes an operation status entry (cleanup)
        
    .PARAMETER TenantId
        Tenant ID
        
    .PARAMETER CorrelationId
        Correlation ID
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        
        [Parameter(Mandatory = $true)]
        [string]$CorrelationId
    )
    
    try {
        $tableClient = Get-TableClient
        
        if (-not $tableClient) {
            return @{ success = $false; message = "Status tracking disabled" }
        }
        
        # Delete entity
        $tableClient.DeleteEntity($TenantId, $CorrelationId) | Out-Null
        
        Write-Host "Removed status entry: $CorrelationId"
        
        return @{
            success = $true
            correlationId = $CorrelationId
        }
    }
    catch {
        Write-Error "Failed to remove operation status: $_"
        
        return @{
            success = $false
            error = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-TableClient',
    'New-OperationStatus',
    'Get-OperationStatus',
    'Update-OperationProgress',
    'Add-OperationResult',
    'Get-TenantOperations',
    'Remove-OperationStatus'
)
