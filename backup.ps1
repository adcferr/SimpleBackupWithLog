#Region Functions
    #****************************************************
    #function to write to log
    function Write-Log {
        Param (
            [Parameter(Mandatory=$true)]
            [string]$Message,
            [Parameter(Mandatory=$true)]
            [string]$LogFilePath
        )
        $date = get-date -format "ddmmyy hh:ss" 
        $logMessage = "[$date] :: $Message"
        Add-Content -Path $logFilePath -Value $logMessage
    }

    #****************************************************


    #Function to get source folder size
    function Get-FolderSize {
        param (
            [Parameter(Mandatory = $true)]
            [string]$Folder
        )

        # Recursively get all files and directories within the folder
        $items = Get-ChildItem $Folder -Recurse

        # Initialize the total size variable
        $totalSize = 0

        try {
             # Iterate through each item (file or directory)
            foreach ($item in $items) {

                # If it's a file, add its size to the total
                if ($item.PSIsContainer -eq $false) {
                    $totalSize += $item.Length
                }
            }
            #write info to log
            Write-Log -Message "Current Folder Sider: $totalSize" -LogFilePath $logPath
        }
        catch {
            #Catch exeption error 
            throw "Something went wrong...check logs for more info!"
            Write-Output $_
            
            #write info to log
            Write-Log -Message "ERROR | REASON: FOLDERSIZE Unavailable" -LogFilePath $logPath
            Write-Log -Message $_ -LogFilePath $logPath
        }
       

        $totalMBSize = "{0:N2}" -f ($totalSize / 1MB)

        # Return full Size in bytes
        return $totalMBSize
        
    }

    #****************************************************
    function MakeBackup{

        param (
            [Parameter(Mandatory = $true)]
            [string]$Source,
            [Parameter(Mandatory = $true)]
            [string]$Destination,
            [Parameter(Mandatory = $true)]
            [int]$Itemcount
        )
        try {
            #create destination folder
            New-Item -ItemType Directory -Path $Destination
            Write-Host "Destination folder created: $Destination" -ForegroundColor DarkCyan 

            $counter = 0
            
            $itemsToCopy = Get-ChildItem -Path $Source -Recurse

            # Iterate through each item and copy it to the destination folder
            foreach ($item in $itemsToCopy) {
                
                # Increment the counter
                $counter++
            
                # Calculate the progress percentage to show on progress bar
                $pb = ($counter / $Itemcount) * 100
            
                # Use Write-Progress to display progress bar
                Write-Progress -Activity "Copying from source folder" -Status "Item $counter of $Itemcount" -PercentComplete $pb
            
                # Copy the item to the destination folder
                Copy-Item -Path $Source -Destination $Destination -Recurse -Force
            }
            
            # Clear the progress bar once the copying is complete
            Write-Progress -Activity "Copying items" -Completed
            
            #write info to log
            Write-Log -Message "Backup Finished Successfully!" -LogFilePath $logPath
            
        }
        catch {
            #Catch exeption error 
            throw "Something went wrong...check logs for more info!"
            Write-Output $_

            #write info to log
            Write-Log -Message "ERROR | REASON: COPY ERROR" -LogFilePath $logPath
            Write-Log -Message $_ -LogFilePath $logPath

        }
    }
    #****************************************************

    
  
    

#endregion Functions

Clear-Host


#Region Logging folder

    #cycle to validate Source Folder or exit script
    Do {

        #Aquire source folder for backup
       $LoggingFolder = Read-host "Enter existing folder for logs: "

       #quiting here if user decides to
       if(($LoggingFolder).ToLower() -eq "q") {
            write-warning "Canceled by user $Env:UserName"
            exit
       }

   }while(!(Test-Path -Path $LoggingFolder) )

   $today = get-date -format "ddmmyy" 

   $logPath = $LoggingFolder + "\BackupLog_" + $today + "_.log"

   Write-Host "Logging to $logPath initiated!"  -ForegroundColor DarkCyan
    #write info to log
   Write-Log -Message "Logging Started" -LogFilePath $logPath
#EndRegion Logging folder


#Region Source folder

    #cycle to validate Source Folder or exit script
    Do {

         #Aquire source folder for backup
        $sourceFolder = Read-host "Enter source path or q/Q to Quit "

        #quiting here if user decides to
        if(($sourceFolder).ToLower() -eq "q") {
            write-warning "Canceled by user $Env:UserName"            
            Write-Log -Message "Canceled by user $Env:UserName" -LogFilePath $logPath

            Write-Host "Check log $logPath"
            exit
        }

    }while(!(Test-Path -Path $sourceFolder) )


    $displayNeededSpace = Get-FolderSize -Folder $sourceFolder

    Write-Host "Needed space in destination path: $displayNeededSpace" -ForegroundColor DarkCyan
