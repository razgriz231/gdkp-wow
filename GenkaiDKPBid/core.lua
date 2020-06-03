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
currentSpec = ""
lastSender = ""
currentBidTieText = ""

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
	frame:SetStatusText("v1.3.7")
	frame:SetCallback("OnClose", function(widget)
								AceGUI:Release(widget) 
								frameShown = false 
								MLShown = false end)
	frame:SetLayout("List")
	
	yourbidlabel = AceGUI:Create("Label")
	yourbidlabel:SetText("Your Bid: " .. yourBid)
	frame:AddChild(yourbidlabel)
	
	currentbidlabel = AceGUI:Create("Label")
	currentbidlabel:SetText("Current High Bid: " .. currentHighBid .. currentBidTieText)
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
	editbox:SetCallback("OnEnterPressed", function(widget, event, text) sendBid(editbox:GetText()) AceGUI:ClearFocus() end)
	sgroup_1:AddChild(editbox)
	
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
	itemLinkbox:SetLabel("Item to Bid:")
	itemLinkbox:DisableButton("True")
	itemLinkbox:SetCallback("OnEnterPressed", function(widget, event, text) sendItemLinkTolabel(itemLinkbox:GetText()) AceGUI:ClearFocus() end)
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
	if textInput ~= "" then
		genkaiDKPBid:SendCommMessage("gsdkpitem", textInput, "RAID")
		itemLinkbox:SetText("")
	end
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
		gsdkpCommRecievedFunctions(prefix, message, distribution, sender)
	elseif prefix == "gsdkpitem" then
		gsdkpitemCommRecievedFunctions(prefix, message, distribution, sender)
	elseif prefix == "gsdkpspec" then
		gsdkpspecCommRecievedFunctions(prefix, message, distribution, sender)
	end
end

function gsdkpCommRecievedFunctions(prefixGSDKP, messageGSDKP, distributionGSDKP, senderGSDKP)
	
	if tonumber(messageGSDKP) then
		checkHighBid(tonumber(messageGSDKP), senderGSDKP)
	end
	
	if isMasterLooter then
		if prefixGSDKP == "gsdkp" then
			getDKPBid(senderGSDKP, messageGSDKP)
		end
	end
	
	if messageGSDKP == "ClearCurrentAuction" then
		clearCurrentLootAuctionActions()
	end
	
	if messageGSDKP == "ClearCurrentHighBid" then
		currentHighBid = 0
		yourBid = 0
		lastSender = ""
		currentBidTieText = ""
		
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
	lastSender = ""
	currentBidTieText = ""
	
	if frameShown then
		setTextCurrentBidLabel()
		yourbidlabel:SetText("Your Bid: " .. yourBid)
		editbox:SetText("")
		currentItemlabel:SetText("")
	end
end

function checkHighBid(incomingBid, incomingSender)
	
	if currentHighBid < incomingBid then
		currentHighBid = incomingBid
		lastSender = incomingSender
		currentBidTieText = ""
		setTextCurrentBidLabel()
	elseif currentHighBid == incomingBid and lastSender ~= incomingSender then
		currentBidTieText = " - multiple ties, bid again"
		setTextCurrentBidLabel()
	end
end

function setTextCurrentBidLabel()
	
	if frameShown then
		currentbidlabel:SetText("Current High Bid: " .. currentHighBid .. currentBidTieText)
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