EnableGlobals()
FlatAnimation = {
}

-- setting to true so that verifyTransforms[key] returns a truthy value
FlatAnimation.verifyTransforms = {
    setAlpha = true,
    setRGB   = true,
    setTopBottom = true,
    setLeftRight = true,
    setXRot = true,
    setYRot = true,
    setZRot = true,
    setZoom = true,
    setShaderVector = true,
    setScale = true
}
function TableHasElementWithId(tbl, id)
    for k, v in ipairs(tbl) do
        if v["id"] == id then
            return true, v
        end
    end
    return false
end

-- searches for a keyframe with matching id and returns the keyframe table if it exists
function FlatAnimation.GetKeyframeById(self, id)
    for k, v in ipairs(self.m_keyframeList) do
        if v["id"] == id then
            return v, k -- returns v and optionally the index
        end
    end
end

-- if there is a table that matches the passed id, assign the keyframeTable to that tag
-- do NOT set an id in the keyframe table.
function FlatAnimation.SetKeyframeWithId(self, id, keyframeTable)
    local keyframe, index = self:GetKeyframeByTag(id)
    if keyframe then
        self.m_keyframeList[index]    = keyframeTable
        self.m_keyframeList[index].id = id
    end
end

function FlatAnimation.PlayNext(self, keyframe, index, element, event)
    if keyframe.onEnter then
        keyframe.onEnter(element, index, event)
    end
    if not event.interrupted then
        element:beginAnimation("keyframe", keyframe.duration, false, false, keyframe.tween)
    end
    -- apply transform
    for k, v in pairs(keyframe) do
        -- Engine.ComError( Enum.errorCode.ERROR_UI, string.format("%s(%f)", k, v))
        if self.verifyTransforms[k] then
            if type(v) == "table" then
                element[k](element, unpack(v))
            else
                element[k](element, v)
            end
        end
    end

    if event.interrupted then
        if keyframe.onExit then
            keyframe.onExit(element, index, event)
        end
        element:getParent().clipFinished(element, event)
    else
        element:registerEventHandler("transition_complete_keyframe", function(Element, Event)
            if keyframe.onExit then
                keyframe.onExit(element, index, event)
            end
            if (#self.m_keyframeList > index) then
                self:PlayNext(self.m_keyframeList[index + 1], index + 1, Element, Event)
            else
                Element:getParent().clipFinished(Element, Event)
            end
        end)
    end
end

function FlatAnimation.Play(self, element, index)
    index = index or 1
    self:PlayNext(self.m_keyframeList[index], index, element, {})
end

function FlatAnimation.Dump(self)
    local outputAnims = ""
    for k, v in ipairs(self.m_keyframeList) do
        outputAnims = outputAnims .. v.id .. " {\n"

        for key, value in pairs(v) do
            if type(v[key]) == "function" then
                outputAnims = outputAnims .. "    " .. key .. ": " .. "(function)" .. "\n"
            elseif type(v[key]) == "table" then
                outputAnims = outputAnims .. "    " .. key .. ": " .. "table" .. "\n"
            else
                outputAnims = outputAnims .. "    " .. key .. ": " .. v[key] .. "\n"
            end
        end
        outputAnims = outputAnims .. "}\n\n"
    end
    return outputAnims
end

function FlatAnimation.new(keyframeList)
    local self             = { m_keyframeList = {} }

    self.SetKeyframeWithId = FlatAnimation.SetKeyframeWithId
    self.GetKeyframeById   = FlatAnimation.SetKeyframeWithId
    self.Dump              = FlatAnimation.Dump
    self.PlayOnElement     = FlatAnimation.PlayOnElement
    self.Play              = FlatAnimation.Play
    self.PlayNext          = FlatAnimation.PlayNext
    self.verifyTransforms  = FlatAnimation.verifyTransforms

    for index, keyframe in ipairs(keyframeList) do
        local keyframeIdExists, foundKeyframe = TableHasElementWithId(self.m_keyframeList, keyframe.id)
        if keyframeIdExists then
            table.insert(self.m_keyframeList, foundKeyframe)
        else
            if keyframe["tween"] == nil then
                keyframe["tween"] = CoD.TweenType.Linear
            end
            table.insert(self.m_keyframeList, keyframe)
        end
    end
    return self
end
