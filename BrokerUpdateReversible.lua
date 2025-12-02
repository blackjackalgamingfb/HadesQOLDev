-- ============================================================
--  Unified MarketScreen.lua with Reversible Trades (Option A)
--  Uses:
--    - Vanilla MarketScreen UI/layout/logic
--    - BrokerUpdate hotkey-swap mechanism
--    - StoreData.BrokerData trade definitions
--    - ResourceData & ConsumableData naming/icons
--  Rules:
--    - Priority trades: repeatable + reversible
--    - Non-priority trades: one-shot + reversible, but only one direction shown at a time
--    - Confirm hotkey toggles Forward/Reverse modes
-- ============================================================

-- Only approved global variable
MarketIsReversed = false

-- ============================================================
-- Utility: Build reversed version of BrokerData entry
-- ============================================================

local function BuildReversedEntry(entry)
    local reversed = {
        BuyName    = entry.CostName,
        BuyAmount  = entry.CostAmount,
        CostName   = entry.BuyName,
        CostAmount = entry.BuyAmount,
        Priority   = entry.Priority,  -- stays the same
        PurchaseSound = entry.PurchaseSound,
        GameStateRequirements = entry.GameStateRequirements,
        IsReversal = true             -- internal marker for handling SoldOut
    }

    -- Naming and icons just like vanilla MarketScreen.lua
    reversed.BuyTitle         = ResourceData[reversed.BuyName].TitleName
    reversed.BuyTitleSingular = ResourceData[reversed.BuyName].TitleName_Singular
        or ResourceData[reversed.BuyName].TitleName
    reversed.BuyIcon          = "{!Icons."..ResourceData[reversed.BuyName].IconString.."}"
    reversed.CostIcon         = "{!Icons."..ResourceData[reversed.CostName].SmallIconString.."}"

    return reversed
end

-- Vanilla forward-entry finalization
local function FinalizeEntry(entry)
    entry.BuyTitle         = ResourceData[entry.BuyName].TitleName
    entry.BuyTitleSingular = ResourceData[entry.BuyName].TitleName_Singular
        or ResourceData[entry.BuyName].TitleName
    entry.BuyIcon          = "{!Icons."..ResourceData[entry.BuyName].IconString.."}"
    entry.CostIcon         = "{!Icons."..ResourceData[entry.CostName].SmallIconString.."}"
    return entry
end

-- ============================================================
-- Modified GenerateMarketItems (Option A reversible logic)
-- ============================================================

function GenerateMarketItems()
    -- Always rebuild items fresh when opening.
    CurrentRun.MarketItems = {}
    CurrentRun.MarketOptions = BrokerScreenData.MaxOptions

    local numRemainingTempOptions = BrokerScreenData.MaxNonPriorityOffers
    local forwardOptions = ShallowCopyTable(BrokerData)

    local priorityOptions = {}
    for _, option in ipairs(forwardOptions) do
        if option.Priority then
            table.insert(priorityOptions, option)
        end
    end
    for _, p in ipairs(priorityOptions) do
        RemoveValue(forwardOptions, p)
    end

    -- Choose which set to use
    local function BuildList(isReverse)
        local results = {}

        -- Priority entries first
        for _, entry in ipairs(priorityOptions) do
            local src = isReverse and BuildReversedEntry(entry) or FinalizeEntry(DeepCopyTable(entry))
            table.insert(results, src)
        end

        -- Then non-priority
        local remaining = numRemainingTempOptions
        while remaining > 0 and not IsEmpty(forwardOptions) do
            local base = RemoveRandomValue(forwardOptions)
            if base and (base.GameStateRequirements == nil
               or IsGameStateEligible(CurrentRun, base, base.GameStateRequirements)) then
                remaining = remaining - 1
                local src = nil
                if isReverse then
                    src = BuildReversedEntry(base)
                else
                    src = FinalizeEntry(DeepCopyTable(base))
                end
                table.insert(results, src)
            end
        end

        return results
    end

    local built = BuildList(MarketIsReversed)
    for i, v in ipairs(built) do
        built[i] = DeepCopyTable(v)
    end

    CurrentRun.MarketItems = built
    return built
end

