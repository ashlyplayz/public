--[[
	MythiOs UI Library — exact hub shell from Rivals Assist patterns:
	boot loader, black modal dim, custom cursor, open-scale pop, hint chip, toasts.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Palette aligned with Rivals Assist hub
local Theme = {
	bg = Color3.fromRGB(16, 16, 20),
	panel = Color3.fromRGB(24, 24, 31),
	panelAlt = Color3.fromRGB(30, 30, 38),
	sidebar = Color3.fromRGB(24, 24, 31),
	stroke = Color3.fromRGB(48, 48, 62),
	accent = Color3.fromRGB(99, 102, 241),
	accentDim = Color3.fromRGB(79, 82, 200),
	mint = Color3.fromRGB(150, 226, 140),
	cyan = Color3.fromRGB(153, 204, 216),
	rose = Color3.fromRGB(207, 142, 132),
	text = Color3.fromRGB(236, 236, 244),
	textDim = Color3.fromRGB(148, 150, 168),
	off = Color3.fromRGB(58, 58, 70),
	tabIdle = Color3.fromRGB(30, 30, 38),
	tabHover = Color3.fromRGB(38, 38, 50),
}

local function parentGui()
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
end

local function mk(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(parent, r)
	return mk("UICorner", { CornerRadius = UDim.new(0, r or 10) }, parent)
end

local function stroke(parent, color, th, tr)
	return mk("UIStroke", {
		Color = color or Theme.stroke,
		Thickness = th or 1,
		Transparency = tr or 0.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function pad(parent, t, b, l, r)
	return mk("UIPadding", {
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
	}, parent)
end

local function tween(obj, props, t)
	TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local Library = {
	Theme = Theme,
	Windows = {},
}

function Library.SetTheme(patch)
	for k, v in pairs(patch or {}) do
		Theme[k] = v
	end
end

local function makeSection(host, title)
	local card = mk("Frame", {
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, host)
	corner(card, 12)
	stroke(card, Theme.stroke, 1, 0.35)
	pad(card, 10, 10, 12, 12)

	local list = mk("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, card)

	local head = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		LayoutOrder = 0,
	}, card)

	local accentBar = mk("Frame", {
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(3, 14),
		Position = UDim2.fromOffset(0, 2),
	}, head)
	corner(accentBar, 2)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -10, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = title or "Section",
		TextColor3 = Theme.text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, head)

	local order = 0
	local api = { Instance = card, _items = {} }

	local function nextOrder()
		order += 1
		return order
	end

	local function trackSearch(text, root)
		table.insert(api._items, { text = string.lower(tostring(text or "")), root = root })
	end

	function api:SetSearch(query)
		local q = string.lower(tostring(query or ""))
		for _, item in ipairs(self._items) do
			local show = q == "" or string.find(item.text, q, 1, true) ~= nil
			item.root.Visible = show
		end
	end

	function api:Label(text)
		local row = mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = tostring(text or ""),
			TextColor3 = Theme.textDim,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = nextOrder(),
		}, card)
		trackSearch(text, row)
		return row
	end

	function api:Toggle(opts)
		opts = opts or {}
		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 28),
			LayoutOrder = nextOrder(),
		}, card)
		trackSearch(opts.Text, row)

		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -52, 1, 0),
			Font = Enum.Font.GothamMedium,
			Text = tostring(opts.Text or "Toggle"),
			TextColor3 = Theme.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local on = opts.Default == true
		local accent = opts.Accent or Theme.accent
		local track = mk("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = on and accent or Theme.off,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(42, 22),
			Text = "",
		}, row)
		corner(track, 11)
		local knob = mk("Frame", {
			BackgroundColor3 = Theme.text,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, on and 22 or 2, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
		}, track)
		corner(knob, 9)

		local ctrl = {
			Flag = opts.Flag,
			Get = function()
				return on
			end,
		}
		function ctrl:Set(v, silent)
			on = v and true or false
			tween(track, { BackgroundColor3 = on and accent or Theme.off }, 0.12)
			tween(knob, { Position = UDim2.new(0, on and 22 or 2, 0.5, 0) }, 0.12)
			if not silent and opts.Callback then
				opts.Callback(on)
			end
		end

		track.MouseButton1Click:Connect(function()
			ctrl:Set(not on, false)
		end)
		return ctrl
	end

	function api:Button(opts)
		opts = opts or {}
		local btn = mk("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Theme.panelAlt,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 32),
			Font = Enum.Font.GothamBold,
			Text = tostring(opts.Text or "Button"),
			TextColor3 = opts.Danger and Theme.rose or Theme.accent,
			TextSize = 12,
			LayoutOrder = nextOrder(),
		}, card)
		corner(btn, 9)
		stroke(btn, opts.Danger and Theme.rose or Theme.accentDim, 1, 0.45)
		trackSearch(opts.Text, btn)
		btn.MouseButton1Click:Connect(function()
			if opts.Callback then
				opts.Callback(btn)
			end
		end)
		btn.MouseEnter:Connect(function()
			tween(btn, { BackgroundColor3 = Color3.fromRGB(40, 48, 60) }, 0.1)
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, { BackgroundColor3 = Theme.panelAlt }, 0.1)
		end)
		return btn
	end

	function api:Slider(opts)
		opts = opts or {}
		local minV = tonumber(opts.Min) or 0
		local maxV = tonumber(opts.Max) or 1
		local value = math.clamp(tonumber(opts.Default) or minV, minV, maxV)
		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = nextOrder(),
		}, card)
		trackSearch(opts.Text, row)

		local title = mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -48, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = tostring(opts.Text or "Slider"),
			TextColor3 = Theme.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local valLabel = mk("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(48, 16),
			Font = Enum.Font.GothamBold,
			Text = string.format(opts.Format or "%.2f", value),
			TextColor3 = Theme.accent,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
		}, row)

		local bar = mk("Frame", {
			BackgroundColor3 = Theme.off,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 22),
			Size = UDim2.new(1, 0, 0, 8),
		}, row)
		corner(bar, 4)
		local fill = mk("Frame", {
			BackgroundColor3 = Theme.accent,
			BorderSizePixel = 0,
			Size = UDim2.new((value - minV) / math.max(0.001, maxV - minV), 0, 1, 0),
		}, bar)
		corner(fill, 4)
		local knob = mk("Frame", {
			BackgroundColor3 = Theme.text,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new((value - minV) / math.max(0.001, maxV - minV), 0, 0.5, 0),
			Size = UDim2.fromOffset(14, 14),
		}, bar)
		corner(knob, 7)

		local dragging = false
		local ctrl = {}
		local function apply(alpha, silent)
			alpha = math.clamp(alpha, 0, 1)
			value = minV + (maxV - minV) * alpha
			if opts.Step then
				local step = tonumber(opts.Step) or 1
				value = math.floor((value / step) + 0.5) * step
				value = math.clamp(value, minV, maxV)
				alpha = (value - minV) / math.max(0.001, maxV - minV)
			end
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, 0, 0.5, 0)
			valLabel.Text = string.format(opts.Format or "%.2f", value)
			if not silent and opts.Callback then
				opts.Callback(value)
			end
		end
		function ctrl:Set(v, silent)
			local alpha = (math.clamp(tonumber(v) or minV, minV, maxV) - minV) / math.max(0.001, maxV - minV)
			apply(alpha, silent)
		end
		function ctrl:Get()
			return value
		end

		local function fromX(x)
			local rel = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
			apply(rel, false)
		end
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				fromX(input.Position.X)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				fromX(input.Position.X)
			end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		return ctrl
	end

	function api:Paragraph(text)
		return self:Label(text)
	end

	function api:TextBox(opts)
		opts = opts or {}
		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 52),
			LayoutOrder = nextOrder(),
		}, card)
		trackSearch(opts.Text or opts.Placeholder, row)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = tostring(opts.Text or "Value"),
			TextColor3 = Theme.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local box = mk("TextBox", {
			BackgroundColor3 = Theme.panelAlt,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 28),
			Font = Enum.Font.Gotham,
			Text = tostring(opts.Default or ""),
			PlaceholderText = tostring(opts.Placeholder or ""),
			PlaceholderColor3 = Theme.textDim,
			TextColor3 = Theme.text,
			TextSize = 12,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		corner(box, 8)
		pad(box, 0, 0, 10, 10)
		stroke(box, Theme.stroke, 1, 0.35)
		local ctrl = {}
		function ctrl:Get()
			return box.Text
		end
		function ctrl:Set(text)
			box.Text = tostring(text or "")
		end
		box.FocusLost:Connect(function(enter)
			if opts.Callback then
				opts.Callback(box.Text, enter)
			end
		end)
		return ctrl
	end

	function api:Dropdown(opts)
		opts = opts or {}
		local options = {}
		for _, v in ipairs(opts.Options or {}) do
			table.insert(options, tostring(v))
		end
		if #options == 0 then
			options = { "None" }
		end
		local value = tostring(opts.Default or options[1])
		if not table.find(options, value) then
			value = options[1]
		end

		local row = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 52),
			LayoutOrder = nextOrder(),
			ZIndex = 5,
		}, card)
		trackSearch(opts.Text, row)

		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 16),
			Font = Enum.Font.GothamMedium,
			Text = tostring(opts.Text or "Select"),
			TextColor3 = Theme.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		-- Hub-style trigger (ZeroHub / Linoria-like)
		local trigger = mk("TextButton", {
			AutoButtonColor = false,
			BackgroundColor3 = Theme.panelAlt,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, 0, 0, 30),
			Text = "",
			ZIndex = 6,
		}, row)
		corner(trigger, 6)
		local triggerStroke = stroke(trigger, Theme.stroke, 1, 0.2)

		local valueLabel = mk("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -36, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = value,
			TextColor3 = Theme.text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 7,
		}, trigger)

		local chevron = mk("TextLabel", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			Font = Enum.Font.GothamBold,
			Text = "v",
			TextColor3 = Theme.textDim,
			TextSize = 11,
			ZIndex = 7,
		}, trigger)

		local overlayGui = card:FindFirstAncestorOfClass("ScreenGui")
		local open = false
		local menu = mk("Frame", {
			Name = "DropdownMenu",
			BackgroundColor3 = Theme.panel,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 220,
			ClipsDescendants = true,
		}, overlayGui or row)
		corner(menu, 6)
		stroke(menu, Theme.accent, 1, 0.35)

		local list = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.accent,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ZIndex = 221,
		}, menu)
		pad(list, 4, 4, 4, 4)
		mk("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, list)

		local ctrl = {}
		local itemButtons = {}

		local function refreshItemStyles()
			for _, item in ipairs(itemButtons) do
				local selected = item.Name == value
				item.BackgroundColor3 = selected and Theme.accentDim or Theme.panelAlt
				item.TextColor3 = Theme.text
				local mark = item:FindFirstChild("Sel")
				if mark then
					mark.BackgroundTransparency = selected and 0 or 1
				end
			end
		end

		local function setValue(v, silent)
			value = tostring(v)
			valueLabel.Text = value
			refreshItemStyles()
			if not silent and opts.Callback then
				opts.Callback(value)
			end
		end

		local function placeMenu()
			if not overlayGui then
				menu.Position = UDim2.fromOffset(0, 52)
				menu.Size = UDim2.new(1, 0, 0, math.min(32 * #options + 8, 168))
				return
			end
			local pos = trigger.AbsolutePosition
			local size = trigger.AbsoluteSize
			local yOff = 0
			if not overlayGui.IgnoreGuiInset then
				yOff = game:GetService("GuiService"):GetGuiInset().Y
			end
			menu.Position = UDim2.fromOffset(pos.X, pos.Y + size.Y + 4 - yOff)
			menu.Size = UDim2.fromOffset(math.max(120, size.X), math.min(32 * #options + 8, 168))
		end

		local function setOpen(state)
			open = state and true or false
			chevron.Text = open and "^" or "v"
			chevron.TextColor3 = open and Theme.accent or Theme.textDim
			triggerStroke.Color = open and Theme.accent or Theme.stroke
			triggerStroke.Transparency = open and 0.1 or 0.2
			trigger.BackgroundColor3 = Theme.panelAlt
			if open then
				placeMenu()
				menu.Visible = true
			else
				menu.Visible = false
			end
		end

		function ctrl:Get()
			return value
		end
		function ctrl:Set(v, silent)
			if table.find(options, tostring(v)) then
				setValue(v, silent)
			end
		end
		function ctrl:SetOptions(listOpts, keep)
			table.clear(options)
			table.clear(itemButtons)
			for _, child in ipairs(list:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
			for _, v in ipairs(listOpts or {}) do
				table.insert(options, tostring(v))
			end
			if #options == 0 then
				options = { "None" }
			end
			for i, opt in ipairs(options) do
				local item = mk("TextButton", {
					Name = opt,
					AutoButtonColor = false,
					BackgroundColor3 = Theme.panelAlt,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 28),
					Font = Enum.Font.GothamMedium,
					Text = "  " .. opt,
					TextColor3 = Theme.text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = i,
					ZIndex = 222,
				}, list)
				corner(item, 5)
				local sel = mk("Frame", {
					Name = "Sel",
					BackgroundColor3 = Theme.accent,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 3, 1, -8),
					Position = UDim2.fromOffset(2, 4),
					BackgroundTransparency = 1,
					ZIndex = 223,
				}, item)
				corner(sel, 2)
				item.MouseEnter:Connect(function()
					if item.Name ~= value then
						item.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
					end
				end)
				item.MouseLeave:Connect(function()
					refreshItemStyles()
				end)
				item.MouseButton1Click:Connect(function()
					setValue(opt, false)
					setOpen(false)
				end)
				table.insert(itemButtons, item)
			end
			if keep and table.find(options, value) then
				setValue(value, true)
			else
				setValue(options[1], true)
			end
			if open then
				placeMenu()
			end
		end

		ctrl:SetOptions(options, true)

		trigger.MouseButton1Click:Connect(function()
			setOpen(not open)
		end)
		trigger.MouseEnter:Connect(function()
			if not open then
				tween(trigger, { BackgroundColor3 = Color3.fromRGB(38, 38, 48) }, 0.1)
			end
		end)
		trigger.MouseLeave:Connect(function()
			if not open then
				tween(trigger, { BackgroundColor3 = Theme.panelAlt }, 0.1)
			end
		end)

		UserInputService.InputBegan:Connect(function(input)
			if not open then
				return
			end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			local p = UserInputService:GetMouseLocation()
			local mPos, mSize = menu.AbsolutePosition, menu.AbsoluteSize
			local tPos, tSize = trigger.AbsolutePosition, trigger.AbsoluteSize
			local inMenu = p.X >= mPos.X and p.X <= mPos.X + mSize.X and p.Y >= mPos.Y and p.Y <= mPos.Y + mSize.Y
			local inTrig = p.X >= tPos.X and p.X <= tPos.X + tSize.X and p.Y >= tPos.Y and p.Y <= tPos.Y + tSize.Y
			if not inMenu and not inTrig then
				setOpen(false)
			end
		end)

		if overlayGui then
			trigger:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
				if open then
					placeMenu()
				end
			end)
			trigger:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				if open then
					placeMenu()
				end
			end)
		end

		row.Destroying:Connect(function()
			if menu and menu.Parent then
				menu:Destroy()
			end
		end)

		return ctrl
	end

	return api
end

function Library.CreateWindow(opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Window")
	local brand = tostring(opts.Brand or string.sub(title, 1, 2))
	local subtitle = tostring(opts.Subtitle or "Ready")
	local size = opts.Size or UDim2.fromOffset(640, 540)
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
	local showBoot = opts.Boot ~= false
	local unlockName = "PLUI_MouseUnlock_" .. tostring(math.random(10000, 99999))

	local connections = {}
	local function bind(sig)
		table.insert(connections, sig)
		return sig
	end

	local screen = mk("ScreenGui", {
		Name = opts.Name or "PLUIWindow",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = opts.DisplayOrder or 120000,
		IgnoreGuiInset = true,
	}, parentGui())

	-- Dim black overlay + Modal unlocks the game mouse while menu is open
	local menuModal = mk("TextButton", {
		Name = "MouseUnlock",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.62,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Visible = false,
		Modal = false,
		Selectable = false,
		ZIndex = 1,
	}, screen)

	local root = mk("Frame", {
		Name = "Root",
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		ClipsDescendants = true,
		Visible = false,
		ZIndex = 10,
	}, screen)
	corner(root, 8)
	stroke(root, Theme.stroke, 1, 0.15)
	local openScale = mk("UIScale", { Name = "OpenScale", Scale = 1 }, root)
	mk("Frame", {
		Name = "Accent",
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 15,
	}, root)

	-- custom crosshair cursor (follows mouse while menu open)
	local menuCursor = mk("Frame", {
		Name = "MenuCursor",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22),
		Visible = false,
		ZIndex = 250,
		Active = false,
	}, screen)
	local function cursorBar(barSize, barPos)
		local f = mk("Frame", {
			Size = barSize,
			Position = barPos,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderSizePixel = 0,
			ZIndex = 251,
			Active = false,
		}, menuCursor)
		local s = Instance.new("UIStroke")
		s.Thickness = 1
		s.Color = Color3.fromRGB(0, 0, 0)
		s.Parent = f
	end
	cursorBar(UDim2.fromOffset(2, 22), UDim2.fromOffset(10, 0))
	cursorBar(UDim2.fromOffset(22, 2), UDim2.fromOffset(0, 10))
	local cursorDot = mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(4, 4),
		BackgroundColor3 = Color3.fromRGB(255, 90, 110),
		BorderSizePixel = 0,
		ZIndex = 252,
		Active = false,
	}, menuCursor)
	corner(cursorDot, 99)

	-- hint chip (visible while menu closed — matches Rivals Assist)
	local hintLabel = mk("TextLabel", {
		Name = "Hint",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 14),
		Size = UDim2.fromOffset(168, 26),
		BackgroundColor3 = Theme.bg,
		BackgroundTransparency = 0.08,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = Theme.text,
		ZIndex = 5,
		Text = title .. "  ·  RightShift",
		Visible = true,
	}, screen)
	corner(hintLabel, 6)
	local hintStroke = stroke(hintLabel, Theme.accent, 1, 0.35)

	-- toast stack
	local toastHold = mk("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(280, 220),
		BackgroundTransparency = 1,
		ZIndex = 80,
	}, screen)
	mk("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, toastHold)

	-- header
	local header = mk("Frame", {
		Name = "Header",
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 0, 46),
	}, root)
	corner(header, 8)
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 12),
		Position = UDim2.new(0, 0, 1, -12),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
	}, header)

	local brandBadge = mk("Frame", {
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 9),
		Size = UDim2.fromOffset(28, 28),
	}, header)
	corner(brandBadge, 6)
	mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		Text = string.upper(string.sub(brand, 1, 2)),
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 12,
	}, brandBadge)

	mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(46, 6),
		Size = UDim2.new(0.5, 0, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local subtitleLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(46, 24),
		Size = UDim2.new(0.5, 0, 0, 14),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Theme.textDim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, header)

	local closeBtn = mk("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = Theme.panelAlt,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		Font = Enum.Font.GothamBold,
		Text = "×",
		TextColor3 = Theme.text,
		TextSize = 14,
	}, header)
	corner(closeBtn, 5)

	-- body: sidebar + content (Rivals content chrome)
	local body = mk("Frame", {
		Name = "BodyRow",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 50),
		Size = UDim2.new(1, -16, 1, -80),
	}, root)

	local sidebar = mk("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 128, 1, 0),
		ClipsDescendants = true,
	}, body)
	corner(sidebar, 6)
	stroke(sidebar, Theme.stroke, 1, 0)
	local sidebarNav = mk("ScrollingFrame", {
		Name = "Nav",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.accentDim,
		ZIndex = 2,
	}, sidebar)
	pad(sidebarNav, 8, 8, 6, 6)
	mk("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, sidebarNav)

	local content = mk("Frame", {
		Name = "Content",
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 136, 0, 0),
		Size = UDim2.new(1, -136, 1, 0),
	}, body)
	corner(content, 6)
	stroke(content, Theme.stroke, 1, 0)

	local pageTitle = mk("TextLabel", {
		Name = "PageTitle",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 8),
		Size = UDim2.new(0.55, 0, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Theme.text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, content)

	local searchBox = mk("TextBox", {
		Name = "Search",
		BackgroundColor3 = Theme.panelAlt,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(150, 22),
		Font = Enum.Font.Gotham,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.textDim,
		Text = "",
		TextColor3 = Theme.text,
		TextSize = 11,
		ClearTextOnFocus = false,
		ZIndex = 6,
	}, content)
	corner(searchBox, 5)

	local pagesFolder = mk("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 32),
		Size = UDim2.new(1, -12, 1, -38),
		ClipsDescendants = true,
	}, content)

	-- footer
	local footer = mk("Frame", {
		Name = "Footer",
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 26),
	}, root)
	mk("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
	}, footer)
	local footerLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(0.55, 0, 1, 0),
		Font = Enum.Font.Gotham,
		Text = "Ready",
		TextColor3 = Theme.textDim,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, footer)
	local pulseLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 0),
		Size = UDim2.new(0.42, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Theme.cyan,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, footer)

	local window = {
		Screen = screen,
		Root = root,
		Theme = Theme,
		_tabs = {},
		_active = nil,
		_flags = {},
		_searchables = {},
		_open = false,
		_savedMouseBehavior = nil,
		_savedMouseIcon = nil,
		_alive = true,
	}

	local function applySearch(query)
		for _, tabApi in pairs(window._tabs) do
			for _, section in ipairs(tabApi._sections) do
				section:SetSearch(query)
			end
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(searchBox.Text)
	end)

	function window:SetSubtitle(text)
		subtitleLabel.Text = tostring(text or "")
	end

	function window:SetFooter(text)
		footerLabel.Text = tostring(text or "")
	end

	function window:Notify(text, color)
		text = tostring(text or "")
		color = color or Theme.cyan
		pulseLabel.Text = text
		pulseLabel.TextColor3 = color
		task.delay(1.4, function()
			if pulseLabel.Text == text then
				pulseLabel.Text = ""
			end
		end)

		local toast = mk("Frame", {
			BackgroundColor3 = Theme.panel,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			ZIndex = 81,
		}, toastHold)
		corner(toast, 8)
		local tStroke = stroke(toast, color, 1, 0.35)
		tStroke.Transparency = 1
		pad(toast, 10, 10, 12, 12)
		local tLabel = mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = Theme.text,
			TextSize = 12,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = 1,
			ZIndex = 82,
		}, toast)
		mk("Frame", {
			Size = UDim2.new(0, 3, 1, 0),
			Position = UDim2.fromOffset(-12, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ZIndex = 82,
		}, toast)
		TweenService:Create(toast, TweenInfo.new(0.18), { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(tStroke, TweenInfo.new(0.18), { Transparency = 0.35 }):Play()
		TweenService:Create(tLabel, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
		task.delay(2.4, function()
			if not toast.Parent then
				return
			end
			TweenService:Create(toast, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(tStroke, TweenInfo.new(0.22), { Transparency = 1 }):Play()
			TweenService:Create(tLabel, TweenInfo.new(0.22), { TextTransparency = 1 }):Play()
			task.wait(0.24)
			if toast.Parent then
				toast:Destroy()
			end
		end)
	end

	function window:SetFlag(flag, value)
		self._flags[flag] = value
	end

	function window:GetFlag(flag)
		return self._flags[flag]
	end

	local function selectTab(name)
		for n, tabApi in pairs(window._tabs) do
			local on = n == name
			tabApi.Page.Visible = on
			tabApi.Button.BackgroundColor3 = on and Theme.accent or Theme.tabIdle
			tabApi.Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		window._active = name
		pageTitle.Text = name
		applySearch(searchBox.Text)
	end

	function window:AddTab(name)
		name = tostring(name)
		local order = 0
		for _ in pairs(self._tabs) do
			order += 1
		end

		local btn = mk("TextButton", {
			Name = "Tab_" .. name,
			AutoButtonColor = false,
			BackgroundColor3 = Theme.tabIdle,
			BorderSizePixel = 0,
			Size = UDim2.new(1, -4, 0, 30),
			Font = Enum.Font.GothamBold,
			Text = name,
			TextColor3 = Theme.text,
			TextSize = 12,
			LayoutOrder = order,
		}, sidebarNav)
		corner(btn, 6)

		local page = mk("ScrollingFrame", {
			Name = "Page_" .. name,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.accentDim,
			Visible = false,
		}, pagesFolder)
		pad(page, 0, 12, 0, 4)
		mk("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)

		local tabApi = {
			Name = name,
			Button = btn,
			Page = page,
			_sections = {},
			_colOrder = 0,
		}

		function tabApi:Section(title)
			local sec = makeSection(page, title)
			sec.Instance.LayoutOrder = #self._sections + 1
			table.insert(self._sections, sec)
			return sec
		end

		function tabApi:Columns()
			local row = mk("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = #self._sections + 100,
			}, page)
			mk("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, row)

			local function col()
				local holder = mk("Frame", {
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -5, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				}, row)
				mk("UIListLayout", {
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, holder)
				local proxy = {
					_sections = tabApi._sections,
					Section = function(_, title)
						local sec = makeSection(holder, title)
						table.insert(tabApi._sections, sec)
						return sec
					end,
				}
				return proxy
			end
			return col(), col()
		end

		btn.MouseButton1Click:Connect(function()
			selectTab(name)
		end)
		btn.MouseEnter:Connect(function()
			if window._active ~= name then
				tween(btn, { BackgroundColor3 = Theme.tabHover }, 0.1)
			end
		end)
		btn.MouseLeave:Connect(function()
			if window._active ~= name then
				tween(btn, { BackgroundColor3 = Theme.tabIdle }, 0.1)
			end
		end)

		self._tabs[name] = tabApi
		if not self._active then
			selectTab(name)
		end
		return tabApi
	end

	local function restoreGameMouse()
		pcall(function()
			menuModal.Modal = false
			menuModal.Visible = false
			menuModal.BackgroundTransparency = 0.62
			menuCursor.Visible = false
			if window._savedMouseBehavior ~= nil then
				UserInputService.MouseBehavior = window._savedMouseBehavior
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
			if window._savedMouseIcon ~= nil then
				UserInputService.MouseIconEnabled = window._savedMouseIcon
			else
				UserInputService.MouseIconEnabled = true
			end
		end)
	end

	local function applyMenuMouseState()
		if not window._alive then
			return
		end
		if window._open then
			pcall(function()
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
			end)
			menuModal.Visible = true
			menuModal.Modal = true
			menuCursor.Visible = true
			local loc = UserInputService:GetMouseLocation()
			menuCursor.Position = UDim2.fromOffset(loc.X, loc.Y)
		else
			menuModal.Modal = false
			menuCursor.Visible = false
			-- leave modal visible briefly so close fade can finish; restoreGameMouse hides it
		end
	end

	function window:IsOpen()
		return self._open == true
	end

	function window:SetOpen(visible)
		visible = visible and true or false
		if visible and not self._open then
			pcall(function()
				self._savedMouseBehavior = UserInputService.MouseBehavior
				self._savedMouseIcon = UserInputService.MouseIconEnabled
			end)
		end
		self._open = visible
		hintLabel.Visible = not visible
		root.Visible = visible
		if visible then
			if not root:GetAttribute("Moved") then
				root.Position = UDim2.fromScale(0.5, 0.5)
			end
			menuModal.Visible = true
			menuModal.BackgroundTransparency = 1
			TweenService:Create(menuModal, TweenInfo.new(0.18), { BackgroundTransparency = 0.62 }):Play()
			openScale.Scale = 0.92
			TweenService:Create(
				openScale,
				TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
			applyMenuMouseState()
		else
			TweenService:Create(menuModal, TweenInfo.new(0.16), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(
				openScale,
				TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Scale = 0.96 }
			):Play()
			task.delay(0.14, function()
				if not window._open then
					restoreGameMouse()
				end
			end)
			applyMenuMouseState()
		end
		if opts.OnOpenChanged then
			pcall(opts.OnOpenChanged, visible)
		end
	end

	function window:Toggle()
		self:SetOpen(not self._open)
	end

	function window:Destroy()
		self._alive = false
		self._open = false
		pcall(function()
			RunService:UnbindFromRenderStep(unlockName)
		end)
		restoreGameMouse()
		for _, c in ipairs(connections) do
			pcall(function()
				c:Disconnect()
			end)
		end
		table.clear(connections)
		if screen then
			screen:Destroy()
		end
	end

	-- drag (viewport-stable via RenderStepped)
	do
		local dragging = false
		local dragStart = Vector2.zero
		local startPos = UDim2.fromScale(0.5, 0.5)
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = UserInputService:GetMouseLocation()
				startPos = root.Position
			end
		end)
		header.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		bind(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))
		bind(RunService.RenderStepped:Connect(function()
			if not dragging or not window._open then
				return
			end
			local m = UserInputService:GetMouseLocation()
			local d = m - dragStart
			root:SetAttribute("Moved", true)
			root.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + d.X,
				startPos.Y.Scale,
				startPos.Y.Offset + d.Y
			)
		end))
	end

	bind(UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == toggleKey then
			window:Toggle()
		end
	end))

	bind(UserInputService.InputChanged:Connect(function(input)
		if not window._open then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local loc = UserInputService:GetMouseLocation()
			menuCursor.Position = UDim2.fromOffset(loc.X, loc.Y)
		end
	end))

	closeBtn.MouseButton1Click:Connect(function()
		if opts.OnClose then
			opts.OnClose()
		else
			window:SetOpen(false)
		end
	end)

	-- keep mouse unlocked every frame while open (games scripts often re-lock)
	pcall(function()
		RunService:BindToRenderStep(unlockName, Enum.RenderPriority.Last.Value, applyMenuMouseState)
	end)

	local function playBootThenOpen()
		local overlay = mk("Frame", {
			Name = "Boot",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(6, 6, 10),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 400,
		}, screen)
		local card = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(300, 176),
			BackgroundColor3 = Theme.panel,
			BorderSizePixel = 0,
			BackgroundTransparency = 1,
			ZIndex = 401,
		}, overlay)
		corner(card, 14)
		local cardStroke = stroke(card, Theme.accent, 1, 1)
		local cardScale = mk("UIScale", { Scale = 0.78 }, card)
		mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = Theme.accent,
			BorderSizePixel = 0,
			ZIndex = 402,
		}, card)
		local badge = mk("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 28),
			Size = UDim2.fromOffset(42, 42),
			BackgroundColor3 = Theme.accent,
			BorderSizePixel = 0,
			ZIndex = 402,
		}, card)
		corner(badge, 10)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Text = string.upper(string.sub(brand, 1, 2)),
			ZIndex = 403,
		}, badge)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 80),
			Size = UDim2.new(1, -32, 0, 24),
			Font = Enum.Font.GothamBold,
			TextSize = 18,
			TextColor3 = Theme.text,
			Text = title,
			ZIndex = 402,
		}, card)
		local bootSub = mk("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(16, 104),
			Size = UDim2.new(1, -32, 0, 16),
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = Theme.textDim,
			Text = "Loading...",
			ZIndex = 402,
		}, card)
		local track = mk("Frame", {
			Position = UDim2.fromOffset(28, 136),
			Size = UDim2.new(1, -56, 0, 6),
			BackgroundColor3 = Theme.stroke,
			BorderSizePixel = 0,
			ZIndex = 402,
		}, card)
		corner(track, 3)
		local fill = mk("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.accent,
			BorderSizePixel = 0,
			ZIndex = 403,
		}, track)
		corner(fill, 3)

		local bootAlive = true
		task.spawn(function()
			local n = 0
			while bootAlive and bootSub.Parent and string.sub(bootSub.Text, 1, 7) == "Loading" do
				n = (n % 3) + 1
				bootSub.Text = "Loading" .. string.rep(".", n)
				task.wait(0.28)
			end
		end)

		hintLabel.Visible = false
		TweenService:Create(overlay, TweenInfo.new(0.28), { BackgroundTransparency = 0.22 }):Play()
		TweenService:Create(card, TweenInfo.new(0.28), { BackgroundTransparency = 0 }):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.28), { Transparency = 0.25 }):Play()
		TweenService:Create(
			cardScale,
			TweenInfo.new(0.48, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }
		):Play()
		TweenService:Create(
			fill,
			TweenInfo.new(0.9, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Size = UDim2.new(1, 0, 1, 0) }
		):Play()
		task.wait(0.85)
		bootAlive = false
		if bootSub.Parent then
			bootSub.Text = "Ready"
			bootSub.TextColor3 = Theme.mint
		end
		task.wait(0.55)
		TweenService:Create(
			overlay,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
		TweenService:Create(
			card,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ BackgroundTransparency = 1 }
		):Play()
		TweenService:Create(
			cardScale,
			TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Scale = 1.08 }
		):Play()
		task.wait(0.28)
		if overlay.Parent then
			overlay:Destroy()
		end
		if window._alive then
			window:SetOpen(true)
		end
	end

	if showBoot then
		task.spawn(playBootThenOpen)
	elseif opts.StartOpen ~= false then
		window:SetOpen(true)
	end

	table.insert(Library.Windows, window)
	return window
end

return Library
