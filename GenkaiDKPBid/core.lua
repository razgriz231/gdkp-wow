local genkaiDKPBid = LibStub("AceAddon-3.0"):NewAddon("genkaiDKPBid", "AceEvent-3.0", "AceComm-3.0", "AceConsole-3.0")

local AceGUI = LibStub("AceGUI-3.0")

function genkaiDKPBid:OnEnable()
	genkaiDKPBid:RegisterComm("gsdkp","OnCommReceived")
	print("Initalized Genkai's DKP")
end

local frameShown = false
local MLShown = false
local isMasterLooter = false

bidders = {}
currentHighBid = 0
yourBid = 0

genkaiDKPBid:RegisterChatCommand("gdkp","ChatCommand")

local function showFrame()

	if frameShown then
		return
	end
	
	frameShown = true

	frame = AceGUI:Create("Frame")
	frame:SetTitle("Genkai's DKP Loot")
	frame:SetWidth(320)
	frame:SetHeight(150)
	frame:SetCallback("OnClose", function(widget)
								AceGUI:Release(widget) 
								frameShown = false 
								MLShown = false end)
	frame:SetLayout("List")
	
	sgroup_3 = AceGUI:Create("SimpleGroup")
	sgroup_3:SetFullWidth(true)
	sgroup_3:SetFullHeight(true)
	sgroup_3:SetLayout("Flow")
	frame:AddChild(sgroup_3)
	
	yourbidlabel = AceGUI:Create("Label")
	yourbidlabel:SetText("Your Bid: " .. yourBid)
	sgroup_3:AddChild(yourbidlabel)
	
	currentbidlabel = AceGUI:Create("Label")
	currentbidlabel:SetText("Current High Bid: " .. currentHighBid)
	sgroup_3:AddChild(currentbidlabel)
	
	sgroup_1 = AceGUI:Create("SimpleGroup")
	sgroup_1:SetFullWidth(true)
	sgroup_1:SetFullHeight(true)
	sgroup_1:SetLayout("Flow")
	frame:AddChild(sgroup_1)
	
	editbox = AceGUI:Create("EditBox")
	editbox:SetLabel("Bid Amount:")
	editbox:SetWidth(70)
	editbox:DisableButton("True")
	sgroup_1:AddChild(editbox)
	
	button = AceGUI:Create("Button")
	button:SetText("Send")
	button:SetWidth(70)
	button:SetCallback("OnClick", function() sendBid(editbox:GetText()) end)
	sgroup_1:AddChild(button)
	
	passbutton = AceGUI:Create("Button")
	passbutton:SetText("Pass")
	passbutton:SetWidth(70)
	passbutton:SetCallback("OnClick", function() passOnItem() end)
	sgroup_1:AddChild(passbutton)
	
	cmlbutton = AceGUI:Create("Button")
	cmlbutton:SetText("ML")
	cmlbutton:SetWidth(60)
	cmlbutton:SetCallback("OnClick", function() getMasterLooter() end)
	sgroup_1:AddChild(cmlbutton)
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
			frame:SetWidth(400)
			frame:SetHeight(330)
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
	sgroup_2:SetHeight(170)
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

	yourBid = bidAmount
	
	if tonumber(bidAmount) then
		genkaiDKPBid:SendCommMessage("gsdkp", bidAmount, "RAID")
		
		yourbidlabel:SetText("Your Bid: " .. yourBid)
	end
end

function clearBidArray()
	clearMessageTable()
	bidders = {}
end

function genkaiDKPBid:OnCommReceived(prefix, message, distribution, sender)
	if isMasterLooter and message ~= "ClearCurrentAuction" then
		getDKPBid(sender, message)
	end
	
	if tonumber(message) then
		checkHighBid(tonumber(message))
	end
	
	if message == "ClearCurrentAuction" then
		clearCurrentLootAuctionActions()
	end
end

function clearCurrentLootAuctionMessage()
	genkaiDKPBid:SendCommMessage("gsdkp", "ClearCurrentAuction", "RAID")
	
	clearBidArray()
end

function clearCurrentLootAuctionActions()
	currentHighBid = 0
	yourBid = 0
	
	if frameShown then
		setTextCurrentBidLabel()
		yourbidlabel:SetText("Your Bid: " .. yourBid)
		editbox:SetText("")
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
	elseif frameShown and isTie then
		currentbidlabel:SetText("Current High Bid: " .. currentHighBid .. " - multiple ties, bid again")
	end
	
end

function passOnItem()

	genkaiDKPBid:SendCommMessage("gsdkp", "Pass", "RAID")
	yourbidlabel:SetText("Your Bid: Pass")
	editbox:SetText("")
end