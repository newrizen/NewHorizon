print("[body] Mod carregado")

------------------------------------------------------------
-- TABELAS GLOBAIS
------------------------------------------------------------
local shadow_objects = {}
-- Alternativa: verificar mudança de item periodicamente
local last_wielded = {}
local last_wield_index = {}
-- ARMAZENAMENTO DE ESTADO DO JOGADOR
local player_states = {}
-- Atualizar itens na mão
local wielded_entities = {}
local offhand_entities = {}
-- TABELA PARA ARMAZENAR ENTIDADES DE ARMADURA
local armor_entities = {}
-- TABELA PARA ARMAZENAR ENTIDADES DA CINTURA
local belt_entities = {}


------------------------------------------------------------
-- REGISTRA A ENTIDADE DO ITEM NA CINTURA
------------------------------------------------------------
minetest.register_entity("body:belt_item", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.15, y = 0.15, z = 0.15},  -- Menor que os itens nas mãos
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },
    
    on_step = function(self, dtime)
        if not self.player_name then
            self.object:remove()
            return
        end
        
        local player = minetest.get_player_by_name(self.player_name)
        if not player then
            self.object:remove()
            return
        end
    end,
})

------------------------------------------------------------
-- FUNÇÃO PARA ATUALIZAR ITENS NA CINTURA
------------------------------------------------------------
local function update_belt_items(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    local inv = player:get_inventory()
    
    -- Remove todas as entidades antigas da cintura
    if belt_entities[player_name] then
        for slot_num, entity in pairs(belt_entities[player_name]) do
            if entity and entity:get_luaentity() then
                entity:remove()
            end
        end
        belt_entities[player_name] = nil
    end
    
    -- Inicializa tabela para este jogador
    belt_entities[player_name] = {}
    
    -- Mapeamento: slot da hotbar -> bone da cintura
    local belt_slots = {
        [3] = {bone = "bone1", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
        [4] = {bone = "bone2", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
        [5] = {bone = "bone3", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
        [6] = {bone = "bone4", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
        [7] = {bone = "bone5", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
        [8] = {bone = "bone6", pos = {x = 0.1, y = 0.2, z = 0}, rot = {x = 0, y = -90, z = 0}},
    }
    
    -- Cria entidades para cada slot
    for slot_num, config in pairs(belt_slots) do
        local stack = inv:get_stack("main", slot_num)
        
        if not stack:is_empty() then
            local item_name = stack:get_name()
            
            -- Não mostra itens vazios ou mão
            if item_name ~= "" and item_name ~= ":" then
                local pos = player:get_pos()
                local entity = minetest.add_entity(pos, "body:belt_item")
                
                if entity then
                    local luaentity = entity:get_luaentity()
                    luaentity.player_name = player_name
                    luaentity.slot_num = slot_num
                    
                    -- Anexa ao bone correto
                    entity:set_attach(
                        player,
                        config.bone,
                        config.pos,
                        config.rot,
                        true
                    )
                    
                    -- Configura visual
                    entity:set_properties({
                        wield_item = item_name,
                        visual = "wielditem",
                        visual_size = {x = 0.035, y = 0.035, z = 0.035}  -- Tamanho pequeno
                    })
                    
                    belt_entities[player_name][slot_num] = entity
                end
            end
        end
    end
end

------------------------------------------------------------
-- CAPACIDADES DA MÃO INVISÍVEL (mantida para quebrar blocos)
------------------------------------------------------------
local hand_capabilities = {
    full_punch_interval = 0.9,
    max_drop_level = 0,
    groupcaps = {
        crumbly = {times = {[2] = 2.00, [3] = 0.70}, uses = 0, maxlevel = 1},
        cracky = {times = {[3] = 4.00, [6] = 8.00}, uses = 0, maxlevel = 1}, 
        snappy = {times = {[3] = 0.40}, uses = 0, maxlevel = 1},
        choppy = {times = {[3] = 2.5}, uses = 0, maxlevel = 1},
        oddly_breakable_by_hand = {times = {[1] = 3.50, [2] = 2.00, [3] = 0.70}, uses = 0}
    },
    damage_groups = {fleshy = 1},
}

------------------------------------------------------------
-- REGISTRA O ITEM DA MÃO (SEM IMAGEM VISÍVEL)
------------------------------------------------------------
minetest.register_item(":", {
    type = "none",
    wield_image = "",
    wield_scale = {x = 0, y = 0, z = 0},
    range = 4,
    inventory_image = "",
    tool_capabilities = hand_capabilities,
    visual_scale = 0,
    pointable = false,
})

------------------------------------------------------------
-- FUNÇÃO PARA ATUALIZAR ITEM NA MÃO (com entidade)
------------------------------------------------------------

local function update_wielded_item(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    local item = player:get_wielded_item()
    local item_name = item:get_name()
    
    -- Remove entidade anterior se existir
    if wielded_entities[player_name] then
        wielded_entities[player_name]:remove()
        wielded_entities[player_name] = nil
    end
    
    -- Se não há item ou é mão vazia, não faz nada
    if item_name == "" or item_name == ":" then
        return
    end
    
    -- Cria entidade do item
    local pos = player:get_pos()
    local entity = minetest.add_entity(pos, "body:wielded_item")
    
    if entity then
        local luaentity = entity:get_luaentity()
        luaentity.player_name = player_name
        luaentity.item_name = item_name
        
        -- Anexa à mão direita
        entity:set_attach(
            player,
            "bone_RHand",                    -- Nome do osso
            {x = 1.5, y = 0, z = 0},          -- Posição offset (AJUSTE AQUI)
            {x = 0, y = 0, z = -90},          -- Rotação (AJUSTE AQUI)
            true
        )
        
        -- Configura visual do item
        entity:set_properties({
            wield_item = item_name,
            visual = "wielditem",
            visual_size = {x = 0.15, y = 0.15, z = 0.15}
        })
        
        wielded_entities[player_name] = entity
    end
end

local function update_offhand_item(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    local inv = player:get_inventory()
    local wield_index = player:get_wield_index()
    
    -- Remove entidade anterior se existir
    if offhand_entities[player_name] then
        offhand_entities[player_name]:remove()
        offhand_entities[player_name] = nil
    end
    
    -- Determina qual slot usar (o que NÃO está selecionado)
    local offhand_index
    if wield_index == 1 then
        offhand_index = 2
    elseif wield_index == 2 then
        offhand_index = 1
    else
        -- Se não é slot 1 ou 2, não mostra nada na mão esquerda
        return
    end
    
    -- Pega o item do slot alternativo
    local offhand_item = inv:get_stack("main", offhand_index)
    local offhand_name = offhand_item:get_name()
    
    -- Se não há item, não faz nada
    if offhand_name == "" or offhand_name == ":" then
        return
    end
    
    -- Cria entidade do item
    local pos = player:get_pos()
    local entity = minetest.add_entity(pos, "body:offhand_item")
    
    if entity then
        local luaentity = entity:get_luaentity()
        luaentity.player_name = player_name
        luaentity.item_name = offhand_name
        luaentity.slot_index = offhand_index
        
        -- Anexa à mão esquerda
        entity:set_attach(
            player,
            "bone_LHand",                    -- Mão esquerda
            {x = 1.5, y = 0, z = 0},          -- Ajuste conforme necessário
            {x = 0, y = 0, z = -90},          -- Ajuste conforme necessário
            true
        )
        
        entity:set_properties({
            wield_item = offhand_name,
            visual = "wielditem",
            visual_size = {x = 0.15, y = 0.15, z = 0.15}
        })
        
        offhand_entities[player_name] = entity
    end
end

------------------------------------------------------------
-- REGISTRA A ENTIDADE DO ITEM SEGURADO
------------------------------------------------------------
minetest.register_entity("body:wielded_item", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.25, y = 0.25, z = 0.25},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },
    
    on_step = function(self, dtime)
        -- Verifica se o player ainda existe
        if not self.player_name then
            self.object:remove()
            return
        end
        
        local player = minetest.get_player_by_name(self.player_name)
        if not player then
            self.object:remove()
            wielded_entities[self.player_name] = nil
            return
        end
        
        -- Verifica se mudou o item
        local current_item = player:get_wielded_item():get_name()
        if current_item ~= self.item_name then
            update_wielded_item(player)
            update_offhand_item(player)  -- Atualiza mão esquerda também
        end
    end,
})

minetest.register_entity("body:offhand_item", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.25, y = 0.25, z = 0.25},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },
    
    on_step = function(self, dtime)
        if not self.player_name then
            self.object:remove()
            return
        end
        
        local player = minetest.get_player_by_name(self.player_name)
        if not player then
            self.object:remove()
            offhand_entities[self.player_name] = nil
            return
        end
        
        local inv = player:get_inventory()
        local current_item = inv:get_stack("main", self.slot_index):get_name()
        local wield_index = player:get_wield_index()
        
        -- Se mudou o item no slot OU mudou a seleção
        if current_item ~= self.item_name or 
           (wield_index ~= 1 and wield_index ~= 2) or
           wield_index == self.slot_index then
            update_offhand_item(player)
        end
    end,
})

------------------------------------------------------------
-- REGISTRA A ENTIDADE DE PEÇA DE ARMADURA
------------------------------------------------------------
minetest.register_entity("body:armor_piece", {
    initial_properties = {
        visual = "wielditem",
        visual_size = {x = 0.3, y = 0.3, z = 0.3},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },
    
    on_step = function(self, dtime)
        if not self.player_name then
            self.object:remove()
            return
        end
        
        local player = minetest.get_player_by_name(self.player_name)
        if not player then
            self.object:remove()
            return
        end
    end,
})


------------------------------------------------------------
-- ENTIDADE DE SOMBRA
------------------------------------------------------------
minetest.register_entity("body:shadow_entity", {
    initial_properties = {
        visual = "wielditem",
        wield_item = "body:shadow_node",
        visual_size = {x = 10, y = 0.35, z = 10},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
        glow = 0,
        shaded = true,
        makes_footstep_sound = false,
        collisionbox = {0, 0, 0, 0, 0, 0},
    },
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
        self.object:set_rotation({x = math.pi/2, y = 0, z = 0})
    end,
    
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        return false
    end,
    
    on_step = function(self, dtime)
        if not self.player_name then
            self.object:remove()
            return
        end
        
        local player = minetest.get_player_by_name(self.player_name)
        if not player then
            self.object:remove()
            return
        end
        
        local pos = player:get_pos()
        
        for i = 0, 3 do
            local check_pos = {x = pos.x, y = pos.y - i, z = pos.z}
            local node = minetest.get_node(check_pos)
            
            if node.name ~= "air" then
                self.object:set_pos({x = pos.x, y = check_pos.y + 0.52, z = pos.z})
                break
            end
        end
    end,
})

------------------------------------------------------------
-- REGISTRA O NÓ DA SOMBRA (TEXTURA)
------------------------------------------------------------
minetest.register_node("body:shadow_node", {
    description = "Shadow",
    drawtype = "nodebox",
    tiles = {"shadow.png"},
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    walkable = false,
    node_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.49, 0.5}
    },
    groups = {not_in_creative_inventory = 1},
})


