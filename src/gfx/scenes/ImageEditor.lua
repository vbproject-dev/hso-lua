local Scene         = require("gfx.Scene")
local UI            = require("gfx.ui.components.init")
local UIImagePicker = require("gfx.ui.UIImagePicker")

local ImageEditor   = class("ImageEditor", Scene)

--=====================================================================
-- LAYOUT CONSTANTS
--=====================================================================
local TOOLBAR_H     = 44
local STATUS_H      = 24
local LEFT_W        = 200
local RIGHT_W       = 280

local CANVAS_X      = LEFT_W
local CANVAS_Y      = TOOLBAR_H
local CANVAS_W      = SCREEN_WIDTH - LEFT_W - RIGHT_W
local CANVAS_H      = SCREEN_HEIGHT - TOOLBAR_H - STATUS_H

local PAD           = 10
local GRID          = 8
local ZOOM_MIN      = 0.1
local ZOOM_MAX      = 8.0
local ZOOM_STEP     = 0.15

--=====================================================================
-- PALETTE — single source of truth for the Photoshop-style dark theme
--=====================================================================
local PALETTE       = {
    toolbar      = { 30, 30, 33 },
    panel        = { 37, 37, 40 },
    panelHeader  = { 30, 30, 33 },
    canvasBg     = { 43, 43, 47 },
    statusBar    = { 24, 24, 26 },
    border       = { 15, 15, 17 },

    button       = { 54, 54, 59 },
    buttonHover  = { 66, 66, 72 },
    buttonActive = { 40, 110, 200 },

    item         = { 44, 44, 48 },
    itemSelected = { 34, 90, 160 },

    sliderTrack  = { 54, 54, 59 },
    sliderFill   = { 60, 140, 235 },

    textPrimary  = { 225, 225, 228 },
    textSecond   = { 165, 168, 178 },
    textMuted    = { 110, 112, 122 },
    textHeader   = { 140, 155, 190 },
    accent       = { 60, 150, 240 },
    success      = { 110, 200, 130 },
}

local function clamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function snap(v)
    return math.floor(v / GRID + 0.5) * GRID
end

--=====================================================================
-- LIFECYCLE
--=====================================================================
function ImageEditor:ctor()
    ImageEditor.super.ctor(self)

    self.image = nil
    self.imagePath = ""
    self.sprites = {}
    self.selectedSprite = nil

    self.zoom = 1
    self.panX = 0
    self.panY = 0

    self.dragging = false
    self.selecting = false
    self.panning = false

    self.dragStartX = 0
    self.dragStartY = 0
    self.selectStartX = 0
    self.selectStartY = 0

    self.selection = nil
    self.status = ""
    self.statusTimer = 0

    self.history = {}
    self.adjustBaseImage = nil

    self._picker = UIImagePicker.new(function(path)
        self:open(path)
    end)

    self:_buildUI()
    self:_fitImage()
end

function ImageEditor:_buildUI()
    self:_buildToolbar()
    self:_buildLeftPanel()
    self:_buildCanvas()
    self:_buildRightPanel()
    self:_buildStatusBar()
end

--=====================================================================
-- SHARED WIDGET FACTORIES
--=====================================================================
function ImageEditor:_button(x, y, w, h, text, callback)
    local b = UI.UIButton.new(x, y, w, h)
    b.text = text
    b.r, b.g, b.b = table.unpack(PALETTE.button)
    b.hoverR, b.hoverG, b.hoverB = table.unpack(PALETTE.buttonHover)
    b.textR, b.textG, b.textB = table.unpack(PALETTE.textPrimary)
    b.cornerRadius = 4
    b.onClick = callback
    b:updateAbsolutePosition(0, 0)
    return b
end

function ImageEditor:_label(x, y, w, h, text, color, anchor)
    local l = UI.UILabel.new(x, y, w, h)
    l.text = text
    l.textR, l.textG, l.textB = table.unpack(color or PALETTE.textSecond)
    l.textAnchor = anchor or Graphics.CENTER_LEFT
    l:updateAbsolutePosition(0, 0)
    return l
end

function ImageEditor:_sectionHeader(x, y, w, text)
    return self:_label(x, y, w, 22, text, PALETTE.textHeader)
