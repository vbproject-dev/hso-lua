local Scene            = require("gfx.Scene")
local UIWidget         = require("gfx.ui.UIWidget")
local UIInspector      = require("gfx.ui.UIInspector")
local UIToolbar        = require("gfx.ui.UIToolbar")
local UIImagePicker    = require("gfx.ui.UIImagePicker")
local UIColorPicker    = require("gfx.ui.UIColorPicker")
local UI               = require("gfx.ui.components.init")
local UIRuntimePreview = require("gfx.scenes.UIRuntimePreview")
local UIJson           = require("gfx.ui.UIJson")

local UIEditor         = class("UIEditor", Scene)

-- ─── layout ──────────────────────────────────────────────────────────────────
local TOOLBAR_H        = 52
local HIER_W           = 224
local INSP_W           = 290
local CANVAS_X         = HIER_W
local CANVAS_Y         = TOOLBAR_H
local CANVAS_W         = SCREEN_WIDTH - HIER_W - INSP_W
local CANVAS_H         = SCREEN_HEIGHT - TOOLBAR_H
local GRID             = 8
local SAVE_PATH        = "ui_layout.json"

-- canvas virtual size (the "scene" space)
local SCENE_W          = SCREEN_WIDTH
local SCENE_H          = SCREEN_HEIGHT

-- zoom limits
local ZOOM_MIN         = 0.1
local ZOOM_MAX         = 4.0
local ZOOM_STEP        = 0.15

-- hierarchy tree layout
local HIER_ROW_H       = 28
local INDENT_W         = 16
local TOGGLE_W         = 14
local DRAG_THRESHOLD   = 6 -- px, before a press-in-hierarchy becomes a drag

-- type icon colors
local TYPE_IC          = {
    Canvas      = { 90, 200, 210 },
    Panel       = { 5, 80, 160 },
    Button      = { 60, 100, 200 },
    Image       = { 40, 140, 70 },
    Label       = { 120, 80, 180 },
    TextField   = { 80, 130, 180 },
    ScrollView  = { 100, 60, 160 },
    Slider      = { 40, 150, 160 },
    Checkbox    = { 160, 130, 40 },
    RadioButton = { 170, 90, 40 },
    ProgressBar = { 40, 170, 90 },
    ListView    = { 80, 110, 180 },
    Tooltip     = { 150, 60, 60 },
    ConsoleLog  = { 90, 200, 140 },
}

local function snapToGrid(v) return math.floor(v / GRID + 0.5) * GRID end

-- ─── ctor ────────────────────────────────────────────────────────────────────

