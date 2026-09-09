local UIComponent = require("gfx.ui.components.UIComponent")
local UIToolbar = class("UIToolbar", UIComponent)

function UIToolbar:ctor(x, y, width, height)
    UIComponent.ctor(self, x, y, width, height)

    self.orientation = UIToolbar.HORIZONTAL

    self.paddingLeft = 8
    self.paddingTop = 8
    self.paddingRight = 8
    self.paddingBottom = 8

    self.spacing = 6

    self.align = Graphics.CENTER

    self.drawSeparators = false
    self.separatorSize = 1
end

UIToolbar.HORIZONTAL = 0
UIToolbar.VERTICAL = 1

function UIToolbar:setOrientation(orientation)
    self.orientation = orientation
    self:layoutChildren()
    return self
end

function UIToolbar:setSpacing(spacing)
    self.spacing = spacing or 0
    self:layoutChildren()
    return self
end

function UIToolbar:setPadding(left, top, right, bottom)
    self.paddingLeft = left or 0
    self.paddingTop = top or 0
    self.paddingRight = right or 0
    self.paddingBottom = bottom or 0

    self:layoutChildren()

    return self
end

function UIToolbar:setAlignment(align)
    self.align = align
    self:layoutChildren()
    return self
end

function UIToolbar:setSeparators(enabled, size)
    self.drawSeparators = enabled or false
    self.separatorSize = size or 1
    return self
end

function UIToolbar:addChild(child, index)
    UIComponent.addChild(self, child, index)
    self:layoutChildren()
    return child
end

function UIToolbar:removeChild(child)
    UIComponent.removeChild(self, child)
    self:layoutChildren()
end

function UIToolbar:clearChildren()
    UIComponent.clearChildren(self)
end

function UIToolbar:layoutChildren()
    local x = self.paddingLeft
    local y = self.paddingTop

    local contentWidth =
        self.width -
        self.paddingLeft -
        self.paddingRight

    local contentHeight =
        self.height -
        self.paddingTop -
        self.paddingBottom

    for _, child in ipairs(self.children) do
        if self.orientation == UIToolbar.HORIZONTAL then
            child.x = x

            if self.align == Graphics.TOP_LEFT then
                child.y = y
            elseif self.align == Graphics.CENTER_LEFT then
                child.y = y + (contentHeight - child.height) / 2
            elseif self.align == Graphics.BOTTOM_LEFT then
                child.y = y + contentHeight - child.height
            else
                child.y = y + (contentHeight - child.height) / 2
            end

            x = x + child.width + self.spacing
        else
            child.y = y

            if self.align == Graphics.TOP_LEFT then
                child.x = x
            elseif self.align == Graphics.CENTER_LEFT then
                child.x = x + (contentWidth - child.width) / 2
            elseif self.align == Graphics.TOP_RIGHT then
                child.x = x + contentWidth - child.width
            else
                child.x = x + (contentWidth - child.width) / 2
            end

            y = y + child.height + self.spacing
        end
    end

    self:updateAbsolutePosition(
        self.parent and self.parent._absX or 0,
        self.parent and self.parent._absY or 0
    )
end

function UIToolbar:draw(g)
    if not self.drawSeparators then
        return
    end

    if #self.children <= 1 then
        return
    end

    for i = 1, #self.children - 1 do
        local current = self.children[i]

        if self.orientation == UIToolbar.HORIZONTAL then
            local separatorX =
                current._absX +
                current.width +
                self.spacing / 2

            local separatorY = self._absY + self.paddingTop

            g:setColor(0x555555)

            g:fillRect(
                separatorX,
                separatorY,
                self.separatorSize,
                self.height -
                self.paddingTop -
                self.paddingBottom
            )
        else
            local separatorY =
                current._absY +
                current.height +
                self.spacing / 2

            local separatorX = self._absX + self.paddingLeft

            g:setColor(0x555555)

            g:fillRect(
                separatorX,
                separatorY,
                self.width -
                self.paddingLeft -
                self.paddingRight,
                self.separatorSize
            )
        end
    end
end

return UIToolbar
