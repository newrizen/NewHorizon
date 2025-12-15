-- Arquivo: moves/init.lua
print("[moves] Mod carregado")

local double_tap_time = 0.3  -- tempo máximo entre toques
local last_tap = {}
local was_pressing = {}
local running = {}
local last_shift_tap = {}
local was_shift = {}
local crawling = {}
local crouching = {}


-- WALL JUMP
local walljump_cooldown = {}
local walljump_delay = 0.2
local check_distance = 0.1
local wall_min_height = 1
local was_jump = {}


minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local controls = player:get_player_control()
        
        local pressed_now = controls.up and not was_pressing[name]
        if pressed_now then
            local now = minetest.get_us_time() / 1e6
            if last_tap[name] and (now - last_tap[name] <= double_tap_time) then
                if not running[name] then
                    running[name] = true
                    player:set_physics_override({ speed = 2.0 })
                end
            end
            last_tap[name] = now
        end
        
        if running[name] and not controls.up then
            running[name] = false
            player:set_physics_override({ speed = 1.0 })
        end
        
        was_pressing[name] = controls.up
    end
    
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local controls = player:get_player_control()
        local shift_now = controls.sneak and not was_shift[name]
        
        ---------------------------------------------------------------------
        -- DOUBLE-TAP SHIFT → RASTEJAR
        ---------------------------------------------------------------------
        if shift_now then
            local now = minetest.get_us_time() / 1e6
            if last_shift_tap[name] and (now - last_shift_tap[name] <= double_tap_time) then
                crawling[name] = true
                crouching[name] = false
                player:set_physics_override({ speed = 1.1, jump = 0.5 })
                player:set_properties({
                    eye_height = 0.6,
                    collisionbox = {-0.3, 0, -0.3, 0.3, 0.5, 0.3},  -- Fixo: começa em 0
                })
            end
            last_shift_tap[name] = now
        end
        
        ---------------------------------------------------------------------
        -- SEGURAR SHIFT → AGACHAR (se não estiver rastejando)
        ---------------------------------------------------------------------
        if controls.sneak and not crawling[name] then
            if not crouching[name] then
                crouching[name] = true
                crawling[name] = false  -- Tinha "falsew" aqui (typo)
                player:set_physics_override({ speed = 0.7, jump = 1.0 })  -- Mantém jump
                player:set_properties({
                    eye_height = 1.0,
                    collisionbox = {-0.3, 0, -0.3, 0.3, 1.2, 0.3},  -- Fixo: começa em 0
                })
            end
        end
        
        ---------------------------------------------------------------------
        -- SOLTOU SHIFT → VOLTA AO NORMAL
        ---------------------------------------------------------------------
        if not controls.sneak then
            if crouching[name] or crawling[name] then
                crouching[name] = false
                crawling[name] = false
                player:set_physics_override({ speed = 1.0, jump = 1.0 })
                player:set_properties({
                    eye_height = 2.4,
                    collisionbox = {-0.3, 0, -0.3, 0.3, 2.7, 0.3},  -- Fixo: começa em 0
                })
            end
        end
        
        was_shift[name] = controls.sneak
    end
    
---------------------------------------------------------------------
-- SALTO DUPLO AO ENCONTRAR PAREDES (WALL JUMP)
---------------------------------------------------------------------
for _, player in ipairs(minetest.get_connected_players()) do
    local name = player:get_player_name()
    local ctrl = player:get_player_control()

    -- Criar cooldown inicial
    if not walljump_cooldown[name] then
        walljump_cooldown[name] = 0
    end

    -- Detectar aperto de ESPAÇO agora
    if ctrl.jump and not was_jump[name] then
        local now = minetest.get_us_time() / 1e6

        if now - walljump_cooldown[name] >= walljump_delay then
            
            -- Posição e direção
            local pos = player:get_pos()
            local dir = player:get_look_dir()

            -- Ponto de verificação da parede
            local check_pos = {
                x = pos.x + dir.x * check_distance,
                y = pos.y,
                z = pos.z + dir.z * check_distance
            }

            -- Verificar parede de 2 blocos
            local wall1 = minetest.get_node(check_pos).walkable
            local wall2 = minetest.get_node({
                x = check_pos.x, 
                y = check_pos.y + 1, 
                z = check_pos.z
            }).walkable

            if wall1 and wall2 then
                -- Aplicar wall-jump
                player:add_velocity({
                    x = -dir.x * 4,
                    y = 12,
                    z = -dir.z * 4,
                })

                walljump_cooldown[name] = now
            end
        end
    end

    was_jump[name] = ctrl.jump
