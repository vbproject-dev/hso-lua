local Item = class("Item")

function Item:ctor(data)
    self.id = data.id or 0
    self.quantity = data.quantity or 1
end

return Item
