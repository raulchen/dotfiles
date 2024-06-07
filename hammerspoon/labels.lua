-- Floating labels at the buttom right corner of screen

local module = {}

local drawing = hs.drawing

local screen_margin = { x = 50, y = 10 }
local text_padding = { x = 4, y = 0 }
local bg_margin = { x = 7, y = 5 }

local text_style = {
    size = 17,
    color = { white = 0.2, alpha = 1 },
    klignment = "center",
    lineBreak = "truncateTail",
}

local bg_style = {
    fillColor = { white = 1, alpha = 0.7 },
}

local Label = {}
Label.__index = Label

function Label.new(message)
    local label = {}
    setmetatable(label, Label)
    label.message = message
    label.textFrame = drawing.getTextDrawingSize(message, text_style)
    label.textFrame.w = label.textFrame.w + text_padding.x
    label.textFrame.h = label.textFrame.h + text_padding.y
    return label
end

function Label:show(duration)
    if self.text_obj then
        return
    end
    local screen = hs.screen.mainScreen()
    local screen_frame = screen:fullFrame()

    local right = screen_frame.w - screen_margin.x
    local bottom = screen_frame.h - screen_margin.y

    local bg_display_frame = {
        x = right - self.textFrame.w - bg_margin.x * 2,
        y = bottom - self.textFrame.h - bg_margin.y * 2,
        w = self.textFrame.w + bg_margin.x * 2,
        h = self.textFrame.h + bg_margin.y * 2,
    }
    local text_display_frame = {
        x = right - self.textFrame.w - bg_margin.x,
        y = bottom - self.textFrame.h - bg_margin.y,
        w = self.textFrame.w,
        h = self.textFrame.h,
    }

    self.bg_obj = drawing.rectangle(bg_display_frame)
        :setStroke(false)
        :setFill(true)
        :setFillColor(bg_style.fillColor)
        :setRoundedRectRadii(5, 5)
        :show(0.15)
    self.text_obj = drawing.text(text_display_frame, self.message)
        :setTextStyle(text_style)
        :show(0.15)

    if duration then
        hs.timer.doAfter(duration, function() self:hide() end)
    end
end

function Label:hide()
    if self.bg_obj then
        self.bg_obj:delete()
        self.bg_obj = nil
    end
    if self.text_obj then
        self.text_obj:delete()
        self.text_obj = nil
    end
end

module.new = function(message)
    return Label.new(message)
end

module.show = function(message, duration)
    Label.new(message):show(duration)
end

return module
