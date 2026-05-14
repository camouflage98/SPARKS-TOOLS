(
    try (
        local tempDir = getFilenamePath (getSourceFileName())
        local userStartupDir = getDir #userStartupScripts
        local userIconsDir = getDir #userIcons
        
        makeDir userStartupDir
        makeDir userIconsDir
        
        local targetScript = userStartupDir + "\\SPARKS_Master_Toolbar.ms"
        
        local allTempFiles = getFiles (tempDir + "*.*")
        local subDirs = getDirectories (tempDir + "*")
        for d in subDirs do join allTempFiles (getFiles (d + "*.*"))
        
        local actualScriptSource = ""
        
        for f in allTempFiles do (
            local fName = toLower (filenameFromPath f)
            
            -- Find the script
            if matchPattern fName pattern:"*sparks_master_toolbar*" do actualScriptSource = f
            
            -- Find ANY png file and copy it to the icons folder automatically
            if matchPattern fName pattern:"*.png" do (
                local targetIconPath = userIconsDir + "\\" + (filenameFromPath f)
                if doesFileExist targetIconPath do deleteFile targetIconPath
                copyFile f targetIconPath
            )
        )
        
        if actualScriptSource == "" then (
            messageBox "Installer could not find the Master Toolbar script inside the MZP.\nMake sure you included the file when zipping!" title:"Missing File"
        ) else (
            if doesFileExist targetScript do deleteFile targetScript
            local scriptCopied = copyFile actualScriptSource targetScript
            
            if scriptCopied then (
                fileIn targetScript
                messageBox "SPARKS Tools updated successfully!\n\nYour Master Toolbar has been expanded." title:"Installation Complete"
            ) else (
                messageBox ("Failed to copy from:\n" + actualScriptSource) title:"Error"
            )
        )
    ) catch (
        messageBox ("An unexpected error occurred:\n" + getCurrentException()) title:"Crash Error"
    )
)