function UIEditor:ctor()
    UIEditor.super.ctor(self)

    -- The scene tree: an invisible root widget owns every top-level widget,
    -- so "no parent" is never a special case anywhere else in the editor —
    -- reparenting, deletion and traversal all just walk widget.parent /
    -- widget.children, root included.
    self.sceneRoot                              = UIWidget.new(UIWidget.ROOT_TYPE)
    self.sceneRoot.x, self.sceneRoot.y          = 0, 0
    self.sceneRoot.width, self.sceneRoot.height = SCENE_W, SCENE_H
    self.sceneRoot.a                            = 0
    self.sceneRoot:syncToComponent()

    self.selected                                  = nil
    -- Multiple top-level Canvases can overlap the whole scene (HUD vs.
    -- pause-menu, etc). Only ONE is ever rendered / hit-tested / overlaid
    -- at a time in the editor — this is that canvas. Everything else is
    -- still in the tree and hierarchy, just parked off-screen until focused.
    self.focusedCanvas                             = nil
    self.dragging                                  = false
    self.resizing                                  = false
    self.dragOffX                                  = 0
    self.dragOffY                                  = 0
    self.status                                    = ""
    self.statusTimer                               = 0
    self.statusIsErr                               = false

    -- zoom / pan state
    self.zoom                                      = 1.0
    self.panX                                      = 0 -- offset of scene origin in canvas space
    self.panY                                      = 0
    self._panning                                  = false
    self._panStartX                                = 0
    self._panStartY                                = 0
    self._panOriginX                               = 0
    self._panOriginY                               = 0

    self._pickerKey                                = nil
    self.playing                                   = false
    self._preview                                  = nil
    -- new-scene naming modal
    self._awaitingSceneName                        = false
    self._newSceneBuf                              = ""
    self._newSceneCursor                           = 0
    self._sceneName                                = "untitled"
    self._savePath                                 = SAVE_PATH

    -- hierarchy tree UI state
    self._hierRows                                 = {} -- flattened visible rows: { widget, depth }
    self._hierScrollY                              = 0
    self._hierPressWidget                          = nil
    self._hierPressX, self._hierPressY             = 0, 0
    self._hierDragging                             = false
    self._hierHoverRow                             = nil
    self._hierHoverPos                             = nil -- "before" | "after" | "inside"

    -- modals
    self.picker                                    = UIImagePicker.new(function(path)
        if self.selected and self._pickerKey then
            self.selected[self._pickerKey] = path
            if self._pickerKey == "bgImagePath" then
                self.selected.component:setBgImage(path)
            elseif self._pickerKey == "imagePath" then
                self.selected.component:setImage(path)
            end
            self._pickerKey = nil
        end
    end)

    self.colorPicker                               = UIColorPicker.new(function(r, g, b, a)
        if self.selected then
            self.selected.r = r
            self.selected.g = g
            self.selected.b = b
            self.selected.a = a
        end
    end)

    self.inspector                                 = UIInspector.new(
        function(key, path)
            self.picker:open(); self._pickerKey = key
        end,
        function()
            if self.selected then
                self.colorPicker:open(
                    self.selected.r or 255, self.selected.g or 255,
                    self.selected.b or 255, self.selected.a or 255)
            end
        end
    )

    self.toolbar                                   = UIToolbar.new(function(a) self:_onAction(a) end)

    -- ── Left panel layout ─────────────────────────────────────────────────
    -- Split: top half = Components list, bottom half = Hierarchy tree
    local COMP_H                                   = 280
    local HIER_H                                   = CANVAS_H - COMP_H
    local HDR_H                                    = 30

    -- full left bg
    self._hierBg                                   = UI.UIPanel.new(0, TOOLBAR_H, HIER_W, CANVAS_H)
    self._hierBg.r, self._hierBg.g, self._hierBg.b = 18, 18, 22
    self._hierBg.clip                              = false
    self._hierBg:updateAbsolutePosition(0, 0)

    -- ── Components section ────────────────────────────────────────────────
    self._compHeader = UI.UIPanel.new(0, TOOLBAR_H, HIER_W, HDR_H)
    self._compHeader.r, self._compHeader.g, self._compHeader.b = 14, 14, 18
    self._compHeader.clip = false
    self._compHeader:updateAbsolutePosition(0, 0)

    self._compTitle = UI.UILabel.new(14, TOOLBAR_H, HIER_W - 14, HDR_H)
    self._compTitle.text = "Components"
    self._compTitle.textR, self._compTitle.textG, self._compTitle.textB = 140, 155, 200
    self._compTitle.textAnchor = Graphics.CENTER_LEFT
    self._compTitle:updateAbsolutePosition(0, 0)

    -- component type list — clicking adds that widget as a child of the
    -- current selection (or at the scene root if nothing is selected)
    local ADD_TYPES                                                           = {
        "Canvas",
        "Panel", "Button", "Image", "Label", "TextField",
        "ScrollView", "Slider", "Checkbox", "RadioButton",
        "ProgressBar", "ListView", "Tooltip", "ConsoleLog"
    }

    self._compList                                                            = UI.UIListView.new(0, TOOLBAR_H + HDR_H,
        HIER_W, COMP_H - HDR_H)
    self._compList.r, self._compList.g, self._compList.b                      = 18, 18, 22
    self._compList.itemR, self._compList.itemG, self._compList.itemB          = 22, 22, 27
    self._compList.selR, self._compList.selG, self._compList.selB             = 28, 58, 115
    self._compList.textR, self._compList.textG, self._compList.textB          = 165, 175, 205
    self._compList.selTextR, self._compList.selTextG, self._compList.selTextB = 215, 228, 255
    self._compList.itemHeight                                                 = 30
    self._compList:setItems(ADD_TYPES)
    self._compList.onSelect = function(idx, item)
        self:_onAction("add_" .. item)
        self._compList.selectedIndex = 0 -- deselect after add
    end
    self._compList:updateAbsolutePosition(0, 0)
    self._addTypes = ADD_TYPES

    -- ── Hierarchy section (custom tree — no generic list widget, since it
    --    needs to draw indentation, expand arrows and drop indicators) ─────
    local hierTop = TOOLBAR_H + COMP_H
    self._hierHeader = UI.UIPanel.new(0, hierTop, HIER_W, HDR_H)
    self._hierHeader.r, self._hierHeader.g, self._hierHeader.b = 14, 14, 18
    self._hierHeader.clip = false
    self._hierHeader:updateAbsolutePosition(0, 0)

    self._hierTitle = UI.UILabel.new(14, hierTop, HIER_W - 14, HDR_H)
    self._hierTitle.text = "Hierarchy"
    self._hierTitle.textR, self._hierTitle.textG, self._hierTitle.textB = 140, 155, 200
    self._hierTitle.textAnchor = Graphics.CENTER_LEFT
    self._hierTitle:updateAbsolutePosition(0, 0)

    self._hierListY                                      = hierTop + HDR_H
    self._hierListH                                      = HIER_H - HDR_H

    -- store for render
    self._COMP_H                                         = COMP_H
    self._HIER_H                                         = HIER_H
    self._HDR_H                                          = HDR_H

    -- ── Canvas background ─────────────────────────────────────────────────
    self._canvasBg                                       = UI.UIPanel.new(CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H)
    self._canvasBg.r, self._canvasBg.g, self._canvasBg.b = 32, 32, 38
    self._canvasBg.clip                                  = false
    self._canvasBg:updateAbsolutePosition(0, 0)

    -- ── Status bar ────────────────────────────────────────────────────────
    self._statusBar = UI.UIPanel.new(CANVAS_X, SCREEN_HEIGHT - 24, CANVAS_W, 24)
    self._statusBar.r, self._statusBar.g, self._statusBar.b = 14, 14, 18
    self._statusBar.clip = false
    self._statusBar:updateAbsolutePosition(0, 0)

    self:_rebuildHierRows()
    self:_ensureFocusedCanvas()
    self:_fitZoom()
end

-- ─── zoom helpers ─────────────────────────────────────────────────────────────

function UIEditor:_fitZoom()
    local zx = (CANVAS_W - 40) / SCENE_W
    local zy = (CANVAS_H - 40) / SCENE_H
    self.zoom = math.max(ZOOM_MIN, math.min(ZOOM_MAX, math.min(zx, zy)))
    self.panX = math.floor((CANVAS_W - SCENE_W * self.zoom) / 2)
    self.panY = math.floor((CANVAS_H - SCENE_H * self.zoom) / 2)
end

-- scene coords → screen coords
function UIEditor:_toScreen(sx, sy)
    return CANVAS_X + self.panX + sx * self.zoom,
        CANVAS_Y + self.panY + sy * self.zoom
end

-- screen coords → scene coords
function UIEditor:_toScene(px, py)
    return (px - CANVAS_X - self.panX) / self.zoom,
        (py - CANVAS_Y - self.panY) / self.zoom