------------------------------------------------------------
-- INVENTÁRIO DE VESTUÁRIO
------------------------------------------------------------

-- Define os slots de vestuário
local armor_slots = {
    head = "Cabeça",
    torso = "Tronco",
    arms = "Braços",
    legs = "Pernas",
    back = "Costas",
    waist = "Cintura",
    hands = "Mãos",
    feet = "Pés"
}

------------------------------------------------------------
-- CRIA O INVENTÁRIO DE VESTUÁRIO PARA O JOGADOR
------------------------------------------------------------
local function create_armor_inventory(player)
    if not player then return end
    
    local inv = player:get_inventory()
    
    -- Cria as listas de vestuário (1 slot cada)
    for slot, _ in pairs(armor_slots) do
        inv:set_size("armor_" .. slot, 1)
    end
end

------------------------------------------------------------
-- FORMSPEC DO INVENTÁRIO (VISUAL)
------------------------------------------------------------
local function get_armor_formspec(player_name)
    local formspec = "size[9,9.5]" ..
        "bgcolor[#00000000;true]" ..
        "background[0,0;9,9.5;gui_formbg.png]" ..
        
        -- === COLUNA ESQUERDA ===
        -- Cabeça
        "label[0.5,0.5;Cabeça]" ..
        "list[current_player;armor_head;0.5,0.5;1,1;]" ..
        
        -- Tronco
        "label[0.5,1.6;Tronco]" ..
        "list[current_player;armor_torso;0.5,1.6;1,1;]" ..
        
        -- Cintura
        "label[0.5,2.7;Pernas]" ..
        "list[current_player;armor_legs;0.5,2.7;1,1;]" ..
        
        -- Pernas
        "label[0.5,3.8;Pés]" ..
        "list[current_player;armor_feet;0.5,3.8;1,1;]" ..
        
                
        -- Modelo do player no centro
        "model[1.25,0.5;3,6;player_model;" .. 
        "character2.glb;skin.png;0,180;false;true]" ..
        
        -- Nome do jogador
        "label[1.75,4.8;" .. minetest.formspec_escape(player_name) .. "]" ..
        
        -- === COLUNA DIREITA ===
        -- Costas
        "label[3.5,0.5;Costas]" ..
        "list[current_player;armor_back;3.5,0.5;1,1;]" ..
        
        -- Braços
        "label[3.5,1.6;Braços]" ..
        "list[current_player;armor_arms;3.5,1.6;1,1;]" ..
        
        -- Mãos
        "label[3.5,2.7;Mãos]" ..
        "list[current_player;armor_hands;3.5,2.7;1,1;]" ..
        
        -- Pés
        "label[3.5,3.8;Cintura]" ..
        "list[current_player;armor_waist;3.5,3.8;1,1;]" ..
        
        -- Inventário principal
        "list[current_player;main;0.5,5.8;8,1;]" ..
        "list[current_player;main;0.5,7;8,2;8]" ..
        
        -- Estilos padrão
        "listring[current_player;main]" ..
        "listring[current_player;armor_head]" ..
        "listring[current_player;armor_torso]" ..
        "listring[current_player;armor_waist]" ..
        "listring[current_player;armor_legs]" ..
        "listring[current_player;armor_back]" ..
        "listring[current_player;armor_arms]" ..
        "listring[current_player;armor_hands]" ..
        "listring[current_player;armor_feet]"
    
    return formspec
