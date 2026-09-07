local UI = require("gfx.ui.components.init")

local UIWidget = class("UIWidget")

local TYPES = {
    CANVAS      = "Canvas",
    PANEL       = "Panel",
    BUTTON      = "Button",
    IMAGE       = "Image",
    SCROLLVIEW  = "ScrollView",
    SLIDER      = "Slider",
    CHECKBOX    = "Checkbox",
    RADIOBUTTON = "RadioButton",
    PROGRESSBAR = "ProgressBar",
    LISTVIEW    = "ListView",
    TOOLTIP     = "Tooltip",
    LABEL       = "Label",
    TEXTFIELD   = "TextField",
    CONSOLELOG  = "ConsoleLog",
}
UIWidget.TYPES = TYPES

-- Pseudo-type for the invisible scene root every top-level widget lives
-- under. Giving the tree a real (if hidden) root means "top-level" is never
-- a special case: reparenting, deletion and hierarchy traversal all just
-- walk widget.parent / widget.children, root included.
UIWidget.ROOT_TYPE = "Root"

local DEFAULTS = {
    Canvas      = { width = SCREEN_WIDTH, height = SCREEN_HEIGHT, r = 0, g = 0, b = 0 },
    Panel       = { width = 160, height = 100, r = 60, g = 60, b = 60 },
    Button      = { width = 120, height = 40, r = 70, g = 100, b = 160 },
    Image       = { width = 120, height = 120, r = 50, g = 50, b = 50 },
    ScrollView  = { width = 160, height = 200, r = 45, g = 45, b = 45 },
    Slider      = { width = 200, height = 28, r = 50, g = 50, b = 50 },
    Checkbox    = { width = 160, height = 28, r = 50, g = 50, b = 50 },
    RadioButton = { width = 160, height = 28, r = 50, g = 50, b = 50 },
    ProgressBar = { width = 200, height = 24, r = 40, g = 40, b = 40 },
    ListView    = { width = 180, height = 200, r = 30, g = 30, b = 32 },
    Tooltip     = { width = 140, height = 32, r = 40, g = 40, b = 44 },
    Label       = { width = 140, height = 28, r = 0, g = 0, b = 0 },
    TextField   = { width = 200, height = 32, r = 40, g = 40, b = 40 },
    ConsoleLog  = { width = 320, height = 160, r = 14, g = 14, b = 17 },
}

-- Mirrors UIComponent's own anchor table. Kept local/static here (rather than
-- rebuilt per call, as the previous version of syncToComponent did) since
-- it's read on every sync of every widget in the tree.
local ANCHOR_OFFSET = {
    [Graphics.TOP_LEFT]      = { 0, 0 },
    [Graphics.TOP_CENTER]    = { 0.5, 0 },
    [Graphics.TOP_RIGHT]     = { 1, 0 },
    [Graphics.CENTER_LEFT]   = { 0, 0.5 },
    [Graphics.CENTER]        = { 0.5, 0.5 },
    [Graphics.CENTER_RIGHT]  = { 1, 0.5 },
    [Graphics.BOTTOM_LEFT]   = { 0, 1 },
    [Graphics.BOTTOM_CENTER] = { 0.5, 1 },
    [Graphics.BOTTOM_RIGHT]  = { 1, 1 },
}

local _idCounter = 0
local function nextId()
    _idCounter = _idCounter + 1
    return _idCounter
end

