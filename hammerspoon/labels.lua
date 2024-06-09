-- Floating labels at the buttom right corner of screen

local module = {}

local drawing = hs.drawing

local Label = {}
Label.__index = Label

local screen_margin = { x = 50, y = 10 }
local bg_margin = { x = 7, y = 5 }

function Label.new(message, position)
    local label = {}
    setmetatable(label, Label)
    label.message = message
    label.position = position or "center"
    local size = label.position == "center" and 22 or 17
    label.text_style = {
        size = size,
        color = { white = 0.2, alpha = 1 },
        klignment = "center",
        lineBreak = "truncateTail",
    }

    label.bg_color = { white = 1, alpha = 0.8 }
    label.textFrame = drawing.getTextDrawingSize(message, label.text_style)
    return label
end

function Label:get_text_display_frame()
    local screen = hs.screen.mainScreen()
    local screen_frame = screen:fullFrame()

    if self.position == "bottom_left" then
        return {
            x = screen_margin.x,
            y = screen_frame.h - screen_margin.y - self.textFrame.h,
            w = self.textFrame.w,
            h = self.textFrame.h,
        }
    elseif self.position == "bottom_right" then
        return {
            x = screen_frame.w - self.textFrame.w - screen_margin.x,
            y = screen_frame.h - screen_margin.y - self.textFrame.h,
            w = self.textFrame.w,
            h = self.textFrame.h,
        }
    elseif self.position == "center" then
        return {
            x = (screen_frame.w - self.textFrame.w) / 2,
            y = (screen_frame.h - self.textFrame.h) / 2,
            w = self.textFrame.w,
            h = self.textFrame.h,
        }
    else
        assert(false, "Invalid position")
    end
end

function Label:text_display_frame()
end

function Label:show(duration)
    if self.text_obj then
        return
    end
    local text_display_frame = self:get_text_display_frame()

    local bg_display_frame = {
        x = text_display_frame.x - bg_margin.x,
        y = text_display_frame.y - bg_margin.y,
        w = text_display_frame.w + bg_margin.x * 2,
        h = text_display_frame.h + bg_margin.y * 2,
    }

    self.bg_obj = drawing.rectangle(bg_display_frame)
        :setStroke(true)
        :setFill(true)
        :setFillColor(self.bg_color)
        :setRoundedRectRadii(5, 5)
        :show(0.15)
    self.text_obj = drawing.text(text_display_frame, self.message)
        :setTextStyle(self.text_style)
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

module.new = function(message, position)
    return Label.new(message, position)
end

module.show = function(message, position, duration)
    Label.new(message, position):show(duration)
end

return module
