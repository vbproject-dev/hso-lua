local UIComponent = require("gfx.ui.components.UIComponent")

local UICanvas = class("UICanvas", UIComponent)

local ZOOM_MIN = 0.1
local ZOOM_MAX = 8.0
local ZOOM_STEP = 0.15
local GRID = 8

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function snap(value)
    return math.floor(value / GRID + 0.5) * GRID
end

function UICanvas:ctor(x, y, width, height)
    UICanvas.super.ctor(self, x, y, width, height)

    self.image = nil

    self.zoom = 1
    self.panX = 0
    self.panY = 0

    self.selection = nil

    self.selecting = false
    self.panning = false

    self.selectStartX = 0
    self.selectStartY = 0

    self.dragStartX = 0
    self.dragStartY = 0

    self.panStartX = 0
    self.panStartY = 0

    self.gridSize = GRID
    self.showPixelGrid = true

    self.backgroundR = 43
    self.backgroundG = 43
    self.backgroundB = 47

    self.onSelectionChanged = nil
end

function UICanvas:setImage(image)
    self.image = image
    self.selection = nil

    self:fitImage()
end

function UICanvas:getImage()
    return self.image
end

function UICanvas:getSelection()
    return self.selection
end

function UICanvas:setSelection(selection)
    self.selection = selection
    self:_notifySelectionChanged()
end

function UICanvas:clearSelection()
    self.selection = nil
    self:_notifySelectionChanged()
end

function UICanvas:getZoom()
    return self.zoom
end

function UICanvas:setZoom(zoom)
    self.zoom = clamp(zoom, ZOOM_MIN, ZOOM_MAX)
    self:_clampPan()
end

function UICanvas:resetZoom()
    self.zoom = 1
    self:centerImage()
end

function UICanvas:fitImage()
    if not self.image then
        self.zoom = 1
        self.panX = self.width / 2
        self.panY = self.height / 2
        return
    end

    local imageWidth = self.image:getWidth()
    local imageHeight = self.image:getHeight()

    local margin = 32

    local zoomX = (self.width - margin) / imageWidth
    local zoomY = (self.height - margin) / imageHeight

    self.zoom = clamp(
        math.min(zoomX, zoomY),
        ZOOM_MIN,
        ZOOM_MAX
    )

    self:centerImage()
end

function UICanvas:centerImage()
    if not self.image then
        return
    end

    local width = self.image:getWidth() * self.zoom
    local height = self.image:getHeight() * self.zoom

    self.panX = (self.width - width) / 2
    self.panY = (self.height - height) / 2
end

function UICanvas:zoomAt(px, py, zoom)
    zoom = clamp(zoom, ZOOM_MIN, ZOOM_MAX)

    local localX = px - self._absX
    local localY = py - self._absY

    local imageX = (localX - self.panX) / self.zoom
    local imageY = (localY - self.panY) / self.zoom

    self.zoom = zoom

    self.panX = localX - imageX * self.zoom
    self.panY = localY - imageY * self.zoom

    self:_clampPan()
end

function UICanvas:zoomIn()
    self:zoomAt(
        self._absX + self.width / 2,
        self._absY + self.height / 2,
        self.zoom + ZOOM_STEP
    )
end

function UICanvas:zoomOut()
    self:zoomAt(
        self._absX + self.width / 2,
        self._absY + self.height / 2,
        self.zoom - ZOOM_STEP
    )
end

function UICanvas:_clampPan()
    if not self.image then
        return
    end

    local minVisible = 32

    local imageWidth = self.image:getWidth() * self.zoom
    local imageHeight = self.image:getHeight() * self.zoom

    local minX = math.min(
        minVisible - imageWidth,
        self.width - minVisible
    )

    local maxX = math.max(
        minVisible - imageWidth,
        self.width - minVisible
    )

    local minY = math.min(
        minVisible - imageHeight,
        self.height - minVisible
    )

    local maxY = math.max(
        minVisible - imageHeight,
        self.height - minVisible
    )

    self.panX = clamp(self.panX, minX, maxX)
    self.panY = clamp(self.panY, minY, maxY)
end

function UICanvas:getImageRect()
    if not self.image then
        return nil
    end

    return self._absX + self.panX,
        self._absY + self.panY,
        self.image:getWidth() * self.zoom,
        self.image:getHeight() * self.zoom
end

function UICanvas:screenToImage(px, py)
    if not self.image then
        return nil
    end

    return (px - self._absX - self.panX) / self.zoom,
        (py - self._absY - self.panY) / self.zoom
end

function UICanvas:imageToScreen(x, y)
    return self._absX + self.panX + x * self.zoom,
        self._absY + self.panY + y * self.zoom
end

function UICanvas:isInsideImage(px, py)
    local x, y, width, height = self:getImageRect()

    if not x then
        return false
    end

    return px >= x
        and px <= x + width
        and py >= y
        and py <= y + height
end

function UICanvas:_notifySelectionChanged()
    if self.onSelectionChanged then
        self.onSelectionChanged(self.selection)
    end
end

function UICanvas:onPointerPressed(px, py)
    if not self:contains(px, py) then
        return false
    end

    if self:isInsideImage(px, py) then
        local imageX, imageY = self:screenToImage(px, py)

        self.selecting = true

        self.selectStartX = snap(imageX)
        self.selectStartY = snap(imageY)

        self.selection = {
            x = self.selectStartX,
            y = self.selectStartY,
            width = 0,
            height = 0,
        }

        self:_notifySelectionChanged()
    else
        self.panning = true

        self.dragStartX = px
        self.dragStartY = py

        self.panStartX = self.panX
        self.panStartY = self.panY
    end

    return true