-- ============================================================
-- Vanilla OpenMarketScreen + hidden Confirm-hotkey swap button
-- ============================================================

function OpenMarketScreen()

    local screen = { Components = {} }
    screen.Name = "Market"
    screen.NumSales = 0
    screen.NumItemsOffered = 0

    if IsScreenOpen(screen.Name) then
        return
    end

    OnScreenOpened({ Flag = screen.Name, PersistCombatUI = true })
    FreezePlayerUnit()
    EnableShopGamepadCursor()
    PlaySound({ Name = "/SFX/Menu Sounds/DialoguePanelIn" })

    local components = screen.Components

    components.ShopBackgroundDim = CreateScreenComponent({ Name = "rectangle01", Group = "Combat_Menu" })
    components.ShopBackground = CreateScreenComponent({ Name = "ShopBackground", Group = "Combat_Menu" })
    components.CloseButton = CreateScreenComponent({ Name = "ButtonClose", Group = "Combat_Menu", Scale = 0.7 })
    Attach({ Id = components.CloseButton.Id, DestinationId = components.ShopBackground.Id, OffsetX = 0, OffsetY = 440 })
    components.CloseButton.OnPressedFunctionName = "CloseMarketScreen"

    CreateTextBox({
        Id = components.ShopBackground.Id,
        Text = "MarketScreen_FlavorText",
        FontSize = 26,
        OffsetX = 0,
        OffsetY = -430,
        Color = Color.ShopFlavor,
        Width = 990,
        Font = "P22UndergroundSCMedium",
        Justification = "Center"
    })

    CreateTextBox({
        Id = components.ShopBackground.Id,
        Text = "MarketScreen_HintText",
        FontSize = 22,
        OffsetX = 0,
        OffsetY = 470,
        Width = 990,
        Color = Color.White,
        Font = "AlegreyaSansSCRegular",
        Justification = "Center"
    })

    -- ============================================================
    -- MOD: Hidden Confirm-hotkey button (BrokerUpdate style)
    -- ============================================================
    components.SwapButton = CreateScreenComponent({ Name = "BlankObstacle", Group = "Combat_Menu" })
    Attach({ Id = components.SwapButton.Id, DestinationId = components.ShopBackground.Id })
    components.SwapButton.ControlHotkey = "Confirm"
    components.SwapButton.OnPressedFunctionName = "SwapMarketMode"

    -- ============================================================
    -- Build the offer buttons (vanilla logic)
    -- ============================================================

    local itemLocationX = ScreenCenterX - 330
    local itemLocationY = ScreenCenterY - 100
    local itemLocationXSpacer = 600
    local itemLocationYSpacer = 190
    local itemLocationMaxX = 2400
    local itemLocationTextBoxOffset = -15

    for itemIndex, item in ipairs(CurrentRun.MarketItems) do
        if not item.SoldOut then
            screen.NumItemsOffered = screen.NumItemsOffered + 1

            local purchaseButtonKey = "PurchaseButton"..itemIndex
            components[purchaseButtonKey] = CreateScreenComponent({
                Name = "MarketSlot", Group = "Combat_Menu", Scale = 1,
                X = itemLocationX, Y = itemLocationY
            })

            local iconKey = "Icon"..itemIndex
            components[iconKey] = CreateScreenComponent({
                Name = "BlankObstacle", Group = "Combat_Menu",
                X = itemLocationX - 360, Y = itemLocationY
            })

            local backingKey = "Backing"..itemIndex
            components[backingKey] = CreateScreenComponent({
                Name = "BlankObstacle", Group = "Combat_Menu",
                X = itemLocationX + itemLocationTextBoxOffset, Y = itemLocationY
            })

            local titleKey = "PurchaseButtonTitle"..itemIndex
            components[titleKey] = CreateScreenComponent({
                Name = "BlankObstacle", Group = "Combat_Menu",
                Scale = 1,
                X = itemLocationX, Y = itemLocationY
            })

            components[purchaseButtonKey].OnPressedFunctionName = "HandleMarketPurchase"
            components[purchaseButtonKey].Data = item
            components[purchaseButtonKey].Index = itemIndex
            components[purchaseButtonKey].TitleId = components[titleKey].Id

            CreateTextBoxWithFormat({
                Id = components[titleKey].Id,
                Text = "MarketScreen_SellFormat",
                FontSize = 30,
                Color = Color.White,
                LuaKey = "TempTextData",
                LuaValue = item,
                Font = "AlegreyaSansSCRegular",
                Justification = "Left",
                OffsetX = 0,
                OffsetY = -35,
                Width = 840,
            })

            itemLocationX = itemLocationX + itemLocationXSpacer
            if itemLocationX >= itemLocationMaxX then
                itemLocationX = ScreenCenterX - 330
                itemLocationY = itemLocationY + itemLocationYSpacer
            end
        end
    end

    HandleScreenInput(screen)
    return screen
