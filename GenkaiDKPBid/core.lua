local genkaiDKPBid = LibStub("AceAddon-3.0"):NewAddon("genkaiDKPBid", "AceEvent-3.0", "AceComm-3.0", "AceConsole-3.0")

local AceGUI = LibStub("AceGUI-3.0")

function genkaiDKPBid:OnEnable()
	genkaiDKPBid:RegisterComm("gsdkp","OnCommReceived")
	genkaiDKPBid:RegisterComm("gsdkpitem","OnCommReceived")
	genkaiDKPBid:RegisterComm("gsdkpspec","OnCommReceived")
	print("Initalized Genkai's DKP")
end

local frameShown = false
local MLShown = false
local isMasterLooter = false

bidders = {}
currentHighBid = 0
yourBid = 0
currentBidItem = ""
currentSpec = "MS - "
lastSender = ""
isSameSender = false

genkaiDKPBid:RegisterChatCommand("gdkp","ChatCommand")

local function showFrame()

	if frameShown then
		return
	end
	
	frameShown = true

	frame = AceGUI:Create("Frame")
	frame:SetTitle("Genkai's DKP Loot")
	frame:SetWidth(250)
	frame:SetHeight(150)
	frame:SetStatusText("v1.3.5")
	frame:SetCallback("OnClose", function(widget)
								AceGUI:Release(widget) 
								frameShown = false 
								MLShown = false end)
	frame:SetLayout("List")
	
	yourbidlabel = AceGUI:Create("Label")
	yourbidlabel:SetText("Your Bid: " .. yourBid)
	frame:AddChild(yourbidlabel)
	
	currentbidlabel = AceGUI:Create("Label")
	currentbidlabel:SetText("Current High Bid: " .. currentHighBid)
	frame:AddChild(currentbidlabel)
	
	currentItemlabel = AceGUI:Create("InteractiveLabel")
	currentItemlabel:SetText(currentSpec .. currentBidItem)
	currentItemlabel:SetCallback("OnEnter", function() getItemLinkInfo() end)
	currentItemlabel:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	frame:AddChild(currentItemlabel)
	
	sgroup_1 = AceGUI:Create("SimpleGroup")
	sgroup_1:SetFullWidth(true)
	sgroup_1:SetFullHeight(true)
	sgroup_1:SetLayout("Flow")
	frame:AddChild(sgroup_1)
	
	editbox = AceGUI:Create("EditBox")
	editbox:SetLabel("Bid Amount:")
	editbox:SetWidth(70)
	editbox:DisableButton("True")
	editbox:SetCallback("OnEnterPressed", function(widget, event, text) sendBid(editbox:GetText()) end)
	sgroup_1:AddChild(editbox)
	
	-- button = AceGUI:Create("Button")
	-- button:SetText("Send")
	-- button:SetWidth(70)
	-- button:SetCallback("OnClick", function() sendBid(editbox:GetText()) end)
	-- sgroup_1:AddChild(button)
	
	cmlbutton = AceGUI:Create("Button")
	cmlbutton:SetText("OS")
	cmlbutton:SetWidth(60)
	cmlbutton:SetCallback("OnClick", function() sendOSForItem() end)
	sgroup_1:AddChild(cmlbutton)
	
	passbutton = AceGUI:Create("Button")
	passbutton:SetText("Pass")
	passbutton:SetWidth(70)
	passbutton:SetCallback("OnClick", function() passOnItem() end)
	sgroup_1:AddChild(passbutton)
end

function genkaiDKPBid:ChatCommand()
	showFrame()
	getMasterLooter()
end

function clearMessageTable()
	scrollgroup:ReleaseChildren()
end

function getMasterLooter()
	
	isInRaid = IsInRaid()
	if isInRaid then
		lootmethod, masterlooterPartyID, masterlooterRaidID = GetLootMethod()
		
		indexRaid = UnitInRaid("player")
		if indexRaid == masterlooterRaidID then
			frame:SetWidth(320)
			frame:SetHeight(290)
			showMasterLootSection()
			buildRecievedMessageTable()
		end
	end
