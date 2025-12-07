-- Arquivo: player/init.lua
print("[player] Mod carregado")

minetest.register_on_joinplayer(function(player)
    -- Ajusta o tamanho visual e hitbox do player
    player:set_properties({
        visual_size = {x = 1, y = 1.5},
        collisionbox = {-0.3, 0, -0.3, 0.25, 2.7, 0.3},
        selectionbox = {-0.3, 0, -0.3, 0.3, 2.7, 0.3},
        eye_height = 2.4,  -- Ajusta a altura dos olhos
    })
    
    -- Define a hotbar com 2 slots
    minetest.after(0.1, function()
        player:hud_set_hotbar_itemcount(2)
        player:hud_set_hotbar_image("gui_hotbar2.png")
        player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
    end)
    
    -- APLIQUE O STEPHEIGHT DEPOIS
    minetest.after(0.2, function()
        player:set_physics_override({
            stepheight = 1.1,
            jump = 1.0,
        })
    end)
end)

-----------------------------
-- SISTEMA DE AUTO-PULO
-----------------------------
local auto_jump_cooldown = {}  -- Evita pulos repetidos muito rápidos

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        
        -- Atualiza cooldown
        if auto_jump_cooldown[player_name] then
            auto_jump_cooldown[player_name] = auto_jump_cooldown[player_name] - dtime
            if auto_jump_cooldown[player_name] <= 0 then
                auto_jump_cooldown[player_name] = nil
            end
        end
        
        -- Verifica se o jogador está se movendo
        local controls = player:get_player_control()
        local is_moving = controls.up or controls.down or controls.left or controls.right
        
        if is_moving and not auto_jump_cooldown[player_name] then
            local pos = player:get_pos()
            local vel = player:get_velocity()
            
            -- Verifica se está no chão (velocidade Y próxima de zero ou negativa)
            local on_ground = vel.y <= 0.1 and vel.y >= -0.5
            
            if on_ground then
                -- Pega a direção do movimento
                local yaw = player:get_look_horizontal()
                local move_dir = {x = 0, z = 0}
                
                if controls.up then
                    move_dir.x = move_dir.x - math.sin(yaw)
                    move_dir.z = move_dir.z + math.cos(yaw)
                end
                if controls.down then
                    move_dir.x = move_dir.x + math.sin(yaw)
                    move_dir.z = move_dir.z - math.cos(yaw)
                end
                if controls.left then
                    move_dir.x = move_dir.x - math.cos(yaw)
                    move_dir.z = move_dir.z - math.sin(yaw)
                end
                if controls.right then
                    move_dir.x = move_dir.x + math.cos(yaw)
                    move_dir.z = move_dir.z + math.sin(yaw)
                end
                
                -- Normaliza a direção
                local length = math.sqrt(move_dir.x^2 + move_dir.z^2)
                if length > 0 then
                    move_dir.x = move_dir.x / length
                    move_dir.z = move_dir.z / length
                    
                    -- Verifica o bloco no nível dos pés (y + 0)
                    local check_pos_feet = {
                        x = math.floor(pos.x + move_dir.x * 0.5 + 0.5),
                        y = math.floor(pos.y),
                        z = math.floor(pos.z + move_dir.z * 0.5 + 0.5)
                    }
                    
                    -- Verifica o bloco na altura da cintura (y + 1)
                    local check_pos_waist = {
                        x = check_pos_feet.x,
                        y = check_pos_feet.y + 1,
                        z = check_pos_feet.z
                    }
                    
                    -- Verifica o bloco acima da cabeça (y + 2)
                    local check_pos_head = {
                        x = check_pos_feet.x,
                        y = check_pos_feet.y + 2,
                        z = check_pos_feet.z
                    }
                    
                    local node_feet = minetest.get_node(check_pos_feet)
                    local node_waist = minetest.get_node(check_pos_waist)
                    local node_head = minetest.get_node(check_pos_head)
                    
                    -- Define quais blocos são "sólidos" (obstáculos)
                    local function is_solid(node_name)
                        return node_name ~= "air" and 
                               node_name ~= "nodes:water" and
                               node_name ~= "nodes:lava" and
                               node_name ~= "nodes:leaves" and
                               node_name ~= "nodes:pebble"
                    end
                    
                    -- Define quais blocos permitem passagem
                    local function is_passable(node_name)
                        return node_name == "air" or 
                               node_name == "nodes:water" or
                               node_name == "nodes:leaves" or 
                               node_name == "nodes:pebble"
                    end
                    
                    -- CONDIÇÕES PARA PULAR:
                    -- 1. Há um bloco sólido na altura da cintura (obstáculo de 1 bloco)
                    -- 2. Há espaço livre acima (pode pular)
                    if is_solid(node_waist.name) and 
                       is_passable(node_head.name) then
                        
                        -- Faz o jogador pular
                        player:add_velocity({
                            x = 0,
                            y = 7.0,  -- Força do pulo
                            z = 0
                        })
                        
                        -- Define cooldown de 0.4 segundos
                        auto_jump_cooldown[player_name] = 0.4
                    end
                end
            end
        end
    end
end)

-----------------------------
-- SISTEMA DINÂMICO DE DANO POR QUEDA
-----------------------------
-- Tabela de absorção de impacto por material
local surface_absorption = {
    ["nodes:leaves"] = 0.85,      -- Folhas absorvem 85% do impacto
    ["nodes:sand"] = 0.70,         -- Areia absorve 70% do impacto
    ["nodes:wet_sand"] = 0.40,     -- Areia molhada absorve 40% do impacto
    ["nodes:water"] = 0.50,        -- Água absorve 50% do impacto
    ["nodes:water_flowing"] = 0.50,
    ["nodes:snow"] = 0.90,         -- Neve absorve 90% do impacto
    ["nodes:lava"] = 0.20,         -- Lava absorve apenas 20% (líquido denso)
    ["nodes:lava_flowing"] = 0.20,
    -- Materiais duros não têm absorção (dano total)
    ["nodes:grass"] = 0.0,
    ["nodes:top_grass"] = 0.0,
    ["nodes:dirt"] = 0.0,
    ["nodes:gneiss"] = 0.0,
    ["nodes:bedrock"] = 0.0,
    ["nodes:wood"] = 0.0,
}

minetest.register_on_player_hpchange(function(player, hp_change, reason)
    if reason.type == "fall" then
        local pos = player:get_pos()
        pos.y = pos.y - 1
        local node = minetest.get_node(pos).name
        
        -- Pega o fator de absorção do material
        local absorption = surface_absorption[node] or 0.0
        
        -- Calcula o dano reduzido
        -- hp_change é negativo (ex: -4 de dano)
        -- absorption de 0.85 significa que 85% do impacto é absorvido
        local reduced_damage = hp_change * (1 - absorption)
        
        -- Garante um dano mínimo de -1 se cair de altura considerável
        -- (evita quedas de 10 blocos em folhas não causarem dano nenhum)
        if hp_change < -5 and reduced_damage > -1 then
            reduced_damage = -1
        end
        
        -- Arredonda para baixo (menos severo para o jogador)
        reduced_damage = math.ceil(reduced_damage)
        
        return reduced_damage
    end
    return hp_change
end, true)

-- Limpa cooldown quando o jogador sai
minetest.register_on_leaveplayer(function(player)
    auto_jump_cooldown[player:get_player_name()] = nil
end)
