local UIToolbar        = class("UIToolbar")

local H                = 52
local BTN_H            = 26 -- Unity's toolbar buttons are compact and flat
local BTN_Y            = (H - BTN_H) / 2
local PAD              = 10
local GROUP_GAP        = 16 -- space between the play button and its neighboring groups
local RADIUS           = 4
local PLAY_W           = 100

-- Left cluster: scene/file operations.
local LEFT_ACTIONS     = {
    { label = "New",  action = "new" },
    { label = "Save", action = "save" },
    { label = "Load", action = "load" },
}

-- Cluster just right of Play: destructive edits, kept close to Play since
-- both act on "the whole scene" rather than a specific selection.
local RIGHT_ACTIONS    = {
    { label = "Clear",  action = "clear",  danger = true },
    { label = "Delete", action = "delete", danger = true },
}

local ZOOM_ACTIONS     = {
    { label = "−", action = "zoom_out" },
    { label = "Fit", action = "zoom_fit" },
    { label = "+", action = "zoom_in" },
}

-- Flat, single-hue palette — Unity's toolbar conveys state through
-- hover/active highlighting rather than per-action color coding.
local BG               = { 24, 24, 28 }
local BG_PLAYING       = { 18, 26, 42 } -- the whole bar tints cool blue while playing, like Unity's
local GROUP_BG         = { 30, 30, 35 }
local BTN_HOVER        = { 54, 56, 64 }
local DIVIDER          = { 20, 20, 24 }
local BORDER           = { 14, 14, 18 }
local TEXT             = { 205, 210, 225 }
local TEXT_DIM         = { 130, 134, 150 }
local TEXT_DANGER      = { 235, 140, 140 }
local PLAY_IDLE_BG     = { 40, 40, 46 }
local PLAY_IDLE_TEXT   = { 130, 215, 150 }
local PLAY_ACTIVE_BG   = { 45, 115, 210 }
local PLAY_ACTIVE_TEXT = { 230, 242, 255 }

local function segWidth(label)
    return #label * 7 + 20
end

function UIToolbar:ctor(onAction)
    self.onAction   = onAction
    self.height     = H
    self._zoomLabel = "100%"
    self._hovered   = nil
    self._playing   = false

    self._leftBtns  = {}
    self._rightBtns = {}
    self._zoomBtns  = {}
    self._playBtn   = nil

    self:_layout()
end

-- Lays out three independent zones: a left-anchored group, a group
-- right-anchored to the screen edge, and Play sitting dead-center on the
-- bar — its position never depends on how wide the other groups are,
-- exactly like Unity's toolbar.
function UIToolbar:_layout()
    local function buildGroup(actions, x)
        local group = {}
        for _, a in ipairs(actions) do
            local w = segWidth(a.label)
            group[#group + 1] = {
                label = a.label,
                action = a.action,
                danger = a.danger,
                x = x,
                y = BTN_Y,
                w = w,
                h =
                    BTN_H
            }
            x = x + w
        end
        return group, x
    end

    self._leftBtns = buildGroup(LEFT_ACTIONS, PAD)

    local playLabel = self._playing and "■  Stop" or "▶  Play"
    local playX = math.floor((SCREEN_WIDTH - PLAY_W) / 2)
    self._playBtn = { label = playLabel, action = "play", x = playX, y = BTN_Y, w = PLAY_W, h = BTN_H }

    self._rightBtns = buildGroup(RIGHT_ACTIONS, playX + PLAY_W + GROUP_GAP)

    -- zoom cluster + % readout, right-anchored
    local zoomW = 46
    for _, a in ipairs(ZOOM_ACTIONS) do zoomW = zoomW + segWidth(a.label) end
    self._zoomBtns, self._zoomBoxX = buildGroup(ZOOM_ACTIONS, SCREEN_WIDTH - PAD - zoomW)
    self._zoomBoxW = 46
end

function UIToolbar:setZoom(zoom)
    self._zoomLabel = string.format("%.0f%%", zoom * 100)
end

function UIToolbar:setActionLabel(action, label)
    if action == "play" then
        self._playing = (label == "Stop")
        self._playBtn.label = self._playing and "■  Stop" or "▶  Play"
        return
    end
    for _, group in ipairs({ self._leftBtns, self._rightBtns, self._zoomBtns }) do
        for _, btn in ipairs(group) do
            if btn.action == action then
                btn.label = label
                return
            end
        end
    end
end

local function hitBtn(btn, px, py)
    return px >= btn.x and px <= btn.x + btn.w and py >= btn.y and py <= btn.y + btn.h
end