end

------------------------------------------------------------
-- VALIDAÇÃO: APENAS ITENS CORRETOS EM CADA SLOT
------------------------------------------------------------
minetest.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    if action == "move" then
        local from_list = inventory_info.from_list
        local to_list = inventory_info.to_list
        
        -- Se está movendo PARA um slot de armadura
        if to_list:match("^armor_") then
            local slot_type = to_list:gsub("armor_", "")
            local stack = inventory:get_stack(from_list, inventory_info.from_index)
            local item_name = stack:get_name()
            local item_def = minetest.registered_items[item_name]
            
            -- Verifica se o item tem o grupo correto
            if not item_def or not item_def.groups or 
               not item_def.groups["armor_" .. slot_type] then
                return 0  -- Não permite
            end
            
            return stack:get_count()  -- RETORNA AQUI PARA PERMITIR
        end
        
    elseif action == "put" then
        local listname = inventory_info.listname
        
        -- Se está colocando em um slot de armadura
        if listname:match("^armor_") then
            local slot_type = listname:gsub("armor_", "")
            local stack = inventory_info.stack
            local item_name = stack:get_name()
            local item_def = minetest.registered_items[item_name]
            
            -- Verifica se o item tem o grupo correto
            if not item_def or not item_def.groups or 
               not item_def.groups["armor_" .. slot_type] then
                return 0  -- Não permite
            end
            
            return stack:get_count()  -- RETORNA AQUI PARA PERMITIR
        end
    end
    
    -- Para todas as outras ações, permite normalmente
    -- Usa inventory_info.count se disponível, senão retorna stack count se existir
    if inventory_info.count then
        return inventory_info.count
    elseif inventory_info.stack then
        return inventory_info.stack:get_count()
    else
        return 1  -- Permite 1 item como fallback
    end
