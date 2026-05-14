---------------------------------------------------------
-- 1. TOOL 1: RESOURCE COLLECTOR LOGIC
---------------------------------------------------------
try(destroyDialog ::UltimateResCollector)catch()
rollout UltimateResCollector "SPARKS Resource Collector" width:380 height:225
(
	groupBox grp_dest "1. Destination Folder" pos:[10,10] width:360 height:60
	label lbl_path "No folder selected..." pos:[20,30] width:260 height:30
	button btn_browse "Browse..." pos:[290,25] width:70 height:25
	
	groupBox grp_options "2. Options" pos:[10,80] width:360 height:50
	checkbox chk_update "Update scene materials/proxies to new destination" pos:[20,100] checked:true
	
	button btn_collect "BEGIN COLLECTING" pos:[10,140] width:360 height:35
	progressBar pb_progress pos:[10,185] width:360 height:12 color:green value:0
	
	label lbl_credit "Created by SPARKS" pos:[260,205] width:110 height:15
	local destFolder = ""
	
	on btn_browse pressed do
	(
		local f = getSavePath caption:"Select Destination Folder for Assets"
		if f != undefined do ( destFolder = f; lbl_path.text = destFolder )
	)
	
	on btn_collect pressed do
	(
		if destFolder == "" do ( messageBox "Please select a destination folder first!" title:"Missing Folder"; return() )
		
		ATSOps.Silent = true
		ATSOps.Refresh()
		
		local allFiles = #()
		ATSOps.GetFiles &allFiles
		
		local currentMaxFile = pathConfig.appendPath maxFilePath maxFileName
		local assetsToProcess = #()
		
		for f in allFiles do (
			if (f != undefined) and (f != "") and (stricmp f currentMaxFile != 0) do ( appendIfUnique assetsToProcess f )
		)
		
		local totalAssets = assetsToProcess.count
		if totalAssets == 0 do ( messageBox "No external assets found in this scene to collect." title:"Notice"; return() )
		
		pb_progress.value = 0
		local successCount = 0
		
		for i = 1 to totalAssets do (
			local sourceFile = assetsToProcess[i]
			local fileName = filenameFromPath sourceFile
			local targetFile = pathConfig.appendPath destFolder fileName
			
			if doesFileExist sourceFile do (
				if (stricmp sourceFile targetFile != 0) do ( copyFile sourceFile targetFile )
			)
			successCount += 1
			pb_progress.value = (successCount as float / totalAssets) * 50
		)
		
		if chk_update.checked do (
			ATSOps.ClearSelection()
			ATSOps.SelectFiles &assetsToProcess
			ATSOps.SetPathOnSelection destFolder
			ATSOps.Refresh()
		)
		
		pb_progress.value = 100
		local msg = "Collection Complete!\nProcessed " + totalAssets as string + " assets."
		if chk_update.checked do msg += "\nScene paths have been updated."
		messageBox msg title:"Success"
		pb_progress.value = 0
	)
)

---------------------------------------------------------
-- 2. TOOL 2: PIVOT TO BOTTOM LOGIC
---------------------------------------------------------
try(destroyDialog ::PivotTool)catch()
rollout PivotTool "Pivot to Bottom" width:160 height:50
(
    button btn_bottom "Bottom Center" width:140 height:30 pos:[10,10] toolTip:"Align pivot to bottom center"
    
    on btn_bottom pressed do
    (
        if selection.count > 0 then
        (
			undo "Pivot to Bottom" on 
			(
            	for obj in selection do obj.pivot = [obj.center.x, obj.center.y, obj.min.z]
			)
        )
        else
        (
            messageBox "Please select at least one object." title:"No Selection"
        )
    )
)