function UIToolbar:onPointerPressed(px, py)
    if py > H then return false end

    if hitBtn(self._playBtn, px, py) then
        if self.onAction then self.onAction("play") end
        return true
    end

    for _, group in ipairs({ self._leftBtns, self._rightBtns, self._zoomBtns }) do
        for _, btn in ipairs(group) do
            if hitBtn(btn, px, py) then
                if self.onAction then self.onAction(btn.action) end
                return true
            end
        end
    end

    return true -- the toolbar strip swallows the click either way
end

function UIToolbar:onPointerMoved(px, py)
    self._hovered = nil
    if py > H then return end

    if hitBtn(self._playBtn, px, py) then
        self._hovered = self._playBtn
        return
    end
    for _, group in ipairs({ self._leftBtns, self._rightBtns, self._zoomBtns }) do
        for _, btn in ipairs(group) do
            if hitBtn(btn, px, py) then
                self._hovered = btn
                return
            end
        end
    end
end

-- ─── render ──────────────────────────────────────────────────────────────────

function UIToolbar:render(g)
    local bg = self._playing and BG_PLAYING or BG
    g:setColor(bg[1], bg[2], bg[3], 255)
    g:fillRect(0, 0, SCREEN_WIDTH, H)

    g:setColor(BORDER[1], BORDER[2], BORDER[3], 255)
    g:drawLine(0, H, SCREEN_WIDTH, H)

    self:_renderGroup(g, self._leftBtns)
    self:_renderPlayButton(g)
    self:_renderGroup(g, self._rightBtns)
    self:_renderGroup(g, self._zoomBtns)
    self:_renderZoomReadout(g)
end

-- Draws one segmented pill: a single rounded container spanning every
-- button in the group, thin dividers between segments, and a flat
-- (non-rounded) hover highlight per segment — the classic Unity toolbar
-- look, as opposed to individually shadowed floating buttons.
function UIToolbar:_renderGroup(g, btns)
    if #btns == 0 then return end
    local x0 = btns[1].x
    local w = (btns[#btns].x + btns[#btns].w) - x0

    g:setColor(GROUP_BG[1], GROUP_BG[2], GROUP_BG[3], 255)
    g:fillRoundRect(x0, BTN_Y, w, BTN_H, RADIUS, RADIUS)

    for i, btn in ipairs(btns) do
        if btn == self._hovered then
            g:setColor(BTN_HOVER[1], BTN_HOVER[2], BTN_HOVER[3], 255)
            g:fillRect(btn.x, btn.y, btn.w, btn.h)
        end
        if i > 1 then
            g:setColor(DIVIDER[1], DIVIDER[2], DIVIDER[3], 255)
            g:fillRect(btn.x, btn.y + 3, 1, btn.h - 6)
        end
        local col = btn.danger and TEXT_DANGER or TEXT
        g:setColor(col[1], col[2], col[3], 255)
        g:drawString(btn.label, btn.x + btn.w / 2, btn.y + btn.h / 2, Graphics.CENTER)
    end

    g:setColor(BORDER[1], BORDER[2], BORDER[3], 255)
    g:drawRoundRect(x0, BTN_Y, w, BTN_H, RADIUS, RADIUS)
end

function UIToolbar:_renderPlayButton(g)
    local btn = self._playBtn
    local bg, text = PLAY_IDLE_BG, PLAY_IDLE_TEXT
    if self._playing then
        bg, text = PLAY_ACTIVE_BG, PLAY_ACTIVE_TEXT
    end

    g:setColor(bg[1], bg[2], bg[3], btn == self._hovered and 255 or 235)
    g:fillRoundRect(btn.x, btn.y, btn.w, btn.h, RADIUS, RADIUS)
    g:setColor(BORDER[1], BORDER[2], BORDER[3], 255)
    g:drawRoundRect(btn.x, btn.y, btn.w, btn.h, RADIUS, RADIUS)
    g:setColor(text[1], text[2], text[3], 255)
    g:drawString(btn.label, btn.x + btn.w / 2, btn.y + btn.h / 2, Graphics.CENTER)
end

function UIToolbar:_renderZoomReadout(g)
    g:setColor(GROUP_BG[1], GROUP_BG[2], GROUP_BG[3], 255)
    g:fillRoundRect(self._zoomBoxX, BTN_Y, self._zoomBoxW, BTN_H, RADIUS, RADIUS)
    g:setColor(BORDER[1], BORDER[2], BORDER[3], 255)
    g:drawRoundRect(self._zoomBoxX, BTN_Y, self._zoomBoxW, BTN_H, RADIUS, RADIUS)
    g:setColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 255)
    g:drawString(self._zoomLabel, self._zoomBoxX + self._zoomBoxW / 2, BTN_Y + BTN_H / 2, Graphics.CENTER)
end

return UIToolbar
