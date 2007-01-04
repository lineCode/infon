--[[

    Copyright (c) 2006 Florian Wesch <fw@dividuum.de>. All Rights Reserved.
    
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place - Suite 330, Boston, MA  02111-1307, USA

]]--

-- function clone(f, env) return function(...) setfenv(f, env) return f(...) end end

function createCreature(id, parent)
    local creature = {
        id          = id;
        parent      = parent;
        GLOBAL      = _G;

        print       = print;
        error       = error;
        math        = math;
        table       = table;
        string      = string;
    }

    creature._G = creature

    setmetatable(creature, {
        __tostring = function(self)
            local x, y  = get_pos(self.id)
            local states = { [0]="idle",   [1]="walk",    [2]="heal",  [3]="eat",
                             [4]="attack", [5]="convert", [6]="spawn", [7]="feed"}
            return "<creature " .. self.id .." [" .. x .. "," .. y .."] " .. 
                    "type " .. get_type(self.id) ..", health " .. get_health(self.id) .. ", " ..
                    "food " .. get_food(self.id) .. ", state " .. states[get_state(self.id)]  .. ", handler " .. self._state_name .. ">"
        end, 
        __concat = function (op1, op2)
            return tostring(op1) .. tostring(op2)
        end
    })

    setfenv(function ()
        -- Internal Stuff -----------------

        function _set_state(state, ...)
            GLOBAL.assert(_G[state], "state '" .. state .. "' not defined")
            _state_name = state
            _state_func = _G[state]
            _state_args = {...}
        end

        function to(state, ...)
            GLOBAL.assert(_G[state], "state '" .. state .. "' not defined")
            return state, ...
        end

        and_switch_to = to

        function _state_handler() 
            while true do
                local function handle_state_change(state, ...) 
                    if not state then 
                        -- change to idle
                        _set_state("idle")
                    elseif state == true then
                        -- keep state (restart state handler)
                    else
                        -- change to new state
                        _set_state(state, ...)
                    end
                end
                handle_state_change(_state_func(GLOBAL.unpack(_state_args)))
                wait_for_next_round()
            end
        end

        function _restart_thread()
            thread = GLOBAL.coroutine.create(_state_handler)
        end

        function restart()
            GLOBAL.setfenv(GLOBAL.load, _G)()
            _set_state("restarting")
            _restart_thread()
        end

        function wait_for_next_round()
            if GLOBAL.can_yield then
                GLOBAL.coroutine.yield()
            else
                print("-----------------------------------------------------------")
                print("Error: A called function wanted to wait_for_next_round().")
                print("-----------------------------------------------------------")
                error("cannot continue")
            end
        end

        function call_event(event, ...)
            if not _G[event] then return end
            local function handle_state_change(ok, state, ...) 
                if not ok then
                    print("calling event '" .. event .. "' failed: " .. state)
                else
                    if not state then 
                        -- no change
                    else
                        -- change to new state
                        _set_state(state, ...)
                        _restart_thread()
                    end
                end
            end
            return handle_state_change(GLOBAL.epcall(GLOBAL._TRACEBACK, _G[event], ...))
        end

        -- States ---------------------------

        function idle()
            GLOBAL.set_state(id, GLOBAL.CREATURE_IDLE)
            if onIdle then return onIdle() end
        end

        function restarting()
            if onRestart then return onRestart() end
        end
        
        -- Functions ------------------------
        
        time       = GLOBAL.game_time
        koth_pos   = GLOBAL.get_koth_pos
        world_size = GLOBAL.world_size

        function suicide()
            GLOBAL.suicide(id)
        end

        function nearest_enemy()
            return GLOBAL.get_nearest_enemy(id)
        end

        function set_path(x, y)
            return GLOBAL.set_path(id, x, y)
        end

        function set_target(c)
            return GLOBAL.set_target(id, c)
        end

        function set_conversion(t)
            return GLOBAL.set_convert(id, t)
        end

        function pos()
            return GLOBAL.get_pos(id)
        end

        function speed()
            return GLOBAL.get_speed(id)
        end

        function health()
            return GLOBAL.get_health(id)
        end

        function food()
            return GLOBAL.get_food(id)
        end

        function max_food()
            return GLOBAL.get_max_food(id)
        end

        function tile_food()
            return GLOBAL.get_tile_food(id)
        end

        function tile_type()
            return GLOBAL.get_tile_type(id)
        end

        function type()
            return GLOBAL.get_type(id)
        end

        function say(msg)
            return GLOBAL.set_message(id, msg)
        end

        function begin_idling()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_IDLE)
        end

        function begin_walk_path()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_WALK)
        end

        function begin_healing()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_HEAL)
        end

        function begin_eating()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_EAT)
        end

        function begin_attacking()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_ATTACK)
        end

        function begin_converting()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_CONVERT)
        end

        function begin_spawning()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_SPAWN)
        end

        function begin_feeding()
            return GLOBAL.set_state(id, GLOBAL.CREATURE_FEED)
        end

        function is_idle()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_IDLE
        end

        function is_healing()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_HEAL
        end

        function is_walking()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_WALK
        end

        function is_eating()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_EAT
        end

        function is_attacking()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_ATTACK
        end

        function is_converting()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_CONVERT
        end

        function is_spawning()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_SPAWN
        end

        function is_feeding()
            return GLOBAL.get_state(id) == GLOBAL.CREATURE_FEED
        end

        function random_path()
            local x1, y1, x2, y2 = world_size()
            local i = 0
            while true do 
                for i = 1, 300 do 
                    local x, y = math.random(x1, x2), math.random(y1, y2)
                    if set_path(x, y) then
                        return  x, y
                    end
                end
                wait_for_next_round()
            end
        end

        function in_state(state)
            if type(state) == "function" then
                return _state_func == state
            elseif type(state) == "string" then
                return _state_name == state
            else
                return false
            end
        end

        -- Blocking Actions -----------------
        
        function sleep(msec)
            local now = time()
            while now + msec < time() do
                wait_for_next_round()
            end
        end
        
        function random_move()
            return move_to(random_path())
        end

        function move_to(tx, ty)
            local x, y = pos()
            if x == tx and y == ty then
                return true
            end
            
            if not GLOBAL.set_path(id, tx, ty) then
                return false
            end

            return move_path(tx, ty)
        end

        function move_path(tx, ty)
            if not GLOBAL.set_state(id, GLOBAL.CREATURE_WALK) then
                return false
            end

            local review = time()
            while GLOBAL.get_state(id) == GLOBAL.CREATURE_WALK do
                wait_for_next_round()
            end
            
            x, y = pos()
            return x == tx and y == ty
        end

        function heal() 
            if not begin_healing() then
                return false
            end
            while is_healing() do
                wait_for_next_round()
            end
            return true
        end

        function eat()
            if not begin_eating() then
                return false
            end
            while is_eating() do
                wait_for_next_round()
            end
            return true
        end

        function feed(target)
            if not set_target(target) then
                return false
            end
            if not begin_feeding() then
                return false
            end
            while is_feeding() do
                wait_for_next_round()
            end
            return true
        end

        function attack(target) 
            if not set_target(target) then
                return false
            end
            if not begin_attacking() then
                return false
            end
            while is_attacking() do
                wait_for_next_round()
            end
            return true
        end

        function convert(to_type)
            if not set_conversion(to_type) then
                return false
            end
            if not begin_converting() then 
                return false
            end
            while is_converting() do
                wait_for_next_round()
            end
            return type() == to_type
        end

        function spawn()
            if not begin_spawning() then
                return false
            end
            while is_spawning() do
                wait_for_next_round()
            end
            return true
        end

    end, creature)()
    return creature