function UIWidget:ctor(widgetType)
    local def           = DEFAULTS[widgetType] or {}
    self.type           = widgetType
    self.name           = widgetType .. "_" .. nextId()
    self.x              = 100
    self.y              = 100
    self.width          = def.width or 120
    self.height         = def.height or 60
    self.anchor         = Graphics.TOP_LEFT
    self.r              = def.r or 80
    self.g              = def.g or 80
    self.b              = def.b or 80
    self.a              = 255
    self.bgImagePath    = ""
    self.bgNinePath     = false
    self.bgNineLeft     = 8
    self.bgNineTop      = 8
    self.bgNineRight    = 8
    self.bgNineBottom   = 8

    -- scene tree (Unity-style hierarchy)
    self.parent         = nil
    self.children       = {}
    self.expanded       = true -- hierarchy-panel fold state

    -- Canvas: whole-screen containers can be switched on/off independently
    -- (e.g. HUD vs. pause-menu canvas), mirrored onto the component's own
    -- `visible` so an inactive canvas neither renders nor receives input
    self.active         = true

    -- Button / Checkbox / RadioButton shared text
    self.text           = (widgetType == TYPES.BUTTON) and "Button" or
        (widgetType == TYPES.CHECKBOX) and "Checkbox" or
        (widgetType == TYPES.RADIOBUTTON) and "Option" or ""
    self.fontSize       = 16
    self.textR          = 255
    self.textG          = 255
    self.textB          = 255
    self.cornerRadius   = 6
    -- Image
    self.imagePath      = ""

    -- Label
    self.labelText      = "Label"
    self.labelR         = 255
    self.labelG         = 255
    self.labelB         = 255
    self.labelSize      = 16
    -- TextField
    self.placeholder    = ""
    -- ScrollView
    self.contentWidth   = 300
    self.contentHeight  = 300
    self.direction      = "vertical"
    -- Slider
    self.sliderMin      = 0
    self.sliderMax      = 100
    self.sliderValue    = 50
    self.fillR          = 70
    self.fillG          = 130
    self.fillB          = 220
    -- Checkbox / RadioButton
    self.checked        = false
    self.radioGroup     = "default"
    self.checkR         = 70
    self.checkG         = 130
    self.checkB         = 220
    -- ProgressBar
    self.progressValue  = 0.5
    self.fillR2         = 70
    self.fillG2         = 180
    self.fillB2         = 100
    -- ListView
    self.listItems      = "Item 1,Item 2,Item 3"
    self.itemHeight     = 32
    -- Tooltip
    self.tooltipText    = "Tooltip"
    self.arrowDir       = "up"
    -- ConsoleLog
    self.maxEntries     = 300
    self.showTimestamps = false
    -- Event callbacks (stored as string names for serialization)
    self.onClick        = ""
    self.onChange       = ""
    self.onChanged      = ""
    self.onSelect       = ""
    -- ProgressBar extra
    self.showLabel      = true
    -- Label anchor
    self.textAnchor     = "CENTER_LEFT"

    self:_buildComponent()
end

