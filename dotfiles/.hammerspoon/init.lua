local BUTTON = 2
mcTap = hs.eventtap.new(
    {hs.eventtap.event.types.otherMouseDown, hs.eventtap.event.types.otherMouseUp},
    function(e)
        if e:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber) ~= BUTTON then
            return false
        end
        if e:getType() == hs.eventtap.event.types.otherMouseDown then
            hs.spaces.toggleMissionControl()
        end
        return true  -- swallow both down and up
    end
)
mcTap:start()