end

function showMasterLootSection()

	isMasterLooter = true
	
	if MLShown then
		return
	end
	
	MLShown = true

	sgroup_2 = AceGUI:Create("InlineGroup")
	sgroup_2:SetTitle("Bid Messages:")
	sgroup_2:SetFullWidth(true)
	sgroup_2:SetFullHeight(true)
	sgroup_2:SetHeight(90)
	sgroup_2:SetLayout("Fill")
	frame:AddChild(sgroup_2)
	
	scrollgroup = AceGUI:Create("ScrollFrame")
	scrollgroup:SetLayout("List")
	sgroup_2:AddChild(scrollgroup)
	
	clearbutton = AceGUI:Create("Button")
	clearbutton:SetText("Clear")
	clearbutton:SetWidth(70)
	clearbutton:SetCallback("OnClick", function() clearCurrentLootAuctionMessage() end)
	sgroup_1:AddChild(clearbutton)
	
	sitemgroup_1 = AceGUI:Create("SimpleGroup")
	sitemgroup_1:SetFullWidth(true)
	sitemgroup_1:SetFullHeight(true)
	sitemgroup_1:SetLayout("Flow")
	frame:AddChild(sitemgroup_1)
	
	itemLinkbox = AceGUI:Create("EditBox")
	itemLinkbox:SetWidth(120)
	itemLinkbox:DisableButton("True")
	itemLinkbox:SetCallback("OnEnterPressed", function(widget, event, text) sendItemLinkTolabel(itemLinkbox:GetText())  end)
	sitemgroup_1:AddChild(itemLinkbox)
	
	rwbiditembutton = AceGUI:Create("Button")
	rwbiditembutton:SetText("MS")
	rwbiditembutton:SetWidth(70)
	rwbiditembutton:SetCallback("OnClick", function() sendMSRWMessage() end)
	sitemgroup_1:AddChild(rwbiditembutton)
	
	rwosbidbutton = AceGUI:Create("Button")
	rwosbidbutton:SetText("OS")
	rwosbidbutton:SetWidth(70)
	rwosbidbutton:SetCallback("OnClick", function() sendOSRWMessage() end)
	sitemgroup_1:AddChild(rwosbidbutton)
end

function sendItemLinkTolabel(textInput)
	genkaiDKPBid:SendCommMessage("gsdkpitem", textInput, "RAID")
	itemLinkbox:SetText("")
end

