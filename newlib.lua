--[[
 MythiOs UI Library V5
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local function sanitizeConfigName(name)
 name = tostring(name or ""):lower():gsub("%s+", "_"):gsub("[^%w%-%_]", "")
 name = string.sub(name, 1, 32)
 if name == "" or name == "_meta" then
  return "default"
 end
 return name
end

local function sanitizeFolderPart(name)
 name = tostring(name or "ui"):gsub("[^%w%-%_]", "")
 name = string.sub(name, 1, 48)
 if name == "" then
  return "ui"
 end
 return name
end

local function ensureFolders(path)
 if type(makefolder) ~= "function" then
  return
 end
 local built = ""
 for part in string.gmatch(path, "[^/]+") do
  built = built == "" and part or (built .. "/" .. part)
  pcall(makefolder, built)
 end
end

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
   Font = Enum.Font.Gotham,
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

local function makeSection(host, title, ctx, style)
 ctx = ctx or {}
 style = style or {}
 local bindFlag = ctx.BindFlag
 if type(ctx) == "function" then
  bindFlag = ctx
  ctx = { BindFlag = bindFlag }
 end
 local flat = style.Flat == true
 local card = mk("Frame", {
 BackgroundColor3 = flat and Theme.bg or Theme.panel,
 BackgroundTransparency = flat and 1 or 0,
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 0),
 AutomaticSize = Enum.AutomaticSize.Y,
 }, host)
 if not flat then
  corner(card, 10)
  local cardStroke = stroke(card, Theme.stroke, 1, 0.5)
  pad(card, 18, 18, 18, 18)
  card.MouseEnter:Connect(function()
   tween(cardStroke, { Color = Theme.accentDim, Transparency = 0.35 }, 0.16)
  end)
  card.MouseLeave:Connect(function()
   tween(cardStroke, { Color = Theme.stroke, Transparency = 0.55 }, 0.2)
  end)
 else
  pad(card, style.PadTop or 4, style.PadBottom or 8, style.PadLeft or 0, style.PadRight or 0)
 end

 local list = mk("UIListLayout", {
 Padding = UDim.new(0, 14),
 SortOrder = Enum.SortOrder.LayoutOrder,
 }, card)

 if not flat and title and title ~= "" then
  local head = mk("Frame", {
   BackgroundTransparency = 1,
   Size = UDim2.new(1, 0, 0, 24),
   LayoutOrder = 0,
  }, card)

  local accentBar = mk("Frame", {
   BackgroundColor3 = Theme.accent,
   BorderSizePixel = 0,
   Size = UDim2.fromOffset(3, 16),
   Position = UDim2.fromOffset(0, 3),
  }, head)
  corner(accentBar, 2)

  mk("TextLabel", {
   BackgroundTransparency = 1,
   Position = UDim2.fromOffset(12, 0),
   Size = UDim2.new(1, -12, 1, 0),
   Font = Enum.Font.GothamBold,
   Text = title or "Section",
   TextColor3 = Theme.text,
   TextSize = 14,
   TextXAlignment = Enum.TextXAlignment.Left,
  }, head)
 end

 local order = 0
 local api = { Instance = card, _items = {} }
 local function openSettings(settingsOpts, anchor)
  if ctx.OpenSettings then
   ctx.OpenSettings(settingsOpts, anchor)
  end
 end

 local function attachSettings(row, ctrl, settings)
  if type(settings) ~= "table" or type(settings.Build) ~= "function" then
   return 0
  end
  -- layout from right: [gear][swatch?][gap][checkbox]
  local hasColor = settings.Color ~= nil or type(settings.GetColor) == "function"
  local swatchRight = 30 -- left of 22px checkbox + 8px gap
  local gearRight = hasColor and 54 or 30 -- left of swatch or checkbox

  local gear = mk("TextButton", {
   AutoButtonColor = false,
   BackgroundTransparency = 1,
   BorderSizePixel = 0,
   AnchorPoint = Vector2.new(1, 0.5),
   Position = UDim2.new(1, -gearRight, 0.5, 0),
   Size = UDim2.fromOffset(20, 20),
   Font = Enum.Font.GothamBold,
   Text = "⚙",
   TextColor3 = Theme.textDim,
   TextSize = 13,
   ZIndex = 5,
  }, row)
  hoverScale(gear, 1.12)
  gear.MouseEnter:Connect(function()
   tween(gear, { TextColor3 = Theme.accent }, 0.12)
  end)
  gear.MouseLeave:Connect(function()
   tween(gear, { TextColor3 = Theme.textDim }, 0.16)
  end)

  local swatch
  if hasColor then
   local initial = settings.Color
   if type(settings.GetColor) == "function" then
    local ok, c = pcall(settings.GetColor)
    if ok and typeof(c) == "Color3" then
     initial = c
    end
   end
   if typeof(initial) ~= "Color3" then
    initial = Theme.accent
   end
   swatch = mk("TextButton", {
    AutoButtonColor = false,
    BackgroundColor3 = initial,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -swatchRight, 0.5, 0),
    Size = UDim2.fromOffset(16, 16),
    Text = "",
    ZIndex = 5,
   }, row)
   corner(swatch, 4)
   stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.55)
   hoverScale(swatch, 1.1)
   function ctrl:SetPreviewColor(c)
    if typeof(c) == "Color3" and swatch then
     tween(swatch, { BackgroundColor3 = c }, 0.16)
    end
   end
   swatch.MouseButton1Click:Connect(function()
    pressPunch(swatch)
    openSettings(settings, gear)
   end)
  end

  gear.MouseButton1Click:Connect(function()
   pressPunch(gear)
   openSettings(settings, gear)
  end)
  -- extra width beyond the checkbox column
  return hasColor and 50 or 28
 end

 local function nextOrder()
 order += 1
 return order
 end

 local function trackSearch(text, root)
 table.insert(api._items, { text = string.lower(tostring(text or "")), root = root })
 end

 local function attachFlag(ctrl, flag)
  if type(flag) == "string" and flag ~= "" and type(bindFlag) == "function" and type(ctrl) == "table" then
   ctrl.Flag = flag
   bindFlag(flag, ctrl)
  end
  return ctrl
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
 Size = UDim2.new(1, 0, 0, 38),
 LayoutOrder = nextOrder(),
 }, card)
 trackSearch(opts.Text, row)

 local on = opts.Default == true
 local accent = opts.Accent or Theme.accent
 local ctrl = {
 Flag = opts.Flag,
 Get = function()
 return on
 end,
 }

 local settingsExtra = attachSettings(row, ctrl, opts.Settings)
 local labelRight = 56 + settingsExtra

 mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, -labelRight, 1, 0),
 Font = Enum.Font.Gotham,
 Text = tostring(opts.Text or "Toggle"),
 TextColor3 = Theme.text,
 TextSize = 13,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)

 local box = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = on and accent or Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, 0, 0.5, 0),
 Size = UDim2.fromOffset(22, 22),
 Font = Enum.Font.Gotham,
 Text = on and "✓" or "",
 TextColor3 = Color3.fromRGB(255, 255, 255),
 TextSize = 13,
 ZIndex = 5,
 }, row)
 corner(box, 6)
 local boxStroke = stroke(box, on and accent or Theme.stroke, 1, on and 0.1 or 0.35)

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
 return attachFlag(ctrl, opts.Flag)
 end

 function api:Button(opts)
 opts = opts or {}
 local btn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 38),
 Font = Enum.Font.GothamBold,
 Text = tostring(opts.Text or "Button"),
 TextColor3 = opts.Danger and Theme.rose or Theme.accent,
 TextSize = 13,
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
 Size = UDim2.new(1, 0, 0, 54),
 LayoutOrder = nextOrder(),
 }, card)
 trackSearch(opts.Text, row)

 local title = mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, -56, 0, 18),
 Font = Enum.Font.Gotham,
 Text = tostring(opts.Text or "Slider"),
 TextColor3 = Theme.text,
 TextSize = 13,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)
 local valLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 AnchorPoint = Vector2.new(1, 0),
 Position = UDim2.new(1, 0, 0, 0),
 Size = UDim2.fromOffset(48, 16),
 Font = Enum.Font.Gotham,
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
 return attachFlag(ctrl, opts.Flag)
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
 Font = Enum.Font.Gotham,
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
 return attachFlag(ctrl, opts.Flag)
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
 Size = UDim2.new(1, 0, 0, 36),
 LayoutOrder = nextOrder(),
 }, card)
 trackSearch(opts.Text, row)
 mk("TextLabel", {
 BackgroundTransparency = 1,
 Size = UDim2.new(1, -96, 1, 0),
 Font = Enum.Font.Gotham,
 Text = tostring(opts.Text or "Keybind"),
 TextColor3 = Theme.text,
 TextSize = 13,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, row)
 local btn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, 0, 0.5, 0),
 Size = UDim2.fromOffset(90, 28),
 Font = Enum.Font.Gotham,
 Text = current.Name,
 TextColor3 = Theme.text,
 TextSize = 12,
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
 return attachFlag(ctrl, opts.Flag)
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 return current
 end
 function ctrl:GetName()
 return currentName
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
 return attachFlag(ctrl, opts.Flag)
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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

 return attachFlag(ctrl, opts.Flag)
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
 local size = opts.Size or UDim2.fromOffset(840, 560)
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
 addToggleKey(Enum.KeyCode.RightControl)
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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
 Font = Enum.Font.Gotham,
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

 -- header (Kompile-style: brand + title / subtitle + search)
 local header = mk("Frame", {
 Name = "Header",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 0),
 Size = UDim2.new(1, 0, 0, 48),
 ZIndex = 20,
 }, root)

 local headerBrand = makeBrand(header, 30, 22)
 headerBrand.Position = UDim2.fromOffset(14, 9)

 local titleLabel = mk("TextLabel", {
 Name = "Title",
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(52, 0),
 Size = UDim2.new(0.5, -60, 1, 0),
 Font = Enum.Font.GothamBold,
 Text = title,
 TextColor3 = Theme.text,
 TextSize = 15,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 ZIndex = 22,
 }, header)

 local subtitleLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(52, 0),
 Size = UDim2.new(0.5, -60, 1, 0),
 Font = Enum.Font.Gotham,
 Text = subtitle ~= "" and ("/ " .. subtitle) or "",
 TextColor3 = Theme.textDim,
 TextSize = 14,
 TextXAlignment = Enum.TextXAlignment.Left,
 TextTruncate = Enum.TextTruncate.AtEnd,
 Visible = false,
 ZIndex = 22,
 }, header)
 -- place "/ subtitle" right after measured title text
 task.defer(function()
  if not titleLabel.Parent then
   return
  end
  local tw = titleLabel.TextBounds.X
  subtitleLabel.Position = UDim2.fromOffset(52 + tw + 6, 0)
  subtitleLabel.Visible = subtitle ~= ""
 end)

 local closeBtn = mk("TextButton", {
 AutoButtonColor = false,
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, -10, 0.5, 0),
 Size = UDim2.fromOffset(28, 28),
 Font = Enum.Font.Gotham,
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
 Position = UDim2.new(1, -40, 0.5, 0),
 Size = UDim2.fromOffset(28, 28),
 Font = Enum.Font.Gotham,
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

 local searchBox = mk("TextBox", {
 Name = "Search",
 BackgroundColor3 = Theme.panelAlt,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(1, 0.5),
 Position = UDim2.new(1, -76, 0.5, 0),
 Size = UDim2.fromOffset(168, 28),
 Font = Enum.Font.Gotham,
 PlaceholderText = "Search",
 PlaceholderColor3 = Theme.textDim,
 Text = "",
 TextColor3 = Theme.text,
 TextSize = 12,
 ClearTextOnFocus = false,
 Selectable = true,
 ZIndex = 22,
 }, header)
 corner(searchBox, 8)
 pad(searchBox, 0, 0, 12, 12)
 local searchStroke = stroke(searchBox, Theme.stroke, 1, 0.4)
 searchBox.Focused:Connect(function()
 tween(searchStroke, { Color = Theme.accent, Transparency = 0.08 }, 0.16)
 tween(searchBox, { BackgroundColor3 = Theme.tabIdle }, 0.16)
 end)
 searchBox.FocusLost:Connect(function()
 tween(searchStroke, { Color = Theme.stroke, Transparency = 0.4 }, 0.2)
 tween(searchBox, { BackgroundColor3 = Theme.panelAlt }, 0.2)
 end)

 -- horizontal tab bar
 local tabBar = mk("Frame", {
 Name = "TabBar",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 48),
 Size = UDim2.new(1, 0, 0, 40),
 ZIndex = 20,
 }, root)
 mk("Frame", {
 BackgroundColor3 = Theme.stroke,
 BackgroundTransparency = 0.4,
 BorderSizePixel = 0,
 Position = UDim2.new(0, 0, 1, -1),
 Size = UDim2.new(1, 0, 0, 1),
 ZIndex = 21,
 }, tabBar)
 local sidebarNav = mk("ScrollingFrame", {
 Name = "Nav",
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(10, 0),
 Size = UDim2.new(1, -20, 1, 0),
 CanvasSize = UDim2.new(0, 0, 0, 0),
 AutomaticCanvasSize = Enum.AutomaticSize.X,
 ScrollBarThickness = 0,
 ScrollingDirection = Enum.ScrollingDirection.X,
 ZIndex = 22,
 }, tabBar)
 mk("UIListLayout", {
 FillDirection = Enum.FillDirection.Horizontal,
 Padding = UDim.new(0, 4),
 SortOrder = Enum.SortOrder.LayoutOrder,
 VerticalAlignment = Enum.VerticalAlignment.Center,
 }, sidebarNav)

 -- full-width content (no sidebar)
 local content = mk("Frame", {
 Name = "Content",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(0, 88),
 Size = UDim2.new(1, 0, 1, -116),
 ZIndex = 20,
 }, root)

 local pageTitle = mk("TextLabel", {
 Name = "PageTitle",
 BackgroundTransparency = 1,
 Visible = false,
 Size = UDim2.fromOffset(0, 0),
 Text = "",
 }, content)

 local pagesFolder = mk("Frame", {
 Name = "Pages",
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 Position = UDim2.fromOffset(16, 12),
 Size = UDim2.new(1, -32, 1, -20),
 ClipsDescendants = true,
 }, content)

 -- footer
 local footer = mk("Frame", {
 Name = "Footer",
 BackgroundColor3 = Theme.bg,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(0, 1),
 Position = UDim2.new(0, 0, 1, 0),
 Size = UDim2.new(1, 0, 0, 28),
 ZIndex = 20,
 }, root)
 mk("Frame", {
 BackgroundColor3 = Theme.stroke,
 BackgroundTransparency = 0.45,
 BorderSizePixel = 0,
 Size = UDim2.new(1, 0, 0, 1),
 }, footer)
 local footerLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 Position = UDim2.fromOffset(14, 0),
 Size = UDim2.new(0.7, 0, 1, 0),
 Font = Enum.Font.Gotham,
 Text = "Ready",
 TextColor3 = Theme.textDim,
 TextSize = 11,
 TextXAlignment = Enum.TextXAlignment.Left,
 }, footer)
 local pulseLabel = mk("TextLabel", {
 BackgroundTransparency = 1,
 AnchorPoint = Vector2.new(1, 0),
 Position = UDim2.new(1, -14, 0, 0),
 Size = UDim2.new(0.28, 0, 1, 0),
 Font = Enum.Font.Gotham,
 Text = "",
 TextColor3 = Theme.cyan,
 TextSize = 11,
 TextXAlignment = Enum.TextXAlignment.Right,
 }, footer)

 local configId = sanitizeFolderPart(opts.ConfigId or opts.Name or title)
 local placeKey = tostring(opts.PlaceId or game.PlaceId or 0)
 local configRoot = string.format("MythiOs/configs/%s/%s", placeKey, configId)
 local controls = {}
 local configUi = {
  selected = "default",
  built = false,
 }

 local window = {
 Screen = screen,
 Root = root,
 Theme = Theme,
 _tabs = {},
 _active = nil,
 _flags = {},
 _controls = controls,
 _configRoot = configRoot,
 _configId = configId,
 _placeKey = placeKey,
 _searchables = {},
 _open = false,
 _savedMouseBehavior = nil,
 _savedMouseIcon = nil,
 _restoreFrames = 0,
 _alive = true,
 Hint = hintLabel,
 }

 function window.BindFlag(flag, ctrl)
  if type(flag) ~= "string" or flag == "" or type(ctrl) ~= "table" then
   return
  end
  controls[flag] = ctrl
  if type(ctrl.Get) == "function" then
   local ok, value = pcall(function()
    return ctrl:Get()
   end)
   if ok then
    window._flags[flag] = value
   end
  end
 end

 local settingsHost = nil
 local sectionCtx

 function window:CloseSettings()
  if settingsHost and settingsHost.Parent then
   settingsHost:Destroy()
  end
  settingsHost = nil
 end

 function window:OpenSettings(settings, anchor)
  settings = settings or {}
  if type(settings.Build) ~= "function" then
   return
  end
  self:CloseSettings()

  local width = tonumber(settings.Width) or 280
  local panelTitle = tostring(settings.Title or "Settings")
  local holder = mk("Frame", {
   Name = "SettingsPopup",
   BackgroundColor3 = Theme.panel,
   BorderSizePixel = 0,
   Size = UDim2.fromOffset(width, 0),
   AutomaticSize = Enum.AutomaticSize.Y,
   ZIndex = 80,
   Active = true,
  }, screen)
  corner(holder, 12)
  stroke(holder, Theme.stroke, 1, 0.35)
  local popScale = mk("UIScale", { Scale = 0.92 }, holder)

  local header = mk("Frame", {
   BackgroundTransparency = 1,
   Size = UDim2.new(1, 0, 0, 36),
   ZIndex = 81,
  }, holder)
  mk("TextLabel", {
   BackgroundTransparency = 1,
   Position = UDim2.fromOffset(14, 0),
   Size = UDim2.new(1, -44, 1, 0),
   Font = Enum.Font.GothamBold,
   Text = panelTitle,
   TextColor3 = Theme.text,
   TextSize = 14,
   TextXAlignment = Enum.TextXAlignment.Left,
   ZIndex = 82,
  }, header)
  local closePop = mk("TextButton", {
   AutoButtonColor = false,
   BackgroundTransparency = 1,
   AnchorPoint = Vector2.new(1, 0.5),
   Position = UDim2.new(1, -8, 0.5, 0),
   Size = UDim2.fromOffset(28, 28),
   Font = Enum.Font.Gotham,
   Text = "×",
   TextColor3 = Theme.textDim,
   TextSize = 16,
   ZIndex = 82,
  }, header)
  closePop.MouseEnter:Connect(function()
   tween(closePop, { TextColor3 = Theme.rose }, 0.12)
  end)
  closePop.MouseLeave:Connect(function()
   tween(closePop, { TextColor3 = Theme.textDim }, 0.16)
  end)
  closePop.MouseButton1Click:Connect(function()
   window:CloseSettings()
  end)

  mk("Frame", {
   BackgroundColor3 = Theme.stroke,
   BackgroundTransparency = 0.45,
   BorderSizePixel = 0,
   Position = UDim2.fromOffset(12, 36),
   Size = UDim2.new(1, -24, 0, 1),
   ZIndex = 81,
  }, holder)

  local body = mk("Frame", {
   BackgroundTransparency = 1,
   Position = UDim2.fromOffset(12, 44),
   Size = UDim2.new(1, -24, 0, 0),
   AutomaticSize = Enum.AutomaticSize.Y,
   ZIndex = 81,
  }, holder)
  local bodySec = makeSection(body, "", sectionCtx, { Flat = true, PadTop = 4, PadBottom = 12 })
  pcall(function()
   settings.Build(bodySec)
  end)

  local function placePopup()
   local gap = 12
   local rootPos = root.AbsolutePosition
   local rootSize = root.AbsoluteSize
   local cam = workspace.CurrentCamera
   local view = cam and cam.ViewportSize or Vector2.new(1280, 720)
   local h = math.max(holder.AbsoluteSize.Y, 120)
   local x = rootPos.X + rootSize.X + gap
   local y = rootPos.Y + 48
   if typeof(anchor) == "Instance" and anchor.AbsolutePosition then
    y = anchor.AbsolutePosition.Y - 8
   end
   if x + width > view.X - 8 then
    x = math.max(8, rootPos.X - width - gap)
   end
   if y + h > view.Y - 8 then
    y = math.max(8, view.Y - h - 8)
   end
   if y < 8 then
    y = 8
   end
   holder.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
  end

  settingsHost = holder
  task.defer(placePopup)
  holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(placePopup)
  tween(popScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)

  -- drag header
  local draggingPop = false
  local dragStart, startPos
  header.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    draggingPop = true
    dragStart = input.Position
    startPos = holder.Position
   end
  end)
  UserInputService.InputChanged:Connect(function(input)
   if not draggingPop then
    return
   end
   if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
    local d = input.Position - dragStart
    holder.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
   end
  end)
  UserInputService.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
    draggingPop = false
   end
  end)
 end

 sectionCtx = {
  BindFlag = window.BindFlag,
  OpenSettings = function(settings, anchor)
   window:OpenSettings(settings, anchor)
  end,
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
 subtitle = tostring(text or "")
 subtitleLabel.Text = subtitle ~= "" and ("/ " .. subtitle) or ""
 subtitleLabel.Visible = subtitle ~= ""
 task.defer(function()
  if titleLabel.Parent then
   subtitleLabel.Position = UDim2.fromOffset(52 + titleLabel.TextBounds.X + 6, 0)
  end
 end)
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
 local ctrl = controls[flag]
 if ctrl and type(ctrl.Set) == "function" then
  pcall(function()
   ctrl:Set(value, false)
  end)
 end
 end

 function window:GetFlag(flag)
 local ctrl = controls[flag]
 if ctrl and type(ctrl.Get) == "function" then
  local ok, value = pcall(function()
   return ctrl:Get()
  end)
  if ok then
   return value
  end
 end
 return self._flags[flag]
 end

 local function encodeValue(v)
  local t = typeof(v)
  if t == "Color3" then
   return {
    __t = "Color3",
    r = math.floor(v.R * 255 + 0.5),
    g = math.floor(v.G * 255 + 0.5),
    b = math.floor(v.B * 255 + 0.5),
   }
  end
  if t == "EnumItem" then
   return { __t = "KeyCode", name = v.Name }
  end
  if t == "boolean" or t == "number" or t == "string" then
   return v
  end
  return nil
 end

 local function decodeValue(v)
  if type(v) ~= "table" or type(v.__t) ~= "string" then
   return v
  end
  if v.__t == "Color3" then
   return Color3.fromRGB(tonumber(v.r) or 255, tonumber(v.g) or 255, tonumber(v.b) or 255)
  end
  if v.__t == "KeyCode" then
   return Enum.KeyCode[tostring(v.name)] or Enum.KeyCode.RightControl
  end
  return v
 end

 local function metaPath()
  return configRoot .. "/_meta.json"
 end

 local function configPath(name)
  return configRoot .. "/" .. sanitizeConfigName(name) .. ".json"
 end

 local function readJson(path)
  if type(readfile) ~= "function" or type(isfile) ~= "function" then
   return nil
  end
  local okFile, exists = pcall(isfile, path)
  if not okFile or not exists then
   return nil
  end
  local ok, raw = pcall(readfile, path)
  if not ok or type(raw) ~= "string" or raw == "" then
   return nil
  end
  local dOk, data = pcall(function()
   return HttpService:JSONDecode(raw)
  end)
  if dOk and type(data) == "table" then
   return data
  end
  return nil
 end

 local function writeJson(path, data)
  if type(writefile) ~= "function" then
   return false, "writefile unavailable"
  end
  ensureFolders(configRoot)
  local ok, encoded = pcall(function()
   return HttpService:JSONEncode(data)
  end)
  if not ok or type(encoded) ~= "string" then
   return false, "encode failed"
  end
  local wOk, err = pcall(writefile, path, encoded)
  if not wOk then
   return false, tostring(err)
  end
  return true
 end

 local function readMeta()
  local meta = readJson(metaPath()) or {}
  if type(meta.autoload) ~= "string" then
   meta.autoload = ""
  end
  return meta
 end

 local function writeMeta(meta)
  return writeJson(metaPath(), meta or readMeta())
 end

 function window:GetConfigRoot()
  return configRoot
 end

 function window:ListConfigs()
  local names = {}
  local seen = {}
  if type(listfiles) == "function" then
   local ok, files = pcall(listfiles, configRoot)
   if ok and type(files) == "table" then
    for _, path in ipairs(files) do
     local file = tostring(path):gsub("\\", "/")
     local base = string.match(file, "([^/]+)$") or file
     if base ~= "_meta.json" and string.sub(base, -5) == ".json" then
      local name = sanitizeConfigName(string.sub(base, 1, #base - 5))
      if not seen[name] then
       seen[name] = true
       table.insert(names, name)
      end
     end
    end
   end
  end
  if #names == 0 and type(isfile) == "function" then
   local ok, exists = pcall(isfile, configPath("default"))
   if ok and exists then
    table.insert(names, "default")
   end
  end
  table.sort(names)
  return names
 end

 function window:GetAutoload()
  local meta = readMeta()
  return tostring(meta.autoload or "")
 end

 function window:SetAutoload(name)
  local meta = readMeta()
  if name == nil or name == false or name == "" then
   meta.autoload = ""
  else
   meta.autoload = sanitizeConfigName(name)
  end
  local ok, err = writeMeta(meta)
  return ok, err
 end

 local function isInternalFlag(flag)
  return type(flag) == "string" and string.sub(flag, 1, 10) == "__mythios_"
 end

 function window:CollectFlags()
  local out = {}
  for flag, ctrl in pairs(controls) do
   if not isInternalFlag(flag) and type(ctrl.Get) == "function" then
    local ok, value = pcall(function()
     return ctrl:Get()
    end)
    if ok then
     local encoded = encodeValue(value)
     if encoded ~= nil then
      out[flag] = encoded
      self._flags[flag] = value
     end
    end
   end
  end
  return out
 end

 function window:ApplyFlags(flags, silent)
  if type(flags) ~= "table" then
   return
  end
  for flag, raw in pairs(flags) do
   if not isInternalFlag(flag) then
    local value = decodeValue(raw)
    local ctrl = controls[flag]
    if ctrl and type(ctrl.Set) == "function" then
     pcall(function()
      ctrl:Set(value, silent == true)
     end)
    end
    self._flags[flag] = value
   end
  end
 end

 function window:SaveConfig(name)
  name = sanitizeConfigName(name or configUi.selected or "default")
  configUi.selected = name
  local payload = {
   version = 1,
   placeId = tonumber(placeKey) or game.PlaceId,
   configId = configId,
   name = name,
   savedAt = os.time(),
   toggleKeys = {},
   flags = self:CollectFlags(),
   custom = nil,
  }
  for _, key in ipairs(toggleKeys) do
   table.insert(payload.toggleKeys, key.Name)
  end
  if type(opts.OnSaveConfig) == "function" then
   local ok, custom = pcall(opts.OnSaveConfig, payload)
   if ok then
    payload.custom = custom
   end
  end
  local ok, err = writeJson(configPath(name), payload)
  if ok then
   pcall(function()
    self:Notify("Saved config: " .. name)
   end)
  else
   pcall(function()
    self:Notify(tostring(err or "Save failed"))
   end)
  end
  return ok, err, name
 end

 function window:LoadConfig(name, silent)
  name = sanitizeConfigName(name or configUi.selected or "default")
  configUi.selected = name
  local data = readJson(configPath(name))
  if type(data) ~= "table" then
   if not silent then
    pcall(function()
     self:Notify("No config: " .. name)
    end)
   end
   return false, "missing"
  end
  if type(data.flags) == "table" then
   self:ApplyFlags(data.flags, false)
  end
  if type(data.toggleKeys) == "table" and #data.toggleKeys > 0 then
   self:SetToggleKeys(data.toggleKeys)
  end
  if type(opts.OnLoadConfig) == "function" then
   pcall(opts.OnLoadConfig, data.custom, data)
  end
  if not silent then
   pcall(function()
    self:Notify("Loaded config: " .. name)
   end)
  end
  return true, nil, name
 end

 function window:DeleteConfig(name)
  name = sanitizeConfigName(name or configUi.selected or "default")
  local path = configPath(name)
  if type(delfile) ~= "function" then
   return false, "delfile unavailable"
  end
  local ok = pcall(delfile, path)
  local meta = readMeta()
  if meta.autoload == name then
   meta.autoload = ""
   writeMeta(meta)
  end
  if ok then
   pcall(function()
    self:Notify("Deleted config: " .. name)
   end)
  end
  return ok
 end

 function window:TryAutoload()
  local name = self:GetAutoload()
  if name == nil or name == "" then
   return false
  end
  return self:LoadConfig(name, true)
 end

 local function selectTab(name)
 if activeDropdownClose then
 pcall(activeDropdownClose, false)
 end
 for n, tabApi in pairs(window._tabs) do
 local on = n == name
 tween(tabApi.Button, {
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
 pageScale.Scale = 0.98
 tween(pageScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Quad)
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
 BackgroundTransparency = 1,
 BorderSizePixel = 0,
 Size = UDim2.fromOffset(math.max(64, 18 + #name * 8), 34),
 Font = Enum.Font.Gotham,
 Text = name,
 TextColor3 = Theme.textDim,
 TextSize = 13,
 TextXAlignment = Enum.TextXAlignment.Center,
 LayoutOrder = order,
 }, sidebarNav)
 local sel = mk("Frame", {
 Name = "Sel",
 BackgroundColor3 = Theme.accent,
 BorderSizePixel = 0,
 AnchorPoint = Vector2.new(0.5, 1),
 Position = UDim2.new(0.5, 0, 1, -2),
 Size = UDim2.new(0.7, 0, 0, 2),
 BackgroundTransparency = 1,
 ZIndex = 2,
 }, btn)
 corner(sel, 1)

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
 pad(page, 6, 16, 6, 6)
 mk("UIListLayout", {
 Padding = UDim.new(0, 16),
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
 local sec = makeSection(page, title, sectionCtx)
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
 Padding = UDim.new(0, 16),
 SortOrder = Enum.SortOrder.LayoutOrder,
 }, row)

 local function col()
 local holder = mk("Frame", {
 BackgroundTransparency = 1,
 Size = UDim2.new(0.5, -8, 0, 0),
 AutomaticSize = Enum.AutomaticSize.Y,
 }, row)
 mk("UIListLayout", {
 Padding = UDim.new(0, 16),
 SortOrder = Enum.SortOrder.LayoutOrder,
 }, holder)
 local proxy = {
 _sections = tabApi._sections,
 Section = function(_, title)
 local sec = makeSection(holder, title, sectionCtx)
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
 tween(btn, { TextColor3 = Theme.text }, 0.14)
 end
 end)
 btn.MouseLeave:Connect(function()
 if window._active ~= name then
 tween(btn, { TextColor3 = Theme.textDim }, 0.16)
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
 addToggleKey(Enum.KeyCode.RightControl)
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
 self:CloseSettings()
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
 self:CloseSettings()
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
 Font = Enum.Font.Gotham,
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

 local function refreshConfigDropdown(drop, prefer)
  if not drop or type(drop.SetOptions) ~= "function" then
   return
  end
  local names = window:ListConfigs()
  if #names == 0 then
   names = { "default" }
  end
  local keep = prefer or configUi.selected
  if not table.find(names, keep) then
   keep = names[1]
  end
  configUi.selected = keep
  drop:SetOptions(names, true)
  drop:Set(keep, true)
 end

 local function ensureConfigTab()
  if opts.BuiltInConfig == false or configUi.built then
   return
  end
  configUi.built = true
  local tab = window:AddTab("Config")
  local left, right = tab:Columns()
  local profiles = left:Section("Profiles")
  profiles:Label("Per-game folder: " .. configRoot)
  local nameBox = profiles:TextBox({
   Text = "Config Name",
   Default = "default",
   Placeholder = "e.g. farm, pvp, main",
   Flag = "__mythios_config_name",
  })
  local listDrop
  listDrop = profiles:Dropdown({
   Text = "Saved Configs",
   Options = { "default" },
   Default = "default",
   Flag = "__mythios_config_select",
   Callback = function(v)
    configUi.selected = sanitizeConfigName(v)
    if nameBox and nameBox.Set then
     nameBox:Set(configUi.selected)
    end
   end,
  })
  profiles:Button({
   Text = "Refresh List",
   Callback = function()
    refreshConfigDropdown(listDrop, configUi.selected)
   end,
  })
  profiles:Button({
   Text = "Save Config",
   Callback = function()
    local name = sanitizeConfigName((nameBox and nameBox.Get and nameBox:Get()) or configUi.selected)
    window:SaveConfig(name)
    refreshConfigDropdown(listDrop, name)
   end,
  })
  profiles:Button({
   Text = "Load Config",
   Callback = function()
    local name = sanitizeConfigName((nameBox and nameBox.Get and nameBox:Get()) or configUi.selected)
    window:LoadConfig(name, false)
    refreshConfigDropdown(listDrop, name)
   end,
  })
  profiles:Button({
   Text = "Delete Config",
   Danger = true,
   Callback = function()
    local name = sanitizeConfigName((nameBox and nameBox.Get and nameBox:Get()) or configUi.selected)
    window:DeleteConfig(name)
    refreshConfigDropdown(listDrop, "default")
    if nameBox and nameBox.Set then
     nameBox:Set(configUi.selected)
    end
   end,
  })

  local boot = right:Section("Autoload / Menu")
  local autoDrop
  autoDrop = boot:Dropdown({
   Text = "Autoload Config",
   Options = { "(none)", "default" },
   Default = "(none)",
   Flag = "__mythios_autoload",
   Callback = function(v)
    if v == "(none)" then
     window:SetAutoload("")
    else
     window:SetAutoload(v)
    end
   end,
  })
  boot:Button({
   Text = "Use Selected As Autoload",
   Callback = function()
    local name = sanitizeConfigName((nameBox and nameBox.Get and nameBox:Get()) or configUi.selected)
    window:SetAutoload(name)
    local names = window:ListConfigs()
    local optsList = { "(none)" }
    for _, n in ipairs(names) do
     table.insert(optsList, n)
    end
    if not table.find(optsList, name) then
     table.insert(optsList, name)
    end
    autoDrop:SetOptions(optsList, true)
    autoDrop:Set(name, true)
    window:Notify("Autoload → " .. name)
   end,
  })
  boot:Button({
   Text = "Clear Autoload",
   Callback = function()
    window:SetAutoload("")
    autoDrop:Set("(none)", true)
    window:Notify("Autoload cleared")
   end,
  })
  local defaultKey = toggleKeys[1] or Enum.KeyCode.RightControl
  boot:Keybind({
   Text = "Toggle Hub Key",
   Default = defaultKey,
   Flag = "__mythios_toggle_key",
   Callback = function(key)
    window:SetToggleKeys({ key })
   end,
  })
  boot:Label("Default key: RightControl")
  boot:Label("Configs stay separate per PlaceId + UI id.")

  local function syncAutoloadDrop()
   local names = window:ListConfigs()
   local optsList = { "(none)" }
   for _, n in ipairs(names) do
    table.insert(optsList, n)
   end
   local current = window:GetAutoload()
   if current ~= "" and not table.find(optsList, current) then
    table.insert(optsList, current)
   end
   autoDrop:SetOptions(optsList, true)
   autoDrop:Set(current ~= "" and current or "(none)", true)
  end

  refreshConfigDropdown(listDrop, configUi.selected)
  syncAutoloadDrop()
  configUi.refresh = function()
   refreshConfigDropdown(listDrop, configUi.selected)
   syncAutoloadDrop()
  end
 end

 function window:EnsureConfigTab()
  ensureConfigTab()
 end

 if showBoot then
  task.spawn(playBootThenOpen)
 elseif opts.StartOpen ~= false then
  window:SetOpen(true)
 end

 if opts.BuiltInConfig ~= false then
  task.spawn(function()
   task.wait(0.2)
   if not window._alive then
    return
   end
   ensureConfigTab()
   if opts.Autoload ~= false then
    window:TryAutoload()
   end
   if configUi.refresh then
    configUi.refresh()
   end
  end)
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
