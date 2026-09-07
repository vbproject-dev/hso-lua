local UIWidget = require("gfx.ui.UIWidget")

local UIJson = class("UIJson")

function UIJson.load(path)
    if not FileUtils.exists(path) then
        return {}
    end

    local text = FileUtils.readText(path)
    if not text or text == "" then
        return {}
    end

    local data = JSON.toTable(text)
    if not data or not data.widgets then
        return {}
    end

    local widgets = {}

    for _, widgetData in ipairs(data.widgets) do
        widgets[#widgets + 1] = UIWidget.fromTable(widgetData)
    end

    return widgets
end

function UIJson.save(path, widgets)
    local data = {
        widgets = {}
    }

    for _, widget in ipairs(widgets) do
        data.widgets[#data.widgets + 1] = widget:toTable()
    end

    FileUtils.writeText(path, JSON.fromTable(data))
end

return UIJson
