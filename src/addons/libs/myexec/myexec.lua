-- Eleven Pies: Modified from mymacro

require 'common'

myexec = myexec or { };

local __macros = { };

local __go = false;

local function zerotimer()
    return os.clock();
end

local function update_go()
    local tmp_go = false;

    for k, v in pairs(__macros) do
        if (v.go) then
            tmp_go = true;
        end
    end

    __go = tmp_go;
end

local function timer_once(macro_item, cycle, fn)
    -- Apply the remaining offset and reset it to zero
    macro_item.timer = zerotimer() - macro_item.remaining_offset;
    macro_item.remaining_offset = 0;
    macro_item.curr_cycle = cycle;
    macro_item.curr_fn = fn;
    macro_item.go = true;
    update_go();
end

---------------------------------------------------------------------------------------------------
-- func: do_step
-- desc: Queues the next macro step to be run after a specified delay
---------------------------------------------------------------------------------------------------
local function do_step(macro_item, state)
    macro_item.go = false;
    update_go();

    while (macro_item.running) do
        if (state == 0) then
            if (macro_item.cycle > 0) then
                timer_once(macro_item, macro_item.cycle, function()
                    do_step(macro_item, state + 1);
                end);

                -- Engaging timer, so go ahead and stop here
                break;
            else
                -- Running immediately, so increment state
                state = state + 1;
            end
        else
            local step_item = macro_item.steps[state];
            if (step_item ~= nil) then
                if (step_item.cycle > 0) then
                    timer_once(macro_item, step_item.cycle, function()
                        -- Do not run empty commands
                        -- Allowing this for wait delay without a command specified
                        if (step_item.cmd ~= nil and step_item.cmd ~= '') then
                            AshitaCore:GetChatManager():QueueCommand(step_item.cmd, 1);
                        end
                        do_step(macro_item, state + 1);
                    end);
    
                    -- Engaging timer, so go ahead and stop here
                    break;
                else
                    AshitaCore:GetChatManager():QueueCommand(step_item.cmd, 1);
    
                    -- Running immediately, so increment state
                    state = state + 1;
                end
            else
                if (macro_item.persist == false) then
                    -- Unload macro
                    __macros[macro_item.name] = nil;

                    -- No more work to do
                    break;
                end

                -- Apply run limit, if any
                if (macro_item.limit > 0) then
                    macro_item.position = macro_item.position + 1;
                    if (macro_item.position >= macro_item.limit) then
                        -- If macro ends in /echo or similar chat command, this message may appear earlier in chat log
                        print('stopping ' .. macro_item.name);
                        macro_item.running = false;
                        macro_item.go = false;
                        update_go();
                    end
                end

                -- Reached the end, now go back to the beginning
                state = 0;

                -- Sanity check
                if (macro_item.cycle < (1/30)) then
                    macro_item.cycle = (1/30);
                end
            end
        end
    end
end

local function get_macro_item(name)
    local macro_item = __macros[name];
    if (macro_item == nil) then
        macro_item = { };
        macro_item.name = name;
        macro_item.cycle = 0;
        macro_item.offset = 0;
        macro_item.limit = 0;
        macro_item.position = 0;
        macro_item.persist = false;
        macro_item.running = false;
        macro_item.go = false;
        macro_item.timer = zerotimer();
        macro_item.steps = { };
        __macros[name] = macro_item;
    end

    return macro_item;
end

local function resume_steps(name)
    local macro_item = __macros[name];
    if (macro_item ~= nil) then
        -- Do not reset position for resuming
        -- Offset is a one-shot
        macro_item.remaining_offset = macro_item.offset;
        macro_item.running = true;
        do_step(macro_item, 0);
    else
        print ('Macro not found: ' .. name);
    end
end

local function start_steps(name)
    local macro_item = __macros[name];
    if (macro_item ~= nil) then
        -- Reset position for starting
        macro_item.position = 0;
        -- Offset is a one-shot
        macro_item.remaining_offset = macro_item.offset;
        macro_item.running = true;
        do_step(macro_item, 0);
    else
        print ('Macro not found: ' .. name);
    end
end

local function stop_steps(name)
    local macro_item = __macros[name];
    if (macro_item ~= nil) then
        macro_item.running = false;
        macro_item.go = false;
        update_go();
    else
        print ('Macro not found: ' .. name);
    end
end

local function resume_all()
    print("Resuming all!");
    for k, v in pairs(__macros) do
        -- Do not reset position for resuming
        -- Offset is a one-shot
        v.remaining_offset = v.offset;
        v.running = true;
        do_step(v, 0);
    end
end

local function start_all()
    print("Starting all!");
    for k, v in pairs(__macros) do
        -- Reset position for starting
        v.position = 0;
        -- Offset is a one-shot
        v.remaining_offset = v.offset;
        v.running = true;
        do_step(v, 0);
    end
end

local function stop_all()
    print("Stopping all!");
    for k, v in pairs(__macros) do
        v.running = false;
        v.go = false;
        update_go();
    end
end

local function toggle_all()
    if (__go) then
        stop_all();
    else
        start_all();
    end
end

local function pause_all()
    if (__go) then
        stop_all();
    else
        resume_all();
    end
end

