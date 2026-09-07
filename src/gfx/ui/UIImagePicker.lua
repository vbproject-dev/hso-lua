local UIImagePicker = class("UIImagePicker")

local MODAL_W       = 700
local MODAL_H       = 500
local MODAL_X       = (SCREEN_WIDTH - MODAL_W) / 2
local MODAL_Y       = (SCREEN_HEIGHT - MODAL_H) / 2
local HEADER_H      = 36
local FOOTER_H      = 40
local SIDEBAR_W     = 140
local PAD           = 8
local THUMB_SIZE    = 72
local THUMB_PAD     = 8
local FOLDER_H      = 30

-- FileUtils base is assets/res/ so paths are relative to that
local BASE_PATH     = "interface"

function UIImagePicker:ctor(onPick)
    self.onPick       = onPick -- callback(path) or nil on cancel
    self.visible      = false
    self.folders      = {}
    self.selFolder    = nil
    self.files        = {} -- { path, name, image, loaded }
    self.selFile      = nil
    self.scrollY      = 0
    self._dragging    = false
    self._dragStartY  = 0
    self._dragScrollY = 0
    self:_scanFolders()
end

-- ─── scan ────────────────────────────────────────────────────────────────────

function UIImagePicker:_scanFolders()
    self.folders = {}
    -- always include the root folder itself
    self.folders[1] = { name = "(root)", path = BASE_PATH }
    local ok, entries = FileUtils.listDirectory(BASE_PATH)
    if ok and entries then
        for _, e in ipairs(entries) do
            local fullPath = BASE_PATH .. "/" .. e
            if FileUtils.directoryExists(fullPath) then
                self.folders[#self.folders + 1] = { name = e, path = fullPath }
            end
        end
    end
    self:_selectFolder(self.folders[1])
end

function UIImagePicker:_selectFolder(folder)
    self.selFolder = folder
    self.files     = {}
    self.selFile   = nil
    self.scrollY   = 0
    local list     = FileUtils.listFiles(folder.path, false)
    if not list then return end
    for _, f in ipairs(list) do
        local lower = f:lower()
        if lower:sub(-4) == ".png" or lower:sub(-4) == ".jpg" or lower:sub(-5) == ".jpeg" then
            local name = f:match("([^/\\]+)$") or f
            -- ensure full relative path for Image.createImage
            local fullPath = folder.path .. "/" .. f
            self.files[#self.files + 1] = { path = fullPath, name = name, image = nil, loaded = false }
        end
    end
end

function UIImagePicker:_loadThumb(file)
    if file.loaded then return end
    file.loaded = true
    if file.path == "" then return end
    local ok, img = pcall(Image.createImage, file.path)
    if ok and img and img:getWidth() > 0 then
        file.image = img
    end
end

-- ─── open / close ────────────────────────────────────────────────────────────

function UIImagePicker:open()
    self.visible = true
    self.selFile = nil
    self.scrollY = 0
end

function UIImagePicker:close()
    self.visible = false
end

-- ─── content area geometry ───────────────────────────────────────────────────

local function contentX() return MODAL_X + SIDEBAR_W end
local function contentY() return MODAL_Y + HEADER_H end
local function contentW() return MODAL_W - SIDEBAR_W end
local function contentH() return MODAL_H - HEADER_H - FOOTER_H end

function UIImagePicker:_thumbsPerRow()
    return math.max(1, math.floor((contentW() - PAD) / (THUMB_SIZE + THUMB_PAD)))
end

function UIImagePicker:_totalContentH()
    local cols = self:_thumbsPerRow()
    local rows = math.ceil(#self.files / cols)
    return rows * (THUMB_SIZE + THUMB_PAD) + PAD
end

-- ─── pointer ─────────────────────────────────────────────────────────────────

function UIImagePicker:onPointerPressed(px, py)
    if not self.visible then return false end

    -- block all clicks when visible
    -- close button (X)
    local closeX = MODAL_X + MODAL_W - 28
    local closeY = MODAL_Y + 4
    if px >= closeX and px <= closeX + 24 and py >= closeY and py <= closeY + 28 then
        self:close()
        return true
    end

    -- cancel / confirm buttons
    local btnY     = MODAL_Y + MODAL_H - FOOTER_H + 6
    local confirmX = MODAL_X + MODAL_W - 110
    local cancelX  = MODAL_X + MODAL_W - 220
    if py >= btnY and py <= btnY + 28 then
        if px >= confirmX and px <= confirmX + 100 then
            if self.selFile and self.onPick then
                self.onPick(self.selFile.path)
            end
            self:close()
            return true
        end
        if px >= cancelX and px <= cancelX + 100 then
            self:close()
            return true
        end
    end

    -- sidebar folder list
    if px >= MODAL_X and px <= MODAL_X + SIDEBAR_W then
        local fy = MODAL_Y + HEADER_H
        for _, folder in ipairs(self.folders) do
            if py >= fy and py <= fy + FOLDER_H then
                self:_selectFolder(folder)
                return true
            end
            fy = fy + FOLDER_H
        end
        return true
    end

    -- content grid
    local cx = contentX()
    local cy = contentY()
    local cw = contentW()
    local ch = contentH()
    if px >= cx and px <= cx + cw and py >= cy and py <= cy + ch then
        self._dragging    = true
        self._dragStartY  = py
        self._dragScrollY = self.scrollY

        -- hit test thumbnail
        local cols        = self:_thumbsPerRow()
        local localY      = py - cy + self.scrollY
        local col         = math.floor((px - cx - PAD) / (THUMB_SIZE + THUMB_PAD))
        local row         = math.floor((localY - PAD) / (THUMB_SIZE + THUMB_PAD))
        local idx         = row * cols + col + 1
        if idx >= 1 and idx <= #self.files then
            local tx = cx + PAD + col * (THUMB_SIZE + THUMB_PAD)
            local ty = cy - self.scrollY + PAD + row * (THUMB_SIZE + THUMB_PAD)
            if px >= tx and px <= tx + THUMB_SIZE and py >= ty and py <= ty + THUMB_SIZE then
                self.selFile = self.files[idx]
            end
        end
        return true
    end

    return true -- always consume when visible
end

function UIImagePicker:onPointerDragged(px, py)
    if not self.visible or not self._dragging then return end
    local dy        = self._dragStartY - py
    local maxScroll = math.max(0, self:_totalContentH() - contentH())
    self.scrollY    = math.max(0, math.min(self._dragScrollY + dy, maxScroll))
end

function UIImagePicker:onPointerReleased(px, py)
    self._dragging = false
end

function UIImagePicker:onKeyPressed(key)
    if not self.visible then return end
    if key == Input.KEY_ESCAPE then self:close() end
    if key == Input.KEY_RETURN and self.selFile then
        if self.onPick then self.onPick(self.selFile.path) end
        self:close()
    end
end

-- ─── render ──────────────────────────────────────────────────────────────────

function UIImagePicker:render(g)
    if not self.visible then return end

    -- dim overlay
    g:setColor(0, 0, 0, 160)
    g:fillRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

    -- modal background
    g:setColor(28, 28, 30, 255)
    g:fillRoundRect(MODAL_X, MODAL_Y, MODAL_W, MODAL_H, 8, 8)
    g:setColor(50, 50, 55, 255)
    g:drawRoundRect(MODAL_X, MODAL_Y, MODAL_W, MODAL_H, 8, 8)

    -- header
    g:setColor(22, 22, 24, 255)
    g:fillRoundRect(MODAL_X, MODAL_Y, MODAL_W, HEADER_H, 8, 8)
    g:fillRect(MODAL_X, MODAL_Y + HEADER_H / 2, MODAL_W, HEADER_H / 2)
    g:setColor(200, 200, 205, 255)
    g:drawString("Image Picker", MODAL_X + PAD * 2, MODAL_Y + HEADER_H / 2, Graphics.CENTER_LEFT)

    -- close button
    g:setColor(180, 60, 60, 255)
    g:fillRoundRect(MODAL_X + MODAL_W - 28, MODAL_Y + 4, 24, 28, 4, 4)
    g:setColor(255, 255, 255, 255)
    g:drawString("X", MODAL_X + MODAL_W - 16, MODAL_Y + HEADER_H / 2, Graphics.CENTER)

    -- sidebar
    g:setColor(22, 22, 24, 255)
    g:fillRect(MODAL_X, MODAL_Y + HEADER_H, SIDEBAR_W, MODAL_H - HEADER_H - FOOTER_H)
    g:setColor(40, 40, 44, 255)
    g:drawLine(MODAL_X + SIDEBAR_W, MODAL_Y + HEADER_H, MODAL_X + SIDEBAR_W, MODAL_Y + MODAL_H - FOOTER_H)

    local fy = MODAL_Y + HEADER_H
    for _, folder in ipairs(self.folders) do
        local isSel = self.selFolder and self.selFolder.name == folder.name
        if isSel then
            g:setColor(40, 70, 120, 255)
            g:fillRect(MODAL_X, fy, SIDEBAR_W, FOLDER_H)
        end
        if isSel then
            g:setColor(220, 230, 255, 255)
        else
            g:setColor(160, 160, 165, 255)
        end
        g:drawString(folder.name, MODAL_X + PAD, fy + FOLDER_H / 2, Graphics.CENTER_LEFT)
        fy = fy + FOLDER_H
    end

    -- content area clip
    local cx = contentX()
    local cy = contentY()
    local cw = contentW()
    local ch = contentH()

    g:setColor(32, 32, 35, 255)
    g:fillRect(cx, cy, cw, ch)

    g:save()
    g:setClip(cx, cy, cw, ch)

    local cols = self:_thumbsPerRow()
    for i, file in ipairs(self.files) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local tx  = cx + PAD + col * (THUMB_SIZE + THUMB_PAD)
        local ty  = cy - self.scrollY + PAD + row * (THUMB_SIZE + THUMB_PAD)

        if ty + THUMB_SIZE >= cy and ty <= cy + ch then
            self:_loadThumb(file)

            local isSel = self.selFile == file
            if isSel then
                g:setColor(60, 110, 200, 255)
                g:fillRoundRect(tx - 2, ty - 2, THUMB_SIZE + 4, THUMB_SIZE + 4, 4, 4)
            end

            g:setColor(45, 45, 48, 255)
            g:fillRect(tx, ty, THUMB_SIZE, THUMB_SIZE)

            if file.image then
                g:drawImageScale(file.image, tx, ty, THUMB_SIZE, THUMB_SIZE, Graphics.TOP_LEFT)
            else
                g:setColor(70, 70, 75, 255)
                g:drawString("?", tx + THUMB_SIZE / 2, ty + THUMB_SIZE / 2, Graphics.CENTER)
            end

            -- filename label
            g:setColor(0, 0, 0, 140)
            g:fillRect(tx, ty + THUMB_SIZE - 16, THUMB_SIZE, 16)
            g:setColor(200, 200, 200, 255)
            g:drawString(file.name, tx + THUMB_SIZE / 2, ty + THUMB_SIZE - 8, Graphics.CENTER)
        end
    end

    g:restore()

    -- scrollbar
    local maxScroll = math.max(0, self:_totalContentH() - ch)
    if maxScroll > 0 then
        local ratio  = ch / self:_totalContentH()
        local thumbH = math.max(20, ch * ratio)
        local travel = ch - thumbH
        local thumbY = cy + (self.scrollY / maxScroll) * travel
        g:setColor(50, 50, 55, 255)
        g:fillRect(cx + cw - 6, cy, 6, ch)
        g:setColor(100, 100, 110, 220)
        g:fillRoundRect(cx + cw - 5, thumbY, 4, thumbH, 2, 2)
    end

    -- footer
    g:setColor(22, 22, 24, 255)
    g:fillRect(MODAL_X, MODAL_Y + MODAL_H - FOOTER_H, MODAL_W, FOOTER_H)
    g:setColor(40, 40, 44, 255)
    g:drawLine(MODAL_X, MODAL_Y + MODAL_H - FOOTER_H, MODAL_X + MODAL_W, MODAL_Y + MODAL_H - FOOTER_H)

    -- selected path label
    if self.selFile then
        g:setColor(140, 140, 145, 255)
        g:drawString(self.selFile.path, MODAL_X + PAD * 2, MODAL_Y + MODAL_H - FOOTER_H / 2, Graphics.CENTER_LEFT)
    end

    -- cancel button
    local btnY = MODAL_Y + MODAL_H - FOOTER_H + 6
    g:setColor(60, 60, 65, 255)
    g:fillRoundRect(MODAL_X + MODAL_W - 220, btnY, 100, 28, 5, 5)
    g:setColor(180, 180, 185, 255)
    g:drawString("Cancel", MODAL_X + MODAL_W - 170, btnY + 14, Graphics.CENTER)

    -- confirm button
    local canConfirm = self.selFile ~= nil
    if canConfirm then
        g:setColor(45, 90, 160, 255)
    else
        g:setColor(40, 40, 45, 255)
    end
    g:fillRoundRect(MODAL_X + MODAL_W - 110, btnY, 100, 28, 5, 5)
    if canConfirm then
        g:setColor(220, 230, 255, 255)
    else
        g:setColor(80, 80, 85, 255)
    end
    g:drawString("Select", MODAL_X + MODAL_W - 60, btnY + 14, Graphics.CENTER)
end

return UIImagePicker