end

--=====================================================================
-- TOOLBAR — grouped, auto-laid-out buttons with separators
--=====================================================================
function ImageEditor:_buildToolbar()
    self.toolbar = UI.UIPanel.new(0, 0, SCREEN_WIDTH, TOOLBAR_H)
    self.toolbar.r, self.toolbar.g, self.toolbar.b = table.unpack(PALETTE.toolbar)
    self.toolbar.clip = false
    self.toolbar:updateAbsolutePosition(0, 0)

    self.toolbarButtons = {}
    self.toolbarSeparators = {}

    local BTN_H = 32
    local BTN_Y = math.floor((TOOLBAR_H - BTN_H) / 2)
    local cursor = PAD

    local function addButton(text, w, callback)
        local btn = self:_button(cursor, BTN_Y, w, BTN_H, text, callback)
        self.toolbarButtons[#self.toolbarButtons + 1] = btn
        cursor = cursor + w + 6
        return btn
    end

    local function addSeparator()
        cursor = cursor + 4
        self.toolbarSeparators[#self.toolbarSeparators + 1] = cursor
        cursor = cursor + 10
    end

    -- File group
    self.openButton = addButton("Open", 64, function() self._picker:open() end)
    self.saveButton = addButton("Save", 64, function() self:_save() end)
    addSeparator()

    -- Edit group
    self.undoButton = addButton("Undo", 64, function() self:_undo() end)
    addSeparator()

    -- Transform group
    self.splitButton                              = addButton("Split", 64, function() self:_split() end)
    self.cropButton                               = addButton("Crop", 64, function() self:_crop() end)
    self.rotateButton                             = addButton("Rotate", 68, function() self:_rotate() end)
    self.flipButton                               = addButton("Flip", 64, function() self:_flip() end)

    -- Zoom group — right aligned
    local zoomW                                   = 42 + 6 + 76 + 6 + 42
    local zoomX                                   = SCREEN_WIDTH - PAD - zoomW

    self.zoomOutButton                            = self:_button(zoomX, BTN_Y, 42, BTN_H, "-", function()
        self:_zoomAt(CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2, self.zoom - ZOOM_STEP)
    end)

    self.zoomResetButton                          = self:_button(zoomX + 48, BTN_Y, 76, BTN_H, "100%", function()
        self.zoom = 1
        self:_centerImage()
    end)

    self.zoomInButton                             = self:_button(zoomX + 48 + 82, BTN_Y, 42, BTN_H, "+", function()
        self:_zoomAt(CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2, self.zoom + ZOOM_STEP)
    end)

    self.toolbarButtons[#self.toolbarButtons + 1] = self.zoomOutButton
    self.toolbarButtons[#self.toolbarButtons + 1] = self.zoomResetButton
    self.toolbarButtons[#self.toolbarButtons + 1] = self.zoomInButton
end

--=====================================================================
-- LEFT PANEL — sprite list
--=====================================================================
function ImageEditor:_buildLeftPanel()
    self.leftPanel = UI.UIPanel.new(0, TOOLBAR_H, LEFT_W, CANVAS_H)
    self.leftPanel.r, self.leftPanel.g, self.leftPanel.b = table.unpack(PALETTE.panel)
    self.leftPanel.clip = false
    self.leftPanel:updateAbsolutePosition(0, 0)

    self.spriteTitle = self:_sectionHeader(PAD, TOOLBAR_H + 10, LEFT_W - PAD * 2, "SPRITES")

    self.spriteList = UI.UIListView.new(PAD, TOOLBAR_H + 38, LEFT_W - PAD * 2, CANVAS_H - 48)
    self.spriteList.r, self.spriteList.g, self.spriteList.b = table.unpack(PALETTE.panel)
    self.spriteList.itemR, self.spriteList.itemG, self.spriteList.itemB = table.unpack(PALETTE.item)
    self.spriteList.selR, self.spriteList.selG, self.spriteList.selB = table.unpack(PALETTE.itemSelected)
    self.spriteList.textR, self.spriteList.textG, self.spriteList.textB = table.unpack(PALETTE.textSecond)
    self.spriteList.selTextR, self.spriteList.selTextG, self.spriteList.selTextB = table.unpack(PALETTE.textPrimary)
    self.spriteList.itemHeight = 56
    self.spriteList:setItems({})
    self.spriteList.onSelect = function(index)
        self:_selectSprite(index)
    end
    self.spriteList.onDrawItem = function(g, index, sprite, x, y, w, h, selected)
        local thumb = 40

        -- Draw the thumbnail
        g:drawImageScale(
            sprite.image,
            x + 6,
            y + 8,
            thumb,
            thumb
        )

        -- Text
        if selected then
            g:setColor(225, 225, 228, 255)
        else
            g:setColor(165, 168, 178, 255)
        end

        g:drawString(
            string.format("%d %dx%d", index, sprite.width, sprite.height),
            x + 54,
            y + 18,
            Graphics.CENTER_LEFT
        )
    end
    self.spriteList:updateAbsolutePosition(0, 0)
end

--=====================================================================
-- CANVAS
--=====================================================================
function ImageEditor:_buildCanvas()
    self.canvasPanel = UI.UIPanel.new(CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H)
    self.canvasPanel.r, self.canvasPanel.g, self.canvasPanel.b = table.unpack(PALETTE.canvasBg)
    self.canvasPanel.clip = false
    self.canvasPanel:updateAbsolutePosition(0, 0)
end

--=====================================================================
-- RIGHT PANEL — properties / effects grid / adjustment sliders
--=====================================================================
function ImageEditor:_buildRightPanel()
    local x = SCREEN_WIDTH - RIGHT_W
    self.rightPanelX = x

    self.rightPanel = UI.UIPanel.new(x, TOOLBAR_H, RIGHT_W, CANVAS_H)
    self.rightPanel.r, self.rightPanel.g, self.rightPanel.b = table.unpack(PALETTE.panel)
    self.rightPanel.clip = false
    self.rightPanel:updateAbsolutePosition(0, 0)

    local y              = TOOLBAR_H + 10

    self.propertiesTitle = self:_sectionHeader(x + PAD, y, RIGHT_W - PAD * 2, "PROPERTIES")
    y                    = y + 28

    self.infoLabel       = self:_label(x + PAD, y, RIGHT_W - PAD * 2, 60, "No image", PALETTE.textSecond,
        Graphics.TOP_LEFT)
    y                    = y + 70

    self.effectTitle     = self:_sectionHeader(x + PAD, y, RIGHT_W - PAD * 2, "EFFECTS")
    y                    = y + 30

    -- 2-column effect grid, auto laid out
    local colW           = (RIGHT_W - PAD * 2 - 8) / 2
    local rowH           = 36
    local gapY           = 8

    local function gridButton(row, col, span, text, callback)
        local w = span == 2 and (colW * 2 + 8) or colW
        local bx = x + PAD + col * (colW + 8)
        local by = y + row * (rowH + gapY)
        return self:_button(bx, by, w, rowH - 2, text, callback)
    end

    self.grayButton = gridButton(0, 0, 1, "Grayscale", function()
        self:_applyEffect(function(img) return ImageProcessing.grayscale(img) end)
    end)

    self.invertButton = gridButton(0, 1, 1, "Invert", function()
        self:_applyEffect(function(img) return ImageProcessing.invert(img) end)
    end)

    self.outlineButton = gridButton(1, 0, 1, "Outline", function()
        self:_applyEffect(function(img)
            return ImageProcessing.outline(img, ColorRGBA.new(255, 255, 255, 255), 1)
        end)
    end)

    self.shadowButton = gridButton(1, 1, 1, "Shadow", function()
        self:_applyEffect(function(img)
            return ImageProcessing.dropShadow(img, 2, 2, ColorRGBA.new(0, 0, 0, 160), 3)
        end)
    end)

    self.glowButton = gridButton(2, 0, 1, "Glow", function()
        self:_applyEffect(function(img)
            return ImageProcessing.glow(img, ColorRGBA.new(255, 220, 80, 255), 6, 1)
        end)
    end)

    self.trimButton = gridButton(2, 1, 1, "Trim", function()
        self:_applyEffect(function(img) return ImageProcessing.trim(img) end)
    end)

    self.removeBgButton = gridButton(3, 0, 2, "Remove Background", function()
        self:_applyEffect(function(img)
            return ImageProcessing.removeBackgroundAuto(img, 32, true)
        end)
    end)

    y = y + 4 * (rowH + gapY) + 6

    self.adjustTitle = self:_sectionHeader(x + PAD, y, RIGHT_W - PAD * 2, "ADJUSTMENTS")
    y = y + 28

    y = self:_buildSlider("brightness", x, y, "Brightness", -100, 100, 0, function(img, value)
        return ImageProcessing.adjustBrightness(img, value)
    end)

    y = self:_buildSlider("contrast", x, y, "Contrast", -100, 100, 0, function(img, value)
        return ImageProcessing.adjustContrast(img, value)
    end)
end

-- Builds a labelled slider row (label + live value + track) and wires it
-- to a non-destructive preview: dragging re-applies `effectFn` against the
-- image snapshot taken when the drag started, and commits to history once
-- the user releases.
function ImageEditor:_buildSlider(key, x, y, title, min, max, default, effectFn)
    local valueLabel = self:_label(x + PAD, y, RIGHT_W - PAD * 2, 20, title .. ": " .. default,
        PALETTE.textSecond, Graphics.CENTER_LEFT)

    local slider = UI.UISlider.new(x + PAD, y + 22, RIGHT_W - PAD * 2, 22)
    slider.min = min
    slider.max = max
    slider.value = default
    slider.r, slider.g, slider.b = table.unpack(PALETTE.sliderTrack)
    slider.fillR, slider.fillG, slider.fillB = table.unpack(PALETTE.sliderFill)
    slider:updateAbsolutePosition(0, 0)

    slider.onDragStart = function()
        self.adjustBaseImage = self.image
    end

    slider.onChange = function(value)
        valueLabel.text = string.format("%s: %d", title, math.floor(value + 0.5))

        if self.adjustBaseImage then
            local result = effectFn(self.adjustBaseImage, math.floor(value + 0.5))
            if result then
                self.image = result
                self:_updateInfo()
            end
        end
    end

    slider.onDragEnd = function()
        if self.adjustBaseImage and self.adjustBaseImage ~= self.image then
            self.history[#self.history + 1] = self.adjustBaseImage
            self:_status(title .. " applied")
        end
        self.adjustBaseImage = nil
    end

    self[key .. "Label"] = valueLabel
    self[key] = slider

    return y + 22 + 22 + 14
end

--=====================================================================
-- STATUS BAR — full width, Photoshop-style
--=====================================================================
function ImageEditor:_buildStatusBar()
    self.statusBar = UI.UIPanel.new(0, SCREEN_HEIGHT - STATUS_H, SCREEN_WIDTH, STATUS_H)
    self.statusBar.r, self.statusBar.g, self.statusBar.b = table.unpack(PALETTE.statusBar)
    self.statusBar.clip = false
    self.statusBar:updateAbsolutePosition(0, 0)
end

--=====================================================================
-- HISTORY / EFFECTS
--=====================================================================
function ImageEditor:_pushHistory()
    if not self.image then return end
    self.history[#self.history + 1] = self.image
end

function ImageEditor:_applyEffect(fn)
    if not self.image then return end

    self:_pushHistory()

    local result = fn(self.image)
    if result then
        self.image = result
        self:_updateInfo()
        self:_status("Effect applied")
    end
end

--=====================================================================
-- IMAGE / SPRITE OPERATIONS
--=====================================================================
function ImageEditor:open(path)
    if not path or path == "" then return end

    local image = Image.createImage(path)
    if not image then
        self:_status("Failed to load image")
        return
    end

    self.image = image
    self.imagePath = path
    self.sprites = {}
    self.selectedSprite = nil
    self.selection = nil
    self.history = {}
    self.zoom = 1

    self:_updateSpriteList()
    self:_updateInfo()
    self:_fitImage()
    self:_status("Opened " .. path)
end

function ImageEditor:_updateSpriteList()
    local items = {}

    for i, sprite in ipairs(self.sprites) do
        items[#items + 1] = sprite
    end

    self.spriteList:setItems(items)
    self.spriteList.selectedIndex = self.selectedSprite or 0
end

function ImageEditor:_split()
    if not self.image then return end

    local columns, rows = 4, 4
    local width, height = self.image:getWidth(), self.image:getHeight()
    local frameW = math.floor(width / columns)
    local frameH = math.floor(height / rows)

    local frames = ImageProcessing.splitByFrameSize(self.image, frameW, frameH)
    self.sprites = {}

    for i, frame in ipairs(frames) do
        self.sprites[i] = {
            image = frame,
            x = ((i - 1) % columns) * frameW,
            y = math.floor((i - 1) / columns) * frameH,
            width = frameW,
            height = frameH,
            pivotX = math.floor(frameW / 2),
            pivotY = math.floor(frameH / 2),
        }
    end

    self:_updateSpriteList()
    self:_status("Split into " .. #self.sprites .. " sprites")
end

function ImageEditor:_selectSprite(index)
    local sprite = self.sprites[index]
    if not sprite then return end

    self.selectedSprite = index
    self.selection = { x = sprite.x, y = sprite.y, width = sprite.width, height = sprite.height }
    self:_updateInfo()
end

function ImageEditor:_crop()
    if not self.image or not self.selection then return end

    local s = self.selection
    self:_pushHistory()

    local result = ImageProcessing.crop(
        self.image,
        math.floor(s.x), math.floor(s.y),
        math.floor(s.width), math.floor(s.height)
    )

    if result then
        self.image = result
        self.selection = nil
        self.sprites = {}
        self:_updateSpriteList()
        self:_updateInfo()
        self:_fitImage()
        self:_status("Cropped")
    end
end

function ImageEditor:_rotate()
    if not self.image then return end

    self:_pushHistory()
    local result = ImageProcessing.rotate90(self.image, 1)

    if result then
        self.image = result
        self.selection = nil
        self:_updateInfo()
        self:_fitImage()
        self:_status("Rotated 90°")
    end
end

function ImageEditor:_flip()
    if not self.image then return end

    self:_pushHistory()
    local result = ImageProcessing.flip(self.image, FlipDirection.HORIZONTAL)

    if result then
        self.image = result
        self:_updateInfo()
        self:_status("Flipped")
    end
end

function ImageEditor:_undo()
    if #self.history == 0 then
        self:_status("Nothing to undo")
        return
    end

    self.image = self.history[#self.history]
    self.history[#self.history] = nil

    self.selection = nil
    self:_updateInfo()
    self:_fitImage()
    self:_status("Undo")
end

function ImageEditor:_save()
    if not self.image then return end

    if self.image.save then
        self.image:save(self.imagePath)
        self:_status("Saved")
    else
        self:_status("Image save() not available")
    end
end

--=====================================================================
-- CAMERA / VIEWPORT (zoom, pan, coordinate conversion)
--=====================================================================
function ImageEditor:_fitImage()
    if not self.image then
        self.zoom = 1
        self.panX = CANVAS_W / 2
        self.panY = CANVAS_H / 2
        return
    end

    local iw, ih = self.image:getWidth(), self.image:getHeight()
    local margin = 32

    local zx = (CANVAS_W - margin) / iw
    local zy = (CANVAS_H - margin) / ih

    self.zoom = clamp(math.min(zx, zy), ZOOM_MIN, ZOOM_MAX)
    self:_centerImage()
end

function ImageEditor:_centerImage()
    if not self.image then return end

    local iw = self.image:getWidth() * self.zoom
    local ih = self.image:getHeight() * self.zoom

    self.panX = (CANVAS_W - iw) / 2
    self.panY = (CANVAS_H - ih) / 2
end

function ImageEditor:_zoomAt(px, py, newZoom)
    newZoom = clamp(newZoom, ZOOM_MIN, ZOOM_MAX)

    local lx = px - CANVAS_X
    local ly = py - CANVAS_Y

    local sx = (lx - self.panX) / self.zoom
    local sy = (ly - self.panY) / self.zoom

    self.zoom = newZoom
    self.panX = lx - sx * self.zoom
    self.panY = ly - sy * self.zoom

    self:_clampPan()
end

-- Keeps at least `minVisible` px of the image inside the canvas on every
-- axis, regardless of zoom level. Without this, scrolling to zoom near an
-- edge (or zooming far out) could push the whole image outside the canvas
-- with no way back except pressing F to re-fit.
function ImageEditor:_clampPan()
    if not self.image then return end

    local minVisible = 32
    local iw = self.image:getWidth() * self.zoom
    local ih = self.image:getHeight() * self.zoom

    local minX = math.min(minVisible - iw, CANVAS_W - minVisible)
    local maxX = math.max(minVisible - iw, CANVAS_W - minVisible)
    self.panX = clamp(self.panX, minX, maxX)

    local minY = math.min(minVisible - ih, CANVAS_H - minVisible)
    local maxY = math.max(minVisible - ih, CANVAS_H - minVisible)
    self.panY = clamp(self.panY, minY, maxY)
end

function ImageEditor:_imageRect()
    if not self.image then return nil end

    return CANVAS_X + self.panX,
        CANVAS_Y + self.panY,
        self.image:getWidth() * self.zoom,
        self.image:getHeight() * self.zoom
end

function ImageEditor:_screenToImage(px, py)
    if not self.image then return nil end

    return (px - CANVAS_X - self.panX) / self.zoom,
        (py - CANVAS_Y - self.panY) / self.zoom
end

function ImageEditor:_imageToScreen(x, y)
    return CANVAS_X + self.panX + x * self.zoom,
        CANVAS_Y + self.panY + y * self.zoom
end

function ImageEditor:_insideImage(px, py)
    local x, y, w, h = self:_imageRect()
    if not x then return false end

    return px >= x and px <= x + w and py >= y and py <= y + h
end

function ImageEditor:_updateInfo()
    if not self.image then
        self.infoLabel.text = "No image"
        return
    end

    local w, h = self.image:getWidth(), self.image:getHeight()

    if self.selection then
        self.infoLabel.text = string.format(
            "Size: %dx%d\nSelection: %d, %d\n%dx%d   %.0f%%",
            w, h, self.selection.x, self.selection.y,
            self.selection.width, self.selection.height, self.zoom * 100
        )
    else
        self.infoLabel.text = string.format("Size: %dx%d\nZoom: %.0f%%", w, h, self.zoom * 100)
    end
end

function ImageEditor:_status(text)
    self.status = text
    self.statusTimer = 3
end

--=====================================================================
-- INPUT
--=====================================================================
function ImageEditor:_forEachButton(fn)
    for _, btn in ipairs(self.toolbarButtons) do fn(btn) end

    fn(self.grayButton); fn(self.invertButton); fn(self.outlineButton)
    fn(self.shadowButton); fn(self.glowButton); fn(self.trimButton)
    fn(self.removeBgButton)
end

function ImageEditor:onPointerPressed(px, py)
    if self._picker.visible then
        self._picker:onPointerPressed(px, py)
        return
    end

    local consumed = false
    self:_forEachButton(function(btn)
        if not consumed and btn:onPointerPressed(px, py) then consumed = true end
    end)
    if consumed then return end

    if self.brightness:onPointerPressed(px, py) then return end
    if self.contrast:onPointerPressed(px, py) then return end

    if px < LEFT_W and py >= TOOLBAR_H then
        self.spriteList:onPointerPressed(px, py)
        return
    end

    if px < CANVAS_X or px > CANVAS_X + CANVAS_W then return end
    if py < CANVAS_Y or py > CANVAS_Y + CANVAS_H then return end

    if self:_insideImage(px, py) then
        local x, y = self:_screenToImage(px, py)

        self.selecting = true
        self.selectStartX = snap(x)
        self.selectStartY = snap(y)

        self.selection = { x = self.selectStartX, y = self.selectStartY, width = 0, height = 0 }
    else
        self.panning = true
        self.dragStartX, self.dragStartY = px, py
        self.panStartX, self.panStartY = self.panX, self.panY
    end
end

function ImageEditor:onPointerDragged(px, py)
    if self._picker.visible then
        self._picker:onPointerDragged(px, py)
        return
    end

    self.brightness:onPointerDragged(px, py)
    self.contrast:onPointerDragged(px, py)

    if self.panning then
        self.panX = self.panStartX + px - self.dragStartX
        self.panY = self.panStartY + py - self.dragStartY
        self:_clampPan()
        return
    end

    if self.selecting then
        local x, y = self:_screenToImage(px, py)
        if not x then return end

        local sx, sy = self.selectStartX, self.selectStartY

        x = clamp(snap(x), 0, self.image:getWidth())
        y = clamp(snap(y), 0, self.image:getHeight())

        self.selection.x = math.min(sx, x)
        self.selection.y = math.min(sy, y)
        self.selection.width = math.abs(x - sx)
        self.selection.height = math.abs(y - sy)

        self:_updateInfo()
    end
end

function ImageEditor:onPointerReleased(px, py)
    if self._picker.visible then
        self._picker:onPointerReleased(px, py)
        return
    end

    self:_forEachButton(function(btn) btn:onPointerReleased(px, py) end)
    self.brightness:onPointerReleased(px, py)
    self.contrast:onPointerReleased(px, py)
    self.spriteList:onPointerReleased(px, py)

    self.selecting = false
    self.panning = false

    if self.selection then
        if self.selection.width < GRID or self.selection.height < GRID then
            self.selection = nil
        end
        self:_updateInfo()
    end
end

function ImageEditor:onScrolled(scrollX, scrollY)
    local x, y = Input.getX(), Input.getY()

    if x < LEFT_W then
        self.spriteList:onScrolled(scrollX, scrollY)
        return true
    end

    if x >= CANVAS_X and x <= CANVAS_X + CANVAS_W and y >= CANVAS_Y and y <= CANVAS_Y + CANVAS_H then
        if scrollY > 0 then
            self:_zoomAt(x, y, self.zoom + ZOOM_STEP)
        elseif scrollY < 0 then
            self:_zoomAt(x, y, self.zoom - ZOOM_STEP)
        end

        self:_updateInfo()
        return true
    end

    return false
end

function ImageEditor:onKeyPressed(key)
    if self._picker.visible then
        self._picker:onKeyPressed(key)
        return
    end

    if key == Input.KEY_F then
        self:_fitImage(); return
    end
    if key == Input.KEY_DELETE then
        self.selection = nil; self:_updateInfo(); return
    end
    if key == Input.KEY_R then
        self:_rotate(); return
    end
    if key == Input.KEY_X then
        self:_flip(); return
    end
end

function ImageEditor:update(dt)
    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - dt
    end

    self:_updateInfo()
end

--=====================================================================
-- RENDERING
--=====================================================================
function ImageEditor:_renderCheckerboard(g, x, y, w, h)
    local size = 12
    local right, bottom = x + w, y + h

    g:setColor(60, 60, 64, 255)
    g:fillRect(x, y, w, h)
    g:setColor(72, 72, 77, 255)

    local startX = math.floor(x / size) * size
    local startY = math.floor(y / size) * size
    local row = math.floor(startY / size)

    for py = startY, bottom, size do
        local col = math.floor(startX / size)

        for px = startX, right, size do
            if (row + col) % 2 == 1 then
                local rw = math.min(size, right - px)
                local rh = math.min(size, bottom - py)
                if rw > 0 and rh > 0 then
                    g:fillRect(px, py, rw, rh)
                end
            end
            col = col + 1
        end
        row = row + 1
    end
end

function ImageEditor:_renderImage(g)
    if not self.image then
        g:setColor(120, 122, 130, 255)
        g:drawString("Open an image to begin", CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2, Graphics.CENTER)
        return
    end

    local x, y, w, h = self:_imageRect()

    self:_renderCheckerboard(g, x, y, w, h)

    g:drawImageScale(self.image, x, y, w, h)

    g:setColor(table.unpack(PALETTE.border))
    g:drawRect(x, y, w, h)
end

function ImageEditor:_renderPixelGrid(g)
    if not self.image or self.zoom < 4 then return end

    local x, y, w, h = self:_imageRect()
    local iw, ih = self.image:getWidth(), self.image:getHeight()

    g:setColor(255, 255, 255, 35)

    for ix = 0, iw, GRID do
        local sx = x + ix * self.zoom
        if sx >= CANVAS_X and sx <= CANVAS_X + CANVAS_W then
            g:drawLine(sx, y, sx, y + h)
        end
    end

    for iy = 0, ih, GRID do
        local sy = y + iy * self.zoom
        if sy >= CANVAS_Y and sy <= CANVAS_Y + CANVAS_H then
            g:drawLine(x, sy, x + w, sy)
        end
    end
end

function ImageEditor:_renderSelection(g)
    if not self.selection then return end

    local s = self.selection
    local x, y = self:_imageToScreen(s.x, s.y)
    local w, h = s.width * self.zoom, s.height * self.zoom

    g:setColor(table.unpack(PALETTE.accent))
    g:setColor(60, 150, 240, 60)
    g:fillRect(x, y, w, h)

    g:setColor(table.unpack(PALETTE.accent))
    g:drawRect(x, y, w, h)

    local hs = 6
    g:setColor(255, 255, 255, 255)
    g:fillRect(x - hs / 2, y - hs / 2, hs, hs)
    g:fillRect(x + w - hs / 2, y - hs / 2, hs, hs)
    g:fillRect(x - hs / 2, y + h - hs / 2, hs, hs)
    g:fillRect(x + w - hs / 2, y + h - hs / 2, hs, hs)
end

-- small floating "dimensions / zoom" chip in the bottom-left of the canvas
function ImageEditor:_renderCanvasBadge(g)
    if not self.image then return end

    local text = string.format("%dx%d   %.0f%%", self.image:getWidth(), self.image:getHeight(), self.zoom * 100)
    local badgeW, badgeH = 130, 22
    local bx = CANVAS_X + 10
    local by = CANVAS_Y + CANVAS_H - badgeH - 10

    g:setColor(20, 20, 22, 190)
    g:fillRect(bx, by, badgeW, badgeH)
    g:setColor(table.unpack(PALETTE.textSecond))
    g:drawString(text, bx + 8, by + badgeH / 2, Graphics.CENTER_LEFT)
end

function ImageEditor:_renderToolbarSeparators(g)
    g:setColor(table.unpack(PALETTE.border))
    for _, sx in ipairs(self.toolbarSeparators) do
        g:drawLine(sx, 8, sx, TOOLBAR_H - 8)
    end
end

function ImageEditor:_renderStatusBar(g)
    self.statusBar:render(g)

    if self.statusTimer > 0 then
        g:setColor(table.unpack(PALETTE.success))
        g:drawString(self.status, PAD, SCREEN_HEIGHT - STATUS_H / 2, Graphics.CENTER_LEFT)
    end

    if self.imagePath ~= "" then
        g:setColor(table.unpack(PALETTE.textMuted))
        g:drawString(self.imagePath, SCREEN_WIDTH - PAD, SCREEN_HEIGHT - STATUS_H / 2, Graphics.CENTER_RIGHT)
    end
end

function ImageEditor:render(g)
    -- Canvas
    self.canvasPanel:render(g)

    g:save()
    g:setClip(CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H)
    self:_renderImage(g)
    self:_renderPixelGrid(g)
    self:_renderSelection(g)
    g:restore()

    self:_renderCanvasBadge(g)

    -- Left panel
    self.leftPanel:render(g)
    self.spriteTitle:render(g)
    self.spriteList:draw(g)

    -- Right panel
    self.rightPanel:render(g)
    self.propertiesTitle:render(g)
    self.infoLabel:render(g)
    self.effectTitle:render(g)

    self.grayButton:render(g)
    self.invertButton:render(g)
    self.outlineButton:render(g)
    self.shadowButton:render(g)
    self.glowButton:render(g)
    self.trimButton:render(g)
    self.removeBgButton:render(g)

    self.adjustTitle:render(g)
    self.brightnessLabel:render(g)
    self.brightness:render(g)
    self.contrastLabel:render(g)
    self.contrast:render(g)

    -- Toolbar (drawn above panels so separators sit correctly on top)
    self.toolbar:render(g)
    for _, btn in ipairs(self.toolbarButtons) do btn:render(g) end
    self:_renderToolbarSeparators(g)

    self:_renderStatusBar(g)

    self._picker:render(g)
end

return ImageEditor
