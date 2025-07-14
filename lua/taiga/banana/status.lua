---@module "banana.instance"

---@param document Banana.Instance
return function(document)
    local root = document:getElementById("cont")
    local projectId = tonumber(root:getData("projectId")) or
        error("'projectId' data must be provided to <Status>")
    local tp = root:getData("type") or error("'type' data must be provided to <Status>")
    local id = tonumber(root:getData("id")) or error("'id' data must be provided to <Status>")
    local editCallback = root:getData("editCallback") or error("'editCallback' data must be provided to <Status>")
    local statusColor = document:getElementById("status-color")
    local statusName = document:getElementById("status-name")

    local reqTp = ""
    local dataTp = ""
    if tp == "epic" then
        reqTp = "epics"
        dataTp = "epic"
    elseif tp == "task" then
        reqTp = "tasks"
        dataTp = "task"
    elseif tp == "story" then
        reqTp = "stories"
        dataTp = "us"
    else
        error("Could not find require type for type '" .. tp .. "'")
    end


    require("taiga.api.projects").get(function(proj)
        local statusTypes = proj[dataTp .. "_statuses"]

        require("taiga.api." .. reqTp).get(function(obj)
            local status = vim.iter(statusTypes):filter(function(l)
                return l.id == obj.status
            end):nth(1)
            statusColor:setStyleValue("hl-fg", status.color)
            statusName:setTextContent(status.name)
            local open = false
            local els = {}
            statusName:attachRemap('n', "<CR>", { "line-hover" }, function()
                if not open then
                    for _, v in ipairs(statusTypes) do
                        local el = document:createElement('div')
                        local color = document:createElement('span')
                        color:setStyleValue("hl-fg", v.color)
                        color:setTextContent("■")
                        el:appendChild(color)
                        el:setStyleValue("margin-left", "2ch")
                        el:appendTextNode(" " .. v.name)
                        el:addClass("open")
                        el:attachRemap('n', '<CR>', { 'line-hover' }, function()
                            for _, e in ipairs(els) do
                                e:remove()
                            end
                            statusColor:setStyleValue("hl-fg", v.color)
                            statusName:setTextContent(v.name)
                            els = {}
                            open = false
                            vim.schedule_wrap(editCallback)(v)
                        end, {})
                        root:appendChild(el)
                        table.insert(els, el)
                    end
                    open = true
                else
                    for _, v in ipairs(els) do
                        v:remove()
                    end
                    els = {}
                    open = false
                end
            end, {})
        end, {}, { id = id })
    end, {}, { id = projectId })
    -- local filetype = root:getData("filetype") or "markdown"
    -- local displayTitle = root:getData("displayTitle") or function(s) return s end
end