end

function UICanvas:onPointerDragged(px, py)
    if self.panning then
        self.panX = self.panStartX + px - self.dragStartX
        self.panY = self.panStartY + py - self.dragStartY

        self:_clampPan()

        return true
    end

    if not self.selecting or not self.image then
        return false
    end

    local imageX, imageY = self:screenToImage(px, py)

    if not imageX then
        return false
    end

    imageX = clamp(
        snap(imageX),
        0,
        self.image:getWidth()
    )

    imageY = clamp(
        snap(imageY),
        0,
        self.image:getHeight()
    )

    local startX = self.selectStartX
    local startY = self.selectStartY

    self.selection.x = math.min(startX, imageX)
    self.selection.y = math.min(startY, imageY)

    self.selection.width = math.abs(imageX - startX)
    self.selection.height = math.abs(imageY - startY)

    self:_notifySelectionChanged()

    return true
end

function UICanvas:onPointerReleased(px, py)
    local wasActive = self.selecting or self.panning

    self.selecting = false
    self.panning = false

    if self.selection then
        if self.selection.width < self.gridSize
            or self.selection.height < self.gridSize then
            self.selection = nil
        end

        self:_notifySelectionChanged()
    end

    return wasActive
end

function UICanvas:onScrolled(scrollX, scrollY)
    local x = Input.getX()
    local y = Input.getY()

    if not self:contains(x, y) then
        return false
    end

    if scrollY > 0 then
        self:zoomAt(
            x,
            y,
            self.zoom + ZOOM_STEP
        )
    elseif scrollY < 0 then
        self:zoomAt(
            x,
            y,
            self.zoom - ZOOM_STEP
        )
    end

    return true
end

function UICanvas:_drawCheckerboard(g, x, y, width, height)
    local size = 12

    local right = x + width
    local bottom = y + height

    g:setColor(60, 60, 64, 255)
    g:fillRect(x, y, width, height)

    g:setColor(72, 72, 77, 255)

    local startX = math.floor(x / size) * size
    local startY = math.floor(y / size) * size

    local row = math.floor(startY / size)

    for py = startY, bottom, size do
        local col = math.floor(startX / size)

        for px = startX, right, size do
            if (row + col) % 2 == 1 then
                local cellWidth = math.min(size, right - px)
                local cellHeight = math.min(size, bottom - py)

                if cellWidth > 0 and cellHeight > 0 then
                    g:fillRect(
                        px,
                        py,
                        cellWidth,
                        cellHeight
                    )
                end
            end

            col = col + 1
        end

        row = row + 1
    end
end

function UICanvas:_drawImage(g)
    if not self.image then
        g:setColor(120, 122, 130, 255)

        g:drawString(
            "Open an image to begin",
            self._absX + self.width / 2,
            self._absY + self.height / 2,
            Graphics.CENTER
        )

        return
    end

    local x, y, width, height = self:getImageRect()

    self:_drawCheckerboard(
        g,
        x,
        y,
        width,
        height
    )

    g:drawImageScale(
        self.image,
        x,
        y,
        width,
        height
    )

    g:setColor(15, 15, 17, 255)
    g:drawRect(x, y, width, height)
end

function UICanvas:_drawPixelGrid(g)
    if not self.image then
        return
    end

    if not self.showPixelGrid or self.zoom < 4 then
        return
    end

    local x, y, width, height = self:getImageRect()

    local imageWidth = self.image:getWidth()
    local imageHeight = self.image:getHeight()

    g:setColor(255, 255, 255, 35)

    for imageX = 0, imageWidth, self.gridSize do
        local screenX = x + imageX * self.zoom

        if screenX >= self._absX
            and screenX <= self._absX + self.width then
            g:drawLine(
                screenX,
                y,
                screenX,
                y + height
            )
        end
    end

    for imageY = 0, imageHeight, self.gridSize do
        local screenY = y + imageY * self.zoom

        if screenY >= self._absY
            and screenY <= self._absY + self.height then
            g:drawLine(
                x,
                screenY,
                x + width,
                screenY
            )
        end
    end
end

function UICanvas:_drawSelection(g)
    if not self.selection then
        return
    end

    local selection = self.selection

    local x, y = self:imageToScreen(
        selection.x,
        selection.y
    )

    local width = selection.width * self.zoom
    local height = selection.height * self.zoom

    g:setColor(60, 150, 240, 60)
    g:fillRect(
        x,
        y,
        width,
        height
    )

    g:setColor(60, 150, 240, 255)
    g:drawRect(
        x,
        y,
        width,
        height
    )

    local handleSize = 6
    local halfHandle = handleSize / 2

    g:setColor(255, 255, 255, 255)

    g:fillRect(
        x - halfHandle,
        y - halfHandle,
        handleSize,
        handleSize
    )

    g:fillRect(
        x + width - halfHandle,
        y - halfHandle,
        handleSize,
        handleSize
    )

    g:fillRect(
        x - halfHandle,
        y + height - halfHandle,
        handleSize,
        handleSize
    )

    g:fillRect(
        x + width - halfHandle,
        y + height - halfHandle,
        handleSize,
        handleSize
    )
end

function UICanvas:draw(g)
    g:setColor(
        self.backgroundR,
        self.backgroundG,
        self.backgroundB,
        255
    )

    g:fillRect(
        self._absX,
        self._absY,
        self.width,
        self.height
    )

    g:save()

    g:setClip(
        self._absX,
        self._absY,
        self.width,
        self.height
    )

    self:_drawImage(g)
    self:_drawPixelGrid(g)
    self:_drawSelection(g)

    g:restore()
end

return UICanvas
