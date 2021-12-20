# Bo3FlatAnims
Flat animation syntax for T7/Black Ops 3 Lua

# Features: 
- Flattens the "traditional" nested function callbacks into a simple list of anim id's and transforms
- reduces repetition: if you add an animation with the same ID as a previous animation, the transforms for the previous anim get copied into the new anim so you don't have to specify the same transform and duration over and over again
- onEnter and onExit callbacks for each keyframe allow you to specify code to run at the beginning or end of a particular keyframe animation, for instance you can set the text at the end of a fade_out animation so when the next fade_in happens the text will have changed
- Works on multiple elements, so if you have a text element with background text that should have the same animations as the foreground text, you simply call `animation:Play(fgText)` and then `animation:Play(bgText)` in your clip
- Cleaner, expressive syntax

# Usage: 
Add to your maps ui folder and `require` it in whatever widgets you are trying to animate.

## API: 
`FlatAnimation.new(keyframeTable) `
- Creates a new FlatAnimation object
```lua
local myAnims = FlatAnimation.new{
    { id = "fade_out", setAlpha = 0.0, duration = 250 },
    { id = "fade_in_red", setAlpha = 1.0, setRGB = {1, 0, 0}, duration = 250 },
}
```

`animation:Play(element, index)`
- plays this animation on `element`
- `index` allows you to "jump" to a certain animation, for instance if I wanted to skip the fade_out in the previous example, I could do `myAnim:Play(element, 2)`

`onEnter(element, index, event)`
- `element` is the element this animation was called on
- `index` is the current index of this animation in the keyframe table
- `event` is the same `event` from `self:registerEventHandler("transition_complete_keyframe",  function(elem, event) end)`
- called on this keyframe before any animations actually happen

`onExit(element, index, event)`
- called on this keyframe once all animations have finished (or the anim was interrupted)



Here is an example widget file: 
```lua
-[[ Add to zone:
    rawfile,ui/uieditor/widgets/tests/AnimationTest.lua
    require("ui.uieditor.widgets.tests.AnimationTest.lua")
--]]
require("ui.utility.FlatAnimation")
CoD.AnimationTest = InheritFrom(LUI.UIElement)


function CoD.AnimationTest.new(menu, controller)
    local self = LUI.UIElement.new()
    if PreLoadFunc then
        PreLoadFunc(self, controller)
    end
    self:setClass(CoD.AnimationTest)
    self:setLeftRight(true, true, 0, 0)
    self:setTopBottom(true, true, 0, 0)
    self.anyChildUsesUpdateState = true
    self.ignoreCurrentStateCheck = true
    
    self.m_animations = FlatAnimation.new({
        {id = "pause", duration = 4501},
        {id = "fade_out", setAlpha = 0, duration = 500},
        {id = "fade_in", setAlpha = 1, duration = 500},
        {id = "fade_out"},
        {id = "fade_in"},
        {id = "fade_out"},
        {id = "fade_in"},
        {id = "fade_out"},
        {id = "fade_in"},
        {id = "fade_out"},
        {id = "fade_in"},
        {id = "fade_out"},
        {id = "fade_in"},
        {id = "fade_out"},
        {id = "fade_out"},
        {
            id = "lerp_to_red", 
            setRGB = {1, 0, 0}, 
            setAlpha = 1.0,
            duration=1000, 
            onEnter = function(element, index, event)
                element:setText(Engine.Localize(string.format("entered keyframe #%d", index)))
            end
        },
        {
            id = "lerp_to_green", 
            setRGB = {0, 1, 0}, 
            duration=1000, 
            onExit = function(element, index, event)
                element:setText(Engine.Localize(string.format("anim done keyframe #%d", index)))
            end
        }
    })

    local TestText = LUI.UIText.new()
    TestText:setLeftRight(false, false, 0, 0)
    TestText:setTopBottom(true, false, 0, 16)
    self.TestText = TestText
    self:addElement(TestText)
    TestText:setText("Test me out boiiii")
    
    self.clipsPerState = {
        DefaultState = {
            DefaultClip = function()
                self:setupElementClipCounter(1)
                self.m_animations:Play(TestText)
            end
        }
    }


    LUI.OverrideFunction_CallOriginalSecond(self, "close", function(self)
        -- close all resources created 
        self.TestText:close()
    end)
    return self
end
```
