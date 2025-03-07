local ADDON_NAME, T = ...
local L = T.L
local EDDM = LibStub("ElioteDropDownMenu-1.0")
local dropdownFrame = EDDM.UIDropDownMenu_GetOrCreate("SimpleAddonManager_MenuFrame")

--- @type SimpleAddonManager
local frame = T.AddonFrame

ButtonFrameTemplate_HidePortrait(frame)

local function CharacterDropDown_Initialize()
	local selectedValue = frame:GetCharacter() == true
	local info = {
		text = ALL,
		value = true,
		func = function(self)
			local value = self.value
			frame:SetCharacter(value)
			EDDM.UIDropDownMenu_SetSelectedValue(frame.CharacterDropDown, value)
			frame.ScrollFrame.update()
		end,
		checked = selectedValue
	};
	EDDM.UIDropDownMenu_AddButton(info);

	info.text = UnitName("player")
	info.value = UnitName("player")
	info.checked = not selectedValue
	EDDM.UIDropDownMenu_AddButton(info);
end

local function SaveCurrentAddonsToSet(setName)
	local db = frame:GetDb()
	local enabledAddons = {}
	local count = GetNumAddOns()
	for i = 1, count do
		if frame:IsAddonSelected(i) then
			local name = GetAddOnInfo(i)
			table.insert(enabledAddons, name)
		end
	end
	db.sets[setName] = db.sets[setName] or {}
	db.sets[setName].addons = enabledAddons
end

local function ProfilesDropDownCreate()
	local menu = {
		{ text = L["Profiles"], isTitle = true, notCheckable = true },
	}
	local db = frame:GetDb()

	for profileName, set in pairs(db.sets) do
		local setMenu = {
			text = profileName,
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{ text = profileName, isTitle = true, notCheckable = true },
				{ text = #set.addons .. " AddOns", notCheckable = true },
				T.separatorInfo,
				{
					text = L["Save"],
					notCheckable = true,
					func = function()
						frame:ShowConfirmDialog(
								L("Save current addons in profile '${profile}'?", { profile = profileName }),
								function()
									SaveCurrentAddonsToSet(profileName)
								end
						)
					end
				},
				{
					text = L["Load"],
					notCheckable = true,
					func = function()
						frame:ShowConfirmDialog(
								L("Load the profile '${profile}'?", { profile = profileName }),
								function()
									local enabledAddons = db.sets[profileName].addons
									local character = frame:GetCharacter()
									DisableAllAddOns(character)
									for _, name in ipairs(enabledAddons) do
										EnableAddOn(name, character)
									end
									frame:Update()
								end
						)
					end
				},
				{
					text = L["Rename"],
					notCheckable = true,
					func = function()
						frame:ShowInputDialog(
								L("Enter the new name for the profile '${profile}'", { profile = profileName }),
								function(text)
									db.sets[text] = db.sets[profileName]
									db.sets[profileName] = nil
								end
						)
					end
				},
				{
					text = L["Delete"],
					notCheckable = true,
					func = function()
						frame:ShowConfirmDialog(
								L("Delete the profile '${profile}'?", { profile = profileName }),
								function()
									db.sets[profileName] = nil
								end
						)
					end
				},
			}
		}
		table.insert(menu, setMenu)
	end

	table.insert(menu, T.separatorInfo)
	table.insert(menu, {
		text = L["Create new profile"],
		func = function()
			frame:ShowInputDialog(
					L["Enter the name for the new profile"],
					function(text)
						SaveCurrentAddonsToSet(text)
					end
			)
		end,
		notCheckable = true
	})
	table.insert(menu, T.separatorInfo)
	table.insert(menu, T.closeMenuInfo)

	return menu
end

