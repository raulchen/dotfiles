-- Floating labels at the buttom right corner of screen

local module = {}

local drawing = hs.drawing

local textStyle = {
    size = 23,
    lineBreak = "truncateTail",
}

local Label = {}
Label.__index = Label

function Label.new(message, duration)
    local label = {}
    setmetatable(label, Label)
    label.message = message
    label.duration = duration
    label.frame = drawing.getTextDrawingSize(message, textStyle)
    return label
end

function Label:show()
    if self.drawingObj then
        return
    end
    local screen = hs.screen.mainScreen()
    local screenFrame = screen:fullFrame()

    local right = screenFrame.w - 5
    local bottom = screenFrame.h - 5

    local displayFrame = {
        x = right - self.frame.w - 5,
        y = bottom - self.frame.h - 5,
        w = self.frame.w + 10,
        h = self.frame.h + 10,
    }

    self.drawingObj = drawing.text(displayFrame, self.message)
            :setTextStyle(textStyle)
            :show(0.5)
end

function Label:hide()
    self.drawingObj:delete()
    self.drawingObj = nil
end

module.new = function(message, duration)
    return Label.new(message, duration)
end

return module