end)

------------------------------------------------------------
-- FUNÇÃO PARA ATUALIZAR VISUAL DAS ARMADURAS
------------------------------------------------------------
local function update_armor_visuals(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    local inv = player:get_inventory()
    
    -- Remove todas as entidades de armadura antigas
    if armor_entities[player_name] then
        for slot, entity in pairs(armor_entities[player_name]) do
            if entity and entity:get_luaentity() then
                entity:remove()
            end
        end
        armor_entities[player_name] = nil
    end
    
    -- Inicializa tabela para este jogador
    armor_entities[player_name] = {}
    
    -- Mapeamento de slots para ossos e configurações
    local armor_bones = {
        head = {
            bone = "bone_All_Head",
            pos = {x = 0, y = 4.75, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.3, y = 0.3, z = 0.3}
        },
        torso = {
            bone = "bone_TorsoArms",
            pos = {x = 0, y = 0, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.35, y = 0.35, z = 0.35}
        },
        waist = {
            bone = "bone_TorsoArms",
            pos = {x = 0.5, y = 2.5, z = 0},
            rot = {x = 0, y = -90, z = 0},
            size = {x = 0.3, y = 0.3, z = 0.3}
        },
        legs = {
            bone = "bone_Legs",
            pos = {x = 0, y = 0, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.3, y = 0.3, z = 0.3}
        },
        back = {
            bone = "bone_TorsoArms",
            pos = {x = -2.5, y = 2.5, z = 0},
            rot = {x = 0, y = -90, z = 0},
            size = {x = 0.3, y = 0.3, z = 0.3}
        },
        arms = {
            bone = "bone_TorsoArms",
            pos = {x = 0, y = -2, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.25, y = 0.25, z = 0.25}
        },
        hands = {
            bone = "bone_RHand",
            pos = {x = 0, y = 0, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.2, y = 0.2, z = 0.2}
        },
        feet = {
            bone = "bone_Legs",
            pos = {x = 0, y = -4, z = 0},
            rot = {x = 0, y = 0, z = 0},
            size = {x = 0.25, y = 0.25, z = 0.25}
        }
    }
    
    -- Cria entidades para cada peça de armadura equipada
    for slot, config in pairs(armor_bones) do
        local stack = inv:get_stack("armor_" .. slot, 1)
        
        if not stack:is_empty() then
            local item_name = stack:get_name()
            local item_def = minetest.registered_items[item_name]
            
            -- Verifica se o item tem um modelo 3D definido
            local visual_item = item_name
            if item_def and item_def.armor_model then
                visual_item = item_def.armor_model
            end
            
            local pos = player:get_pos()
            local entity = minetest.add_entity(pos, "body:armor_piece")
            
            if entity then
                local luaentity = entity:get_luaentity()
                luaentity.player_name = player_name
                luaentity.slot = slot
                
                -- Anexa ao osso correto
                entity:set_attach(
                    player,
                    config.bone,
                    config.pos,
                    config.rot,
                    true
                )
                
                -- Configura visual
                entity:set_properties({
                    wield_item = visual_item,
                    visual = "wielditem",
                    visual_size = config.size
                })
                
                armor_entities[player_name][slot] = entity
            end
        end
    end
end


------------------------------------------------------------
-- FUNÇÃO PARA APLICAR TEXTURAS DE VESTUÁRIO NO PLAYER
------------------------------------------------------------
local function update_armor_textures(player)
    if not player then return end
    
    local inv = player:get_inventory()
    local textures = {"skin.png"}  -- Textura base
    
    -- Verifica cada slot e adiciona a textura correspondente
    for slot, _ in pairs(armor_slots) do
        local stack = inv:get_stack("armor_" .. slot, 1)
        if not stack:is_empty() then
            local item_name = stack:get_name()
            local item_def = minetest.registered_items[item_name]
            
            -- Se o item tem uma textura de armadura definida
            if item_def and item_def.armor_texture then
                table.insert(textures, item_def.armor_texture)
            end
        end
    end
    
    -- Aplica as texturas no player
    player:set_properties({
        textures = textures
    })

    update_armor_visuals(player)
end

-- Atualiza quando o inventário muda
minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if action == "move" or action == "put" or action == "take" then
        local listname = inventory_info.listname or inventory_info.to_list or inventory_info.from_list
        
        if listname and listname:match("^armor_") then
            update_armor_textures(player)
        end
    end
end)


