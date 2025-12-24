-- Arquivo: player/init.lua
print("[player] Mod carregado")

local health_hud = {}
local hunger_data = {} -- Tabela para armazenar os dados de fome
local breath_hud = {}  -- Nova tabela para armazenar o HUD de respiração
local hotbar_state = {}


-- Função para atualizar o HUD de breath
local function update_breath_hud(player)
    local name = player:get_player_name()
    if breath_hud[name] then
        local breath = player:get_breath()
        player:hud_change(breath_hud[name], "number", breath * 2)  -- Multiplica por 2 para ficar visual
    end
end

-- Função para atualizar a barra de fome visual
local function update_hunger_hud(player, hunger_level)
    local name = player:get_player_name()
    if not hunger_data[name] then return end
    
    -- Calcula quantos ícones de comida mostrar (máximo 20)
    local hunger_icons = math.floor(hunger_level)
    
    -- Atualiza o HUD
    player:hud_change(hunger_data[name].hud_id, "number", hunger_icons)
end

-- Função para curar o player ao longo do tempo
local function heal_player(player, amount)
    local hp = player:get_hp()
    local new_hp = math.min(20, hp + amount)
    player:set_hp(new_hp)
end

-- Função para diminuir a fome ao longo do tempo
local function hunger_timer()
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        if hunger_data[name] then
            -- Diminui 1 ponto de fome a cada 30 segundos
            hunger_data[name].level = math.max(0, hunger_data[name].level - 1)
            update_hunger_hud(player, hunger_data[name].level)
            
            -- Se a fome chegar a 0, causa dano
            if hunger_data[name].level == 0 then
		player:set_hp(player:get_hp() - 1)
	    end

            
            -- Regenera vida se a fome estiver alta
            if hunger_data[name].level >= 18 and player:get_hp() < 20 then
                heal_player(player, 1)
            end
        end
    end
    
    -- Chama a função novamente após 30 segundos
    minetest.after(30, hunger_timer)
end

-- Inicia o timer de fome
minetest.after(30, hunger_timer)

minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    
    -- Remove o HUD de barras
    player:hud_set_flags({ 
        healthbar = false, -- Remove a barra de coração padrão
        breathbar = false  -- Remove a barra de breath padrão
    })
    
    -- Cria a nova barra
    health_hud[name] = player:hud_add({
        hud_elem_type = "statbar",
        position = {x = 0.5, y = 1},
        text = "blood.png",   -- Seu coração customizado
        number = 20,             -- Vida máxima = 20
        direction = 0,
        size = {x = 24, y = 24},
        offset = {x = -300, y = -88},  -- Para alinhar ao lado da barra de fome
    })
    
    -- INICIALIZA O ESTADO DA HOTBAR
    if not hotbar_state then
        hotbar_state = {}
    end
    hotbar_state[name] = {
        current_size = 2,  -- Começa com 2 slots
        needs_update = false
    }
    
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
    
    -- Adiciona a barra de fome
    minetest.after(0.3, function()
        -- Inicializa a fome do jogador (20 = máximo)
        hunger_data[name] = {
            level = 20,
            hud_id = nil
        }
        
        -- Cria o HUD da barra de fome
        hunger_data[name].hud_id = player:hud_add({
            hud_elem_type = "statbar",
            position = {x = 0.5, y = 1},
            text = "food.png",
            number = 20,
            direction = 0,
            size = {x = 24, y = 24},
            offset = {x = 50, y = -88},
        })
    end)
    
    -- Adiciona a barra de breath (respiração) ACIMA da fome
    minetest.after(0.4, function()
        breath_hud[name] = player:hud_add({
            hud_elem_type = "statbar",
            position = {x = 0.5, y = 1},
            text = "bubble.png",
            number = 22,
            direction = 0,
            size = {x = 24, y = 24},
            offset = {x = 50, y = -116},
        })
    end)
end)

-- Remove os dados quando o jogador sai
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    hunger_data[name] = nil
    health_hud[name] = nil
    breath_hud[name] = nil
    hotbar_state[name] = nil  -- Reiniciar hotbar
end)

-- Função auxiliar para restaurar fome (use ao comer itens)
function restore_hunger(player, amount)
    local name = player:get_player_name()
    if hunger_data[name] then
        hunger_data[name].level = math.min(20, hunger_data[name].level + amount)
        update_hunger_hud(player, hunger_data[name].level)
    end
end