end


---------------------------------------------------------------------
-- ESCALAR PAREDES (segurar pulo) - versão com fricção vertical
---------------------------------------------------------------------
local CLIMB_SPEED = 2.5
local HORIZ_FRICTION = 0.15
local VERT_FRICTION = 1        -- NOVO → fricção vertical
local FRONT_DIST = 0.6
local HEIGHT_OFFS = {0.5, 1.1, 1.8}

local function is_tall_wall(x, y, z)
    for i = 0, 2 do
        local n = minetest.get_node_or_nil({x = x, y = y + i, z = z})
        if not n then return false end
        local reg = minetest.registered_nodes[n.name]
        if not reg or not reg.walkable then
            return false
        end
    end
    return true
end


for _, player in ipairs(minetest.get_connected_players()) do
    local ctrl = player:get_player_control()

    if ctrl.jump then
        local pos = player:get_pos()
        local dir = player:get_look_dir()

        local check_x = pos.x + dir.x * FRONT_DIST
        local check_z = pos.z + dir.z * FRONT_DIST

        --------------------------------------------------------------
        -- Verificação da parede
        --------------------------------------------------------------
        local base_wall_found = false
        for _, yoff in ipairs(HEIGHT_OFFS) do
            local n = minetest.get_node_or_nil({ x = check_x, y = pos.y + yoff, z = check_z })
            if n then
                local reg = minetest.registered_nodes[n.name]
                if reg and reg.walkable then
                    base_wall_found = true
                    break
                end
            end
        end

        local tall_enough = false
        if base_wall_found then
            tall_enough = is_tall_wall(check_x, pos.y, check_z)
        end

        --------------------------------------------------------------
        -- ESCALADA ATIVA
        --------------------------------------------------------------
        if base_wall_found and tall_enough then
            local vel = player:get_velocity() or {x=0,y=0,z=0}

            ----------------------------------------------------------
            -- FRICÇÃO VERTICAL
            -- Se o jogador não estiver se movendo, ou se quiser parar,
            -- faça Y tender a zero: permite "ficar colado" na parede.
            ----------------------------------------------------------
            local new_y = vel.y

            if math.abs(vel.y) > 0.05 then
                -- puxa y para zero, devagar
                if vel.y > 0 then
                    new_y = math.max(0, vel.y - VERT_FRICTION)
                else
                    new_y = math.min(0, vel.y + VERT_FRICTION)
                end
            else
                new_y = 0  -- fica parado
            end

            ----------------------------------------------------------
            -- SUBIR ao segurar pulo (override do atrito vertical)
            ----------------------------------------------------------
            new_y = CLIMB_SPEED

            ----------------------------------------------------------
            -- Aplicar velocidade
            ----------------------------------------------------------
            local new_vel = {
                x = vel.x * HORIZ_FRICTION,
                y = new_y,
                z = vel.z * HORIZ_FRICTION
            }

            player:set_velocity(new_vel)

            -- baixa gravidade para permitir escalada suave
            player:set_physics_override({
                gravity = 0.25,
                jump = 0
            })

        else
            -- se não está escalando
            player:set_physics_override({
                gravity = 1.0,
                jump = 1.0
            })
        end

    else
        player:set_physics_override({ jump = 1.0 })
    end
end
end)