------------------------------------------------------------
-- FUNÇÃO PARA APLICAR O MODELO/SKIN CUSTOMIZADO NO PLAYER
------------------------------------------------------------
local function apply_custom_model(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    
    -- Inicializa estado do jogador
    if not player_states[player_name] then
        player_states[player_name] = {
            body_yaw = 0,
            current_anim = nil
        }
    end
    
    -- Aplica seu modelo e skin diretamente no player
    player:set_properties({
        visual = "mesh",
        mesh = "character2.glb",
        textures = {"skin.png"},
        visual_size = {x = 1, y = 1, z = 1},
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 2.7, 0.3},
        stepheight = 0.6,
        eye_height = 2.5,
        --makes_footstep_sound = true,
    })
    
    -- Configura offset da câmera
    player:set_eye_offset(
        {x = 0, y = 0, z = 0},    -- Primeira pessoa
        {x = 0, y = 7, z = -7}    -- Terceira pessoa
    )
    
    print("[body] Modelo customizado aplicado para " .. player_name)
end

------------------------------------------------------------
-- FUNÇÃO PARA ROTACIONAR CABEÇA E CORPO DO PLAYER
------------------------------------------------------------
local function rotate_head_to_look(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    local state = player_states[player_name]
    if not state then return end
    
    local look_pitch = player:get_look_vertical()
    local look_yaw = player:get_look_horizontal()
    local ctrl = player:get_player_control()
    
    local is_moving_keys = ctrl.up or ctrl.down or ctrl.left or ctrl.right
    
    if is_moving_keys then
        state.body_yaw = look_yaw
    end
    
    local yaw_diff = look_yaw - state.body_yaw
    
    while yaw_diff > math.pi do
        yaw_diff = yaw_diff - 2 * math.pi
    end
    while yaw_diff < -math.pi do
        yaw_diff = yaw_diff + 2 * math.pi
    end
    
    local head_pitch = math.deg(-look_pitch)
    local head_yaw_raw = math.deg(-yaw_diff)
    
    local head_limit = 60
    
    local head_yaw
    if is_moving_keys then
        head_yaw = 0
    else
        head_yaw = math.max(-head_limit, math.min(head_limit, head_yaw_raw))
    end
    
    head_pitch = math.max(-60, math.min(60, head_pitch))
    
    -- Rotaciona a cabeça do player
    player:set_bone_position(
        "bone_All_Head",
        {x = 0.5, y = 5, z = 0},
        {x = 0, y = head_yaw * 0.5, z = head_pitch}
    )
    
    -- Rotaciona o torso e braços
    player:set_bone_position(
        "bone_TorsoArms",
        {x = 0, y = 0, z = 0},
        {x = 0, y = 0, z = 0}
    )
    
    -- Rotaciona as pernas
    player:set_bone_position(
        "bone_Legs",
        {x = 0, y = 0, z = 0},
        {x = 0, y = 0, z = 0}
    )
end

------------------------------------------------------------
-- FUNÇÃO PARA DEFINIR ANIMAÇÃO DO PLAYER
------------------------------------------------------------
local function set_player_animation(player, anim)
    if not player then return end
    
    local player_name = player:get_player_name()
    local state = player_states[player_name]
    if not state then return end
    
    if state.current_anim == anim then return end
    state.current_anim = anim
    
    if anim == "idle" then
        player:set_animation({x = 0, y = 1}, 0.25, 0, true)
    elseif anim == "jump" then
        player:set_animation({x = 2.08, y = 2.63}, 4, 0, false)
    elseif anim == "climb" then
        player:set_animation({x = 2.08, y = 2.63}, 1, 0, true)
    elseif anim == "walk" then
        player:set_animation({x = 1, y = 2}, 2, 0, true)
    elseif anim == "walk_back" then
        player:set_animation({x = 2, y = 1}, 2, 0, true)
    elseif anim == "run" then
        player:set_animation({x = 1, y = 2}, 6, 0, true)
    elseif anim == "run_back" then
        player:set_animation({x = 2, y = 1}, 6, 0, true)
    elseif anim == "sneak" then
        player:set_animation({x = 2.63, y = 2.88}, 2, 0, false)
    elseif anim == "sneak_walk" then
        player:set_animation({x = 2.91, y = 4.91}, 0.8, 0, true)
    elseif anim == "sneak_walk_back" then
        player:set_animation({x = 4.91, y = 2.91}, 0.8, 0, true)
    elseif anim == "crawling" then
        player:set_animation({x = 5.25, y = 5.5}, 0.8, 5.5, false)
    elseif anim == "crawling_walk" then
        player:set_animation({x = 5.58, y = 6.08}, 0.8, 0, true)
    elseif anim == "swimming" then
        player:set_animation({x = 9, y = 9.5}, 0.8, 0, true)
    end
end

------------------------------------------------------------
-- FUNÇÃO PARA CRIAR A SOMBRA
------------------------------------------------------------
local function create_shadow(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    
    if shadow_objects[player_name] then
        shadow_objects[player_name]:remove()
        shadow_objects[player_name] = nil
    end
    
    local shadow = minetest.add_entity(player:get_pos(), "body:shadow_entity")
    if shadow then
        shadow:get_luaentity().player_name = player_name
        shadow_objects[player_name] = shadow
        print("[body] Sombra criada para " .. player_name)
    else
        print("[body] ERRO: Não foi possível criar sombra para " .. player_name)
    end
end


------------------------------------------------------------
-- ATUALIZA QUANDO O JOGADOR MUDA O ITEM SELECIONADO
------------------------------------------------------------
minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
    if puncher and puncher:is_player() then
        update_wielded_item(puncher)
    end
end)

local last_belt_items = {}
local last_armor_items = {}

------------------------------------------------------------
-- GLOBALSTEP PARA ATUALIZAR ANIMAÇÕES E ROTAÇÕES
------------------------------------------------------------
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local item = player:get_wielded_item()
        local item_name = item:get_name()
        
        -- Verifica se mudou o item
        if last_wielded[player_name] ~= item_name then
            last_wielded[player_name] = item_name
            update_wielded_item(player)
            update_offhand_item(player)  -- Atualiza mão esquerda
        end
        
        -- Verifica se mudou algum item da cintura (slots 3-8)
        local inv = player:get_inventory()
        local current_belt = {}
        for i = 3, 8 do
            local stack = inv:get_stack("main", i)
            current_belt[i] = stack:get_name()
        end
        
        -- Compara com o estado anterior
        local belt_changed = false
        if not last_belt_items[player_name] then
            belt_changed = true
            last_belt_items[player_name] = {}
        else
            for i = 3, 8 do
                if last_belt_items[player_name][i] ~= current_belt[i] then
                    belt_changed = true
                    break
                end
            end
        end
        
        if belt_changed then
            last_belt_items[player_name] = current_belt
            update_belt_items(player)
        end
        
        -- Verifica mudanças nos slots de armadura
        local current_armor = {}
        for slot, _ in pairs(armor_slots) do
            local stack = inv:get_stack("armor_" .. slot, 1)
            current_armor[slot] = stack:get_name()
        end
        
        -- Compara com o estado anterior
        local armor_changed = false
        if not last_armor_items[player_name] then
            armor_changed = true
            last_armor_items[player_name] = {}
        else
            for slot, _ in pairs(armor_slots) do
                if last_armor_items[player_name][slot] ~= current_armor[slot] then
                    armor_changed = true
                    break
                end
            end
        end
        
        if armor_changed then
            last_armor_items[player_name] = current_armor
            update_armor_visuals(player)
        end
        
        
        if player_states[player_name] then
            -- Atualiza rotação da cabeça
            rotate_head_to_look(player)
            
            -- Atualiza animação
            local ctrl = player:get_player_control()
            local vel = player:get_velocity()
            
            if ctrl.jump and vel.y >= 0 then
                set_player_animation(player, "jump")
            else
                local props = player:get_properties()
                local is_crawling = props.eye_height <= 0.7

                if is_crawling then
                    local horizontal = {x = vel.x, y = 0, z = vel.z}
                    local speed = vector.length(horizontal)

                    if speed > 0.1 then
                        set_player_animation(player, "crawling_walk")
                    else
                        set_player_animation(player, "crawling")
                    end
                elseif ctrl.sneak and vel.x < 0.1 and vel.z < 0.1 then
                    set_player_animation(player, "sneak")
                else
                    local is_moving_back = ctrl.down
                    local is_moving = ctrl.up or ctrl.left or ctrl.right
                    local horizontal = {x = vel.x, y = 0, z = vel.z}
                    local speed = vector.length(horizontal)
                 
                    if is_moving_back then
                        if ctrl.sneak and speed >= 0.1 then
                            set_player_animation(player, "sneak_walk_back")
                        elseif ctrl.aux1 or speed >= 4 then
                            set_player_animation(player, "run_back")
                        elseif speed < 4 and speed > 0 then
                            set_player_animation(player, "walk_back")
                        end
                    elseif is_moving then
                        if ctrl.sneak and speed >= 0.1 then
                            set_player_animation(player, "sneak_walk")
                        elseif ctrl.aux1 or speed >= 4 then
                            set_player_animation(player, "run")
                        elseif speed < 4 and speed > 0 then
                            set_player_animation(player, "walk")
                        end
                    else
                        set_player_animation(player, "idle")
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- EVENTOS DE JOGADOR
------------------------------------------------------------

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    
    -- Cria inventário de vestuário
    create_armor_inventory(player)
    
    -- Define o formspec do inventário
    player:set_inventory_formspec(get_armor_formspec(player_name))
 
    local check_count = 0
    local max_checks = 10
    
    local function verify_and_apply()
        if not player or not player:is_player() then return end
        
        check_count = check_count + 1
        apply_custom_model(player)
        
        -- Verifica se foi aplicado corretamente
        local props = player:get_properties()
        if props.eye_height ~= 2.5 and check_count < max_checks then
            minetest.after(0.2, verify_and_apply)
        end
    end
    
    minetest.after(0.3, function()
        if player and player:is_player() then
            verify_and_apply()
            create_shadow(player)
            update_wielded_item(player)
            update_offhand_item(player)
            update_armor_visuals(player)  -- Armaduras e etc
            update_belt_items(player)  -- Itens no cinto
        end
    end)
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    
    -- Remove estado do jogador
    player_states[player_name] = nil
    last_wielded[player_name] = nil
    last_wield_index[player_name] = nil
    last_belt_items[player_name] = nil  -- cinto
    last_armor_items[player_name] = nil  -- 
    
    -- Remove entidade do item
    if wielded_entities[player_name] then
        wielded_entities[player_name]:remove()
        wielded_entities[player_name] = nil
    end
    
    if offhand_entities[player_name] then
        offhand_entities[player_name]:remove()
        offhand_entities[player_name] = nil
    end
    
    -- Itens do cinto:
    if belt_entities[player_name] then
        for slot_num, entity in pairs(belt_entities[player_name]) do
            if entity and entity:get_luaentity() then
                entity:remove()
            end
        end
        belt_entities[player_name] = nil
    end
    
    -- Remove entidades de armadura
    if armor_entities[player_name] then
        for slot, entity in pairs(armor_entities[player_name]) do
            if entity and entity:get_luaentity() then
                entity:remove()
            end
        end
        armor_entities[player_name] = nil
    end
    
    -- Remove sombra
    if shadow_objects[player_name] then
        shadow_objects[player_name]:remove()
        shadow_objects[player_name] = nil
    end
end)



minetest.register_on_dieplayer(function(player)
    local player_name = player:get_player_name()
    
    if wielded_entities[player_name] then
        wielded_entities[player_name]:remove()
        wielded_entities[player_name] = nil
    end
    
    if offhand_entities[player_name] then
        offhand_entities[player_name]:remove()
        offhand_entities[player_name] = nil
    end

    -- Remove entidades de armadura
    if armor_entities[player_name] then
        for slot, entity in pairs(armor_entities[player_name]) do
            if entity and entity:get_luaentity() then
                entity:remove()
            end
        end
        armor_entities[player_name] = nil
    end

    if shadow_objects[player_name] then
        shadow_objects[player_name]:remove()
        shadow_objects[player_name] = nil
    end
end)



minetest.register_on_respawnplayer(function(player)
    minetest.after(0.5, function()
        if player and player:is_player() then
            apply_custom_model(player)
            create_shadow(player)
        end
    end)
end)
