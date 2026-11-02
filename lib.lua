--[[
	PL UI Library — Rivals-style sidebar + cards
	Host as lib.lua and load with:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/ashlyplayz/public/main/lib.lua"))()
	Local fallback: PLUILib.lua in executor workspace.
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

	return api
end

function Library.CreateWindow(opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Window")
	local brand = tostring(opts.Brand or string.sub(title, 1, 2))
	local subtitle = tostring(opts.Subtitle or "Ready")
	local size = opts.Size or UDim2.fromOffset(640, 540)
	local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift

	local connections = {}
	local function bind(sig)
		table.insert(connections, sig)
		return sig
	end

	local screen = mk("ScreenGui", {
		Name = opts.Name or "PLUIWindow",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = opts.DisplayOrder or 1300,
		IgnoreGuiInset = true,
	}, parentGui())

	local root = mk("Frame", {
		Name = "Root",
		BackgroundColor3 = Theme.bg,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = size,
		ClipsDescendants = true,
	}, screen)
	corner(root, 8)
	stroke(root, Theme.stroke, 1, 0.15)
	mk("Frame", {
		Name = "Accent",
		BackgroundColor3 = Theme.accent,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 2),
		ZIndex = 5,
	}, root)

	-- header
	local header = mk("Frame", {
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 2),
		Size = UDim2.new(1, 0, 0, 46),
	}, root)
	corner(header, 8)

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

	-- body: sidebar + content
	local body = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 52),
		Size = UDim2.new(1, -16, 1, -82),
	}, root)

	local sidebar = mk("ScrollingFrame", {
		BackgroundColor3 = Theme.sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 128, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.accentDim,
	}, body)
	corner(sidebar, 6)
	stroke(sidebar, Theme.stroke, 1, 0.2)
	pad(sidebar, 8, 8, 8, 8)
	mk("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)

	local content = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(136, 0),
		Size = UDim2.new(1, -136, 1, 0),
	}, body)

	local contentHeader = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -28, 0, 28),
	}, content)

	local pageTitle = mk("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.45, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Theme.text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, contentHeader)

	local searchBox = mk("TextBox", {
		BackgroundColor3 = Theme.panelAlt,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(150, 26),
		Font = Enum.Font.Gotham,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Theme.textDim,
		Text = "",
		TextColor3 = Theme.text,
		TextSize = 11,
		ClearTextOnFocus = false,
	}, contentHeader)
	corner(searchBox, 8)
	pad(searchBox, 0, 0, 10, 10)

	local pagesFolder = mk("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.new(1, -28, 1, -52),
	}, content)

	-- footer
	local footer = mk("Frame", {
		BackgroundColor3 = Theme.panel,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 28),
	}, root)
	local footerLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.Gotham,
		Text = "Ready",
		TextColor3 = Theme.textDim,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, footer)
	local pulseLabel = mk("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(120, 18),
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Theme.cyan,
		TextSize = 11,
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
		pulseLabel.Text = tostring(text or "")
		pulseLabel.TextColor3 = color or Theme.cyan
		task.delay(1.2, function()
			if pulseLabel.Text == tostring(text or "") then
				pulseLabel.Text = ""
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
			Size = UDim2.new(1, 0, 0, 32),
			Font = Enum.Font.GothamBold,
			Text = name,
			TextColor3 = Theme.text,
			TextSize = 12,
			LayoutOrder = order,
		}, sidebar)
		corner(btn, 9)

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

	function window:Destroy()
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

	-- drag
	do
		local dragging, dragStart, startPos = false, nil, nil
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = root.Position
			end
		end)
		header.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		bind(UserInputService.InputChanged:Connect(function(input)
			if not dragging then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local d = input.Position - dragStart
				root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end))
	end

	bind(UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == toggleKey then
			root.Visible = not root.Visible
		end
	end))

	closeBtn.MouseButton1Click:Connect(function()
		if opts.OnClose then
			opts.OnClose()
		else
			window:Destroy()
		end
	end)

	-- entrance
	do
		local target = root.Position
		root.Position = UDim2.new(target.X.Scale, target.X.Offset, target.Y.Scale, target.Y.Offset + 18)
		root.BackgroundTransparency = 0.2
		tween(root, { Position = target, BackgroundTransparency = 0 }, 0.28)
	end

	table.insert(Library.Windows, window)
	return window
end

return Library