function getItemLinkInfo()
	
	if currentBidItem ~= "" then
		GameTooltip:SetOwner(TargetFrame, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(currentBidItem)
		GameTooltip:Show()
	end
end

function sendMSRWMessage()
	currentSpec = "MS - "
	SendChatMessage("Send in MS Bids Now: " .. currentBidItem, "RAID_WARNING")
	genkaiDKPBid:SendCommMessage("gsdkpspec", currentSpec, "RAID")
end

function sendOSRWMessage()
	currentSpec = "OS - "
	clearBidArray()
	SendChatMessage("Send in OS Bids Now: " .. currentBidItem, "RAID_WARNING")
	genkaiDKPBid:SendCommMessage("gsdkp", "ClearCurrentHighBid", "RAID")
	genkaiDKPBid:SendCommMessage("gsdkpspec", currentSpec, "RAID")
end

function getDKPBid(senderName, messageBid)
	bidders[senderName] = messageBid
	
	buildRecievedMessageTable()
end

function buildRecievedMessageTable()
	
	clearMessageTable()
	
	for i,v in pairs(bidders) do
		sllist = AceGUI:Create("Label")
		sllist:SetText(i .. " - " .. v)
		scrollgroup:AddChild(sllist)
	end
end

function sendBid(bidAmount)
	
	if tonumber(bidAmount) then
		yourBid = bidAmount
		genkaiDKPBid:SendCommMessage("gsdkp", bidAmount, "RAID")
		yourbidlabel:SetText("Your Bid: " .. yourBid)
		editbox:SetText("")
	end
end

function clearBidArray()
	clearMessageTable()
	bidders = {}
end

function genkaiDKPBid:OnCommReceived(prefix, message, distribution, sender)
	
	if prefix == "gsdkp" then
		gsdkpCommRecievedFunctions(message, distribution, sender)
	elseif prefix == "gsdkpitem" then
		gsdkpitemCommRecievedFunctions(message, distribution, sender)
	elseif prefix == "gsdkpspec" then
		gsdkpspecCommRecievedFunctions(message, distribution, sender)
	end
end

function gsdkpCommRecievedFunctions(messageGSDKP, distributionGSDKP, senderGSDKP)
	if isMasterLooter and messageGSDKP ~= "ClearCurrentAuction" and messageGSDKP ~= "ClearCurrentHighBid" then
		getDKPBid(senderGSDKP, messageGSDKP)
	end
	
	if lastSender == senderGSDKP then
		isSameSender = true
	else
		lastSender = senderGSDKP
		isSameSender = false
	end
	
	if tonumber(messageGSDKP) then
		checkHighBid(tonumber(messageGSDKP))
	end
	
	if messageGSDKP == "ClearCurrentAuction" then
		clearCurrentLootAuctionActions()
	end
	
	if messageGSDKP == "ClearCurrentHighBid" then
		currentHighBid = 0
		yourBid = 0
		
		if frameShown then
		setTextCurrentBidLabel()
		yourbidlabel:SetText("Your Bid: " .. yourBid)
		editbox:SetText("")
		end
	end
end

function gsdkpitemCommRecievedFunctions(messageITEM, distributionITEM, senderITEM)
	currentItemlabel:SetText(messageITEM)
	currentBidItem = messageITEM
end

function gsdkpspecCommRecievedFunctions(messageSPEC, distributionSPEC, senderSPEC)
	currentSpec = messageSPEC
	
	if frameShown then
		currentItemlabel:SetText(currentSpec .. currentBidItem)
	end
end

function clearCurrentLootAuctionMessage()
	genkaiDKPBid:SendCommMessage("gsdkp", "ClearCurrentAuction", "RAID")
	
	clearBidArray()
	itemLinkbox:SetText("")
end

function clearCurrentLootAuctionActions()
	currentHighBid = 0
	yourBid = 0
	currentBidItem = ""
	currentSpec = ""
	
	if frameShown then
		setTextCurrentBidLabel()
		yourbidlabel:SetText("Your Bid: " .. yourBid)
		editbox:SetText("")
		currentItemlabel:SetText("")
	end
end

function checkHighBid(incomingBid)
	
	if currentHighBid < incomingBid then
		currentHighBid = incomingBid
		setTextCurrentBidLabel(false)
	elseif currentHighBid == incomingBid then
		setTextCurrentBidLabel(true)
	end
end

function setTextCurrentBidLabel(isTie)
	
	isTie = isTie or false
	
	if frameShown and not isTie then
		currentbidlabel:SetText("Current High Bid: " .. currentHighBid)
	elseif frameShown and isTie and not isSameSender then
		currentbidlabel:SetText("Current High Bid: " .. currentHighBid .. " - multiple ties, bid again")
	end
	
end

function passOnItem()

	genkaiDKPBid:SendCommMessage("gsdkp", "Pass", "RAID")
	yourBid = "Pass"
	yourbidlabel:SetText("Your Bid: " .. yourBid)
	editbox:SetText("")
end

function sendOSForItem()

	genkaiDKPBid:SendCommMessage("gsdkp", "OS", "RAID")
	yourBid = "OS"
	yourbidlabel:SetText("Your Bid: " .. yourBid)
	editbox:SetText("")
end