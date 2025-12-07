-- SPAWN SEGURO COM DETECÇÃO DE TERRENO
local SPAWN_X = 0
local SPAWN_Z = 0
local SEARCH_HEIGHT_START = 80  -- Começa procurando de cima
local SEARCH_HEIGHT_MIN = -10   -- Para de procurar aqui

-- Tabela para rastrear jogadores em processo de spawn
local spawning_players = {}

-- Função para encontrar posição segura de spawn
local function find_safe_spawn(pos_x, pos_z, callback)
    -- Força geração do terreno em uma área maior
    minetest.emerge_area(
        {x = pos_x - 32, y = -16, z = pos_z - 32},
        {x = pos_x + 32, y = 80, z = pos_z + 32},
        function(blockpos, action, calls_remaining)
            if calls_remaining == 0 then
                -- Agora procura por um bloco sólido de cima para baixo
                local spawn_y = SEARCH_HEIGHT_START
                
                for y = SEARCH_HEIGHT_START, SEARCH_HEIGHT_MIN, -1 do
                    local check_pos = {x = pos_x, y = y, z = pos_z}
                    local node = minetest.get_node(check_pos)
                    local node_above = minetest.get_node({x = pos_x, y = y + 1, z = pos_z})
                    local node_above2 = minetest.get_node({x = pos_x, y = y + 2, z = pos_z})
                    
                    local def = minetest.registered_nodes[node.name]
                    local def_above = minetest.registered_nodes[node_above.name]
                    local def_above2 = minetest.registered_nodes[node_above2.name]
                    
                    -- Verifica se:
                    -- 1. O bloco atual é sólido e andável
                    -- 2. Os dois blocos acima são ar (espaço para o jogador)
                    -- 3. Não é água
                    if def and def.walkable and node.name ~= "nodes:water" and
                       def_above and not def_above.walkable and 
                       def_above2 and not def_above2.walkable then
                        spawn_y = y + 1
                        break
                    end
                end
                
                -- Retorna a posição segura
                callback({x = pos_x, y = spawn_y, z = pos_z})
            end
        end
    )
end

-- Spawn para novos jogadores
minetest.register_on_newplayer(function(player)
    local player_name = player:get_player_name()
    spawning_players[player_name] = true
    
    -- Coloca o jogador MUITO alto inicialmente (no céu)
    player:set_pos({x = SPAWN_X, y = 150, z = SPAWN_Z})
    
    -- Desativa física temporariamente
    player:set_physics_override({
        gravity = 0,
        speed = 0,
        jump = 0
    })
    
    -- Torna o jogador invisível e invulnerável durante o spawn
    player:set_properties({
        visual_size = {x = 0, y = 0},
        makes_footstep_sound = false,
    })
    player:set_armor_groups({immortal = 1})
    
    -- Procura posição segura
    find_safe_spawn(SPAWN_X, SPAWN_Z, function(safe_pos)
        if not player or not player:is_player() then return end
        
        -- Teleporta para a posição segura
        player:set_pos(safe_pos)
        
        -- Aguarda 0.5s antes de restaurar física (garante que o chunk está carregado)
        minetest.after(0.5, function()
            if not player or not player:is_player() then return end
            
            -- Restaura física normal
            player:set_physics_override({
                gravity = 1,
                speed = 1,
                jump = 1
            })
            
            -- Restaura visibilidade
            player:set_properties({
                visual_size = {x = 1, y = 1},
                makes_footstep_sound = true,
            })
            player:set_armor_groups({})
            
            -- Zera velocidade
            player:set_velocity({x = 0, y = 0, z = 0})
            
            spawning_players[player_name] = nil
        end)
    end)
end)

-- Respawn quando morre
minetest.register_on_respawnplayer(function(player)
    local player_name = player:get_player_name()
    spawning_players[player_name] = true
    
    -- Coloca no céu novamente
    player:set_pos({x = SPAWN_X, y = 150, z = SPAWN_Z})
    
    -- Desativa física
    player:set_physics_override({
        gravity = 0,
        speed = 0,
        jump = 0
    })
    
    player:set_properties({
        visual_size = {x = 0, y = 0},
    })
    player:set_armor_groups({immortal = 1})
    
    -- Procura posição segura
    find_safe_spawn(SPAWN_X, SPAWN_Z, function(safe_pos)
        if not player or not player:is_player() then return end
        
        player:set_pos(safe_pos)
        
        minetest.after(0.5, function()
            if not player or not player:is_player() then return end
            
            player:set_physics_override({
                gravity = 1,
                speed = 1,
                jump = 1
            })
            
            player:set_properties({
                visual_size = {x = 1, y = 1},
            })
            player:set_armor_groups({})
            
            player:set_velocity({x = 0, y = 0, z = 0})
            
            spawning_players[player_name] = nil
        end)
    end)
    
    return true  -- Impede o spawn padrão do engine
end)

-- Proteção extra: verifica se o jogador está preso em blocos
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        
        -- Ignora jogadores em processo de spawn
        if not spawning_players[player_name] then
            local pos = player:get_pos()
            local node_feet = minetest.get_node({x = pos.x, y = pos.y, z = pos.z})
            local node_head = minetest.get_node({x = pos.x, y = pos.y + 1, z = pos.z})
            
            local def_feet = minetest.registered_nodes[node_feet.name]
            local def_head = minetest.registered_nodes[node_head.name]
            
            -- Se o jogador está dentro de blocos sólidos (sufocando)
            if (def_feet and def_feet.walkable and node_feet.name ~= "nodes:water") or
               (def_head and def_head.walkable and node_head.name ~= "nodes:water") then
                
                -- Teleporta para cima até achar espaço livre
                for y_offset = 1, 10 do
                    local new_pos = {x = pos.x, y = pos.y + y_offset, z = pos.z}
                    local check_feet = minetest.get_node(new_pos)
                    local check_head = minetest.get_node({x = new_pos.x, y = new_pos.y + 1, z = new_pos.z})
                    
                    local check_def_feet = minetest.registered_nodes[check_feet.name]
                    local check_def_head = minetest.registered_nodes[check_head.name]
                    
                    if (not check_def_feet or not check_def_feet.walkable) and
                       (not check_def_head or not check_def_head.walkable) then
                        player:set_pos(new_pos)
                        break
                    end
                end
            end
        end
    end
end)

print("[spawn] Sistema de spawn seguro carregado")
