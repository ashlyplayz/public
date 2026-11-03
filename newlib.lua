--[[
 MythiOs UI Library V5
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer

-- Dark purple (clean, no neon wash)
local Theme = {
 bg = Color3.fromRGB(14, 12, 20),
 panel = Color3.fromRGB(20, 16, 28),
 panelAlt = Color3.fromRGB(30, 24, 42),
 sidebar = Color3.fromRGB(12, 10, 18),
 stroke = Color3.fromRGB(48, 40, 64),
 accent = Color3.fromRGB(168, 85, 247),
 accentDim = Color3.fromRGB(126, 58, 196),
 mint = Color3.fromRGB(52, 211, 153),
 cyan = Color3.fromRGB(196, 181, 253),
 rose = Color3.fromRGB(248, 113, 113),
 text = Color3.fromRGB(246, 242, 255),
 textDim = Color3.fromRGB(150, 142, 168),
 off = Color3.fromRGB(42, 34, 56),
 tabIdle = Color3.fromRGB(12, 10, 18),
 tabHover = Color3.fromRGB(34, 26, 50),
}

local function parentGui()
 -- prefer executor hide GUI so the hub survives PlayerGui resets
 local ok, hui = pcall(function()
  if typeof(gethui) == "function" then
   return gethui()
  end
  return nil
 end)
 if ok and hui then
  return hui
 end
 local ok2, core = pcall(function()
  return game:GetService("CoreGui")
 end)
 if ok2 and core then
  return core
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

local brandImage = nil
local function getBrandImage()
 if brandImage ~= nil then
  return brandImage
 end
 brandImage = ""
 pcall(function()
  if typeof(isfile) ~= "function" or typeof(getcustomasset) ~= "function" then
   return
  end
  local paths = {
   "MythiOs/icon.jpg",
   "MythiOs/icon.png",
   "Scripts/MythiOs/icon.jpg",
  }
  for i = 1, #paths do
   local path = paths[i]
   if isfile(path) then
    local ok, asset = pcall(getcustomasset, path)
    if ok and type(asset) == "string" and asset ~= "" then
     brandImage = asset
     return
    end
   end
  end
 end)
 return brandImage
end

local function makeBrand(parent, size, z)
 size = size or 28
 z = z or 21
 local wrap = mk("Frame", {
 Name = "Brand",
 BackgroundColor3 = Color3.fromRGB(12, 8, 24),
 BorderSizePixel = 0,
 Size = UDim2.fromOffset(size, size),
 ClipsDescendants = true,
 ZIndex = z,
 }, parent)
 corner(wrap, math.floor(size * 0.5))
 local img = getBrandImage()
 if img ~= "" then
  mk("ImageLabel", {
   BackgroundTransparency = 1,
   Size = UDim2.fromScale(1, 1),
   Image = img,
   ScaleType = Enum.ScaleType.Crop,
   ZIndex = z + 1,
  }, wrap)
 else
  wrap.BackgroundColor3 = Theme.accent
  mk("TextLabel", {
   BackgroundTransparency = 1,
   Size = UDim2.fromScale(1, 1),
   Font = Enum.Font.Code,
   Text = "M",
   TextColor3 = Color3.fromRGB(16, 14, 12),
   TextSize = math.max(12, math.floor(size * 0.48)),
   ZIndex = z + 1,
  }, wrap)
 end
 return wrap
end

local function pad(parent, t, b, l, r)
 return mk("UIPadding", {
 PaddingTop = UDim.new(0, t or 0),
 PaddingBottom = UDim.new(0, b or 0),
 PaddingLeft = UDim.new(0, l or 0),
 PaddingRight = UDim.new(0, r or 0),
 }, parent)
end

local function tween(obj, props, t, style, dir)
 if not obj then
 return nil
 end
 local tw = TweenService:Create(
 obj,
 TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
 props
 )
 tw:Play()
 return tw
end

local function ensureScale(gui)
 local s = gui:FindFirstChild("AnimScale")
 if not s then
 s = mk("UIScale", { Name = "AnimScale", Scale = 1 }, gui)
 end
 return s
end

local function hoverScale(gui, grow)
 local s = ensureScale(gui)
 gui.MouseEnter:Connect(function()
 tween(s, { Scale = grow or 1.04 }, 0.14, Enum.EasingStyle.Quad)
 end)
 gui.MouseLeave:Connect(function()
 tween(s, { Scale = 1 }, 0.18, Enum.EasingStyle.Quad)
 end)
end

local function pressPunch(gui)
 local s = ensureScale(gui)
 s.Scale = 0.94
 tween(s, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
end

local Library = {
 Theme = Theme,
 Windows = {},
}
local activeDropdownClose = nil

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
 corner(card, 14)
 -- quiet border; no hover glow (was reading as a purple back-halo)
 local cardStroke = stroke(card, Theme.stroke, 1, 0.62)
 pad(card, 12, 12, 12, 12)
 card.MouseEnter:Connect(function()
  tween(card, { BackgroundColor3 = Theme.panelAlt }, 0.14)
 end)
 card.MouseLeave:Connect(function()
  tween(card, { BackgroundColor3 = Theme.panel }, 0.18)
  tween(cardStroke, { Color = Theme.stroke, Transparency = 0.62 }, 0.18)
 end)

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
 Font = Enum.Font.Code,
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
 Font = Enum.Font.Code,
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
 Font = Enum.Font.Code,
 Text = tostring(opts.Text or "Toggle"),
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)

 local on = opts.Default == true
 local accent = opts.Accent or Theme.accent
 local box = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = on and accent or Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, 0, 0.5, 0),
 Size = UDim2.fromOffset(20, 20),
 Font = Enum.Font.Code,
 Text = on and "✓" or "",
 TextColor3 = Color3.fromRGB(255, 255, 255),
 TextSize = 12,
 }, row)
 corner(box, 5)
 local boxStroke = stroke(box, on and accent or Theme.stroke, 1, on and 0.1 or 0.35)

 local ctrl = {
 Flag = opts.Flag,
 Get = function()
 return on
 end,
 }
 function ctrl:Set(v, silent)
 on = v and true or false
 box.Text = on and "✓" or ""
 tween(box, { BackgroundColor3 = on and accent or Theme.panelAlt }, 0.16)
 tween(boxStroke, { Color = on and accent or Theme.stroke, Transparency = on and 0.1 or 0.35 }, 0.16)
 if not silent and opts.Callback then
 opts.Callback(on)
 end
 end

 hoverScale(box, 1.08)
 box.MouseButton1Click:Connect(function()
 pressPunch(box)
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
 Font = Enum.Font.Code,
 Text = tostring(opts.Text or "Button"),
 TextColor3 = opts.Danger and Theme.rose or Theme.accent,
 TextSize = 12,
 LayoutOrder = nextOrder(),
 }, card)
 corner(btn, 9)
 stroke(btn, opts.Danger and Theme.rose or Theme.accentDim, 1, 0.45)
 trackSearch(opts.Text, btn)
 hoverScale(btn, 1.02)
 btn.MouseButton1Click:Connect(function()
 pressPunch(btn)
 if opts.Callback then
 opts.Callback(btn)
 end
 end)
 btn.MouseEnter:Connect(function()
 tween(btn, { BackgroundColor3 = Theme.tabHover }, 0.14)
 end)
 btn.MouseLeave:Connect(function()
 tween(btn, { BackgroundColor3 = Theme.panelAlt }, 0.2)
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
 Font = Enum.Font.Code,
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
 Font = Enum.Font.Code,
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
 if dragging then
 fill.Size = UDim2.new(alpha, 0, 1, 0)
 knob.Position = UDim2.new(alpha, 0, 0.5, 0)
 else
 tween(fill, { Size = UDim2.new(alpha, 0, 1, 0) }, 0.16)
 tween(knob, { Position = UDim2.new(alpha, 0, 0.5, 0) }, 0.18, Enum.EasingStyle.Back)
 end
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
 Font = Enum.Font.Code,
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
 Font = Enum.Font.Code,
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
 local boxStroke = stroke(box, Theme.stroke, 1, 0.35)
 local ctrl = {}
 function ctrl:Get()
 return box.Text
 end
 function ctrl:Set(text)
 box.Text = tostring(text or "")
 end
 box.Focused:Connect(function()
 tween(boxStroke, { Color = Theme.accent, Transparency = 0.05 }, 0.16)
 tween(box, { BackgroundColor3 = Theme.tabIdle }, 0.16)
 end)
 box.FocusLost:Connect(function(enter)
 tween(boxStroke, { Color = Theme.stroke, Transparency = 0.35 }, 0.2)
 tween(box, { BackgroundColor3 = Theme.panelAlt }, 0.2)
 if opts.Callback then
 opts.Callback(box.Text, enter)
 end
 end)
 return ctrl
 end

 function api:Keybind(opts)
 opts = opts or {}
 local current = opts.Default
 if typeof(current) == "string" then
 current = Enum.KeyCode[current] or Enum.KeyCode.K
 end
 if typeof(current) ~= "EnumItem" then
 current = Enum.KeyCode.K
 end
 local listening = false
 local row = mk("Frame", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, 0, 0, 32),
 LayoutOrder = nextOrder(),
 }, card)
 trackSearch(opts.Text, row)
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, -92, 1, 0),
 Font = Enum.Font.Code,
 Text = tostring(opts.Text or "Keybind"),
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)
 local btn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, 0, 0.5, 0),
 Size = UDim2.fromOffset(86, 26),
 Font = Enum.Font.Code,
 Text = current.Name,
 TextColor3 = Theme.text,
 TextSize = 11,
 }, row)
 corner(btn, 6)
 stroke(btn, Theme.stroke, 1, 0.3)
 hoverScale(btn, 1.06)
 local ctrl = {}
 local function paint()
 btn.Text = listening and "..." or current.Name
 tween(btn, {
 BackgroundColor3 = listening and Theme.accentDim or Theme.panelAlt,
 TextColor3 = listening and Color3.fromRGB(255, 255, 255) or Theme.text,
 }, 0.16)
 end
 function ctrl:Get()
 return current
 end
 function ctrl:Set(key, silent)
 if typeof(key) == "string" then
 key = Enum.KeyCode[key]
 end
 if typeof(key) ~= "EnumItem" then
 return
 end
 current = key
 listening = false
 paint()
 if not silent and opts.Callback then
 opts.Callback(current)
 end
 end
 btn.MouseButton1Click:Connect(function()
 pressPunch(btn)
 listening = not listening
 paint()
 end)
 UserInputService.InputBegan:Connect(function(input)
 if not listening then
 return
 end
 if input.UserInputType ~= Enum.UserInputType.Keyboard then
 return
 end
 if input.KeyCode == Enum.KeyCode.Unknown or input.KeyCode == Enum.KeyCode.Escape then
 listening = false
 paint()
 return
 end
 ctrl:Set(input.KeyCode, false)
 end)
 paint()
 return ctrl
 end

 function api:ColorPicker(opts)
 opts = opts or {}
 local presets = opts.Presets or {
 { "Red", Color3.fromRGB(255, 72, 88) },
 { "Orange", Color3.fromRGB(255, 140, 64) },
 { "Gold", Color3.fromRGB(255, 204, 72) },
 { "Lime", Color3.fromRGB(140, 255, 90) },
 { "Green", Color3.fromRGB(52, 196, 120) },
 { "Cyan", Color3.fromRGB(80, 220, 230) },
 { "Blue", Color3.fromRGB(80, 140, 255) },
 { "Indigo", Color3.fromRGB(129, 140, 248) },
 { "Purple", Color3.fromRGB(168, 85, 247) },
 { "Magenta", Color3.fromRGB(232, 80, 200) },
 { "Pink", Color3.fromRGB(255, 130, 180) },
 { "White", Color3.fromRGB(240, 244, 255) },
 }
 local current = opts.Default or presets[1][2]
 local currentName = opts.DefaultName or "Custom"
 local row = mk("Frame", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, 0, 0, 92),
 LayoutOrder = nextOrder(),
 }, card)
 trackSearch((opts.Text or "Color") .. " purple red blue", row)

 local head = mk("Frame", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, 0, 0, 22),
 }, row)
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, -28, 1, 0),
 Font = Enum.Font.Code,
 Text = tostring(opts.Text or "Color"),
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, head)
 local preview = mk("Frame", {
 BackgroundColor3 = current,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, 0, 0.5, 0),
 Size = UDim2.fromOffset(18, 18),
 }, head)
 corner(preview, 9)
 stroke(preview, Color3.fromRGB(255, 255, 255), 1, 0.45)
 hoverScale(preview, 1.14)

 local nameLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(0, 22),
 Size = UDim2.new(1, 0, 0, 14),
 Font = Enum.Font.Code,
 Text = currentName,
 TextColor3 = Theme.textDim,
 TextSize = 10,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)

 local grid = mk("Frame", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(0, 40),
 Size = UDim2.new(1, 0, 0, 50),
 }, row)
 mk("UIGridLayout", {
 CellSize = UDim2.fromOffset(22, 22),
 CellPadding = UDim2.fromOffset(6, 6),
 FillDirectionMaxCells = 8,
 SortOrder = Enum.SortOrder.LayoutOrder,
 }, grid)

 local swatches = {}
 local function nearestName(color)
 local best, bestD = "Custom", 1e9
 for _, item in ipairs(presets) do
 local d = (item[2].R - color.R) ^ 2 + (item[2].G - color.G) ^ 2 + (item[2].B - color.B) ^ 2
 if d < bestD then
 bestD = d
 best = item[1]
 end
 end
 if bestD > 0.004 then
 return "Custom"
 end
 return best
 end

 local ctrl = {}
 local function sameColor(a, b)
 return math.abs(a.R - b.R) < 0.02 and math.abs(a.G - b.G) < 0.02 and math.abs(a.B - b.B) < 0.02
 end
 local function paintSwatches()
 for _, item in ipairs(swatches) do
 local on = sameColor(item.color, current)
 tween(item.stroke, {
 Transparency = on and 0.05 or 0.55,
 Color = on and Color3.fromRGB(255, 255, 255) or Theme.stroke,
 }, 0.16)
 end
 end
 function ctrl:Set(color, silent, name)
 if typeof(color) ~= "Color3" then
 return
 end
 current = color
 currentName = name or nearestName(color)
 tween(preview, { BackgroundColor3 = current }, 0.18)
 nameLabel.Text = currentName
 paintSwatches()
 if not silent and opts.Callback then
 opts.Callback(current, currentName)
 end
 end
 function ctrl:Get()
 return current, currentName
 end

 for i, item in ipairs(presets) do
 local btn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = item[2],
 BorderSizePixel = 0,
 Text = "",
 LayoutOrder = i,
 }, grid)
 corner(btn, 6)
 local s = stroke(btn, Theme.stroke, 1, 0.4)
 table.insert(swatches, { color = item[2], stroke = s })
 hoverScale(btn, 1.12)
 btn.MouseButton1Click:Connect(function()
 pressPunch(btn)
 ctrl:Set(item[2], false, item[1])
 end)
 end
 ctrl:Set(current, true, nearestName(current))
 return ctrl
 end

 function api:Dropdown(opts)
 opts = opts or {}
 local options = {}
 local rawOpts = opts.Options or opts.Values or opts.List or {}
 if type(rawOpts) == "table" then
 if #rawOpts > 0 then
 for _, v in ipairs(rawOpts) do
 table.insert(options, tostring(v))
 end
 else
 for k, v in pairs(rawOpts) do
 local s = type(v) == "string" and v ~= "" and v or (type(k) == "string" and k or "")
 if s ~= "" then
 table.insert(options, s)
 end
 end
 table.sort(options)
 end
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
 AutomaticSize = Enum.AutomaticSize.Y,
 LayoutOrder = nextOrder(),
 ZIndex = 8,
 }, card)
 trackSearch(opts.Text, row)

 mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, 0, 0, 16),
 Font = Enum.Font.Code,
 Text = tostring(opts.Text or "Select"),
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)

 local trigger = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 20),
 Size = UDim2.new(1, 0, 0, 30),
 Text = "",
 ZIndex = 9,
 }, row)
 corner(trigger, 6)
 local triggerStroke = stroke(trigger, Theme.stroke, 1, 0.35)

 local valueLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(10, 0),
 Size = UDim2.new(1, -28, 1, 0),
 Font = Enum.Font.Code,
 Text = value,
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 10,
 }, trigger)

 local chevron = mk("TextLabel", {
 BackgroundTransparency = 1,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, -8, 0.5, 0),
 Size = UDim2.fromOffset(14, 14),
 Font = Enum.Font.Code,
 Text = "v",
 TextColor3 = Theme.textDim,
 TextSize = 11,
 ZIndex = 10,
 }, trigger)

 local open = false
 local menu = mk("Frame", {
 Name = "DropdownMenu",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 52),
 Size = UDim2.new(1, 0, 0, 0),
 Visible = false,
 ZIndex = 40,
 ClipsDescendants = true,
 }, row)
 corner(menu, 6)
 stroke(menu, Theme.stroke, 1, 0.25)

 local list = mk("ScrollingFrame", {
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 Size = UDim2.fromScale(1, 1),
 ScrollBarThickness = 4,
 ScrollBarImageColor3 = Theme.accentDim,
 CanvasSize = UDim2.new(0, 0, 0, 0),
 AutomaticCanvasSize = Enum.AutomaticSize.Y,
 ZIndex = 41,
 }, menu)
 pad(list, 4, 4, 4, 4)
 mk("UIListLayout", {
 Padding = UDim.new(0, 2),
 SortOrder = Enum.SortOrder.LayoutOrder,
 }, list)

 local ctrl = {}
 local itemButtons = {}

 local function setValue(v, silent)
 value = tostring(v)
 valueLabel.Text = value
 for _, item in ipairs(itemButtons) do
 local selected = item.Name == value
 item.BackgroundColor3 = selected and Theme.tabHover or Theme.panelAlt
 item.TextColor3 = selected and Theme.text or Theme.textDim
 end
 if not silent and opts.Callback then
 opts.Callback(value)
 end
 end

 local function setOpen(state)
 state = state and true or false
 if state and activeDropdownClose and activeDropdownClose ~= setOpen then
 activeDropdownClose(false)
 end
 open = state
 if open then
 activeDropdownClose = setOpen
 else
 if activeDropdownClose == setOpen then
 activeDropdownClose = nil
 end
 end
 chevron.Text = open and "^" or "v"
 chevron.TextColor3 = open and Theme.accent or Theme.textDim
 triggerStroke.Color = open and Theme.accent or Theme.stroke
 local height = math.min(6, math.max(1, #options)) * 28 + 10
 menu.Size = UDim2.new(1, 0, 0, open and height or 0)
 menu.Visible = open
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
 local incoming = {}
 if type(listOpts) == "table" then
 if #listOpts > 0 then
 for _, v in ipairs(listOpts) do
 local s = tostring(v)
 if s ~= "" then
 table.insert(incoming, s)
 end
 end
 else
 for k, v in pairs(listOpts) do
 local s = type(v) == "string" and v ~= "" and v or (type(k) == "string" and k or "")
 if s ~= "" then
 table.insert(incoming, s)
 end
 end
 table.sort(incoming)
 end
 end
 table.clear(options)
 table.clear(itemButtons)
 for _, child in ipairs(list:GetChildren()) do
 if child:IsA("TextButton") then
 child:Destroy()
 end
 end
 for _, s in ipairs(incoming) do
 table.insert(options, s)
 end
 if #options == 0 then
 table.insert(options, "None")
 end
 for i, opt in ipairs(options) do
 local item = mk("TextButton", {
 Name = opt,
 AutoButtonColor = false,
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 26),
 Font = Enum.Font.Code,
 Text = "  " .. opt,
 TextColor3 = Theme.textDim,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 LayoutOrder = i,
 ZIndex = 42,
 }, list)
 corner(item, 4)
 item.MouseEnter:Connect(function()
 item.BackgroundColor3 = Theme.tabHover
 item.TextColor3 = Theme.text
 end)
 item.MouseLeave:Connect(function()
 local selected = item.Name == value
 item.BackgroundColor3 = selected and Theme.tabHover or Theme.panelAlt
 item.TextColor3 = selected and Theme.text or Theme.textDim
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
 setOpen(true)
 end
 end

 ctrl:SetOptions(options, true)

 trigger.MouseButton1Click:Connect(function()
 setOpen(not open)
 end)

 UserInputService.InputBegan:Connect(function(input)
 if not open then
 return
 end
 if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
 return
 end
 local p = UserInputService:GetMouseLocation()
 local inset = game:GetService("GuiService"):GetGuiInset()
 p = Vector2.new(p.X, p.Y - inset.Y)
 local function hit(gui)
 local pos, size = gui.AbsolutePosition, gui.AbsoluteSize
 return p.X >= pos.X and p.X <= pos.X + size.X and p.Y >= pos.Y and p.Y <= pos.Y + size.Y
 end
 if not hit(menu) and not hit(trigger) then
 setOpen(false)
 end
 end)

 row.Destroying:Connect(function()
 if activeDropdownClose == setOpen then
 activeDropdownClose = nil
 end
 end)

 return ctrl
 end

 return api
end

function Library.CreateWindow(opts)
 opts = opts or {}
 local title = tostring(opts.Title or "MythiOs")
 if title == "" then
  title = "MythiOs"
 end
 local subtitle = tostring(opts.Subtitle or "")
 local size = opts.Size or UDim2.fromOffset(760, 520)
 local toggleKeys = {}
 local function addToggleKey(key)
 if typeof(key) == "string" then
 key = Enum.KeyCode[key]
 end
 if typeof(key) == "EnumItem" then
 for _, existing in ipairs(toggleKeys) do
 if existing == key then
 return
 end
 end
 table.insert(toggleKeys, key)
 end
 end
 if opts.ToggleKeys then
 for _, key in ipairs(opts.ToggleKeys) do
 addToggleKey(key)
 end
 end
 addToggleKey(opts.ToggleKey)
 if #toggleKeys == 0 then
 addToggleKey(Enum.KeyCode.RightShift)
 end
 local showBoot = opts.Boot ~= false
 local unlockName = "PLUI_Toggle_" .. tostring(math.random(10000, 99999))
 local mouseUnlockName = unlockName .. "_Mouse"

 local connections = {}
 local function bind(sig)
 table.insert(connections, sig)
 return sig
 end

 local screenParent = parentGui()
 local screen = mk("ScreenGui", {
 Name = opts.Name or "PLUIWindow",
 ResetOnSpawn = false,
 ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
 DisplayOrder = opts.DisplayOrder or 120000,
 IgnoreGuiInset = true,
 Enabled = false,
 }, screenParent)
 local hintGui = mk("ScreenGui", {
 Name = (opts.Name or "PLUIWindow") .. "Hint",
 ResetOnSpawn = false,
 ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
 DisplayOrder = 25,
 IgnoreGuiInset = true,
 Enabled = true,
 }, screenParent)

 local root = mk("Frame", {
 Name = "Root",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(0.5, 0.5),
 Position = UDim2.new(0.5, 0, 0.5, 0),
 Size = size,
 ClipsDescendants = true,
 Visible = false,
 Active = true,
 ZIndex = 10,
 }, screen)
 corner(root, 12)
 -- optional thin border only — no outer glow/halo
 if opts.WindowGlow == true then
  stroke(root, Theme.accent, 2, 0.35)
 elseif opts.WindowStroke ~= false then
  stroke(root, Theme.stroke, 1, 0.55)
 end
 local openScale = mk("UIScale", { Name = "OpenScale", Scale = 1 }, root)

 -- hint chip (visible while menu closed)
 local hintLabel = mk("TextLabel", {
 Name = "Hint",
 BackgroundTransparency = 0.08,
 BackgroundColor3 = Theme.bg,
 AnchorPoint = Vector2.new(1, 0),
 Position = UDim2.new(1, -14, 0, 14),
 Size = UDim2.fromOffset(168, 26),
 Font = Enum.Font.Code,
 TextSize = 11,
 TextColor3 = Theme.text,
 ZIndex = 5,
 Text = title,
 Visible = true,
 Active = false,
 Selectable = false,
 }, hintGui)
 pcall(function()
 hintLabel.Interactable = false
 end)
 corner(hintLabel, 8)
 local hintStroke = stroke(hintLabel, Theme.accent, 1, 0.28)
 local function keyHintText()
 local names = {}
 for _, key in ipairs(toggleKeys) do
 table.insert(names, key.Name)
 end
 return title .. " · " .. table.concat(names, " / ")
 end
 local function refreshHint()
 hintLabel.Text = keyHintText()
 hintLabel.Size = UDim2.fromOffset(math.clamp(12 + #hintLabel.Text * 7, 118, 260), 26)
 end
 refreshHint()

 -- toast stack
 local banner = mk("Frame", {
 Name = "StatusBanner",
 AnchorPoint = Vector2.new(0.5, 0),
 Position = UDim2.new(0.5, 0, 0, 14),
 Size = UDim2.fromOffset(420, 58),
 BackgroundColor3 = Theme.panel,
 BorderSizePixel = 0,
 Visible = false,
 ZIndex = 90,
 }, screen)
 corner(banner, 14)
 local bannerStroke = stroke(banner, Theme.accent, 1, 0.25)
 local bannerBar = mk("Frame", {
 BackgroundColor3 = Theme.accent,
 BorderSizePixel = 0,
 Size = UDim2.new(0, 4, 1, -16),
 Position = UDim2.fromOffset(8, 8),
 ZIndex = 91,
 }, banner)
 corner(bannerBar, 2)
 local bannerBadge = mk("TextLabel", {
 BackgroundColor3 = Theme.accentDim,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(20, 10),
 Size = UDim2.fromOffset(54, 18),
 Font = Enum.Font.Code,
 Text = "SPEC",
 TextColor3 = Color3.fromRGB(255, 255, 255),
 TextSize = 10,
 ZIndex = 91,
 }, banner)
 corner(bannerBadge, 6)
 local bannerCount = mk("TextLabel", {
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0),
 Position = UDim2.new(1, -12, 0, 10),
 Size = UDim2.fromOffset(64, 18),
 Font = Enum.Font.Code,
 Text = "0",
 TextColor3 = Theme.text,
 TextSize = 10,
 ZIndex = 91,
 }, banner)
 corner(bannerCount, 6)
 local bannerTitle = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(20, 32),
 Size = UDim2.new(1, -32, 0, 18),
 Font = Enum.Font.Code,
 Text = "",
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 91,
 }, banner)
 local bannerBody = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(20, 48),
 Size = UDim2.new(1, -32, 0, 0),
 Font = Enum.Font.Code,
 Text = "",
 TextColor3 = Theme.textDim,
 TextSize = 11,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 Visible = false,
 ZIndex = 91,
 }, banner)

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
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 0),
 Size = UDim2.new(1, 0, 0, 44),
 ZIndex = 20,
 }, root)
 local headerLine = mk("Frame", {
 BackgroundColor3 = Theme.stroke,
 BackgroundTransparency = 0.35,
 BorderSizePixel = 0,
 Position = UDim2.new(0, 0, 1, -1),
 Size = UDim2.new(1, 0, 0, 1),
 ZIndex = 21,
 }, header)

 local headerBrand = makeBrand(header, 28, 22)
 headerBrand.Position = UDim2.fromOffset(12, 8)

 mk("TextLabel", {
 Name = "Title",
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(48, 4),
 Size = UDim2.new(1, -128, 0, 22),
 Font = Enum.Font.Code,
 Text = title,
 TextColor3 = Theme.text,
 TextSize = 14,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 22,
 }, header)

 local subtitleLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(48, 24),
 Size = UDim2.new(1, -128, 0, 14),
 Font = Enum.Font.Code,
 Text = subtitle,
 TextColor3 = Theme.textDim,
 TextSize = 11,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 22,
 }, header)

 local closeBtn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, -8, 0.5, 0),
 Size = UDim2.fromOffset(28, 28),
 Font = Enum.Font.Code,
 Text = "×",
 TextColor3 = Theme.textDim,
 TextSize = 16,
 ZIndex = 22,
 }, header)
 local minBtn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, -36, 0.5, 0),
 Size = UDim2.fromOffset(28, 28),
 Font = Enum.Font.Code,
 Text = "–",
 TextColor3 = Theme.textDim,
 TextSize = 16,
 ZIndex = 22,
 }, header)
 closeBtn.MouseEnter:Connect(function()
 tween(closeBtn, { TextColor3 = Theme.rose }, 0.12)
 end)
 closeBtn.MouseLeave:Connect(function()
 tween(closeBtn, { TextColor3 = Theme.textDim }, 0.16)
 end)
 minBtn.MouseEnter:Connect(function()
 tween(minBtn, { TextColor3 = Theme.text }, 0.12)
 end)
 minBtn.MouseLeave:Connect(function()
 tween(minBtn, { TextColor3 = Theme.textDim }, 0.16)
 end)

 -- body: sidebar + content
 local body = mk("Frame", {
 Name = "BodyRow",
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(0, 44),
 Size = UDim2.new(1, 0, 1, -70),
 ZIndex = 20,
 }, root)

 local sidebar = mk("Frame", {
 Name = "Sidebar",
 BackgroundColor3 = Theme.sidebar,
 BorderSizePixel = 0,
 Size = UDim2.new(0, 176, 1, 0),
 ClipsDescendants = true,
 }, body)
 local sideLine = mk("Frame", {
 BackgroundColor3 = Theme.stroke,
 BackgroundTransparency = 0.35,
 BorderSizePixel = 0,
 Position = UDim2.new(1, -1, 0, 0),
 Size = UDim2.new(0, 1, 1, 0),
 ZIndex = 3,
 }, sidebar)
 local sidebarNav = mk("ScrollingFrame", {
 Name = "Nav",
 BackgroundTransparency = 1,
 Size = UDim2.new(1, 0, 1, -62),
 CanvasSize = UDim2.new(0, 0, 0, 0),
 AutomaticCanvasSize = Enum.AutomaticSize.Y,
 ScrollBarThickness = 2,
 ScrollBarImageColor3 = Theme.accentDim,
 ZIndex = 2,
 }, sidebar)
 pad(sidebarNav, 10, 8, 10, 10)
 mk("UIListLayout", {
 Padding = UDim.new(0, 3),
 SortOrder = Enum.SortOrder.LayoutOrder,
 HorizontalAlignment = Enum.HorizontalAlignment.Center,
 }, sidebarNav)

 local profile = mk("Frame", {
 Name = "Profile",
 BackgroundTransparency = 1,
 AnchorPoint = Vector2.new(0, 1),
 Position = UDim2.new(0, 0, 1, 0),
 Size = UDim2.new(1, 0, 0, 62),
 ZIndex = 4,
 }, sidebar)
 mk("Frame", {
 BackgroundColor3 = Theme.stroke,
 BackgroundTransparency = 0.4,
 BorderSizePixel = 0,
 Size = UDim2.new(1, -20, 0, 1),
 Position = UDim2.fromOffset(10, 0),
 }, profile)
 local avatar = mk("ImageLabel", {
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(12, 14),
 Size = UDim2.fromOffset(34, 34),
 Image = "",
 ZIndex = 5,
 }, profile)
 corner(avatar, 17)
 task.spawn(function()
  local ok, url = pcall(function()
   return Players:GetUserThumbnailAsync(
    LocalPlayer.UserId,
    Enum.ThumbnailType.HeadShot,
    Enum.ThumbnailSize.Size48x48
   )
  end)
  if ok and avatar.Parent then
   avatar.Image = url
  end
 end)
 local profileName = LocalPlayer and (LocalPlayer.DisplayName or LocalPlayer.Name) or "Player"
 if profileName == "" then
  profileName = LocalPlayer.Name
 end
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(54, 14),
 Size = UDim2.new(1, -64, 0, 18),
 Font = Enum.Font.Code,
 Text = profileName,
 TextColor3 = Theme.text,
 TextSize = 12,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 5,
 }, profile)
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(54, 32),
 Size = UDim2.new(1, -64, 0, 16),
 Font = Enum.Font.Code,
 Text = "@" .. tostring(LocalPlayer.Name),
 TextColor3 = Theme.textDim,
 TextSize = 10,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 5,
 }, profile)

 local content = mk("Frame", {
 Name = "Content",
 BackgroundColor3 = Theme.panel,
 BorderSizePixel = 0,
 Position = UDim2.new(0, 176, 0, 0),
 Size = UDim2.new(1, -176, 1, 0),
 }, body)

 local pageTitle = mk("TextLabel", {
 Name = "PageTitle",
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(12, 8),
 Size = UDim2.new(0.55, 0, 0, 18),
 Font = Enum.Font.Code,
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
 Size = UDim2.fromOffset(158, 24),
 Font = Enum.Font.Code,
 PlaceholderText = "Search",
 PlaceholderColor3 = Theme.textDim,
 Text = "",
 TextColor3 = Theme.text,
 TextSize = 11,
 ClearTextOnFocus = false,
 Selectable = true,
 ZIndex = 6,
 }, content)
 corner(searchBox, 8)
 pad(searchBox, 0, 0, 10, 10)
 local searchStroke = stroke(searchBox, Theme.stroke, 1, 0.4)
 searchBox.Focused:Connect(function()
 tween(searchStroke, { Color = Theme.accent, Transparency = 0.08 }, 0.16)
 tween(searchBox, { BackgroundColor3 = Theme.tabIdle }, 0.16)
 end)
 searchBox.FocusLost:Connect(function()
 tween(searchStroke, { Color = Theme.stroke, Transparency = 0.4 }, 0.2)
 tween(searchBox, { BackgroundColor3 = Theme.panelAlt }, 0.2)
 end)

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
 ZIndex = 20,
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
 Font = Enum.Font.Code,
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
 Font = Enum.Font.Code,
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
 _restoreFrames = 0,
 _alive = true,
 Hint = hintLabel,
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

 function window:SetBanner(opts)
 opts = opts or {}
 local visible = opts.Visible == true
 banner.Visible = visible
 if not visible then
 return
 end
 local kind = tostring(opts.Kind or "spec")
 local tone = Theme.accent
 local badge = "SPEC"
 if kind == "staff" then
 tone = Theme.rose
 badge = "STAFF"
 elseif kind == "both" then
 tone = Theme.rose
 badge = "ALERT"
 end
 bannerStroke.Color = tone
 bannerBar.BackgroundColor3 = tone
 bannerBadge.BackgroundColor3 = tone
 bannerBadge.Text = badge
 local count = tonumber(opts.Count) or 0
 bannerCount.Text = count > 0 and (tostring(count) .. (count == 1 and " spec" or " spec")) or "—"
 bannerCount.Visible = kind ~= "staff"
 bannerTitle.Text = tostring(opts.Title or "")
 local body = tostring(opts.Body or "")
 if body ~= "" then
 bannerBody.Text = body
 bannerBody.Visible = true
 banner.Size = UDim2.fromOffset(420, 72)
 bannerBody.Size = UDim2.new(1, -32, 0, 16)
 else
 bannerBody.Visible = false
 banner.Size = UDim2.fromOffset(420, 58)
 end
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
 Font = Enum.Font.Code,
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
 if activeDropdownClose then
 pcall(activeDropdownClose, false)
 end
 for n, tabApi in pairs(window._tabs) do
 local on = n == name
 tween(tabApi.Button, {
 BackgroundColor3 = on and Color3.fromRGB(42, 32, 62) or Theme.tabIdle,
 BackgroundTransparency = on and 0 or 1,
 TextColor3 = on and Theme.text or Theme.textDim,
 }, 0.16)
 local mark = tabApi.Button:FindFirstChild("Sel")
 if mark then
 tween(mark, { BackgroundTransparency = on and 0 or 1 }, 0.16)
 end
 local pageScale = tabApi.Page:FindFirstChild("PageScale")
 if on then
 tabApi.Page.Visible = true
 if pageScale then
 pageScale.Scale = 0.96
 tween(pageScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
 end
 else
 tabApi.Page.Visible = false
 end
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
 BackgroundColor3 = Color3.fromRGB(42, 32, 62),
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 32),
 Font = Enum.Font.Code,
 Text = "  " .. name,
 TextColor3 = Theme.textDim,
 TextSize = 13,
 TextXAlignment = Enum.TextXAlignment.Left,
 LayoutOrder = order,
 }, sidebarNav)
 corner(btn, 8)
 local sel = mk("Frame", {
 Name = "Sel",
 BackgroundColor3 = Theme.accent,
 BorderSizePixel = 0,
 Size = UDim2.new(0, 3, 1, -10),
 Position = UDim2.fromOffset(3, 5),
 BackgroundTransparency = 1,
 ZIndex = 2,
 }, btn)
 corner(sel, 2)

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
 mk("UIScale", { Name = "PageScale", Scale = 1 }, page)
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

 function tabApi:Clear()
 for _, child in ipairs(page:GetChildren()) do
 if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
 child:Destroy()
 end
 end
 table.clear(self._sections)
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
 pressPunch(btn)
 selectTab(name)
 end)
 btn.MouseEnter:Connect(function()
 if window._active ~= name then
 tween(btn, { BackgroundTransparency = 0.35, BackgroundColor3 = Theme.tabHover, TextColor3 = Theme.text }, 0.14)
 end
 end)
 btn.MouseLeave:Connect(function()
 if window._active ~= name then
 tween(btn, { BackgroundTransparency = 1, TextColor3 = Theme.textDim }, 0.16)
 end
 end)

 self._tabs[name] = tabApi
 if not self._active then
 selectTab(name)
 end
 return tabApi
 end

 local function applyClosedMouse()
 pcall(function()
 screen.Enabled = false
 root.Visible = false
 game:GetService("GuiService").SelectedObject = nil
 local box = UserInputService:GetFocusedTextBox()
 if box then
 box:ReleaseFocus()
 end
 end)
 end

 local function mouseUnlockEnabled()
 if opts.UnlockMouseWhileOpen == false then
 return false
 end
 if type(opts.UnlockMouseWhileOpen) == "function" then
 local ok, want = pcall(opts.UnlockMouseWhileOpen)
 return ok and want == true
 end
 return true
 end

 local function stopMouseUnlock()
 pcall(function()
 RunService:UnbindFromRenderStep(mouseUnlockName)
 end)
 -- restore game mouse; never leave Modal / locked overlay behind
 pcall(function()
  if window._savedMouseBehavior ~= nil then
   UserInputService.MouseBehavior = window._savedMouseBehavior
  end
  if window._savedMouseIcon ~= nil then
   UserInputService.MouseIconEnabled = window._savedMouseIcon
  end
  window._savedMouseBehavior = nil
  window._savedMouseIcon = nil
 end)
 end

 local function startMouseUnlock()
 pcall(function()
  RunService:UnbindFromRenderStep(mouseUnlockName)
 end)
 if not mouseUnlockEnabled() then
 return
 end
 -- free cursor for UI clicks, but do not Modal-sink the whole game
 pcall(function()
  if window._savedMouseBehavior == nil then
   window._savedMouseBehavior = UserInputService.MouseBehavior
   window._savedMouseIcon = UserInputService.MouseIconEnabled
  end
  UserInputService.MouseBehavior = Enum.MouseBehavior.Default
  UserInputService.MouseIconEnabled = true
 end)
 -- only re-assert when something else re-locks the cursor (don't fight every frame)
 RunService:BindToRenderStep(mouseUnlockName, Enum.RenderPriority.Last.Value, function()
 if not window._alive or not window._open then
 return
 end
 if UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
  UserInputService.MouseBehavior = Enum.MouseBehavior.Default
 end
 if not UserInputService.MouseIconEnabled then
  UserInputService.MouseIconEnabled = true
 end
 end)
 end

 function window:IsOpen()
 return self._open == true
 end

 function window:SetHintVisible(visible)
 hintLabel.Visible = visible and true or false
 end

 function window:SetToggleKeys(keys)
 table.clear(toggleKeys)
 if typeof(keys) == "EnumItem" or typeof(keys) == "string" then
 addToggleKey(keys)
 else
 for _, key in ipairs(keys or {}) do
 addToggleKey(key)
 end
 end
 if #toggleKeys == 0 then
 addToggleKey(Enum.KeyCode.K)
 end
 refreshHint()
 if type(window.RebindToggle) == "function" then
 window:RebindToggle()
 end
 end

 function window:GetToggleKeys()
 local copy = {}
 for _, key in ipairs(toggleKeys) do
 table.insert(copy, key)
 end
 return copy
 end

 local setOpenGate = 0
 function window:SetOpen(visible)
 visible = visible and true or false
 local now = os.clock()
 if visible and now - setOpenGate < 0.12 then
 return
 end
 if visible then
 setOpenGate = now
 end
 self._open = visible
 local hideHint = visible
 if not visible and opts.HintVisible then
 local ok, show = pcall(opts.HintVisible)
 hideHint = not (ok and show)
 elseif not visible then
 hideHint = false
 end
 hintLabel.Visible = not hideHint
 if visible then
		screen.Enabled = true
		root.Visible = true
 startMouseUnlock()
 if not root:GetAttribute("Moved") then
 root.Position = UDim2.fromScale(0.5, 0.48)
 tween(root, { Position = UDim2.fromScale(0.5, 0.5) }, 0.28, Enum.EasingStyle.Quart)
 end
 pcall(function()
 local box = UserInputService:GetFocusedTextBox()
 if box then
 box:ReleaseFocus()
 end
 end)
 openScale.Scale = 0.88
 tween(openScale, { Scale = 1 }, 0.34, Enum.EasingStyle.Back)
 tween(hintLabel, { TextTransparency = 1, BackgroundTransparency = 1 }, 0.12)
 else
 stopMouseUnlock()
 applyClosedMouse()
 hintLabel.TextTransparency = 0
 hintLabel.BackgroundTransparency = 0.08
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
 stopMouseUnlock()
 pcall(function()
 ContextActionService:UnbindAction(unlockName .. "_Toggle")
 end)
 applyClosedMouse()
 for _, c in ipairs(connections) do
 pcall(function()
 c:Disconnect()
 end)
 end
 table.clear(connections)
 if screen then
 screen:Destroy()
 end
 if hintGui then
 hintGui:Destroy()
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

 -- resize grip (bottom-right)
 if opts.Resizable ~= false then
  local minW = tonumber(opts.MinWidth) or 420
  local minH = tonumber(opts.MinHeight) or 320
  local maxW = tonumber(opts.MaxWidth) or 1100
  local maxH = tonumber(opts.MaxHeight) or 800
  local grip = mk("TextButton", {
   Name = "ResizeGrip",
   AutoButtonColor = false,
   BackgroundTransparency = 1,
   BorderSizePixel = 0,
   AnchorPoint = Vector2.new(1, 1),
   Position = UDim2.new(1, -2, 1, -2),
   Size = UDim2.fromOffset(18, 18),
   Text = "",
   ZIndex = 80,
  }, root)
  -- grip ticks
  for i = 0, 2 do
   mk("Frame", {
    BackgroundColor3 = Theme.textDim,
    BackgroundTransparency = 0.35,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -3 - i * 4, 1, -3),
    Size = UDim2.fromOffset(10 - i * 2, 2),
    Rotation = -45,
    ZIndex = 81,
   }, grip)
  end
  local resizing = false
  local resizeStart = Vector2.zero
  local startSize = Vector2.zero
  grip.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    resizing = true
    resizeStart = UserInputService:GetMouseLocation()
    startSize = Vector2.new(root.AbsoluteSize.X, root.AbsoluteSize.Y)
   end
  end)
  bind(UserInputService.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    resizing = false
   end
  end))
  bind(RunService.RenderStepped:Connect(function()
   if not resizing or not window._open then
    return
   end
   local m = UserInputService:GetMouseLocation()
   local d = m - resizeStart
   local w = math.clamp(startSize.X + d.X, minW, maxW)
   local h = math.clamp(startSize.Y + d.Y, minH, maxH)
   root.Size = UDim2.fromOffset(math.floor(w + 0.5), math.floor(h + 0.5))
  end))
  function window:SetSize(w, h)
   w = math.clamp(tonumber(w) or root.AbsoluteSize.X, minW, maxW)
   h = math.clamp(tonumber(h) or root.AbsoluteSize.Y, minH, maxH)
   root.Size = UDim2.fromOffset(w, h)
  end
  function window:GetSize()
   return root.AbsoluteSize.X, root.AbsoluteSize.Y
  end
 end

 local lastToggleAt = 0
 local function isToggleKey(code)
 for _, key in ipairs(toggleKeys) do
 if code == key then
 return true
 end
 end
 return false
 end
 local function handleTogglePress()
 if not window._alive then
 return
 end
 local now = os.clock()
 if now - lastToggleAt < 0.12 then
 return
 end
 lastToggleAt = now
 pcall(function()
 local box = UserInputService:GetFocusedTextBox()
 if box then
 box:ReleaseFocus()
 end
 end)
 window:Toggle()
 end
 function window:RebindToggle()
 local actionName = unlockName .. "_Toggle"
 pcall(function()
 ContextActionService:UnbindAction(actionName)
 end)
 if #toggleKeys == 0 then
 return
 end
 pcall(function()
 ContextActionService:BindActionAtPriority(
 actionName,
 function(_, state)
 if state == Enum.UserInputState.Begin then
 handleTogglePress()
 end
 -- Pass so the key is not eaten from the game
 return Enum.ContextActionResult.Pass
 end,
 false,
 4000,
 table.unpack(toggleKeys)
 )
 end)
 end
 window:RebindToggle()
 bind(UserInputService.InputBegan:Connect(function(input)
 if not window._alive then
 return
 end
 if input.UserInputType ~= Enum.UserInputType.Keyboard then
 return
 end
 if isToggleKey(input.KeyCode) then
 handleTogglePress()
 end
 end))

 local function hideWindow()
 if opts.OnClose then
 opts.OnClose()
 else
 window:SetOpen(false)
 end
 end
 closeBtn.MouseButton1Click:Connect(hideWindow)
 minBtn.MouseButton1Click:Connect(function()
 window:SetOpen(false)
 end)


 local function playBootThenOpen()
 screen.Enabled = true
 root.Visible = false
 local overlay = mk("Frame", {
 Name = "Boot",
 Size = UDim2.fromScale(1, 1),
 BackgroundColor3 = Color3.fromRGB(0, 0, 0),
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
 local badge = makeBrand(card, 42, 402)
 badge.AnchorPoint = Vector2.new(0.5, 0)
 badge.Position = UDim2.new(0.5, 0, 0, 28)
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(16, 80),
 Size = UDim2.new(1, -32, 0, 24),
 Font = Enum.Font.Code,
 TextSize = 18,
 TextColor3 = Theme.text,
 Text = title,
 ZIndex = 402,
 }, card)
 local bootSub = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(16, 104),
 Size = UDim2.new(1, -32, 0, 16),
 Font = Enum.Font.Code,
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

pcall(function()
 if typeof(getgenv) == "function" then
 getgenv().MythiOs = Library
 end
end)

return Library