end

------------------------------------------------------------------------
-- Callbacks von C
------------------------------------------------------------------------

function this_function_call_fails_if_cpu_limit_exceeded() end

-- Globales Array alle Kreaturen
creatures = creatures or {}

function player_think(events)
    can_yield = false

    -- Events abarbeiten
    for n, event in ipairs(events) do 
        if event.type == CREATURE_SPAWNED then
            local id     = event.id
            local parent = event.parent ~= -1 and event.parent or nil
            local creature = createCreature(id, parent)
            creatures[id]  = creature
            creature.restart()
        elseif event.type == CREATURE_KILLED then
            local id     = event.id
            local killer = event.killer ~= -1 and event.killer or nil
            assert(creatures[id])
            creatures[id].call_event("onKilled", killer)
            creatures[id] = nil
        elseif event.type == CREATURE_ATTACKED then
            local id       = event.id
            local attacker = event.attacker
            creatures[id].call_event("onAttacked")
        elseif event.type == PLAYER_CREATED then
            -- TODO
        else
            error("invalid event " .. event.type)
        end
    end

    can_yield = true

    -- Vorhandene Kreaturen durchlaufen
    for id, creature in pairs(creatures) do
        if type(creature.thread) ~= 'thread' then
            creature.message = 'uuh. self.thread is not a coroutine.'
        elseif coroutine.status(creature.thread) == 'dead' then
            if not creature.message then 
                creature.message = 'main() terminated (maybe it was killed for using too much cpu/memory?)'
            end
        else
            -- creature.call_event("onTest", killer)
            if get_tile_food(creature.id) > 0 then 
                creature.call_event("onTileFood")
            end
            local ok, msg = coroutine.resume(creature.thread)
            if not ok then
                creature.message = msg
                -- Falls die Coroutine abgebrochen wurde, weil zuviel
                -- CPU benutzt wurde, so triggert folgender Funktions-
                -- aufruf den Abbruch von player_think. Um zu ermitteln,
                -- wo zuviel CPU gebraucht wurde, kann der Traceback
                -- in creature.message mittels 'i' angezeigt werden.
                this_function_call_fails_if_cpu_limit_exceeded()
            end
        end
    end

    can_yield = false
end

function load()
    -- function onKilled()
    --     print(id .. " died")
    -- end

    function onIdle()
        return and_switch_to "find_food"
    end

    function find_food()
        random_move()
    end

    function onTileFood()
        if food() < max_food() then 
            return and_switch_to "eat_food"
        end
    end

    function eat_food()
        eat()
        return and_switch_to "find_food"
    end
end