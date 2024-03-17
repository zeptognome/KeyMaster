--------------------------------
-- KMComs.lua
-- Handles all in-game communcaitons
-- between clients via addon channel.
--------------------------------
--------------------------------
-- Namespace
--------------------------------
local _, KeyMaster = ...
KeyMaster.Coms = {}

local Coms = KeyMaster.Coms
local UnitData = KeyMaster.UnitData
local PartyFrameMapping = KeyMaster.PartyFrameMapping
local HeaderFrameMapping = KeyMaster.HeaderFrameMapping
local CharacterInfo = KeyMaster.CharacterInfo

-- Dependencies: LibSerialize
-- todo: Verify what ACE libraries are actually needed.
-- -this doesn't currently break but I don't think it has everything
-- -it needs to function as designed. see /libs/
MyAddon = LibStub("AceAddon-3.0"):NewAddon("KeyMaster", "AceComm-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local comPrefix = "KM2"
local comPrefix2 = "KM3"
local comPrefixOpenRaid = "LRS"

-- Notify Successful Registration (DEBUG)
function MyAddon:OnEnable()
    self:RegisterComm(comPrefix)
    self:RegisterComm(comPrefix2)
    self:RegisterComm(comPrefixOpenRaid)
end

-- Serialize communication data:
-- Can communitcate over whatever default channels are avaialable via hidden Addons subchannel.
function MyAddon:Transmit(data)
    local serialized = LibSerialize:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    
    KeyMaster:_DebugMsg("Transmit", "Coms", "transmitting data ...")
    self:SendCommMessage(comPrefix, encoded, "PARTY", nil)
end

-- sends request to party members to transmit their data
function MyAddon:TransmitRequest(requestData)
    if requestData == nil or requestData.requestType == nil then 
        KeyMaster:_DebugMsg("TransmitRequest", "Coms", "Received invalid data request type.")
        return
    end
    local serialized = LibSerialize:Serialize(requestData)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    
    self:SendCommMessage(comPrefix2, encoded, "PARTY", nil)
end



local function checkVersion(data)
    -- VersionCompare returns:
    -- if result is 0 than values are equal
    -- if result is -1 than version1 is older
    -- if result is 1 than version1 is newer
    if data.buildVersion ~= nil then
        local compareValue = KeyMaster:VersionCompare(data.buildVersion, KM_AUTOVERSION)
        if compareValue == 0 then
            --KeyMaster:_DebugMsg("OnCommReceived", "Coms", data.name.."'s version is the same as mine.")
        else
            if data.buildType == KM_VERSION_STATUS then
                if compareValue == 1 then
                    KeyMaster:_DebugMsg("OnCommReceived", "Coms", data.name.."'s version is higher than mine. NEED TO UPDATE")
                    HeaderFrameMapping:NewVersionAlert()
                else
                    --KeyMaster:_DebugMsg("OnCommReceived", "Coms", data.name.."'s version is lower than mine. Ignoring.")
                end
            else
                if compareValue == 1 and data.buildType ~= "beta" then
                    KeyMaster:_DebugMsg("OnCommReceived", "Coms", data.name.."'s version is higher than mine. NEED TO UPDATE")  
                    HeaderFrameMapping:NewVersionAlert()                  
                else
                    --KeyMaster:_DebugMsg("OnCommReceived", "Coms", data.name.."'s version is being ignored.")
                end
            end
        end
    end
end

-- LRS Data
local function processOpenRaidData(payload, sender)
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local dataCompressed = LibDeflate:DecodeForWoWAddonChannel(payload)
    local openRaidData = LibDeflate:DecompressDeflate(dataCompressed)
    local dataTypePrefix = openRaidData:match("^.")
    if dataTypePrefix == "K" then
        --convert to table
        local dataAsTable = {strsplit(",", openRaidData)}

        --remove the first index (prefix)
        tremove(dataAsTable, 1)

        local isDirty = false -- has the data changed?
        local senderData = UnitData:GetUnitDataByName(sender)
        if senderData == nil then
            local partyMembers = {"player", "party1", "party2", "party3", "party4"}
            for _,unitId in pairs(partyMembers) do
                if UnitName(unitId) == sender then
                    senderData = CharacterInfo:GetUnitInfo(unitId)
                    senderData.ownedKeyId = tonumber(dataAsTable[3])
                    senderData.ownedKeyLevel = tonumber(dataAsTable[1])
                    senderData.mythicPlusRating = tonumber(dataAsTable[5])
                    isDirty = true

                    KeyMaster:_DebugMsg("processOpenRaidData", "Coms", "Received data from OpenRaid for "..sender)
                    UnitData:SetUnitData(senderData)
                    break
                end
            end
        else
            -- Only process openRaid data if they also don't have KeyMaster
            if senderData.hasAddon == false then
                senderData.ownedKeyId = tonumber(dataAsTable[3])
                senderData.ownedKeyLevel = tonumber(dataAsTable[1])
                senderData.mythicPlusRating = tonumber(dataAsTable[5])
                isDirty = true

                KeyMaster:_DebugMsg("processOpenRaidData", "Coms", "Received data from OpenRaid for "..sender)
                UnitData:SetUnitData(senderData)
            end
        end
        
        -- Only update UI if party tab is open
        local partyTabContentFrame = _G["KeyMaster_PartyScreen"]
        if isDirty == true and partyTabContentFrame ~= nil and partyTabContentFrame:IsShown() then
            PartyFrameMapping:UpdateSingleUnitData(senderData.GUID)
            PartyFrameMapping:UpdateKeystoneHighlights()
            PartyFrameMapping:CalculateTotalRatingGainPotential() 
        end        
    end
    return
end

-- KM3 Data
local function processKM3Data(payload, distribution, sender)    
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then
        KeyMaster:_DebugMsg("processKM3Data", "Coms", "Failed to deserialize data from "..sender)
        return
    end    
    if (data == nil) then
        KeyMaster:_DebugMsg("processKM3Data", "Coms", "Received nil data from "..sender)
        return
    end

    if data.requestType == "playerData" then
        -- send player data to party members
        local playerData = UnitData:GetUnitDataByUnitId("player")
        MyAddon:Transmit(playerData)
        KeyMaster:_DebugMsg("processKM3Data", "Coms", "Request replied with player data...")
    end   
end

-- KM2 Data
local function processKM2Data(payload, sender)
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)
    if not decoded then return end
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then return end
    local success, data = LibSerialize:Deserialize(decompressed)
    if not success then
        KeyMaster:_DebugMsg("processKM2Data", "Coms", "Failed to deserialize data from "..sender)
        return
    end    
    if (data == nil) then
        KeyMaster:_DebugMsg("processKM2Data", "Coms", "Received nil data from "..sender)
        return
    end

    KeyMaster:_DebugMsg("processKM2Data", "Coms", "Received data from "..sender)
    data.hasAddon = true
    UnitData:SetUnitData(data)

    -- Only update UI if party tab is open
    local partyTabContentFrame = _G["KeyMaster_PartyScreen"]
    if partyTabContentFrame ~= nil and partyTabContentFrame:IsShown() then
        PartyFrameMapping:UpdateSingleUnitData(data.GUID)
        PartyFrameMapping:UpdateKeystoneHighlights()
        PartyFrameMapping:CalculateTotalRatingGainPotential() 
    end

    checkVersion(data)    
end

-- Deserialize communication data:
-- Returns nil if something went wrong.
function MyAddon:OnCommReceived(prefix, payload, distribution, sender)
    if (sender == UnitName("player")) then return end
    
    -- intercept open raid lib keys for client QOL.
    if (prefix == "LRS" and (distribution == "PARTY" or distribution == "INSTANCE_CHAT")) then
        processOpenRaidData(payload, sender)
    end

    if (prefix == "KM2") then
        processKM2Data(payload, sender)
    end

    if (prefix == "KM3") then
        processKM3Data(payload, distribution, sender)
    end
end