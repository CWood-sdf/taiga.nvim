---@class (exact) Taiga.Api.BaseOpts
---@field cache boolean?


local M = {
}

---@param n number
function M.loadProject(n)
    require("taiga.api.auth").getCredentials(function()
        require("taiga.api.projects").list(function(projects)
            local proj = projects[n]
            if proj == nil then
                return
            end
            require("taiga.api.epics").list(function()
            end, {}, { project = proj.id })
            require("taiga.api.stories").list(function(stories)
                for _, story in ipairs(stories) do
                    require("taiga.api.tasks").list(function()
                    end, {}, { project = proj.id, user_story = story.id })
                end
            end, {}, { project = proj.id })
        end, {}, {})
    end, {}, nil)
end

function M.setup()
    -- M.loadProject(1)
end

return M