end

function UIEditor:_zoomAt(px, py, newZoom)
    newZoom = math.max(ZOOM_MIN, math.min(ZOOM_MAX, newZoom))
    -- keep point under cursor fixed
    local sx = (px - CANVAS_X - self.panX) / self.zoom
    local sy = (py - CANVAS_Y - self.panY) / self.zoom
    self.zoom = newZoom
    self.panX = px - CANVAS_X - sx * self.zoom
    self.panY = py - CANVAS_Y - sy * self.zoom
end

-- ─── canvas focus ────────────────────────────────────────────────────────────

-- Is `w` visible in the editor right now? True for every non-Canvas widget
-- (they're gated only by their ancestor canvas) and for the one Canvas
-- currently focused. This is the single predicate render/hit-test/overlay
-- all share, so "which canvas is showing" can never drift between them.
function UIEditor:_isEditorVisible(w)
    return w.type ~= UIWidget.TYPES.CANVAS or w == self.focusedCanvas
end

-- Walks up from `w` to find the top-level Canvas it lives under (or `w`
-- itself, if it is one). Returns nil for a widget with no Canvas ancestor.
function UIEditor:_findAncestorCanvas(w)
    local cur = w
    while cur do
        if cur.type == UIWidget.TYPES.CANVAS then return cur end
        cur = cur.parent
    end
    return nil
end

-- Keeps self.focusedCanvas pointing at a Canvas that's actually still in
-- the tree, picking the first available one if it's stale (destroyed,
-- cleared, or a fresh scene load) or unset. No-op if the current focus is
-- still valid — call this after any structural change to the scene root.
function UIEditor:_ensureFocusedCanvas()
    if self.focusedCanvas then
        for _, w in ipairs(self.sceneRoot.children) do
            if w == self.focusedCanvas then return end
        end
    end
    self.focusedCanvas = nil
    for _, w in ipairs(self.sceneRoot.children) do
        if w.type == UIWidget.TYPES.CANVAS then
            self.focusedCanvas = w
            return
        end
    end
end

-- ─── hierarchy tree ───────────────────────────────────────────────────────────