#EndRegion Source folder


Write-Host "Aquiring total file count in source folder..." 
#get file count for progress bar 
try {
    #get total number of files in source Path - for ProgressBar
    $totalFiles = (Get-ChildItem -Path $sourceFolder -File -Recurse).Count
}
catch {
    throw "Unable to get file count from source folder! Check logs for more info!"
    Write-Output $_
    
    #write info to log
    Write-Log -Message "Unable to get file count from source folder!" -LogFilePath $logPath
    Write-Log -Message $_ -LogFilePath $logPath
    Write-Host "Check log $logPath"
    exit
}

#Region Destination folder and copy

    #set Destination Folder for backup
    $destinationFolder = Read-host "Enter destination path or q/Q to Quit "

    #quiting here if user decides to
    if(($destinationFolder).ToLower() -eq "q") {
        write-warning "Canceled by user $Env:UserName"

        #write info to log
        Write-Log -Message "Canceled by user $Env:UserName REASON: Canceled | NO DESTINATHION PATH provided" -LogFilePath $logPath
        Write-Host "Check log $logPath"

        exit
    }

    #Testing for destination folder
    if(!(Test-Path -Path $destinationFolder)){

        #cycle to accept only valid option on $reply
        Do {
            
            $reply = Read-host -Host "Destination Folder does not exist. Create folder? (Y/N - Q -to quit) "

            Switch(($reply).ToLower()){
                "y" { 
                    #visual information
                    Write-warning "Creating Destination folder..."

                    #write info to log
                    Write-Log -Message "Created Destination Folder" -LogFilePath $logPath
                    get-date -format "ddmmyy hh:ss"

                    #Make copy
                    MakeBackup -Source $sourceFolder -Destination $destinationFolder -Itemcount $totalFiles

                    #write info to log
                    Write-Log -Message "Copied to destination Floder" -LogFilePath $logPath
                    Write-Host "Check log for copy info $logPath"
                    exit
                }
                "n" {
                    get-date -format "ddmmyy hh:ss"
                    Write-Warning "No destination folder created...Exiting!"

                    #write info to log
                    Write-Log -Message "Canceled by user $Env:UserName REASON: NO FOLDER | NO DESTINATHION PATH Created" -LogFilePath $logPath

                    Write-Host "Check log $logPath"
                    exit
                }
                "q" {
                    get-date -format "ddmmyy hh:ss"
                    write-warning "Canceled by user $Env:UserName"

                    #write info to log
                    Write-Log -Message "Canceled by user $Env:UserName REASON: QUIT MENU | NO DESTINATHION PATH provided" -LogFilePath $logPath
                    Write-Host "Check log $logPath"
                    exit                    
                }
                default {
                    Write-Warning "Invalid Option"                    
                }
            }
        } while (((($reply).ToLower()) -ne "y") -or ((($reply).ToLower()) -ne "n") -or (($reply).ToLower() -ne "q"))          
    } 

    #folder exists, proceed to clear folder contents and make new copy so they are precise match
    else 
    {
        Write-Warning "Destination folder already exeists!"
        
        #write info to log
        Write-Log -Message "Destination folder already exists" -LogFilePath $logPath

        Write-Warning "Continuing with operation will delete current DESTINATION folder and all of its contents!"
        #request to continue or abort action
        $x = Read-host "Continue (C) Abort (A) "
        
        switch (($x).ToLower()) {
            "c" { 

                #Remove existing folder so contents match new folder.
                Remove-Item -Path $destinationFolder -Recurse -Force
                
                #write info to log
                Write-Log -Message "Deleted Destination Folder" -LogFilePath $logPath
                Write-Log -Message "Running MakeCopy Function" -LogFilePath $logPath

                #Make copy
                MakeBackup -Source $sourceFolder -Destination $destinationFolder -Itemcount $totalFiles
                Write-Host "Check log for copy info $logPath"
                exit
             }
             "a" {
                Write-Host "Operation canceled due to DESTINATION folder already containing data not to be overwriten"

                #write info to log
                Write-Log -Message "Canceled by user $Env:UserName REASON: ABORT MENU | DESTINATHION FOLDER NOT EMPTY" -LogFilePath $logPath
                
                exit
             }
            Default { Write-Warning "Invalid Option" }
        }      
    }

#EndRegion Destination folder and copy