local function SearchResultDropDownCreate()
	local userCategories, tocCategories = frame:GetCategoryTables()
	local sortedCategories = frame:TableKeysToSortedList(userCategories, tocCategories)
	local addons = frame:GetAddonsList()
	local function categoriesMenu(add)
		local menu = {}
		for _, categoryName in ipairs(sortedCategories) do
			table.insert(menu, {
				text = categoryName,
				notCheckable = true,
				func = function()
					for _, addon in ipairs(addons) do
						local name = GetAddOnInfo(addon.index)
						if (not add and (not userCategories[categoryName] or not userCategories[categoryName].addons)) then
							-- there is nothing to remove, avoid creating custom category
							return
						end
						userCategories[categoryName] = userCategories[categoryName] or { name = categoryName }
						userCategories[categoryName].addons = userCategories[categoryName].addons or {}
						userCategories[categoryName].addons[name] = add
						EDDM.CloseDropDownMenus()
					end

					frame:Update()
				end,
			})
		end
		return menu
	end

	local menu = {
		{ text = L("Results: ${results}", { results = #addons }), isTitle = true, notCheckable = true },
		{
			text = L["Add search results to category"],
			notCheckable = true,
			hasArrow = true,
			menuList = categoriesMenu(true)
		},
		{
			text = L["Remove search results from category"],
			notCheckable = true,
			hasArrow = true,
			menuList = categoriesMenu(nil)
		}
	}

	table.insert(menu, T.separatorInfo)
	table.insert(menu, T.closeMenuInfo)

	return menu
end

local function ConfigDropDownCreate()
	local db = frame:GetDb()
	return {
		{ text = L["Options"], isTitle = true, notCheckable = true },
		T.separatorInfo,
		{
			text = ADDON_FORCE_LOAD,
			checked = function()
				return not IsAddonVersionCheckEnabled()
			end,
			func = function(_, _, _, checked)
				SetAddonVersionCheck(checked)
				frame:Update()
			end,
		},
		{
			text = L["Replace original Addon wow menu button"],
			checked = function()
				return db.config.hookMenuButton
			end,
			func = function()
				db.config.hookMenuButton = not db.config.hookMenuButton
				if (db.config.hookMenuButton) then
					frame:HookMenuButton()
				end
			end,
		},
		{
			text = L["Show minimap button"],
			checked = function()
				return not db.config.minimap.hide
			end,
			func = function()
				frame:GetModule("Minimap"):ToggleMinimapButton()
			end,
		},
		{
			text = L["Autofocus searchbar when opening the UI"],
			checked = function()
				return db.config.autofocusSearch
			end,
			func = function()
				db.config.autofocusSearch = not db.config.autofocusSearch
			end,
		},
		{
			text = L["Show versions in AddOns list"],
			checked = function()
				return db.config.showVersions
			end,
			func = function()
				db.config.showVersions = not db.config.showVersions
				frame:Update()
			end,
		},
		T.separatorInfo,
		{ text = L["Category Options"], isTitle = true, notCheckable = true },
		{
			text = L["Hide autogenerated categories"],
			checked = function()
				return db.config.hideTocCategories
			end,
			func = function()
				db.config.hideTocCategories = not db.config.hideTocCategories
				frame:Update()
			end,
		},
		{
			text = L["Localize autogenerated categories name"],
			checked = function()
				return db.config.localizeCategoryName
			end,
			func = function()
				db.config.localizeCategoryName = not db.config.localizeCategoryName
				frame:Update()
			end,
		},
		T.separatorInfo,
		{
			text = L["Search By"],
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{
					text = L["Internal name"],
					checked = function()
						return db.config.searchBy.name
					end,
					func = function()
						db.config.searchBy.name = not db.config.searchBy.name
						frame:Update()
					end,
				},
				{
					text = L["Title"],
					checked = function()
						return db.config.searchBy.title
					end,
					func = function()
						db.config.searchBy.title = not db.config.searchBy.title
						frame:Update()
					end,
				},
				{
					text = L["Author"],
					checked = function()
						return db.config.searchBy.author
					end,
					func = function()
						db.config.searchBy.author = not db.config.searchBy.author
						frame:Update()
					end,
				},
			},
		},
		{
			text = L["Sort by"],
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{
					text = L["Name (improved)"],
					checked = function()
						return db.config.sorting == "smart"
					end,
					func = function()
						db.config.sorting = "smart"
						frame:Update()
					end,
				},
				{
					text = L["Internal name"],
					checked = function()
						return db.config.sorting == "name"
					end,
					func = function()
						db.config.sorting = "name"
						frame:Update()
					end,
				},
				{
					text = L["Title"],
					checked = function()
						return db.config.sorting == "title"
					end,
					func = function()
						db.config.sorting = "title"
						frame:Update()
					end,
				},
				{
					text = L["None"],
					checked = function()
						return db.config.sorting == nil
					end,
					func = function()
						db.config.sorting = false
						frame:Update()
					end,
				},
			},
		},
		T.separatorInfo,
		T.closeMenuInfo
	}
end

function frame:SetCategoryVisibility(show, resize)
	local fw = frame:GetWidth()
	if (show) then
		SquareButton_SetIcon(frame.CategoryButton, "LEFT")
		frame.ScrollFrame:SetPoint("BOTTOMRIGHT", (-30 - frame.CATEGORY_SIZE_W), 30)
		if (resize) then
			frame:SetWidth(math.max(frame.MIN_SIZE_W, fw + frame.CATEGORY_SIZE_W))
		end
		frame.CategoryButton:SetPoint("TOPRIGHT", (-7 - frame.CATEGORY_SIZE_W), -27)
		frame:SetMinResize(frame.MIN_SIZE_W + frame.CATEGORY_SIZE_W, frame.MIN_SIZE_H)
		frame.CategoryFrame:Show()
	else
		SquareButton_SetIcon(frame.CategoryButton, "RIGHT")
		frame.ScrollFrame:SetPoint("BOTTOMRIGHT", -30, 30)
		if (resize) then
			frame:SetWidth(math.max(frame.MIN_SIZE_W, fw - frame.CATEGORY_SIZE_W))
		end
		frame.CategoryButton:SetPoint("TOPRIGHT", -7, -27)
		frame:SetMinResize(frame.MIN_SIZE_W, frame.MIN_SIZE_H)
		frame.CategoryFrame:Hide()
	end
	frame.ScrollFrame.update()
	frame.CategoryFrame.ScrollFrame.update()
end

local function AddonsInCategoriesFunc(categories)
	if categories == nil or next(categories) == nil then
		return function()
			return true
		end
	end
	local m = {}
	local fixedCategories = {}
	for categoryName, _ in pairs(categories) do
		local userTable, tocTable, fixedTable = frame:GetCategoryTable(categoryName)
		if (userTable) then
			for name, _ in pairs(userTable.addons) do
				m[name] = true
			end
		end
		if (tocTable) then
			for name, _ in pairs(tocTable.addons) do
				m[name] = true
			end
		end
		if (fixedTable) then
			fixedCategories[categoryName] = fixedTable.addons
		end
	end

	return function(name)
		if (m[name]) then
			return true
		end
		for _, func in pairs(fixedCategories) do
			if (func(name)) then
				return true
			end
		end
	end
end

local addons = {}

local function SortAddons()
	local db = frame:GetDb()
	if (not db.config.sorting) then
		return
	end

	if (db.config.sorting == "name") then
		table.sort(addons, function(a, b)
			return a.name < b.name
		end)
	elseif (db.config.sorting == "title") then
		table.sort(addons, function(a, b)
			return a.title < b.title
		end)
	elseif (db.config.sorting == "smart") then
		table.sort(addons, function(a, b)
			return a.smartName < b.smartName
		end)
	end
end

local function FilterAddon(addonIndex, filterLower, inCategoriesFunc)
	local name, title = GetAddOnInfo(addonIndex)
	if (not inCategoriesFunc(name)) then
		return false
	end

	local searchBy = frame:GetDb().config.searchBy
	if (searchBy.name and name:lower():find(filterLower, 0, true)) then
		return true
	end
	if (searchBy.title and title:lower():find(filterLower, 0, true)) then
		return true
	end
	if (searchBy.author) then
		local author = GetAddOnMetadata(addonIndex, "Author")
		if (author and author:lower():find(filterLower, 0, true)) then
			return true
		end
	end
end

local function CreateList(filter, categories)
	addons = {}
	local inCategoriesFunc = AddonsInCategoriesFunc(categories)
	local count = GetNumAddOns()
	local filterLower = filter:lower()
	for addonIndex = 1, count do
		if (FilterAddon(addonIndex, filterLower, inCategoriesFunc)) then
			local name, title = GetAddOnInfo(addonIndex)
			table.insert(addons, {
				index = addonIndex,
				name = name:lower(),
				smartName = name:gsub(".-([%w].*)", "%1"):gsub("[_-]", " "):lower(),
				title = (title or name):lower()
			})
		end
	end
	SortAddons()
end

function frame:GetAddonsList()
	return addons
end

function frame:DidAddonStateChanged(addonNameOrIndex)
	local initiallyEnabledAddons = frame:GetAddonsInitialState()
	local state = frame:IsAddonSelected(addonNameOrIndex)
	local name = GetAddOnInfo(addonNameOrIndex)
	local initialState = initiallyEnabledAddons[name]
	if (state ~= initialState) then
		return true
	end
end

function frame:DidAnyAddonStateChanged()
	for addonIndex = 1, GetNumAddOns() do
		if (frame:DidAddonStateChanged(addonIndex)) then
			return true
		end
	end
end

function frame:UpdateOkButton()
	if (frame:DidAnyAddonStateChanged()) then
		frame.edited = true
		frame.OkButton:SetText(L["Reload UI"])
	else
		frame.edited = false
		frame.OkButton:SetText(OKAY)
	end
end

function frame:UpdateListFilters()
	CreateList(frame.SearchBox:GetText(), frame:SelectedCategories())
	frame.ScrollFrame.update()
end

function frame:CreateMainFrame()
	local addonName = GetAddOnMetadata(ADDON_NAME, "Title")
	if (frame.TitleText) then
		frame.TitleText:SetText(addonName)
	elseif (frame.TitleContainer and frame.TitleContainer.TitleText) then
		frame.TitleContainer.TitleText:SetText(addonName)
	end

	frame.Sizer = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
	frame.Sizer:SetScript("OnMouseDown", function()
		frame:StartSizing("BOTTOMRIGHT", true)
	end)
	frame.Sizer:SetScript("OnMouseUp", function()
		frame:StopMovingOrSizing()
	end)
	frame.Sizer:SetPoint("BOTTOMRIGHT", -4, 4)

	frame.CharacterDropDown = CreateFrame("Frame", nil, frame, "UIDropDownMenuTemplate")
	frame.CharacterDropDown:SetPoint("TOPLEFT", 0, -30)
	frame.CharacterDropDown.Button:SetScript("OnMouseDown", function(self)
		if self:IsEnabled() then
			EDDM.ToggleDropDownMenu(nil, nil, self:GetParent());
			PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
		end
	end)
	EDDM.UIDropDownMenu_Initialize(frame.CharacterDropDown, CharacterDropDown_Initialize)
	EDDM.UIDropDownMenu_SetSelectedValue(frame.CharacterDropDown, true)

	frame.CancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.CancelButton:SetPoint("BOTTOMRIGHT", -24, 4)
	frame.CancelButton:SetSize(100, 22)
	frame.CancelButton:SetText(CANCEL)
	frame.CancelButton:SetScript("OnClick", function()
		ResetAddOns()
		frame.ScrollFrame.update()
		frame:Hide()
	end)

	frame.OkButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.OkButton:SetPoint("TOPRIGHT", frame.CancelButton, "TOPLEFT", 0, 0)
	frame.OkButton:SetSize(100, 22)
	frame.OkButton:SetText(OKAY)
	frame.OkButton:SetScript("OnClick", function()
		SaveAddOns()
		frame.ScrollFrame.update()
		frame:Hide()
		if (frame.edited) then
			ReloadUI()
		end
	end)

	frame.EnableAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.EnableAllButton:SetPoint("BOTTOMLEFT", 4, 4)
	frame.EnableAllButton:SetSize(120, 22)
	frame.EnableAllButton:SetText(ENABLE_ALL_ADDONS)
	frame.EnableAllButton:SetScript("OnClick", function()
		local character = frame:GetCharacter()
		for _, addon in pairs(frame:GetAddonsList()) do
			EnableAddOn(addon.index, character)
		end
		frame.ScrollFrame.update()
	end)

	frame.DisableAllButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.DisableAllButton:SetPoint("TOPLEFT", frame.EnableAllButton, "TOPRIGHT", 0, 0)
	frame.DisableAllButton:SetSize(120, 22)
	frame.DisableAllButton:SetText(DISABLE_ALL_ADDONS)
	frame.DisableAllButton:SetScript("OnClick", function()
		local character = frame:GetCharacter()
		for _, addon in pairs(frame:GetAddonsList()) do
			DisableAddOn(addon.index, character)
		end
		frame.ScrollFrame.update()
	end)

	frame.CategoryButton = CreateFrame("Button", nil, frame, "UIPanelSquareButton")
	frame.CategoryButton:SetPoint("TOPRIGHT", -7, -27)
	frame.CategoryButton:SetSize(30, 30)
	frame.CategoryButton.icon:SetTexture("Interface\\Buttons\\SquareButtonTextures")
	frame.CategoryButton:SetScript("OnClick", function()
		local db = frame:GetDb()
		db.isCategoryFrameVisible = not db.isCategoryFrameVisible
		frame:SetCategoryVisibility(db.isCategoryFrameVisible, true)
	end)

	frame.SetsButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	frame.SetsButton:SetPoint("LEFT", frame.CharacterDropDown.Button, "RIGHT", 4, 0)
	frame.SetsButton:SetSize(80, 22)
	frame.SetsButton:SetText(L["Profiles"])
	frame.SetsButton:SetScript("OnClick", function()
		EDDM.EasyMenu(ProfilesDropDownCreate(), dropdownFrame, frame.SetsButton, 0, 0, "MENU")
	end)

	frame.SearchBox = CreateFrame("EditBox", nil, frame, "SearchBoxTemplate")
	frame.SearchBox:SetPoint("LEFT", frame.SetsButton, "RIGHT", 8, 0)
	frame.SearchBox:SetSize(120, 20)
	frame.SearchBox:SetScript("OnTextChanged", function(self)
		SearchBoxTemplate_OnTextChanged(self)
		frame:UpdateListFilters()
		if (frame.SearchBox:GetText() == "") then
			frame.ResultOptionsButton:Hide()
		else
			frame.ResultOptionsButton:Show()
		end
	end)

	frame.ResultOptionsButton = CreateFrame("Button", nil, frame, "UIPanelSquareButton")
	frame.ResultOptionsButton:SetPoint("LEFT", frame.SearchBox, "RIGHT", 1, 0)
	frame.ResultOptionsButton:SetSize(26, 26)
	frame.ResultOptionsButton.icon:SetAtlas("transmog-icon-downarrow")
	frame.ResultOptionsButton.icon:SetTexCoord(0, 1, 0, 1)
	frame.ResultOptionsButton.icon:SetSize(15, 9)
	frame.ResultOptionsButton:SetScript("OnClick", function()
		EDDM.EasyMenu(SearchResultDropDownCreate(), dropdownFrame, frame.ConfigButton, 0, 0, "MENU")
	end)

	frame.ConfigButton = CreateFrame("Button", nil, frame, "UIPanelSquareButton")
	frame.ConfigButton:SetPoint("RIGHT", frame.CategoryButton, "LEFT", -4, 0)
	frame.ConfigButton:SetSize(30, 30)
	frame.ConfigButton.icon:SetAtlas("OptionsIcon-Brown")
	frame.ConfigButton.icon:SetTexCoord(0, 1, 0, 1)
	frame.ConfigButton.icon:SetSize(16, 16)
	frame.ConfigButton:SetScript("OnClick", function()
		EDDM.EasyMenu(ConfigDropDownCreate(), dropdownFrame, frame.ConfigButton, 0, 0, "MENU")
	end)
end