function UIWidget:_parseListItems()
    local items = {}
    for item in (self.listItems .. ","):gmatch("([^,]+),") do
        items[#items + 1] = item:match("^%s*(.-)%s*$")
    end
    return items
end

function UIWidget:_buildComponent()
    local t = self.type
    local c

    if t == TYPES.CANVAS then
        -- a whole-screen container, like Unity's Canvas: transparent itself,
        -- exists purely to root a subtree of panels/children
        c = UI.UIPanel.new(self.x, self.y, self.width, self.height)
        c.r, c.g, c.b, c.a = 0, 0, 0, 0
        c.clip = false
    elseif t == TYPES.PANEL then
        c = UI.UIPanel.new(self.x, self.y, self.width, self.height)
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.clip = false
    elseif t == TYPES.BUTTON then
        c = UI.UIButton.new(self.x, self.y, self.width, self.height)
        c.text = self.text
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.textR, c.textG, c.textB = self.textR, self.textG, self.textB
        c.cornerRadius = self.cornerRadius
    elseif t == TYPES.IMAGE then
        c = UI.UIImage.new(self.x, self.y, self.width, self.height)
        c:setImage(self.imagePath)
    elseif t == TYPES.LABEL then
        c = UI.UILabel.new(self.x, self.y, self.width, self.height)
        c.text = self.labelText
        c.textR, c.textG, c.textB = self.labelR, self.labelG, self.labelB
        c.fontSize = self.labelSize
        c.textAnchor = Graphics[self.textAnchor] or Graphics.CENTER_LEFT
    elseif t == TYPES.TEXTFIELD then
        c = UI.UITextField.new(self.x, self.y, self.width, self.height)
        c.text = self.text
        c.placeholder = self.placeholder
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.textR, c.textG, c.textB = self.textR, self.textG, self.textB
        c.fontSize = self.fontSize
        c.cornerRadius = self.cornerRadius
    elseif t == TYPES.SCROLLVIEW then
        c                  = UI.UIScrollView.new(self.x, self.y, self.width, self.height)
        c.contentWidth     = self.contentWidth
        c.contentHeight    = self.contentHeight
        c.direction        = self.direction
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
    elseif t == TYPES.SLIDER then
        c = UI.UISlider.new(self.x, self.y, self.width, self.height)
        c.min, c.max, c.value = self.sliderMin, self.sliderMax, self.sliderValue
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.fillR, c.fillG, c.fillB = self.fillR, self.fillG, self.fillB
    elseif t == TYPES.CHECKBOX then
        c                            = UI.UICheckbox.new(self.x, self.y, self.width, self.height)
        c.checked                    = self.checked
        c.text                       = self.text
        c.r, c.g, c.b, c.a           = self.r, self.g, self.b, self.a
        c.checkR, c.checkG, c.checkB = self.checkR, self.checkG, self.checkB
    elseif t == TYPES.RADIOBUTTON then
        c                         = UI.UIRadioButton.new(self.x, self.y, self.width, self.height)
        c.selected                = self.checked
        c.text                    = self.text
        c.group                   = self.radioGroup
        c.r, c.g, c.b, c.a        = self.r, self.g, self.b, self.a
        c.fillR, c.fillG, c.fillB = self.checkR, self.checkG, self.checkB
    elseif t == TYPES.PROGRESSBAR then
        c = UI.UIProgressBar.new(self.x, self.y, self.width, self.height)
        c.value = self.progressValue
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.fillR, c.fillG, c.fillB = self.fillR2, self.fillG2, self.fillB2
        c.showLabel = self.showLabel
    elseif t == TYPES.LISTVIEW then
        c = UI.UIListView.new(self.x, self.y, self.width, self.height)
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.itemHeight = self.itemHeight
        c:setItems(self:_parseListItems())
    elseif t == TYPES.TOOLTIP then
        c                  = UI.UITooltip.new(self.x, self.y, self.width, self.height)
        c.text             = self.tooltipText
        c.arrowDir         = self.arrowDir
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.visible          = true
    elseif t == TYPES.CONSOLELOG then
        c = UI.UIConsole.new(self.x, self.y, self.width, self.height)
        c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
        c.fontSize = self.fontSize
        c.lineHeight = c.fontSize + 5
        c.charWidth = math.max(4, math.floor(c.fontSize * 0.52))
        c:setMaxEntries(self.maxEntries)
        c.showTimestamps = self.showTimestamps
    elseif t == UIWidget.ROOT_TYPE then
        -- invisible container: never drawn itself, only exists to hold the
        -- top-level widgets so the tree has a single, uniform root
        c = UI.UIPanel.new(self.x, self.y, self.width, self.height)
        c.r, c.g, c.b, c.a = 0, 0, 0, 0
        c.clip = false
    end

    c.anchor = self.anchor
    c:setBgImage(self.bgImagePath)
    c:setNinePath(
        self.bgNinePath,
        self.bgNineLeft,
        self.bgNineTop,
        self.bgNineRight,
        self.bgNineBottom
    )
    c:updateAbsolutePosition(0, 0)
    self.component = c
end

function UIWidget:syncToComponent()
    local c            = self.component

    -- self.x/self.y are local coordinates, relative to the parent's origin
    -- (Unity-style localPosition) — the same space UIComponent already uses
    -- internally, so this is a direct copy. Moving a parent never touches
    -- its children's local x/y; they simply ride along because their
    -- *absolute* position (computed below) is derived from the parent's.
    c.x, c.y           = self.x, self.y
    c.width, c.height  = self.width, self.height
    c.anchor           = self.anchor
    c.r, c.g, c.b, c.a = self.r, self.g, self.b, self.a
    if c.bgImagePath ~= self.bgImagePath then
        c:setBgImage(self.bgImagePath)
    end
    c:setNinePath(
        self.bgNinePath,
        self.bgNineLeft,
        self.bgNineTop,
        self.bgNineRight,
        self.bgNineBottom
    )

    local t = self.type
    if t == TYPES.CANVAS then
        c.visible = self.active
    elseif t == TYPES.BUTTON then
        c.text = self.text
        c.textR, c.textG, c.textB = self.textR, self.textG, self.textB
        c.cornerRadius = self.cornerRadius
    elseif t == TYPES.IMAGE then
        if c.imagePath ~= self.imagePath then
            c:setImage(self.imagePath)
        end
    elseif t == TYPES.SCROLLVIEW then
        c.contentWidth  = self.contentWidth
        c.contentHeight = self.contentHeight
        c.direction     = self.direction
    elseif t == TYPES.SLIDER then
        c.min, c.max, c.value = self.sliderMin, self.sliderMax, self.sliderValue
        c.fillR, c.fillG, c.fillB = self.fillR, self.fillG, self.fillB
    elseif t == TYPES.CHECKBOX then
        c.checked                    = self.checked
        c.text                       = self.text
        c.checkR, c.checkG, c.checkB = self.checkR, self.checkG, self.checkB
    elseif t == TYPES.RADIOBUTTON then
        c.selected                = self.checked
        c.text                    = self.text
        c.group                   = self.radioGroup
        c.fillR, c.fillG, c.fillB = self.checkR, self.checkG, self.checkB
    elseif t == TYPES.PROGRESSBAR then
        c.value = self.progressValue
        c.fillR, c.fillG, c.fillB = self.fillR2, self.fillG2, self.fillB2
        c.showLabel = self.showLabel
    elseif t == TYPES.LISTVIEW then
        c.itemHeight = self.itemHeight
        c:setItems(self:_parseListItems())
    elseif t == TYPES.TOOLTIP then
        c.text     = self.tooltipText
        c.arrowDir = self.arrowDir
        c.visible  = true
    elseif t == TYPES.CONSOLELOG then
        if c.fontSize ~= self.fontSize then
            c.fontSize = self.fontSize
            c.lineHeight = c.fontSize + 5
            c.charWidth = math.max(4, math.floor(c.fontSize * 0.52))
            c._wrappedWidth = nil -- force a rewrap on next draw
        end
        if c.maxEntries ~= self.maxEntries then c:setMaxEntries(self.maxEntries) end
        c.showTimestamps = self.showTimestamps
    elseif t == TYPES.LABEL then
        c.text = self.labelText
        c.textR, c.textG, c.textB = self.labelR, self.labelG, self.labelB
        c.fontSize = self.labelSize
        c.textAnchor = Graphics[self.textAnchor] or Graphics.CENTER_LEFT
    elseif t == TYPES.TEXTFIELD then
        c.text = self.text
        c.placeholder = self.placeholder
        c.textR, c.textG, c.textB = self.textR, self.textG, self.textB
        c.fontSize = self.fontSize
        c.cornerRadius = self.cornerRadius
    end

    if c.parent then
        c:updateAbsolutePosition(c.parent._absX, c.parent._absY)
    else
        c:updateAbsolutePosition(0, 0)
    end
end

-- ─── world / local coordinate conversion ────────────────────────────────────

-- Absolute (world) top-left position, valid as of the last :sync(). This is
-- what the editor needs for hit-testing, drag math, and drawing overlays —
-- self.x/self.y are local-to-parent and not directly comparable across
-- different widgets once nesting is involved.
function UIWidget:getWorldPos()
    return self.component._absX, self.component._absY
end

-- Converts an absolute/world top-left position into the local x/y this
-- widget would need (relative to its current parent, honoring anchor) to
-- sit there. Used when dragging (screen → world → local) and when
-- reparenting (to keep the widget visually in place under its new parent).
function UIWidget:worldToLocal(worldX, worldY)
    local c = self.component
    local pax, pay = 0, 0
    if c.parent then pax, pay = c.parent._absX, c.parent._absY end
    local aoff = ANCHOR_OFFSET[self.anchor] or { 0, 0 }
    return worldX - pax + aoff[1] * self.width,
        worldY - pay + aoff[2] * self.height
end

-- ─── scene tree ────────────────────────────────────────────────────────────

-- Detaches this widget from its current parent, if any (both on the widget
-- tree and the mirrored UIComponent tree). No-op for a widget already at
-- the top of its tree.
function UIWidget:removeFromParent()
    local p = self.parent
    if not p then return end
    for i, c in ipairs(p.children) do
        if c == self then
            table.remove(p.children, i)
            break
        end
    end
    p.component:removeChild(self.component)
    self.parent = nil
end

-- Reparents `child` under self, optionally at a specific sibling index
-- (1-based; omit to append). Safe to call even if `child` already has a
-- parent — it's detached first.
function UIWidget:addChild(child, index)
    child:removeFromParent()
    child.parent = self
    index = index and math.max(1, math.min(index, #self.children + 1)) or (#self.children + 1)
    table.insert(self.children, index, child)
    self.component:addChild(child.component, index)
    return child
end

-- True if `other` is somewhere above self in the tree. Used to reject drops
-- that would make a widget its own ancestor.
function UIWidget:isDescendantOf(other)
    local p = self.parent
    while p do
        if p == other then return true end
        p = p.parent
    end
    return false
end

-- Recursively syncs this widget and its entire subtree to their
-- UIComponents. Call once per frame on the scene root before rendering.
function UIWidget:sync()
    self:syncToComponent()
    for _, c in ipairs(self.children) do c:sync() end
end

-- Renders this widget's component, which cascades to its children via the
-- normal UIComponent parent/child render. Call only on top-level widgets —
-- nested widgets are drawn automatically as part of their parent's render.
function UIWidget:renderComponent(g)
    self.component:render(g)
end

-- Draws the editor-only selection/bounds overlay for this widget alone
-- (does not recurse — the editor calls this once per widget in the tree).
-- Drawn in world space since self.x/self.y are local-to-parent.
function UIWidget:renderOverlay(g, selected)
    local x, y = self:getWorldPos()
    local w, h = self.width, self.height

    if self.type == TYPES.CANVAS then
        -- Canvases are functionally invisible but, with several of them
        -- often overlapping full-screen, need a boundary you can actually
        -- see while editing — drawn distinctly from the generic faint
        -- widget outline below.
        g:setColor(90, 200, 210, selected and 220 or 130)
        g:drawRect(x, y, w, h)
        g:drawRect(x + 1, y + 1, w - 2, h - 2)
        return
    end

    if selected then
        g:setColor(0, 160, 255, 255)
        g:drawRect(x - 1, y - 1, w + 2, h + 2)
        g:drawRect(x - 2, y - 2, w + 4, h + 4)
        g:setColor(0, 160, 255, 255)
        g:fillRect(x + w - 5, y + h - 5, 10, 10)
        g:setColor(255, 255, 255, 255)
        g:fillRect(x + w - 3, y + h - 3, 6, 6)
    else
        g:setColor(80, 80, 80, 100)
        g:drawRect(x, y, w, h)
    end
end

-- Hit-test in world space (self.x/self.y are local-to-parent and not
-- comparable across widgets at different depths).
function UIWidget:contains(px, py)
    local x, y = self:getWorldPos()
    return px >= x and px <= x + self.width and
        py >= y and py <= y + self.height
end

-- Recursively destroys this widget and its whole subtree (children first),
-- detaching from the parent and disposing the backing components.
function UIWidget:destroy()
    for i = #self.children, 1, -1 do
        self.children[i]:destroy()
    end
    self:removeFromParent()
    if self.component then self.component:dispose() end
end

-- ─── JSON ────────────────────────────────────────────────────────────────────

function UIWidget:toTable()
    local t = {
        type = self.type,
        name = self.name,
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height,
        r = self.r,
        g = self.g,
        b = self.b,
        a = self.a,
        expanded = self.expanded,
        bgImagePath = self.bgImagePath,
        bgNinePath = self.bgNinePath,
        bgNineLeft = self.bgNineLeft,
        bgNineTop = self.bgNineTop,
        bgNineRight = self.bgNineRight,
        bgNineBottom = self.bgNineBottom,
    }

    local tp = self.type
    if tp == TYPES.CANVAS then
        t.active = self.active
    elseif tp == TYPES.BUTTON then
        t.text = self.text; t.fontSize = self.fontSize
        t.textR = self.textR; t.textG = self.textG; t.textB = self.textB
        t.cornerRadius = self.cornerRadius; t.onClick = self.onClick
    elseif tp == TYPES.IMAGE then
        t.imagePath = self.imagePath
    elseif tp == TYPES.LABEL then
        t.labelText = self.labelText
        t.labelR = self.labelR; t.labelG = self.labelG; t.labelB = self.labelB
        t.labelSize = self.labelSize; t.textAnchor = self.textAnchor
    elseif tp == TYPES.TEXTFIELD then
        t.placeholder = self.placeholder; t.text = self.text
        t.textR = self.textR; t.textG = self.textG; t.textB = self.textB
        t.fontSize = self.fontSize; t.cornerRadius = self.cornerRadius
    elseif tp == TYPES.SCROLLVIEW then
        t.contentWidth = self.contentWidth
        t.contentHeight = self.contentHeight
        t.direction = self.direction
    elseif tp == TYPES.SLIDER then
        t.sliderMin = self.sliderMin; t.sliderMax = self.sliderMax
        t.sliderValue = self.sliderValue
        t.fillR = self.fillR; t.fillG = self.fillG; t.fillB = self.fillB
        t.onChange = self.onChange
    elseif tp == TYPES.CHECKBOX or tp == TYPES.RADIOBUTTON then
        t.checked = self.checked; t.text = self.text
        t.radioGroup = self.radioGroup
        t.checkR = self.checkR; t.checkG = self.checkG; t.checkB = self.checkB
        t.onChanged = self.onChanged
    elseif tp == TYPES.PROGRESSBAR then
        t.progressValue = self.progressValue; t.showLabel = self.showLabel
        t.fillR2 = self.fillR2; t.fillG2 = self.fillG2; t.fillB2 = self.fillB2
    elseif tp == TYPES.LISTVIEW then
        t.listItems = self.listItems; t.itemHeight = self.itemHeight
        t.onSelect = self.onSelect
    elseif tp == TYPES.TOOLTIP then
        t.tooltipText = self.tooltipText; t.arrowDir = self.arrowDir
    elseif tp == TYPES.CONSOLELOG then
        t.maxEntries = self.maxEntries; t.showTimestamps = self.showTimestamps
        t.fontSize = self.fontSize
    end

    if #self.children > 0 then
        local kids = {}
        for _, child in ipairs(self.children) do
            kids[#kids + 1] = child:toTable()
        end
        t.children = kids
    end

    return t
end

function UIWidget.fromTable(data)
    local w        = UIWidget.new(data.type)
    w.name         = data.name or w.name
    w.x            = data.x or w.x
    w.y            = data.y or w.y
    w.width        = data.width or w.width
    w.height       = data.height or w.height
    w.r            = data.r or w.r
    w.g            = data.g or w.g
    w.b            = data.b or w.b
    w.a            = data.a or w.a
    w.expanded     = data.expanded ~= false

    -- Background
    w.bgImagePath  = data.bgImagePath or ""
    w.bgNinePath   = data.bgNinePath or false
    w.bgNineLeft   = data.bgNineLeft or 8
    w.bgNineTop    = data.bgNineTop or 8
    w.bgNineRight  = data.bgNineRight or 8
    w.bgNineBottom = data.bgNineBottom or 8

    local tp       = data.type
    if tp == TYPES.CANVAS then
        w.active = data.active ~= false
    elseif tp == TYPES.BUTTON then
        w.text         = data.text or w.text
        w.fontSize     = data.fontSize or w.fontSize
        w.textR        = data.textR or w.textR
        w.textG        = data.textG or w.textG
        w.textB        = data.textB or w.textB
        w.cornerRadius = data.cornerRadius or w.cornerRadius
        w.onClick      = data.onClick or ""
    elseif tp == TYPES.IMAGE then
        w.imagePath  = data.imagePath or ""
        w.ninePath   = data.ninePath or false
        w.nineLeft   = data.nineLeft or 8
        w.nineTop    = data.nineTop or 8
        w.nineRight  = data.nineRight or 8
        w.nineBottom = data.nineBottom or 8
    elseif tp == TYPES.LABEL then
        w.labelText  = data.labelText or w.labelText
        w.labelR     = data.labelR or w.labelR
        w.labelG     = data.labelG or w.labelG
        w.labelB     = data.labelB or w.labelB
        w.labelSize  = data.labelSize or w.labelSize
        w.textAnchor = data.textAnchor or w.textAnchor
    elseif tp == TYPES.TEXTFIELD then
        w.placeholder  = data.placeholder or w.placeholder
        w.text         = data.text or w.text
        w.textR        = data.textR or w.textR
        w.textG        = data.textG or w.textG
        w.textB        = data.textB or w.textB
        w.fontSize     = data.fontSize or w.fontSize
        w.cornerRadius = data.cornerRadius or w.cornerRadius
    elseif tp == TYPES.SCROLLVIEW then
        w.contentWidth  = data.contentWidth or w.contentWidth
        w.contentHeight = data.contentHeight or w.contentHeight
        w.direction     = data.direction or w.direction
    elseif tp == TYPES.SLIDER then
        w.sliderMin   = data.sliderMin or w.sliderMin
        w.sliderMax   = data.sliderMax or w.sliderMax
        w.sliderValue = data.sliderValue or w.sliderValue
        w.fillR       = data.fillR or w.fillR
        w.fillG       = data.fillG or w.fillG
        w.fillB       = data.fillB or w.fillB
        w.onChange    = data.onChange or ""
    elseif tp == TYPES.CHECKBOX or tp == TYPES.RADIOBUTTON then
        w.checked    = data.checked or false
        w.text       = data.text or w.text
        w.radioGroup = data.radioGroup or w.radioGroup
        w.checkR     = data.checkR or w.checkR
        w.checkG     = data.checkG or w.checkG
        w.checkB     = data.checkB or w.checkB
        w.onChanged  = data.onChanged or ""
    elseif tp == TYPES.PROGRESSBAR then
        w.progressValue = data.progressValue or w.progressValue
        w.showLabel     = data.showLabel ~= nil and data.showLabel or w.showLabel
        w.fillR2        = data.fillR2 or w.fillR2
        w.fillG2        = data.fillG2 or w.fillG2
        w.fillB2        = data.fillB2 or w.fillB2
    elseif tp == TYPES.LISTVIEW then
        w.listItems  = data.listItems or w.listItems
        w.itemHeight = data.itemHeight or w.itemHeight
        w.onSelect   = data.onSelect or ""
    elseif tp == TYPES.TOOLTIP then
        w.tooltipText = data.tooltipText or w.tooltipText
        w.arrowDir    = data.arrowDir or w.arrowDir
    elseif tp == TYPES.CONSOLELOG then
        w.maxEntries     = data.maxEntries or w.maxEntries
        w.showTimestamps = data.showTimestamps or false
        w.fontSize       = data.fontSize or w.fontSize
    end
    w:_buildComponent()

    if data.children then
        for _, childData in ipairs(data.children) do
            w:addChild(UIWidget.fromTable(childData))
        end
    end

    return w
end

return UIWidget