-- Flattens the visible portion of the tree (respecting each widget's
-- `expanded` state) into an ordered row list for rendering and hit-testing.
-- Call whenever the tree shape or a fold state changes.
function UIEditor:_rebuildHierRows()
    self._hierRows = {}
    local function visit(list, depth)
        for _, w in ipairs(list) do
            self._hierRows[#self._hierRows + 1] = { widget = w, depth = depth }
            if w.expanded and #w.children > 0 then
                visit(w.children, depth + 1)
            end
        end
    end
    visit(self.sceneRoot.children, 0)
end

function UIEditor:_countWidgets()
    local function count(list)
        local n = #list
        for _, w in ipairs(list) do n = n + count(w.children) end
        return n
    end
    return count(self.sceneRoot.children)
end

function UIEditor:_rowIndexAt(py)
    local localY = py - self._hierListY + self._hierScrollY
    local idx = math.floor(localY / HIER_ROW_H) + 1
    if idx < 1 or idx > #self._hierRows then return nil end
    return idx
end

function UIEditor:_rowScreenY(idx)
    return self._hierListY + (idx - 1) * HIER_ROW_H - self._hierScrollY
end

-- Top quarter of a row = insert before it, bottom quarter = insert after
-- it, the middle half = drop *into* it as a new child — matching Unity's
-- Hierarchy drag conventions.
function UIEditor:_dropPosAt(py, rowY)
    local rel = (py - rowY) / HIER_ROW_H
    if rel < 0.25 then
        return "before"
    elseif rel > 0.75 then
        return "after"
    else
        return "inside"
    end
end

-- Moves `widget` to sit before/after/inside `target` in the tree. Refuses
-- no-op and cycle-forming drops (dropping a widget onto its own descendant).
-- Its world position is preserved across the move — since x/y are local to
-- the parent, re-parenting under a differently-positioned parent would
-- otherwise make it visually jump.
function UIEditor:_reparent(widget, target, dropPos)
    if widget == target or target:isDescendantOf(widget) then return end

    -- Canvases are always top-level: only allow reordering them among their
    -- root siblings, never dropping one underneath another widget.
    if widget.type == UIWidget.TYPES.CANVAS then
        local resultingParent = (dropPos == "inside") and target or (target.parent or self.sceneRoot)
        if resultingParent ~= self.sceneRoot then return end
    end

    local worldX, worldY = widget:getWorldPos()
    if dropPos == "inside" then
        target:addChild(widget)
        target.expanded = true
    else
        local newParent = target.parent or self.sceneRoot
        widget:removeFromParent()
        local idx = #newParent.children + 1
        for i, sibling in ipairs(newParent.children) do
            if sibling == target then
                idx = (dropPos == "after") and (i + 1) or i
                break
            end
        end
        newParent:addChild(widget, idx)
    end
    widget.x, widget.y = widget:worldToLocal(worldX, worldY)
    self:_rebuildHierRows()
end

function UIEditor:_hierPointerPressed(px, py)
    local idx = self:_rowIndexAt(py)
    if not idx then
        self:_select(nil)
        return
    end

    local row = self._hierRows[idx]
    local toggleX = 6 + row.depth * INDENT_W
    if #row.widget.children > 0 and px >= toggleX and px <= toggleX + TOGGLE_W then
        row.widget.expanded = not row.widget.expanded
        self:_rebuildHierRows()
        return
    end

    self:_select(row.widget)
    self._hierPressWidget = row.widget
    self._hierPressX, self._hierPressY = px, py
    self._hierDragging = false
end

function UIEditor:_hierPointerDragged(px, py)
    if not self._hierPressWidget then return end

    if not self._hierDragging then
        local dx, dy = px - self._hierPressX, py - self._hierPressY
        if dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then return end
        self._hierDragging = true
    end

    local idx = self:_rowIndexAt(py)
    if not idx then
        self._hierHoverRow, self._hierHoverPos = nil, nil
        return
    end
    local row = self._hierRows[idx]
    if row.widget == self._hierPressWidget or row.widget:isDescendantOf(self._hierPressWidget) then
        self._hierHoverRow, self._hierHoverPos = nil, nil -- would create a cycle
        return
    end
    self._hierHoverRow = idx
    self._hierHoverPos = self:_dropPosAt(py, self:_rowScreenY(idx))
end

function UIEditor:_hierPointerReleased()
    if self._hierDragging and self._hierHoverRow then
        local row = self._hierRows[self._hierHoverRow]
        local moved = self._hierPressWidget
        self:_reparent(moved, row.widget, self._hierHoverPos)
        self:_select(moved)
        self:_status("Moved " .. moved.name)
    end
    self._hierPressWidget = nil
    self._hierDragging = false
    self._hierHoverRow, self._hierHoverPos = nil, nil
end

-- ─── actions ─────────────────────────────────────────────────────────────────

function UIEditor:_onAction(action)
    if action:sub(1, 4) == "add_" then
        local wtype = action:sub(5)
        local w = UIWidget.new(wtype)
        local parent

        if wtype == UIWidget.TYPES.CANVAS then
            -- Canvases are always top-level, full-scene containers — like
            -- Unity's Canvas, they never live under another widget, and
            -- can freely overlap other canvases (Panel1/Panel2/... nest
            -- underneath each one independently). A newly added canvas
            -- becomes the focused one so you immediately see what you made.
            parent = self.sceneRoot
            w.x, w.y = 0, 0
            self.focusedCanvas = w
        elseif self.selected then
            parent = self.selected
            -- x/y are local to the new parent, so centering is just half
            -- the parent's own size — no world coordinates involved.
            w.x = snapToGrid((self.selected.width - w.width) / 2)
            w.y = snapToGrid((self.selected.height - w.height) / 2)
        else
            parent = self.sceneRoot
            local cx, cy = self:_toScene(CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2)
            w.x = snapToGrid(cx - w.width / 2)
            w.y = snapToGrid(cy - w.height / 2)
        end
        parent:addChild(w)
        self:_rebuildHierRows()
        self:_select(w)
        self:_status("Added " .. wtype)
    elseif action == "delete" then
        if self.selected then
            local w = self.selected
            self:_select(nil)
            w:destroy() -- cascades to every descendant
            self:_rebuildHierRows()
            self:_ensureFocusedCanvas()
            self:_status("Deleted")
        end
    elseif action == "save" then
        self:_save()
    elseif action == "new" then
        -- prompt for new scene name; will clear canvas after confirmation
        if not self._awaitingSceneName then
            self._awaitingSceneName = true
            self._newSceneBuf = ""
            self._newSceneCursor = 0
            Input.startInput()
            Input.setInputCallback(function(ch)
                local b = self._newSceneBuf
                self._newSceneBuf = b:sub(1, self._newSceneCursor) .. ch .. b:sub(self._newSceneCursor + 1)
                self._newSceneCursor = self._newSceneCursor + #ch
            end)
            self:_status("Enter scene name and press Enter")
        end
    elseif action == "load" then
        self:_load()
    elseif action == "play" then
        if not self.playing then
            -- start preview
            self._preview = UIRuntimePreview.new()
            self.playing = true
            self.toolbar:setActionLabel("play", "Stop")
            self:_status("Preview started")
        else
            -- stop preview
            if self._preview and self._preview.dispose then self._preview:dispose() end
            self._preview = nil
            self.playing = false
            self.toolbar:setActionLabel("play", "Play")
            self:_status("Preview stopped")
        end
    elseif action == "clear" then
        for i = #self.sceneRoot.children, 1, -1 do
            self.sceneRoot.children[i]:destroy()
        end
        self.focusedCanvas = nil
        self:_select(nil)
        self:_rebuildHierRows()
        self:_status("Canvas cleared")
    elseif action == "zoom_in" then
        self:_zoomAt(CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2, self.zoom + ZOOM_STEP)
    elseif action == "zoom_out" then
        self:_zoomAt(CANVAS_X + CANVAS_W / 2, CANVAS_Y + CANVAS_H / 2, self.zoom - ZOOM_STEP)
    elseif action == "zoom_reset" then
        self.zoom = 1.0; self.panX = math.floor((CANVAS_W - SCENE_W) / 2); self.panY = math.floor((CANVAS_H - SCENE_H) /
            2)
    elseif action == "zoom_fit" then
        self:_fitZoom()
    end
end

-- Selecting a widget also focuses whichever top-level Canvas it lives
-- under (a Canvas row selects itself), so picking anything in the
-- Hierarchy — even something buried under a currently-hidden canvas —
-- brings the right canvas forward automatically.
function UIEditor:_select(w)
    self.selected = w
    self.inspector:setWidget(w)
    if w then
        local canvas = self:_findAncestorCanvas(w)
        if canvas and canvas ~= self.focusedCanvas then
            self.focusedCanvas = canvas
            self:_status("Focused " .. canvas.name)
        end
    end
end

-- ─── save / load ─────────────────────────────────────────────────────────────

function UIEditor:_save()
    UIJson.save(self._savePath, self.sceneRoot.children)
    self:_status("Saved → " .. self._savePath)
end

function UIEditor:_load()
    if not FileUtils.exists(self._savePath) then
        self:_status("File not found: " .. self._savePath, true); return
    end

    local ok, widgets = pcall(UIJson.load, self._savePath)
    if not ok or not widgets then
        self:_status("Invalid JSON", true); return
    end

    for i = #self.sceneRoot.children, 1, -1 do
        self.sceneRoot.children[i]:destroy()
    end

    for _, w in ipairs(widgets) do
        self.sceneRoot:addChild(w)
    end

    self.focusedCanvas = nil
    self:_select(nil)
    self:_rebuildHierRows()
    self:_ensureFocusedCanvas()
    self:_status("Loaded " .. self:_countWidgets() .. " widgets")
end

function UIEditor:_status(msg, isErr)
    self.status = msg; self.statusTimer = 3.0; self.statusIsErr = isErr or false
end

-- ─── hit test in scene space (children take priority over their parent,
--     and later siblings — drawn on top — are tested before earlier ones).
--     Only the focused Canvas (and everything under it) is eligible; other
--     top-level canvases are parked and shouldn't steal clicks even though
--     they occupy the same screen space. ─────────────────────────────────

function UIEditor:_hitTest(sx, sy)
    local function test(list)
        for i = #list, 1, -1 do
            local w = list[i]
            if self:_isEditorVisible(w) then
                if #w.children > 0 then
                    local hit = test(w.children)
                    if hit then return hit end
                end
                if w:contains(sx, sy) then return w end
            end
        end
    end
    return test(self.sceneRoot.children)
end

function UIEditor:_isResizeHandle(w, sx, sy)
    local wx, wy = w:getWorldPos()
    return sx >= wx + w.width - 8 / self.zoom and sx <= wx + w.width + 4 / self.zoom and
        sy >= wy + w.height - 8 / self.zoom and sy <= wy + w.height + 4 / self.zoom
end

local function inCanvas(px, py)
    return px >= CANVAS_X and px <= CANVAS_X + CANVAS_W and
        py >= CANVAS_Y and py <= CANVAS_Y + CANVAS_H
end

-- ─── pointer ─────────────────────────────────────────────────────────────────

function UIEditor:onPointerPressed(px, py)
    if self.colorPicker.visible then
        self.colorPicker:onPointerPressed(px, py); return
    end
    if self.picker.visible then
        self.picker:onPointerPressed(px, py); return
    end
    if self.toolbar:onPointerPressed(px, py) then return end
    -- if preview active and click on canvas, forward to preview
    if self.playing and self._preview then
        if inCanvas(px, py) then
            return self._preview:onPointerPressed(px, py)
        end
    end
    if self.inspector:onPointerPressed(px, py) then return end

    if px < HIER_W then
        if py < TOOLBAR_H + self._COMP_H then
            self._compList:onPointerPressed(px, py)
        else
            self:_hierPointerPressed(px, py)
        end
        return
    end

    if not inCanvas(px, py) then return end

    local sx, sy = self:_toScene(px, py)
    local hit = self:_hitTest(sx, sy)

    if hit then
        self:_select(hit)
        -- Canvases are fixed, full-scene containers (like Unity's Canvas) —
        -- they define the scene bounds, so they're selectable (for the
        -- inspector / focus-switching) but never draggable or resizable
        -- from the editor viewport. Everything else behaves as before.
        if hit.type == UIWidget.TYPES.CANVAS then
            -- no-op: select only
        elseif self:_isResizeHandle(hit, sx, sy) then
            self.resizing = true
            self.dragOffX, self.dragOffY = px, py
        else
            self.dragging = true
            -- dragOffX/Y are the cursor's offset from the widget's *world*
            -- top-left (hit.x/hit.y are local-to-parent and not comparable
            -- to sx/sy, which are in scene/world space).
            local wx, wy = hit:getWorldPos()
            self.dragOffX = sx - wx
            self.dragOffY = sy - wy
        end
    else
        self:_select(nil)
        -- start pan with middle-mouse feel (right side of canvas = pan)
        self._panning    = true
        self._panStartX  = px
        self._panStartY  = py
        self._panOriginX = self.panX
        self._panOriginY = self.panY
    end
end

function UIEditor:onPointerDragged(px, py)
    if self.colorPicker.visible then
        self.colorPicker:onPointerDragged(px, py); return
    end
    if self.picker.visible then
        self.picker:onPointerDragged(px, py); return
    end

    if self.playing and self._preview then
        return self._preview:onPointerDragged(px, py)
    end

    if self._hierPressWidget then
        self:_hierPointerDragged(px, py)
        return
    end

    if self._panning then
        self.panX = self._panOriginX + (px - self._panStartX)
        self.panY = self._panOriginY + (py - self._panStartY)
        return
    end

    if not self.selected then
        self.inspector:onPointerDragged(px, py)
        return
    end

    local sx, sy = self:_toScene(px, py)

    if self.resizing then
        local dw                     = (px - self.dragOffX) / self.zoom
        local dh                     = (py - self.dragOffY) / self.zoom
        self.selected.width          = math.max(20, snapToGrid(self.selected.width + dw))
        self.selected.height         = math.max(20, snapToGrid(self.selected.height + dh))
        self.dragOffX, self.dragOffY = px, py
    elseif self.dragging then
        -- snap the desired *world* position to the grid, then convert down
        -- to the local x/y the widget actually stores — this is what makes
        -- children ride along automatically when a parent is dragged, since
        -- only the parent's local x/y changes.
        local worldX = snapToGrid(sx - self.dragOffX)
        local worldY = snapToGrid(sy - self.dragOffY)
        self.selected.x, self.selected.y = self.selected:worldToLocal(worldX, worldY)
    end

    self._compList:onPointerDragged(px, py)
    self.inspector:onPointerDragged(px, py)
end

function UIEditor:onPointerReleased(px, py)
    if self.colorPicker.visible then
        self.colorPicker:onPointerReleased(px, py); return
    end
    if self.picker.visible then
        self.picker:onPointerReleased(px, py); return
    end
    if self._hierPressWidget then
        self:_hierPointerReleased(px, py)
    end
    self._compList:onPointerReleased(px, py)
    self.dragging = false
    self.resizing = false
    self._panning = false
    self.inspector:onPointerReleased(px, py)
    if self.playing and self._preview then
        return self._preview:onPointerReleased(px, py)
    end
end

function UIEditor:onKeyPressed(key)
    if self.colorPicker.visible then
        self.colorPicker:onKeyPressed(key); return
    end
    if self.picker.visible then
        self.picker:onKeyPressed(key); return
    end
    -- delete key
    if key == Input.KEY_DELETE and self.selected and not self.inspector._activeKey then
        self:_onAction("delete"); return
    end
    -- zoom shortcuts
    if key == Input.KEY_F then
        self:_fitZoom(); return
    end
    if self.playing and self._preview then
        return self._preview:onKeyPressed(key)
    end
    self.inspector:onKeyPressed(key)
end

function UIEditor:onKeyReleased(key)
    if self.playing and self._preview then
        return self._preview:onKeyReleased(key)
    end
    self.inspector:onKeyReleased(key)
end

function UIEditor:onScrolled(scrollX, scrollY)
    local x, y = Input.getX(), Input.getY()

    if x < HIER_W then
        local compTop = TOOLBAR_H + self._HDR_H
        local compBottom = TOOLBAR_H + self._COMP_H

        if y >= compTop and y < compBottom then
            self._compList:onScrolled(scrollX, scrollY)
            return true
        end

        if y >= self._hierListY then
            local maxS = math.max(0, #self._hierRows * HIER_ROW_H - self._hierListH)
            self._hierScrollY = math.max(0, math.min(maxS, self._hierScrollY - scrollY * HIER_ROW_H))
            return true
        end

        return false
    end

    if not inCanvas(x, y) then return false end

    if scrollY > 0 then
        self:_zoomAt(x, y, self.zoom + ZOOM_STEP)
    elseif scrollY < 0 then
        self:_zoomAt(x, y, self.zoom - ZOOM_STEP)
    end

    return true
end

-- ─── update ──────────────────────────────────────────────────────────────────

function UIEditor:update(dt)
    if self.statusTimer > 0 then self.statusTimer = self.statusTimer - dt end
    self.inspector:update(dt)
    self.toolbar:setZoom(self.zoom)
    if self.playing and self._preview then
        self._preview:update(dt)
    end
end

-- ─── render ──────────────────────────────────────────────────────────────────

function UIEditor:render(g)
    if self.playing and self._preview then
        -- render preview centered on canvas area
        self._preview:render(g)
        -- keep toolbar visible so user can Stop
        self.toolbar:render(g)
        self:_renderStatusBar(g)
    else
        self:_renderCanvas(g)
        self:_renderHierarchy(g)
        self.toolbar:render(g)
        self.inspector:render(g)
        self:_renderStatusBar(g)
        self.picker:render(g)
        self.colorPicker:render(g)
    end
end

function UIEditor:_renderCanvas(g)
    self._canvasBg:render(g)

    g:save()
    g:setClip(CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H)

    -- subtle dot grid
    local gridStep = GRID * self.zoom
    if gridStep >= 6 then
        local startX = CANVAS_X + self.panX % gridStep
        local startY = CANVAS_Y + self.panY % gridStep
        local gx = startX
        while gx <= CANVAS_X + CANVAS_W do
            local gy = startY
            while gy <= CANVAS_Y + CANVAS_H do
                g:setColor(55, 58, 68, 255)
                g:fillRect(gx, gy, 1, 1)
                gy = gy + gridStep
            end
            gx = gx + gridStep
        end
    end

    local scx, scy = self:_toScreen(0, 0)
    local scw = SCENE_W * self.zoom
    local sch = SCENE_H * self.zoom

    -- drop shadow
    g:setColor(0, 0, 0, 100)
    g:fillRect(scx + 6, scy + 6, scw, sch)
    g:setColor(0, 0, 0, 50)
    g:fillRect(scx + 10, scy + 10, scw, sch)

    -- scene bg
    g:setColor(30, 30, 36, 255)
    g:fillRect(scx, scy, scw, sch)

    -- sync the whole tree once (parent-before-children, so nested world
    -- coordinates resolve correctly regardless of depth), then let the
    -- UIComponent parent/child render cascade draw everything for us.
    self.sceneRoot:sync()
    self:_ensureFocusedCanvas()

    g:save()
    g:translate(scx, scy)
    g:scale(self.zoom, self.zoom)
    g:setClip(0, 0, SCENE_W, SCENE_H)
    -- Only the focused Canvas actually renders — its siblings are still
    -- alive in the tree (so switching focus back is instant) but skipped
    -- here, otherwise every overlapping canvas would draw on top of
    -- each other every frame.
    for _, w in ipairs(self.sceneRoot.children) do
        if self:_isEditorVisible(w) then
            w:renderComponent(g)
        end
    end

    local function renderOverlays(list)
        for _, w in ipairs(list) do
            if self:_isEditorVisible(w) then
                w:renderOverlay(g, w == self.selected)
                renderOverlays(w.children)
            end
        end
    end
    renderOverlays(self.sceneRoot.children)
    g:restore()

    -- scene border
    g:setColor(55, 60, 78, 255)
    g:drawRect(scx, scy, scw, sch)
    g:setColor(40, 44, 58, 180)
    g:drawRect(scx - 1, scy - 1, scw + 2, sch + 2)

    -- selection handles — a selected Canvas gets the highlight tint only,
    -- no drag/resize corner handles, since it can't be moved or resized
    -- from the editor (it defines the scene bounds itself).
    if self.selected then
        local w = self.selected
        local wx, wy = w:getWorldPos()
        local sx1, sy1 = self:_toScreen(wx, wy)
        local sw = w.width * self.zoom
        local sh = w.height * self.zoom

        g:setColor(0, 150, 255, 60)
        g:fillRect(sx1, sy1, sw, sh)
        g:setColor(0, 160, 255, 255)
        g:drawRect(sx1 - 1, sy1 - 1, sw + 2, sh + 2)

        if w.type ~= UIWidget.TYPES.CANVAS then
            local hs = 7
            local corners = {
                { sx1 - hs / 2, sy1 - hs / 2 }, { sx1 + sw - hs / 2, sy1 - hs / 2 },
                { sx1 - hs / 2, sy1 + sh - hs / 2 }, { sx1 + sw - hs / 2, sy1 + sh - hs / 2 },
            }
            for _, c in ipairs(corners) do
                g:setColor(0, 130, 230, 255)
                g:fillRect(c[1], c[2], hs, hs)
                g:setColor(255, 255, 255, 255)
                g:fillRect(c[1] + 1, c[2] + 1, hs - 2, hs - 2)
            end
            -- resize handle
            g:setColor(0, 160, 255, 255)
            g:fillRect(sx1 + sw - 5, sy1 + sh - 5, 10, 10)
            g:setColor(255, 255, 255, 255)
            g:fillRect(sx1 + sw - 3, sy1 + sh - 3, 6, 6)
        end
    end

    g:restore()

    -- canvas border
    g:setColor(22, 22, 28, 255)
    g:drawRect(CANVAS_X, CANVAS_Y, CANVAS_W, CANVAS_H)
end

function UIEditor:_renderHierarchy(g)
    self._hierBg:render(g)

    -- right border
    g:setColor(10, 10, 14, 255)
    g:fillRect(HIER_W - 1, TOOLBAR_H, 1, SCREEN_HEIGHT)

    local HDR_H  = self._HDR_H
    local COMP_H = self._COMP_H

    -- Components header
    self._compHeader:render(g)
    g:setColor(55, 105, 215, 255)
    g:fillRect(0, TOOLBAR_H, 3, HDR_H)
    g:setColor(10, 10, 14, 255)
    g:drawLine(0, TOOLBAR_H + HDR_H, HIER_W, TOOLBAR_H + HDR_H)
    self._compTitle:render(g)

    self._compList:draw(g)

    -- color dots on component rows
    g:save()
    g:setClip(0, TOOLBAR_H + HDR_H, HIER_W, COMP_H - HDR_H)
    local IH = self._compList.itemHeight
    for i, tp in ipairs(self._addTypes) do
        local iy = TOOLBAR_H + HDR_H + (i - 1) * IH - self._compList._scrollY
        if iy + IH >= TOOLBAR_H + HDR_H and iy <= TOOLBAR_H + COMP_H then
            local ic = TYPE_IC[tp] or { 80, 80, 80 }
            g:setColor(ic[1], ic[2], ic[3], 220)
            g:fillRoundRect(10, iy + (IH - 10) / 2, 10, 10, 5, 5)
        end
    end
    g:restore()

    -- Hierarchy header
    local hierTop = TOOLBAR_H + COMP_H
    self._hierHeader:render(g)
    g:setColor(55, 105, 215, 255)
    g:fillRect(0, hierTop, 3, HDR_H)
    g:setColor(10, 10, 14, 255)
    g:drawLine(0, hierTop + HDR_H, HIER_W, hierTop + HDR_H)
    self._hierTitle:render(g)

    -- count badge
    local total = self:_countWidgets()
    if total > 0 then
        local bw = #tostring(total) * 7 + 12
        g:setColor(35, 60, 110, 255)
        g:fillRoundRect(HIER_W - bw - 8, hierTop + (HDR_H - 18) / 2, bw, 18, 9, 9)
        g:setColor(130, 168, 225, 255)
        g:drawString(tostring(total), HIER_W - bw / 2 - 8, hierTop + HDR_H / 2, Graphics.CENTER)
    end

    -- tree rows
    g:save()
    g:setClip(0, self._hierListY, HIER_W, self._hierListH)

    if #self._hierRows == 0 then
        g:setColor(48, 50, 62, 255)
        g:drawString("Empty", HIER_W / 2, self._hierListY + 24, Graphics.CENTER)
        g:setColor(36, 38, 48, 255)
        g:drawString("Add a component above", HIER_W / 2, self._hierListY + 42, Graphics.CENTER)
    end

    for i, row in ipairs(self._hierRows) do
        local ry = self:_rowScreenY(i)
        if ry + HIER_ROW_H >= self._hierListY and ry <= self._hierListY + self._hierListH then
            self:_renderHierRow(g, row, i, ry)
        end
    end

    -- drop indicator
    if self._hierDragging and self._hierHoverRow then
        local hoverRow = self._hierRows[self._hierHoverRow]
        local ry = self:_rowScreenY(self._hierHoverRow)
        local indent = 6 + hoverRow.depth * INDENT_W
        g:setColor(80, 170, 255, 255)
        if self._hierHoverPos == "inside" then
            g:drawRoundRect(indent - 4, ry + 1, HIER_W - indent - 4, HIER_ROW_H - 2, 4, 4)
        elseif self._hierHoverPos == "before" then
            g:fillRect(indent, ry, HIER_W - indent - 6, 2)
        else -- "after"
            g:fillRect(indent, ry + HIER_ROW_H - 2, HIER_W - indent - 6, 2)
        end
    end

    g:restore()

    -- floating label following the cursor while dragging
    if self._hierDragging and self._hierPressWidget then
        local mx, my = Input.getX(), Input.getY()
        local label = self._hierPressWidget.name
        local lw = #label * 7 + 16
        g:setColor(30, 60, 110, 230)
        g:fillRoundRect(mx + 10, my + 4, lw, 20, 4, 4)
        g:setColor(200, 225, 255, 255)
        g:drawString(label, mx + 10 + lw / 2, my + 14, Graphics.CENTER)
    end

    -- scrollbar
    local contentH = #self._hierRows * HIER_ROW_H
    local maxS = math.max(0, contentH - self._hierListH)
    if maxS > 0 then
        local ratio  = self._hierListH / contentH
        local thumbH = math.max(20, self._hierListH * ratio)
        local travel = self._hierListH - thumbH
        local thumbY = self._hierListY + (self._hierScrollY / maxS) * travel
        g:setColor(14, 14, 18, 255)
        g:fillRect(HIER_W - 6, self._hierListY, 6, self._hierListH)
        g:setColor(55, 58, 72, 220)
        g:fillRoundRect(HIER_W - 5, thumbY + 2, 4, thumbH - 4, 2, 2)
    end
end

function UIEditor:_renderHierRow(g, row, index, ry)
    local w          = row.widget
    local isSelected = (w == self.selected)
    local isCanvas   = (w.type == UIWidget.TYPES.CANVAS)
    local isFocused  = isCanvas and (w == self.focusedCanvas)
    local indent     = 6 + row.depth * INDENT_W

    -- row background
    if isSelected then
        g:setColor(30, 62, 118, 255)
    elseif index % 2 == 0 then
        g:setColor(22, 22, 26, 255)
    else
        g:setColor(20, 20, 24, 255)
    end
    g:fillRect(0, ry, HIER_W, HIER_ROW_H)

    -- Unity-style vertical guide lines connecting a node to its ancestors
    for d = 1, row.depth do
        g:setColor(35, 35, 42, 255)
        g:fillRect(6 + (d - 1) * INDENT_W + 5, ry, 1, HIER_ROW_H)
    end

    -- expand / collapse toggle
    if #w.children > 0 then
        g:setColor(140, 150, 175, 255)
        g:drawString(w.expanded and "▾" or "▸", indent + TOGGLE_W / 2, ry + HIER_ROW_H / 2, Graphics.CENTER)
    end

    -- type color dot
    local ic = TYPE_IC[w.type] or { 80, 80, 80 }
    g:setColor(ic[1], ic[2], ic[3], 220)
    g:fillRoundRect(indent + TOGGLE_W + 2, ry + (HIER_ROW_H - 8) / 2, 8, 8, 4, 4)

    -- name (dimmed for a Canvas that's currently parked/off-screen, so the
    -- hierarchy visually communicates which one you're actually looking at)
    local nameDim = isCanvas and not isFocused and not isSelected
    if nameDim then
        g:setColor(110, 118, 138, 255)
    else
        g:setColor(isSelected and 220 or 175, isSelected and 232 or 182, isSelected and 255 or 205, 255)
    end
    g:drawString(w.name, indent + TOGGLE_W + 16, ry + HIER_ROW_H / 2, Graphics.CENTER_LEFT)

    -- focus indicator + click target for Canvas rows: clicking it (via the
    -- normal row click → _select → _findAncestorCanvas path) brings that
    -- canvas forward, but the label here makes the *current* state visible
    -- without needing to click anything first.
    if isCanvas then
        if isFocused then
            g:setColor(90, 200, 210, 255)
            g:drawString("● shown", HIER_W - 10, ry + HIER_ROW_H / 2, Graphics.CENTER_RIGHT)
        else
            g:setColor(70, 74, 86, 255)
            g:drawString("hidden", HIER_W - 10, ry + HIER_ROW_H / 2, Graphics.CENTER_RIGHT)
        end
    end

    if isSelected then
        g:setColor(55, 120, 220, 255)
        g:fillRect(0, ry, 2, HIER_ROW_H)
    end
end

function UIEditor:_renderStatusBar(g)
    self._statusBar:render(g)
    g:setColor(10, 10, 14, 255)
    g:fillRect(CANVAS_X, SCREEN_HEIGHT - 26, CANVAS_W, 1)

    -- coords
    if self.selected then
        local w = self.selected
        g:setColor(75, 80, 100, 255)
        g:drawString(
            string.format("x: %.0f   y: %.0f   w: %.0f   h: %.0f", w.x, w.y, w.width, w.height),
            CANVAS_X + 12, SCREEN_HEIGHT - 13, Graphics.CENTER_LEFT)
    end

    -- status pill
    if self.statusTimer > 0 then
        local t = self.statusTimer / 3.0
        local alpha = math.min(255, math.floor(t * 400))
        local pr, pg, pb = self.statusIsErr and 180 or 40, self.statusIsErr and 40 or 160, self.statusIsErr and 40 or 80
        local tw = #self.status * 7 + 20
        g:setColor(pr, pg, pb, math.floor(alpha * 0.4))
        g:fillRoundRect(CANVAS_X + CANVAS_W / 2 - tw / 2, SCREEN_HEIGHT - 23, tw, 18, 9, 9)
        g:setColor(self.statusIsErr and 240 or 100, self.statusIsErr and 100 or 220, self.statusIsErr and 100 or 130,
            alpha)
        g:drawString(self.status, CANVAS_X + CANVAS_W / 2, SCREEN_HEIGHT - 13, Graphics.CENTER)
    end

    -- hint (right)
    g:setColor(42, 44, 56, 255)
    g:drawString("Drag=move  Corner=resize  F=fit  DEL=delete",
        CANVAS_X + CANVAS_W - 10, SCREEN_HEIGHT - 13, Graphics.CENTER_RIGHT)
end

return UIEditor