local function persist_all(value)
    for k, v in pairs(__macros) do
        v.persist = value;
    end
end

local function queue_step(name, cmd, cycle)
    local macro_item = get_macro_item(name);
    local step_item = { };
    step_item.cycle = cycle;
    step_item.cmd = cmd;
    table.insert(macro_item.steps, step_item);
end

local function exists(name)
    local macro_item = __macros[name];
    if (macro_item ~= nil) then
        return true;
    else
        return false;
    end
end

---------------------------------------------------------------------------------------------------
-- Accessors
---------------------------------------------------------------------------------------------------

local function get_all()
    local external_conf = { };
    for k, v in pairs(__macros) do
        -- Only copying certain properties
        local item = { };
        item.cycle = v.cycle;
        item.offset = v.offset;
        item.limit = v.limit;
        item.steps = v.steps;
        external_conf[k] = item;
    end

    return external_conf;
end

local function set_all(value)
    if (__go) then
        stop_all();
    end

    local internal_conf = { };
    for k, v in pairs(value) do
        -- Only copying certain properties
        local item = { };
        item.cycle = v.cycle;
        item.offset = v.offset;
        item.limit = v.limit;
        item.steps = v.steps;
        -- Set internal properties
        item.name = k;
        item.position = 0;
        item.persist = false;
        item.running = false;
        item.go = false;
        item.timer = zerotimer();
        internal_conf[k] = item;
    end

    __macros = internal_conf;
end

local function get_steps(name)
    local macro_item = get_macro_item(name);
    return macro_item.steps;
end

local function set_steps(name, value)
    local macro_item = get_macro_item(name);
    macro_item.steps = value;
end

local function get_persist(name)
    local macro_item = get_macro_item(name);
    return macro_item.persist;
end

local function set_persist(name, value)
    local macro_item = get_macro_item(name);
    macro_item.persist = value;
end

local function get_cycle(name)
    local macro_item = get_macro_item(name);
    return macro_item.cycle;
end

local function set_cycle(name, value)
    local macro_item = get_macro_item(name);
    macro_item.cycle = value;
end

local function get_offset(name)
    local macro_item = get_macro_item(name);
    return macro_item.offset;
end

local function set_offset(name, value)
    local macro_item = get_macro_item(name);
    macro_item.offset = value;
end

local function get_limit(name)
    local macro_item = get_macro_item(name);
    return macro_item.limit;
end

local function set_limit(name, value)
    local macro_item = get_macro_item(name);
    macro_item.limit = value;
end

local function get_position(name)
    local macro_item = get_macro_item(name);
    return macro_item.position;
end

local function set_position(name, value)
    local macro_item = get_macro_item(name);
    macro_item.position = value;
end

local function print_debug()
    print('====================');
    print('Macros:');
    for k, v in pairs(__macros) do
        print('--------------------');
        print('Macro: ' .. tostring(k));
        print('Name: ' .. v.name);
        print('Cycle: ' .. tostring(v.cycle));
        print('Offset: ' .. tostring(v.offset));
        print('Limit: ' .. tostring(v.limit));
        print('Position: ' .. tostring(v.position));
        if (v.persist) then
            print('Persist: true');
        else
            print('Persist: false');
        end
        if (v.running) then
            print('Running: true');
        else
            print('Running: false');
        end
        if (v.go) then
            print('Go: true');
        else
            print('Go: false');
        end
        print('Timer: ' .. tostring(v.timer));
        print('Steps:');
        for k2, v2 in pairs(v.steps) do
            print('  Cycle: ' .. tostring(v2.cycle));
            print('  Command: ' .. v2.cmd);
        end
        print('Current cycle: ' .. tostring(v.curr_cycle));
        print('Current function: ' .. '(' .. tostring(v.curr_fn) .. ')');
        print('Remaining offset: ' .. tostring(v.remaining_offset));
    end
    print('====================');
end

local function do_work()
    if (__go) then
        -- Get zerotimer once per pulse
        local thiszerotimer = zerotimer();

        for k, v in pairs(__macros) do
            if (v.go) then
                if ((v.timer + v.curr_cycle) <= thiszerotimer) then
                    v.curr_fn();
                    v.timer = thiszerotimer;
                end
            end
        end
    end
end
ashita.register_event('render', do_work);

myexec.resume_steps = resume_steps;
myexec.start_steps = start_steps;
myexec.stop_steps = stop_steps;
myexec.resume_all = resume_all;
myexec.start_all = start_all;
myexec.stop_all = stop_all;
myexec.toggle_all = toggle_all;
myexec.pause_all = pause_all;
myexec.persist_all = persist_all;
myexec.queue_step = queue_step;
myexec.exists = exists;
myexec.get_all = get_all;
myexec.set_all = set_all;
myexec.get_steps = get_steps;
myexec.set_steps = set_steps;
myexec.get_persist = get_persist;
myexec.set_persist = set_persist;
myexec.get_cycle = get_cycle;
myexec.set_cycle = set_cycle;
myexec.get_offset = get_offset;
myexec.set_offset = set_offset;
myexec.get_limit = get_limit;
myexec.set_limit = set_limit;
myexec.get_position = get_position;
myexec.set_position = set_position;
myexec.print_debug = print_debug;