-----------------------------
-- SISTEMA DE AUTO-PULO
-----------------------------
local auto_jump_cooldown = {}  -- Evita pulos repetidos muito rápidos


-- Atualizar informações

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local name = player_name  -- Adiciona esta linha para consistência
        
        
        if hotbar_state[name] then
            local inv = player:get_inventory()
            --local has_belt_items = false
            
            -- Verifica se há item no slot de armadura da cintura
            local waist_stack = inv:get_stack("armor_waist", 1)
            local has_belt = not waist_stack:is_empty()
            
            -- Determina o tamanho necessário da hotbar
            local needed_size = has_belt and 8 or 2
            
            -- Atualiza apenas se necessário
            if hotbar_state[name].current_size ~= needed_size then
                hotbar_state[name].current_size = needed_size
                
                if needed_size == 8 then
                    -- Expande para 8 slots (padrão Luanti)
                    player:hud_set_hotbar_itemcount(8)
                    player:hud_set_hotbar_image("gui_hotbar.png")  -- Imagem padrão do Luanti
                    player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
                else
                    -- Volta para 2 slots (customizado)
                    player:hud_set_hotbar_itemcount(2)
                    player:hud_set_hotbar_image("gui_hotbar2.png")
                    player:hud_set_hotbar_selected_image("gui_hotbar_selected.png")
                end
            end
        end
        
        
                -- Atualiza breath HUD (barra de respiração)
        if breath_hud[name] then
            local breath = player:get_breath()
            local head_pos = {
                x = player:get_pos().x,
                y = player:get_pos().y + player:get_properties().eye_height,
                z = player:get_pos().z
            }
            local head_node = minetest.get_node(head_pos).name
            
            -- Mostra/esconde a barra baseado se está submerso
            if minetest.get_item_group(head_node, "water") > 0 then
                player:hud_change(breath_hud[name], "number", breath * 2)
            else
                -- Esconde a barra quando não está na água
                player:hud_change(breath_hud[name], "number", 0)
            end
        end
        
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
                               node_name ~= "nodes:pebble" and
                               node_name ~= "nodes:apple" and
                               node_name ~= "nodes:blueberry" and
                               node_name ~= "nodes:coconut"
                    end
                    
                    -- Define quais blocos permitem passagem
                    local function is_passable(node_name)
                        return node_name == "air" or 
                               node_name == "nodes:water" or
                               node_name == "nodes:leaves" or 
                               node_name == "nodes:pebble" or
                               node_name == "nodes:apple" or
                               node_name == "nodes:blueberry" or
                               node_name == "nodes:coconut"
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
    -- Primeiro: calcula dano reduzido por queda
    if reason.type == "fall" then
        local pos = player:get_pos()
        pos.y = pos.y - 1
        local node = minetest.get_node(pos).name
        
        local absorption = surface_absorption[node] or 0.0
        local reduced_damage = hp_change * (1 - absorption)

        if hp_change < -5 and reduced_damage > -1 then
            reduced_damage = -1
        end

        reduced_damage = math.ceil(reduced_damage)
        hp_change = reduced_damage
    end

    -- Segundo: atualiza o HUD SEM alterar o valor do dano
    local name = player:get_player_name()
    if health_hud[name] then
        player:hud_change(health_hud[name], "number", player:get_hp() + hp_change)
    end

    -- Terceiro: retorna o dano final
    return hp_change
end, true)

minetest.register_on_respawnplayer(function(player)
    local name = player:get_player_name()

    -- Restaura a fome ao máximo
    if hunger_data[name] then
        hunger_data[name].level = 20
        update_hunger_hud(player, 20)
    end

    return true  -- mantém o respawn padrão
end)

minetest.register_on_dieplayer(function(player)
    local pos = player:get_pos()
    local inv = player:get_inventory()

    -- Obtém os tamanhos dos inventários
    local size_main = inv:get_size("main")
    local size_craft = inv:get_size("craft")

    -- Solta itens do inventário principal
    for i = 1, size_main do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            minetest.add_item(pos, stack)
            inv:set_stack("main", i, nil)
        end
    end

    -- Solta itens da area de craft / armor (se existir)
    for i = 1, size_craft do
        local stack = inv:get_stack("craft", i)
        if not stack:is_empty() then
            minetest.add_item(pos, stack)
            inv:set_stack("craft", i, nil)
        end
    end

    return true  -- mantém o comportamento padrão da morte
end)
