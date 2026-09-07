local SceneManager = class("SceneManager")

local instance = nil

function SceneManager:ctor()
    self.currentScene = nil
end

function SceneManager.getInstance()
    if not instance then
        instance = SceneManager.new()
    end
    return instance
end

function SceneManager:setScene(scene)
    if self.currentScene then
        self.currentScene:onExit()
        self.currentScene:dispose()
    end

    self.currentScene = scene

    if self.currentScene then
        self.currentScene:onEnter()
    end
end

function SceneManager:update(dt)
    if self.currentScene then
        self.currentScene:update(dt)

        if Input.isPointerPressed() then
            self.currentScene:onPointerPressed(Input.getX(), Input.getY())
        end

        if Input.isPointerDragged() then
            self.currentScene:onPointerDragged(Input.getX(), Input.getY())
        end

        if Input.isPointerReleased() then
            self.currentScene:onPointerReleased(Input.getX(), Input.getY())
        end

        if Input.isKeyPressed() then
            self.currentScene:onKeyPressed(Input.getKey())
        end

        if Input.isKeyReleased() then
            self.currentScene:onKeyReleased(Input.getKey())
        end

        if Input.isScrolled() then
            self.currentScene:onScrolled(Input.getScrollX(), Input.getScrollY())
        end
    end
end

function SceneManager:render(g)
    if self.currentScene then
        self.currentScene:render(g)
    end
end

function SceneManager:getScene()
    return self.currentScene
end

function SceneManager:clearScene()
    if self.currentScene then
        self.currentScene:onExit()
        self.currentScene:dispose()
        self.currentScene = nil
    end
end

return SceneManager
