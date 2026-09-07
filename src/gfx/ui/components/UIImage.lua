local UIComponent = require("gfx.ui.components.UIComponent")

local UIImage = class("UIImage", UIComponent)

function UIImage:ctor(x, y, width, height)
    UIImage.super.ctor(self, x, y, width, height)

    self.imagePath = ""
    self._image = nil
    self._loaded = false

    self.ninePath = false
    self.nineLeft = 0
    self.nineTop = 0
    self.nineRight = 0
    self.nineBottom = 0
end

function UIImage:setImage(path)
    self.imagePath = path or ""
    self._image = nil
    self._loaded = false
end

function UIImage:setNinePath(enabled, left, top, right, bottom)
    self.ninePath = enabled
    self.nineLeft = left or 0
    self.nineTop = top or 0
    self.nineRight = right or 0
    self.nineBottom = bottom or 0
end

function UIImage:_load()
    if self._loaded then return end

    self._loaded = true

    if self.imagePath == "" then
        return
    end

    local ok, img = pcall(function()
        return Image.createImage(self.imagePath)
    end)

    if ok then
        self._image = img
    end
end

function UIImage:draw(g)
    self:_load()

    if not self._image then
        g:setColor(50, 50, 50, 200)
        g:fillRect(self._absX, self._absY, self.width, self.height)

        g:setColor(150, 150, 150, 255)
        g:drawString(
            "No Image",
            self._absX + self.width / 2,
            self._absY + self.height / 2,
            Graphics.CENTER
        )

        return
    end

    if self.ninePath then
        g:draw9Sprite(
            self._image,
            self._absX,
            self._absY,
            self.width,
            self.height,
            self.nineLeft,
            self.nineTop,
            self.nineRight,
            self.nineBottom
        )
    else
        g:drawImageScale(
            self._image,
            self._absX,
            self._absY,
            self.width,
            self.height,
            Graphics.TOP_LEFT
        )
    end
end

return UIImage