---------------------------------------------------------
-- 3. TOOL 3: TV GENERATOR PLUGIN
---------------------------------------------------------
plugin simpleObject SPARKS_TV_Generator
name:"SPARKS TV Generator"
category:"My Custom Tools"
classID:#(0x7c421b82, 0x5d9e1fd2) 
(
    parameters main rollout:params
    (
        diagonal type:#float ui:spn_diagonal default:55.0
        aspectW type:#integer ui:spn_aspectW default:16
        aspectH type:#integer ui:spn_aspectH default:9
        bezel type:#float ui:spn_bezel default:0.5
        thickness type:#float ui:spn_thickness default:2.0
        frameID type:#integer ui:spn_frameID default:1
        screenID type:#integer ui:spn_screenID default:2
    )

    rollout params "TV Parameters"
    (
        group "Screen Dimensions" (
            spinner spn_diagonal "Diag:" range:[1, 1000, 55] type:#float fieldwidth:45
            spinner spn_aspectW "Width R:" range:[1, 100, 16] type:#integer fieldwidth:45
            spinner spn_aspectH "Height R:" range:[1, 100, 9] type:#integer fieldwidth:45
        )
        group "Frame Settings" (
            spinner spn_bezel "Bezel:" range:[0, 20, 0.5] type:#float fieldwidth:45
            spinner spn_thickness "Depth:" range:[0.1, 100, 2.0] type:#float fieldwidth:45
        )
        group "Material IDs" (
            spinner spn_frameID "Frame ID:" range:[1, 100, 1] type:#integer fieldwidth:35 across:2
            spinner spn_screenID "Screen ID:" range:[1, 100, 2] type:#integer fieldwidth:35
        )
        
        button btn_applyMat "Re-Apply Colors" width:150 height:30 align:#center offset:[0,5]
        label lbl_credit "Created by: SPARKS" align:#center offset:[0,5]
        
        on btn_applyMat pressed do (
            local myNode = refs.dependentnodes this firstOnly:on
            if myNode != undefined do (
                local m = MultiMaterial numsubs:2 name:"TV_Base_Colors"
                m[1] = StandardMaterial diffuse:(color 40 40 40) name:"Frame_Color"
                m[2] = StandardMaterial diffuse:(color 150 200 255) name:"Screen_Color"
                myNode.material = m
            )
        )
    )

    on attachedToNode myNode do
    (
        local m = MultiMaterial numsubs:2 name:"TV_Base_Colors"
        m[1] = StandardMaterial diffuse:(color 40 40 40) name:"Frame_Color"
        m[2] = StandardMaterial diffuse:(color 150 200 255) name:"Screen_Color"
        myNode.material = m
    )

    on buildMesh do
    (
        local valRatio = (aspectW as float) / (aspectH as float)
        local valH = diagonal / sqrt(pow valRatio 2 + 1)
        local valW = valH * valRatio
        local valFW = valW + (bezel * 2.0)
        local valFH = valH + (bezel * 2.0)
        local valHalfW = valFW / 2.0
        local valD = thickness
        
        setNumVerts mesh 12
        setNumFaces mesh 14
        
        setVert mesh 1 [-valHalfW, 0, 0]
        setVert mesh 2 [valHalfW, 0, 0]
        setVert mesh 3 [valHalfW, 0, valFH]
        setVert mesh 4 [-valHalfW, 0, valFH]
        
        setVert mesh 5 [-valHalfW, -valD, 0]
        setVert mesh 6 [valHalfW, -valD, 0]
        setVert mesh 7 [valHalfW, -valD, valFH]
        setVert mesh 8 [-valHalfW, -valD, valFH]
        
        local valSHalfW = valW / 2.0
        local valSBot = bezel
        local valSTop = valFH - bezel
        setVert mesh 9  [-valSHalfW, -valD-0.05, valSBot]
        setVert mesh 10 [valSHalfW, -valD-0.05, valSBot]
        setVert mesh 11 [valSHalfW, -valD-0.05, valSTop]
        setVert mesh 12 [-valSHalfW, -valD-0.05, valSTop]

        setFace mesh 1 [1,3,2]
        setFaceMatID mesh 1 frameID
        setFace mesh 2 [1,4,3]
        setFaceMatID mesh 2 frameID
        setFace mesh 3 [5,6,7]
        setFaceMatID mesh 3 frameID
        setFace mesh 4 [5,7,8]
        setFaceMatID mesh 4 frameID
        setFace mesh 5 [1,2,6]
        setFaceMatID mesh 5 frameID
        setFace mesh 6 [1,6,5]
        setFaceMatID mesh 6 frameID
        setFace mesh 7 [2,3,7]
        setFaceMatID mesh 7 frameID
        setFace mesh 8 [2,6,7]
        setFaceMatID mesh 8 frameID
        setFace mesh 9 [3,4,8]
        setFaceMatID mesh 9 frameID
        setFace mesh 10 [3,8,7]
        setFaceMatID mesh 10 frameID
        setFace mesh 11 [4,1,5]
        setFaceMatID mesh 11 frameID
        setFace mesh 12 [4,5,8]
        setFaceMatID mesh 12 frameID
        setFace mesh 13 [9,10,11]
        setFaceMatID mesh 13 screenID
        setFace mesh 14 [9,11,12]
        setFaceMatID mesh 14 screenID
        
        for i = 1 to 14 do (
            setEdgeVis mesh i 1 true
            setEdgeVis mesh i 2 true
            setEdgeVis mesh i 3 true
            setFaceSmoothGroup mesh i 0
        )
    )

    tool create
    (
        on mousePoint click do
        (
            if click == 1 do nodeTM.translation = gridPoint
            if click == 2 do #stop
        )
    )
)

---------------------------------------------------------
-- 4. THE MASTER TOOLBAR
---------------------------------------------------------
try(cui.UnRegisterDialogBar SPARKSMasterToolbar; destroyDialog SPARKSMasterToolbar)catch()

-- Width expanded to 112 to fit three 32px buttons side-by-side
rollout SPARKSMasterToolbar "SPARKS Tools" width:112 height:40 
(
    -- BUTTON 1: Resource Collector
    button btn_rescol "" width:32 height:32 pos:[4,4] toolTip:"SPARKS Resource Collector" \
    images:#((getDir #usericons + "\\sparks_rescol_icon.png"), undefined, 1, 1, 1, 1, 1)

    -- BUTTON 2: Pivot Tool
    button btn_pivot "" width:32 height:32 pos:[40,4] toolTip:"Pivot to Bottom" \
    images:#((getDir #usericons + "\\sparks_pivot_icon.png"), undefined, 1, 1, 1, 1, 1)

    -- BUTTON 3: TV Generator
    button btn_tv "" width:32 height:32 pos:[76,4] toolTip:"SPARKS TV Generator" \
    images:#((getDir #usericons + "\\sparks_tv_icon.png"), undefined, 1, 1, 1, 1, 1)

    on btn_rescol pressed do
    (
        try(destroyDialog ::UltimateResCollector)catch()
        createDialog UltimateResCollector
    )

    on btn_pivot pressed do
    (
        try(destroyDialog ::PivotTool)catch()
        createDialog PivotTool
    )
    
    on btn_tv pressed do
    (
        -- This command triggers the plugin creation mode instantly!
        StartObjectCreation SPARKS_TV_Generator
    )
)

createDialog SPARKSMasterToolbar
cui.RegisterDialogBar SPARKSMasterToolbar style:#(#cui_dock_top, #cui_dock_bottom, #cui_floatable, #cui_handles)
cui.DockDialogBar SPARKSMasterToolbar #cui_dock_top