end

-- ============================================================
-- Handle purchase (vanilla + reversible one-shot logic)
-- ============================================================

function HandleMarketPurchase(screen, button)
    local item = button.Data
    local idx = button.Index

    if not HasResource(item.CostName, item.CostAmount) then
        Flash({ Id = button.Id, Speed = 2, MinFraction = 0, MaxFraction = 1, Color = Color.Red, Duration = 0.3 })
        PlaySound({ Name = "/SFX/Menu Sounds/GeneralItemPurchaseDenied" })
        return
    end

    -- Spend + reward
    SpendResource(item.CostName, item.CostAmount, "Market", { SkipOverheadText = true, ApplyMultiplier = false })
    wait(0.3)
    AddResource(item.BuyName, item.BuyAmount, "Market", { SkipOverheadText = true, ApplyMultiplier = false })

    -- Voice lines (vanilla)
    if CoinFlip() then
        thread( PlayVoiceLines, ResourceData[item.CostName].BrokerSpentVoiceLines, true )
    else
        thread( PlayVoiceLines, ResourceData[item.BuyName].BrokerPurchaseVoiceLines, true )
    end

    -- One-shot logic:
    if not item.Priority then
        -- destroy all UI for this offer exactly like vanilla
        item.SoldOut = true

        local components = screen.Components
        local titleKey = "PurchaseButtonTitle"..idx
        local iconKey  = "Icon"..idx
        local backKey  = "Backing"..idx
        local sellText = titleKey.."SellText"
        local purchaseButton = "PurchaseButton"..idx

        Destroy({
            Ids = {
                components[titleKey].Id,
                components[sellText] and components[sellText].Id or nil,
                components[titleKey.."Icon"] and components[titleKey.."Icon"].Id or nil,
                components[backKey].Id,
                components[iconKey].Id
            }
        })

        components[titleKey] = nil
        components[sellText] = nil
        components[backKey] = nil
        components[iconKey] = nil

        SetAlpha({ Id = components[purchaseButton].Id, Fraction = 0, Duration = 0.2 })
        wait(0.2)
        Destroy({ Id = components[purchaseButton].Id })
        components[purchaseButton] = nil
    end

    -- Update affordability colors
    for itemIndex, check in ipairs(CurrentRun.MarketItems) do
        if not check.SoldOut then
            local col = HasResource(check.CostName, check.CostAmount)
                and Color.TradeAffordable or Color.TradeUnaffordable
            ModifyTextBox({
                Id = screen.Components["PurchaseButtonTitle"..itemIndex.."SellText"].Id,
                ColorTarget = col,
                ColorDuration = 0.1
            })
        end
    end
end

-- ============================================================
-- CloseMarketScreen (vanilla)
-- ============================================================

function CloseMarketScreen(screen, button)
    DisableShopGamepadCursor()
    CloseScreen(GetAllIds(screen.Components))
    PlaySound({ Name = "/SFX/Menu Sounds/GeneralWhooshMENU" })
    UnfreezePlayerUnit()
    screen.KeepOpen = false
    OnScreenClosed({ Flag = screen.Name })
end

-- ============================================================
-- SwapMarketMode (BrokerUpdate-style screen rebuild)
-- ============================================================

function SwapMarketMode(screen, button)
    MarketIsReversed = not MarketIsReversed
    CloseMarketScreen(screen, button)
    GenerateMarketItems()
    OpenMarketScreen()
end