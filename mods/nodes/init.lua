-----------------------------
-- NODES
-----------------------------
print("[nodes] init.lua carregado")



minetest.register_node("nodes:grass", {
    description = "Gramado",
    tiles = {"grama.png"},
    groups = {crumbly = 3},
    
    -- Mecânica da grama morrer na sombra
    paramtype = "light",
    on_construct = function(pos)
        local node = minetest.get_node(pos)
        minetest.get_node_timer(pos):start(math.random(30, 60))
    end,

    on_timer = function(pos, elapsed)
        local light = minetest.get_node_light(pos)
        if light and light <= 1 then
            minetest.set_node(pos, {name = "nodes:dirt"})
        end
        return true
    end,
})


minetest.register_node("nodes:top_grass", {
    description = "Grama",
    -- 6 texturas → top, bottom, right, left, back, front
    tiles = {
        "grama.png",      -- topo (0)
        "terra.png",           -- embaixo (1)
        "grama_terra_lado.png",     -- lado direito (2)
        "grama_terra_lado.png",     -- lado esquerdo (3)
        "grama_terra_lado.png",     -- lado atrás (4)
        "grama_terra_lado.png"      -- lado frente (5)
    },
    groups = {crumbly = 3, soil = 1},
    -- Quando a grama é bloqueada da luz, vira terra
    --drop = "nodes:dirt",
    
    -- Mecânica da grama morrer na sombra
    paramtype = "light",
    on_construct = function(pos)
        local node = minetest.get_node(pos)
        minetest.get_node_timer(pos):start(math.random(3, 6))
    end,
    on_timer = function(pos, elapsed)
        local light = minetest.get_node_light(pos)
        
        -- Verifica se há ar diretamente acima
        local above = {x = pos.x, y = pos.y + 1, z = pos.z}
        local node_above = minetest.get_node(above).name
        
        -- Se tiver luz > 4 e ar acima, verifica vizinhos para virar grass
        if light and light > 4 and node_above == "air" then
            -- Verifica vizinhos laterais e diagonais ABAIXO (8 posições)
            local neighbors_below = {
                -- Laterais abaixo
                {x = pos.x + 1, y = pos.y - 1, z = pos.z},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z},
                {x = pos.x, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x, y = pos.y - 1, z = pos.z - 1},
                -- Diagonais abaixo
                {x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x + 1, y = pos.y - 1, z = pos.z - 1},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
            }
            
            -- Verifica se há grama em algum vizinho abaixo
            local has_grass_below = false
            for _, npos in ipairs(neighbors_below) do
                local neighbor_name = minetest.get_node(npos).name
                if neighbor_name == "nodes:grass" or neighbor_name == "nodes:top_grass" then
                    has_grass_below = true
                    break
                end
            end
            
            -- Se encontrar grama abaixo, converte para grass
            if has_grass_below then
                minetest.set_node(pos, {name = "nodes:grass"})
                return true
            end
        end
        
        -- Verifica se deve morrer por falta de luz
        if light and light <= 1 then
            minetest.set_node(pos, {name = "nodes:dirt"})
        end
        
        return true
    end,
})

minetest.register_node("nodes:dirt", {
    description = "Terra",
    tiles = {"terra.png"},
    groups = {crumbly = 2},
    
    -- Mecânica opcional: grama morrer na sombra
    paramtype = "light",
    on_construct = function(pos)
        local node = minetest.get_node(pos)
        minetest.get_node_timer(pos):start(math.random(30, 60))
    end,
    on_timer = function(pos, elapsed)
        -- Verifica se há algum nó acima (não pode ser ar)
        local above = {x = pos.x, y = pos.y + 1, z = pos.z}
        local node_above = minetest.get_node(above).name
        
        -- Se houver qualquer coisa acima (exceto ar), não converte
        if node_above ~= "air" then
            return true -- Continua o timer mas não converte
        end
        
        local light = minetest.get_node_light(pos)
        
        -- Verifica luz suficiente
        if light and light > 4 then
            -- Verifica vizinhos laterais e diagonais (8 posições)
            local neighbors = {
                -- Laterais
                {x = pos.x + 1, y = pos.y, z = pos.z},
                {x = pos.x - 1, y = pos.y, z = pos.z},
                {x = pos.x, y = pos.y, z = pos.z + 1},
                {x = pos.x, y = pos.y, z = pos.z - 1},
                -- Diagonais
                {x = pos.x + 1, y = pos.y, z = pos.z + 1},
                {x = pos.x + 1, y = pos.y, z = pos.z - 1},
                {x = pos.x - 1, y = pos.y, z = pos.z + 1},
                {x = pos.x - 1, y = pos.y, z = pos.z - 1},
                -- Laterais abaixo
                {x = pos.x + 1, y = pos.y - 1, z = pos.z},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z},
                {x = pos.x, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x, y = pos.y - 1, z = pos.z - 1},
                -- Diagonais abaixo
                {x = pos.x + 1, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x + 1, y = pos.y - 1, z = pos.z - 1},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z + 1},
                {x = pos.x - 1, y = pos.y - 1, z = pos.z - 1},
                -- Laterais acima
                {x = pos.x + 1, y = pos.y + 1, z = pos.z},
                {x = pos.x - 1, y = pos.y + 1, z = pos.z},
                {x = pos.x, y = pos.y + 1, z = pos.z + 1},
                {x = pos.x, y = pos.y + 1, z = pos.z - 1},
                -- Diagonais acima
                {x = pos.x + 1, y = pos.y + 1, z = pos.z + 1},
                {x = pos.x + 1, y = pos.y + 1, z = pos.z - 1},
                {x = pos.x - 1, y = pos.y + 1, z = pos.z + 1},
                {x = pos.x - 1, y = pos.y + 1, z = pos.z - 1},
                
            }
            
            -- Verifica se há grama em algum vizinho
            local has_grass_neighbor = false
            for _, npos in ipairs(neighbors) do
                local neighbor_name = minetest.get_node(npos).name
                if neighbor_name == "nodes:grass" or neighbor_name == "nodes:top_grass" then
                    has_grass_neighbor = true
                    break
                end
            end
            
            -- Só converte se tiver grama ao lado
            if has_grass_neighbor then
                minetest.set_node(pos, {name = "nodes:top_grass"})
            end
        end
        
        return true -- Continua o timer
    end,
})



--minetest.register_node("nodes:pebble", {
--    description = "Seixo",
--    tiles = {"seixo.png"},
--    inventory_image = "seixo.png",
--    wield_image = "seixo.png",
--    drawtype = "item",  -- Mudança aqui!
--    paramtype = "light",
--    sunlight_propagates = true,
 --   walkable = false,
 --   groups = {crumbly = 3, oddly_breakable_by_hand = 3, falling_node = 1},
 --   selection_box = {
 --       type = "fixed",
--        fixed = {-0.25, -0.5, -0.25, 0.25, -0.38, 0.25},
--    },
--})

--minetest.register_node("nodes:pebble", {
--    description = "Seixo",
--    tiles = {"seixo.png"},
--    inventory_image = "seixo.png",
--    wield_image = "seixo.png",
--    drawtype = "plantlike",  -- Mudança aqui!
--    paramtype = "light",
--    sunlight_propagates = true,
--    walkable = false,
--    groups = {crumbly = 3, oddly_breakable_by_hand = 3, falling_node = 1},
--    selection_box = {
--        type = "fixed",
 --       fixed = {-0.25, -0.5, -0.25, 0.25, -0.38, 0.25},
 --   },
--})

minetest.register_node("nodes:sand", {
    description = "Areia",
    tiles = {"areia.png"},
    groups = {crumbly = 2, falling_node = 1},
})

minetest.register_node("nodes:wet_sand", {
    description = "Areia molhada",
    tiles = {"areia_molhada.png"},
    groups = {crumbly = 2},
})


minetest.register_node("nodes:saprolite", {
    description = "Saprólito",
    tiles = {"saprolite.png"},
    groups = {cracky = 3},
})

minetest.register_node("nodes:basalt", {
    description = "Basalto",
    tiles = {"basalt.png"},
    groups = {cracky = 3},
})

minetest.register_node("nodes:gneiss", {
    description = "Gnaisse",
    tiles = {"pedra.png"},
    groups = {cracky = 3},
})

minetest.register_node("nodes:peridotite", {
    description = "Peridotito",
    tiles = {"peridotite.png"},
    groups = {cracky = 3},
})

minetest.register_node("nodes:redrock", {
    description = "Ruborita",
    tiles = {"lava.png"},
    groups = {unbreakable = 1, not_in_creative_inventory = 1}, --{unbreakable = 1, not_in_creative_inventory = 1},
    drop = "",
})


minetest.register_node("nodes:bedrock", {
    description = "Bridgmanita",
    tiles = {"matriz.png"},
    drawtype = "glasslike_framed_optional",
    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    groups = {cracky = 3}, --{cracky = 1, oddly_breakable_by_hand = 1},
})

minetest.register_node("nodes:obsidian", {
    description = "Obsidiana",
    tiles = {"obsidiana.png"},
    groups = {cracky = 3}, --{cracky = 1, oddly_breakable_by_hand = 1},
})


--minetest.register_node("nodes:wood", {
--    description = "Tronco",
--    tiles = {"tronco.png"},
--    groups = {choppy = 3, falling_node = 1},
--})

--minetest.register_node("nodes:leaves", {
--    description = "Folhas",
--    drawtype = "allfaces_optional",
--    waving = 1,
--    tiles = {"folhas.png"},
--    groups = {snappy = 3, falling_node = 1},
--    drop = "items:stick",
--})

-- Função para verificar se um nó tem suporte sólido
local function has_solid_support(pos, checked)
    checked = checked or {}
    local hash = minetest.hash_node_position(pos)
    
    if checked[hash] then
        return false
    end
    checked[hash] = true
    
    if #checked > 100 then
        return false
    end
    
    local below = {x = pos.x, y = pos.y - 1, z = pos.z}
    local below_node = minetest.get_node(below)
    
    -- Se tem algo sólido abaixo (que não seja tronco ou folha), está suportado
    if below_node.name ~= "air" 
       and below_node.name ~= "nodes:oaktimber" 
       and not below_node.name:find("nodes:leaves") then
        return true
    end
    
    -- Se tem um tronco abaixo, verifica se esse tronco tem suporte
    if below_node.name == "nodes:oaktimber" then
        if has_solid_support(below, checked) then
            return true
        end
    end
    
    return false
end

-- Função para fazer folhas caírem
local function make_leaves_fall(pos)
    local radius_horizontal = 8  -- Alcance lateral
    local radius_vertical = 20   -- Alcance vertical (para cima e para baixo)
    
    for x = -radius_horizontal, radius_horizontal do
        for y = radius_vertical, -radius_vertical, -1 do  -- Aumentado para pegar folhas mais altas
            for z = -radius_horizontal, radius_horizontal do
                local check_pos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                local node = minetest.get_node(check_pos)
                
                if node.name:find("nodes:leaves") then
                    local delay = math.random(2, 10) / 10
                    minetest.after(delay, function()
                        local current_node = minetest.get_node(check_pos)
                        if current_node.name:find("nodes:leaves") then
                            minetest.remove_node(check_pos)
                            local obj = minetest.add_entity(check_pos, "__builtin:falling_node")
                            if obj then
                                obj:get_luaentity():set_node(current_node)
                            end
                        end
                    end)
                end
            end
        end
    end
end

-- Tronco
minetest.register_node("nodes:oaktimber", {
    description = "Tronco de Carvalho",
    tiles = {"tronco.png"},
    groups = {choppy = 3, falling_node = 1, armor_head = 1},
    
    -- Detecta quando o tronco é quebrado ou vai cair
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- Verifica se tinha suporte antes de ser quebrado
        -- Se não tinha, significa que vai cair
        local below = {x = pos.x, y = pos.y - 1, z = pos.z}
        local below_node = minetest.get_node(below)
        
        -- Se abaixo é ar ou outro tronco/folha, faz folhas caírem
        if below_node.name == "air" or below_node.name == "nodes:oaktimber" or below_node.name:find("nodes:leaves") then
            make_leaves_fall(pos)
        end
    end,
    
    -- Detecta quando o tronco começa a se mover
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.5)
    end,
    
    on_timer = function(pos)
        local node = minetest.get_node(pos)
        if node.name == "nodes:oaktimber" then
            -- Se não tem suporte, vai começar a cair
            if not has_solid_support(pos) then
                make_leaves_fall(pos)
                return false  -- Para o timer
            end
            return true  -- Continua verificando
        end
        return false
    end,
})

-- Madeira
minetest.register_node("nodes:oakwood", {
    description = "Madeira de Carvalho",
    tiles = {"oakwood.png"},
    groups = {choppy = 3},
})

-- Prancha
minetest.register_node("nodes:oakplank", {
    description = "Prancha de Carvalho",
    drawtype = "mesh",
    mesh = "oakplank.obj",
    tiles = {"oakwood.png"},
    groups = {choppy = 3},

    paramtype = "light",
    paramtype2 = "wallmounted",
    
    selection_box = {
        type = "wallmounted",
        wall_top = {-0.5, 0, -0.5, 0.5, 0.5, 0.5},
        wall_bottom = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        wall_side = {-0.5, -0.5, -0.5, 0, 0.5, 0.5},
    },
    
    node_box = {
        type = "wallmounted",
        wall_top = {0, 0, 0, 0, 0.5, 0},
        wall_bottom = {0, -0.5, 0, 0, 0, 0},
        wall_side = {-0.5, 0, 0, -0.5, 0.5, 0},
    },    
})

-- Tábua
minetest.register_node("nodes:oakboard", {
    description = "Tábua de Carvalho",
    drawtype = "mesh",
    mesh = "oakboard.obj",
    tiles = {"oakwood.png"},
    groups = {choppy = 3},
    paramtype = "light",
    paramtype2 = "facedir",
    
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, 0.38, 0.5, 0.5, 0.5},
    },
    
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.06, 0.5, 0.5, 0.06},
    },
    
    on_place = function(itemstack, placer, pointed_thing)
        if not placer or not placer:is_player() then
            return itemstack
        end
        
        -- Detecta em qual face foi clicado
        local under = pointed_thing.under
        local above = pointed_thing.above
        local click_dir = vector.subtract(above, under)
        
        -- Pega a direção horizontal do jogador
        local yaw = placer:get_look_horizontal()
        local player_dir = minetest.yaw_to_dir(yaw)
        local player_facedir = minetest.dir_to_facedir(player_dir)
        
        local facedir
        
        if click_dir.y == 1 then
            -- Clicado no topo (chão) - tábua deitada
            facedir = player_facedir
        elseif click_dir.y == -1 then
            -- Clicado embaixo (teto) - tábua deitada invertida
            facedir = player_facedir + 20
        elseif click_dir.z ~= 0 then
            -- Parede Norte/Sul (eixo Z)
            local wall_facedir = minetest.dir_to_facedir(click_dir)
            facedir = wall_facedir + 4
        else
            -- Parede Leste/Oeste (eixo X)
            local wall_facedir = minetest.dir_to_facedir(click_dir)
            facedir = wall_facedir + 12  -- Valor diferente para paredes X
        end
        
        return minetest.item_place(itemstack, placer, pointed_thing, facedir)
    end,
})

-- Tarugo
minetest.register_node("nodes:oakdowel", {
    description = "Tarugo de Carvalho",
    drawtype = "mesh",
    mesh = "oakdowel.obj",
    tiles = {"oakwood.png"},
    groups = {choppy = 3},
    
    paramtype = "light",
    paramtype2 = "wallmounted",
    
    selection_box = {
        type = "wallmounted",
        wall_top = {-0.1, -0.5, -0.1, 0.1, 0.5, 0.1},
        wall_bottom = {-0.1, -0.5, -0.1, 0.1, 0.5, 0.1},
        wall_side = {-0.5, -0.1, -0.1, 0.5, 0.1, 0.1},
    },
    
    node_box = {
        type = "wallmounted",
        wall_top = {-0.0625, 0.5-0.5625, -0.0625, 0.0625, 0.5, 0.0625},
        wall_bottom = {-0.0625, -0.5, -0.0625, 0.0625, -0.5+0.5625, 0.0625},
        wall_side = {-0.5, -0.0625, -0.0625, -0.5+0.28125, 0.5, 0.0625},
    },
})

minetest.register_node("nodes:torch", {
    description = "Tocha",
    drawtype = "mesh",
    mesh = "torch.obj",
    tiles = {"torch.png"},
    --inventory_image = "tocha_inventario.png",
    --wield_image = "tocha_inventario.png",
    
    paramtype = "light",
    --paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    
    groups = {choppy = 2, dig_immediate = 3, flammable = 1, attached_node = 1},
    
    --selection_box = {
    --    type = "wallmounted",
    --    wall_top = {-0.1, 0.5-0.6, -0.1, 0.1, 0.5, 0.1},
    --    wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.5+0.6, 0.1},
   --     wall_side = {-0.5, -0.1, -0.1, -0.5+0.3, 0.5, 0.1},
    --},
    
    --node_box = {
    --    type = "wallmounted",
    --    wall_top = {-0.0625, 0.5-0.5625, -0.0625, 0.0625, 0.5, 0.0625},
    --    wall_bottom = {-0.0625, -0.5, -0.0625, 0.0625, -0.5+0.5625, 0.0625},
    --    wall_side = {-0.5, -0.0625, -0.0625, -0.5+0.28125, 0.5, 0.0625},
    --},
})

minetest.register_node("nodes:torch2", {
    description = "Tocha acesa",
    drawtype = "mesh",
    mesh = "torch.obj",
    tiles = {"torchfire.png"},
    --inventory_image = "tocha_inventario.png",
    --wield_image = "tocha_inventario.png",
    
    paramtype = "light",
    --paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    
    light_source = 13,  -- Luminosidade (0-14, onde 14 é máximo)
    
    groups = {choppy = 2, dig_immediate = 3, flammable = 1, attached_node = 1},
    
    --selection_box = {
    --    type = "wallmounted",
    --    wall_top = {-0.1, 0.5-0.6, -0.1, 0.1, 0.5, 0.1},
    --    wall_bottom = {-0.1, -0.5, -0.1, 0.1, -0.5+0.6, 0.1},
   --     wall_side = {-0.5, -0.1, -0.1, -0.5+0.3, 0.5, 0.1},
    --},
    
    --node_box = {
    --    type = "wallmounted",
    --    wall_top = {-0.0625, 0.5-0.5625, -0.0625, 0.0625, 0.5, 0.0625},
    --    wall_bottom = {-0.0625, -0.5, -0.0625, 0.0625, -0.5+0.5625, 0.0625},
    --    wall_side = {-0.5, -0.0625, -0.0625, -0.5+0.28125, 0.5, 0.0625},
    --},
})

-- Node invisível que emite luz
minetest.register_node("nodes:torch_light", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    buildable_to = true,
    light_source = 13,
    groups = {not_in_creative_inventory = 1},
})

-- Folhas de carvalho
minetest.register_node("nodes:leaves", {
    description = "Folhas",
    drawtype = "liquid",
    waving = 1,
    tiles = {"folhas.png"},
    groups = {snappy = 3},
    drop = "items:stick",
    walkable = false,
    alpha = 50,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:leaves",
    liquid_alternative_source = "nodes:leaves",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

-- Folhas mirtilo
minetest.register_node("nodes:blueberryleaves", {
    description = "Folhas de Mirtilo",
    drawtype = "liquid",
    waving = 1,
    tiles = {"folhasmirtilo.png"},
    groups = {snappy = 3},
    drop = "items:stick",
    walkable = false,
    alpha = 50,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:blueberryleaves",
    liquid_alternative_source = "nodes:blueberryleaves",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

minetest.register_node("nodes:nut", {
    description = "Noz",
    wield_scale = {x = -2, y = -2, z = -2},
    drawtype = "mesh",
    mesh = "noz.obj",
    tiles = {"noz.png"},
    
    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.08, -0.5, -0.08, 0.08, -0.30, 0.08}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.08, -0.5, -0.08, 0.08, -0.30, 0.08}
    },
    
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1)  -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

-- Folhas com 4 blueberry
minetest.register_node("nodes:leaves_blueberry4", {
    description = "Folhas com 4 mirtilos",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"folhasmirtilo4.png"},
    groups = {snappy = 3},
    drop = {
        items = {
            {items = {"nodes:blueberry 4"}},
            {items = {"items:stick"}},
        }
    },
    walkable = false,
    alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:leaves_blueberry4",
    liquid_alternative_source = "nodes:leaves_blueberry4",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

-- Folhas com 1 noz
minetest.register_node("nodes:leaves_nut", {
    description = "Folhas com noz",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"folhasnoz.png"},
    groups = {snappy = 3},
    drop = {
        items = {
            {items = {"nodes:nut"}},
            {items = {"items:stick"}},
        }
    },
    walkable = false,
    alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:leaves",
    liquid_alternative_source = "nodes:leaves",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

-- Folhas com 2 nozes
minetest.register_node("nodes:leaves_nut2", {
    description = "Folhas com 2 nozes",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"folhasnoz2.png"},
    groups = {snappy = 3},
    drop = {
        items = {
            {items = {"nodes:nut 2"}},
            {items = {"items:stick"}},
        }
    },
    walkable = false,
    alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:leaves",
    liquid_alternative_source = "nodes:leaves",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

-- Folhas com 3 nozes
minetest.register_node("nodes:leaves_nut3", {
    description = "Folhas com 3 nozes",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"folhasnoz3.png"},
    groups = {snappy = 3},
    drop = {
        items = {
            {items = {"nodes:nut 3"}},
            {items = {"items:stick"}},
        }
    },
    walkable = false,
    alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:leaves",
    liquid_alternative_source = "nodes:leaves",
    liquid_viscosity = 3,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = {a = 15, r = 15, g = 15, b = 15},
})

-- Sistema alternativo de dano (caso on_fall_damage não funcione)
-- Verifica folhas caindo e causa dano aos jogadores
local players_with_torch = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        
        -- ==== SISTEMA DE DANO DAS FOLHAS ====
        local above_pos = {x = pos.x, y = pos.y + 2, z = pos.z}
        local objects = minetest.get_objects_inside_radius(above_pos, 1.5)
        for _, obj in pairs(objects) do
            local entity = obj:get_luaentity()
            if entity and entity.name == "__builtin:falling_node" then
                local node = entity.node
                if node and node.name and node.name:find("nodes:leaves") then
                    local velocity = obj:get_velocity()
                    if velocity and velocity.y < -2 then
                        player:set_hp(player:get_hp() - 1)
                    end
                end
            end
        end
        
        -- ==== SISTEMA DE LUZ DA TOCHA ====
        local wielded = player:get_wielded_item()
        local player_name = player:get_player_name()
        local light_pos_base = {x = pos.x, y = pos.y + 1, z = pos.z}
        
        if wielded:get_name() == "nodes:torch2" then
            -- Cria luz temporária
            if not players_with_torch[player_name] then
                players_with_torch[player_name] = {}
            end
            
            -- Remove luz antiga
            if players_with_torch[player_name].pos then
                local old_pos = players_with_torch[player_name].pos
                local node = minetest.get_node(old_pos)
                if node.name == "nodes:torch_light" then
                    minetest.remove_node(old_pos)
                end
            end
            
            -- Coloca nova luz invisível
            local light_pos = vector.round(light_pos_base)
            local node = minetest.get_node(light_pos)
            if node.name == "air" then
                minetest.set_node(light_pos, {name = "nodes:torch_light"})
                players_with_torch[player_name].pos = light_pos
            end
        else
            -- Remove luz se não está mais segurando
            if players_with_torch[player_name] and players_with_torch[player_name].pos then
                local old_pos = players_with_torch[player_name].pos
                local node = minetest.get_node(old_pos)
                if node.name == "nodes:torch_light" then
                    minetest.remove_node(old_pos)
                end
                players_with_torch[player_name] = nil
            end
        end
    end
end)

-- Limpa luz quando jogador sai
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    if players_with_torch[player_name] and players_with_torch[player_name].pos then
        local pos = players_with_torch[player_name].pos
        local node = minetest.get_node(pos)
        if node.name == "nodes:torch_light" then
            minetest.remove_node(pos)
        end
        players_with_torch[player_name] = nil
    end
end)

-- Limpa luz quando jogador sai
minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    if players_with_torch[player_name] and players_with_torch[player_name].pos then
        local pos = players_with_torch[player_name].pos
        local node = minetest.get_node(pos)
        if node.name == "nodes:torch_light" then
            minetest.remove_node(pos)
        end
        players_with_torch[player_name] = nil
    end
end)


minetest.register_node("nodes:apple", {
    description = "Maçã",
    drawtype = "mesh",
    mesh = "apple.obj",
    tiles = {"AppleTexture.png"},
    
    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1, armor_head = 1},
    
    collision_box = {
        type = "fixed",
        fixed = {-0.125, -0.5, -0.125, 0.125, -0.25, 0.125}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.125, -0.5, -0.125, 0.125, -0.25, 0.125}
    },
    
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 2)  -- Restaura 4 pontos
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_node("nodes:blueberry", {
    description = "Mirtilo",
    --wield_scale = {x = 10, y = 10, z = 10},
    drawtype = "mesh",
    mesh = "blueberry.obj",
    tiles = {"BlueberryTexture.png"},
    
    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.03, -0.5, -0.03, 0.03, -0.44, 0.03}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.03, -0.5, -0.03, 0.03, -0.44, 0.03}
    },
    
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1)  -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_node("nodes:frango", {
    description = "frango",
    drawtype = "mesh",
    mesh = "chicken_node.obj",
    tiles = {"chicken.png"},
    
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.25, 0, -0.25, 0.25, 0, 0.25}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
    },
    visual_size = {x = 15, y = 15},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1)  -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_node("nodes:raw_chicken", {
    description = "Frango cru",
    drawtype = "mesh",
    mesh = "raw_chicken.obj",
    tiles = {"raw_chicken.png"},
    
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.25, 0, -0.25, 0.25, 0, 0.25}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.3, -0.5, -0.3, 0.3, 0, 0.3}
    },
    visual_size = {x = 15, y = 15},
    wield_scale = {x= -2, y= -2, z= -2},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1)  -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

minetest.register_node("nodes:coconut", {
    description = "Coco",
    drawtype = "mesh",
    mesh = "coconut.obj",
    tiles = {"CocoTexture.png"},
    
    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0, 0.25}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0, 0.25}
    },
    
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 3)  -- Restaura 3 pontos
        itemstack:take_item()
        return itemstack
    end,
})


minetest.register_node("nodes:palm_trunk", {
    description = "Tronco de coqueiro",
    drawtype = "mesh",
    mesh = "palm_trunk.obj",
    tiles = {"coqueirotexture.png"},
    
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25}
    },
})

minetest.register_node("nodes:palm_leaf", {
    description = "Folha de coqueiro",
    drawtype = "mesh",
    mesh = "palm_leaf.obj",
    tiles = {"PalmLeafTexture.png"},
    
    paramtype = "light",
    walkable = false,
    sunlight_propagates = true,
    shaded = false,  -- Desabilita sombreamento por face
    backface_culling = false,  -- Renderiza ambos os lados das faces
    use_texture_alpha = "blend",
    paramtype2 = "facedir",
    groups = {snappy = 3, oddly_breakable_by_hand = 1, armor_head = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, -0.3, 0.5}
    },
})


minetest.register_node("nodes:snow", {
    description = "Neve",
    tiles = {"neve.png"},
    drawtype = "normal",
    groups = {crumbly = 3, falling_node = 1}, -- como areia, mas sem fluir
    --sounds = default.node_sound_snow_defaults(),
})

minetest.register_node("nodes:snow_flowing", {
    description = "Avalanche",
    drawtype = "flowingliquid",
    tiles = {"neve.png"},
    special_tiles = {
        {
            name = "neve_flowing_animated.png",
            backface_culling = false,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0},
        },
        {
            name = "neve_flowing_animated.png",
            backface_culling = true,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0},
        },
    },
    alpha = 160,
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "none",  -- ❗ NÃO deixar o motor fluir automaticamente
    groups = {not_in_creative_inventory=1},
})

minetest.register_node("nodes:water", {
    description = "Água",
    drawtype = "liquid",
    tiles = {"agua.png"},
    special_tiles = {
        { name = "agua_animated.png", animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0} },
    },
    alpha = 160,
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:water_flowing",
    liquid_alternative_source = "nodes:water",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=0, g=0, b=255},
    drowning = 1,  -- ADICIONE ESTA LINHA (dano por segundo quando sem ar)
    groups = {water=1, liquid=1},
})

minetest.register_node("nodes:water_flowing", {
    description = "Água Corrente",
    drawtype = "flowingliquid",
    tiles = {"agua.png"},
    special_tiles = {
        {
            name = "agua_flowing_animated.png",
            backface_culling = false,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
        {
            name = "agua_flowing_animated.png",
            backface_culling = true,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
    },
    alpha = 160,
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nodes:water_flowing",
    liquid_alternative_source = "nodes:water",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=0, g=0, b=255},
    drowning = 1,  -- ADICIONE ESTA LINHA
    groups = {water=1, liquid=1, not_in_creative_inventory=1},
})

minetest.register_node("nodes:water2", {
    description = "Água doce",
    drawtype = "liquid",
    tiles = {"agua2.png"},
    special_tiles = {
        { name = "agua2_animated.png", animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0} },
    },
    alpha = 160,
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:water2_flowing",
    liquid_alternative_source = "nodes:water2",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=0, g=0, b=255},
    drowning = 1,  -- ADICIONE ESTA LINHA
    groups = {water=1, liquid=1},
})

minetest.register_node("nodes:water2_flowing", {
    description = "Água Doce Corrente",
    drawtype = "flowingliquid",
    tiles = {"agua2.png"},
    special_tiles = {
        {
            name = "agua2_flowing_animated.png",
            backface_culling = false,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
        {
            name = "agua2_flowing_animated.png",  -- Corrigido (estava agua_flowing)
            backface_culling = true,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
    },
    alpha = 160,
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nodes:water2_flowing",
    liquid_alternative_source = "nodes:water2",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=0, g=0, b=255},
    drowning = 1,  -- ADICIONE ESTA LINHA
    groups = {water=1, liquid=1, not_in_creative_inventory=1},
})
    
    
    minetest.register_node("nodes:lava", {
    description = "Lava",
    drawtype = "liquid",
    tiles = {"lava.png"},
    special_tiles = {
        { name = "lava_animated.png", animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0} },
    },
    alpha = 160,
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nodes:lava_flowing",
    liquid_alternative_source = "nodes:lava",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=255, g=0, b=0},
    groups = {lava=1, liquid=1},
})

minetest.register_node("nodes:lava_flowing", {
    description = "Lava corrente",
    drawtype = "flowingliquid",
    tiles = {"lava.png"},
    special_tiles = {
        {
            name = "lava_flowing_animated.png",
            backface_culling = false,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
        {
            name = "lava_flowing_animated.png",
            backface_culling = true,
            animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=2.0}
        },
    },
    alpha = 160,
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nodes:lava_flowing",
    liquid_alternative_source = "nodes:lava",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=255, g=0, b=0},
    groups = {lava=1, liquid=1, not_in_creative_inventory=1},

})



---------
-- Baú geral
--------

-- Função para atualizar itens visuais no baú
function oak_chest_update_items(pos)
    local node = minetest.get_node(pos)
    if node.name ~= "nodes:oak_chest_open" then
        return
    end
    
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    
    -- Remover entidades de itens antigas
    local objects = minetest.get_objects_inside_radius(pos, 1)
    for _, obj in ipairs(objects) do
        if obj:get_luaentity() and obj:get_luaentity().name == "nodes:chest_item" then
            obj:remove()
        end
    end
    
    -- Procurar a entidade do baú aberto para anexar os itens
    local chest_entity = nil
    for _, obj in ipairs(objects) do
        local luaent = obj:get_luaentity()
        if luaent and luaent.name == "nodes:oak_chest_entity" then
            chest_entity = obj
            break
        end
    end
    
    -- Se não houver entidade do baú, criar uma invisível para servir de base
    if not chest_entity then
        chest_entity = minetest.add_entity(pos, "nodes:oak_chest_entity")
        if chest_entity and chest_entity:get_luaentity() then
            local luaent = chest_entity:get_luaentity()
            luaent.node_pos = pos
            luaent.is_invisible = true
            
            -- Aplicar rotação
            local yaw = minetest.facedir_to_dir(node.param2)
            chest_entity:set_yaw(minetest.dir_to_yaw(yaw))
        end
    end
    
    if not chest_entity then
        return
    end
    
    -- Criar novas entidades para cada item (máximo 16 bones)
    for i = 1, math.min(16, inv:get_size("main")) do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            local entity = minetest.add_entity(pos, "nodes:chest_item")
            if entity and entity:get_luaentity() then
                local luaent = entity:get_luaentity()
                luaent.chest_pos = pos
                luaent.slot_index = i
                luaent:update_item(stack:get_name())
                
                -- Anexar ao bone correspondente do baú
                entity:set_attach(chest_entity, "bone"..i, {x=0, y=0, z=0}, {x=0, y=0, z=0})
            end
        end
    end
end

-- Entidade para representar itens no baú
minetest.register_entity("nodes:chest_item", {
    initial_properties = {
        visual = "wielditem",
        wield_item = "air",
        visual_size = {x=0.1, y=0.1},  -- Tamanho reduzido (era 0.25)
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },
    
    chest_pos = nil,
    slot_index = 0,
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal=1})
    end,
    
    update_item = function(self, item_name)
        self.object:set_properties({
            wield_item = item_name
        })
    end,
    
    on_step = function(self, dtime)
        -- Verificar se o baú ainda existe
        if not self.chest_pos then
            self.object:remove()
            return
        end
        
        local node = minetest.get_node(self.chest_pos)
        if node.name ~= "nodes:oak_chest_open" then
            self.object:remove()
        end
    end,
})

minetest.register_node("nodes:oak_chest_open", {
    drawtype = "mesh",
    mesh = "chestopen.obj",  -- modelo sem tampa
    tiles = {"ChestTexture.png"}, -- mesma textura
    walkable = true,
    pointable = true,
    paramtype = "light",
    paramtype2 = "facedir",

    selection_box = {
        type = "fixed",
        fixed = {-0.5,-0.5,-0.5, 0.5,0.5,0.5}
    },
    collision_box = {
        type = "fixed",
        fixed = {-0.5,-0.5,-0.5, 0.5,0.5,0.5}
    },

    groups = {not_in_creative_inventory = 1},
    
    -- Quando clicar no baú aberto, mostrar inventário
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local player_name = clicker:get_player_name()
        
        -- Marcar que o jogador está usando o baú
        meta:set_string("current_user", player_name)
        
        minetest.show_formspec(player_name, "nodes:oak_chest_"..minetest.pos_to_string(pos),
            meta:get_string("formspec"))
        
        return itemstack
    end,
    
    -- Atualizar itens visuais quando o node é construído
    on_construct = function(pos)
        minetest.after(0.1, function()
            oak_chest_update_items(pos)
        end)
    end,
    
    -- Atualizar itens visuais após colocar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        minetest.after(0.1, function()
            oak_chest_update_items(pos)
        end)
    end,
})

minetest.register_node("nodes:oak_chest", {
    description = "Baú de Carvalho",
    drawtype = "mesh",
    mesh = "chest.glb",
    tiles = {"ChestTexture.png"},
    walkable = true,
    pointable = true,
    
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {choppy = 2, oddly_breakable_by_hand = 1},
    --sounds = default.node_sound_wood_defaults(),
    
    collision_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    selection_box = {
        type = "fixed",
        fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    },
    
    -- Criar inventário quando o node é construído
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        
        -- Criar inventário com 32 slots (8x4)
        inv:set_size("main", 8*2) -- O bau é quadrado escolhi 4x4, mas na forma do inventário 8x2  
        
        -- Adiciona páginas com textos pré-definidos
        local page1 = items.create_page_with_text(
            "Dia 1: Encontrei este lugar abandonado. " ..
            "Parece que alguém viveu aqui há muito tempo atrás."
        )
        
        local page2 = items.create_page_with_text(
            "Dia 15: Os suprimentos estão acabando. " ..
            "Preciso encontrar uma saída antes que seja tarde demais."
        )
        
        local page3 = items.create_page_with_text(
            "Dia 30: Ouvi sons estranhos durante a noite. " ..
            "Não estou sozinho aqui..."
        )
        
        inv:set_stack("main", 1, page1)
        inv:set_stack("main", 2, page2)
        inv:set_stack("main", 3, page3)
        
	-- Adiciona páginas em branco
	inv:set_stack("main", 4, ItemStack("items:page 5"))  -- 5 páginas em branco
	
	inv:set_stack("main", 5, ItemStack("items:feather"))  -- pena de escrever
	inv:set_stack("main", 6, ItemStack("items:inkbottle"))  -- frasco com tinta
	inv:set_stack("main", 7, ItemStack("nodes:torch2"))  -- tocha acesa
        
        inv:set_stack("main", 8, ItemStack("nodes:apple 2"))  -- 2 maças
        inv:set_stack("main", 9, ItemStack("nodes:blueberry 2"))  -- 2 mitilos
        inv:set_stack("main", 10, ItemStack("nodes:coconut 2"))  -- 2 cocos
        inv:set_stack("main", 11, ItemStack("nodes:palm_trunk 1"))
        inv:set_stack("main", 12, ItemStack("nodes:palm_leaf 1"))
        
        -- Definir formspec do inventário
        meta:set_string("formspec",
            "size[8,9]"..
            "list[current_name;main;0,0.3;8,2;]"..
            "list[current_player;main;0,4.85;8,1;]"..
            "list[current_player;main;0,6.08;8,3;8]"..
            "listring[current_name;main]"..
            "listring[current_player;main]"
        )
        
        meta:set_string("infotext", "Baú de Carvalho")
    end,
    
    -- Verificar se pode cavar (não permitir se tiver itens)
    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,
    
    -- Ao clicar com botão direito
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- Tocar som de abertura
        --minetest.sound_play("default_chest_open", {
        --    pos = pos,
        --    gain = 0.3,
        --    max_hear_distance = 10,
        --}, true)
        
        -- Substitui o node pelo baú aberto
        local current_node = minetest.get_node(pos)
        minetest.swap_node(pos, {name = "nodes:oak_chest_open", param2 = current_node.param2})
        
        -- Retira a entidade baú depois da animação
        local objects = minetest.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:get_luaentity() and obj:get_luaentity().name == "nodes:oak_chest_entity" then
                obj:remove()
            end
        end
        
        -- Criar entidade para animação
        local entity = minetest.add_entity(pos, "nodes:oak_chest_entity")
        if entity and entity:get_luaentity() then
            local luaentity = entity:get_luaentity()
            luaentity.node_pos = pos
            luaentity.original_param2 = current_node.param2
            -- Aplicar a rotação do baú à entidade
            local yaw = minetest.facedir_to_dir(current_node.param2)
            entity:set_yaw(minetest.dir_to_yaw(yaw))
            entity:set_animation({x=0, y=0.25}, 1, 0, false) -- 0 a 0.25s a 30fps = frames 0-7.5
        end
        
        -- Abrir inventário
        local meta = minetest.get_meta(pos)
        local player_name = clicker:get_player_name()
        
        -- Marcar que o jogador está usando o baú
        meta:set_string("current_user", player_name)
        
        -- Atualizar itens visuais
        oak_chest_update_items(pos)
        
        minetest.show_formspec(player_name, "nodes:oak_chest_"..minetest.pos_to_string(pos),
            meta:get_string("formspec"))
        
        return itemstack
    end,
    
    -- Preservar inventário ao cavar
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local items = {}
        
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                table.insert(items, stack:to_string())
            end
        end
        
        if #items > 0 then
            drops[1]:get_meta():set_string("items", minetest.serialize(items))
        end
    end,
    
    -- Restaurar inventário ao colocar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local item_meta = itemstack:get_meta()
        local items = item_meta:get_string("items")
        
        if items ~= "" then
            items = minetest.deserialize(items)
            local inv = meta:get_inventory()
            
            for i, item_str in ipairs(items) do
                inv:set_stack("main", i, ItemStack(item_str))
            end
        end
    end,
})

-- Entidade invisível para animação
minetest.register_entity("nodes:oak_chest_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "chest.glb",
        textures = {"ChestTexture.png"},
        visual_size = {x=1, y=1, z=1},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
        paramtype = "light",
        paramtype2 = "facedir",
    },
    
    node_pos = nil,
    original_param2 = 0,
    timer = 0,
    animation_finished = false,
    is_invisible = false,
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal=1})
    end,
    
    on_step = function(self, dtime)
        -- Se for invisível (só para anexar itens), não fazer nada
        if self.is_invisible then
            return
        end
        
        self.timer = self.timer + dtime
        
        -- Após a animação, congelar no último frame
        if self.timer > 0.3 and not self.animation_finished then
            self.animation_finished = true
            -- Congelar no último frame da animação
            self.object:set_animation({x=0.25, y=0.25}, 0, 0, false)
        end
    end,
})

-- Entidade para animação de fechamento
minetest.register_entity("nodes:oak_chest_close_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "chest.glb",
        textures = {"ChestTexture.png"},
        visual_size = {x=1, y=1, z=1},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
        paramtype = "light",
        paramtype2 = "facedir",
    },
    
    node_pos = nil,
    original_param2 = 0,
    timer = 0,
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal=1})
    end,
    
    on_step = function(self, dtime)
        self.timer = self.timer + dtime
        
        -- Remover entidade e fechar baú após a animação
        if self.timer > 0.3 then
            -- Remover todos os itens anexados
            if self.node_pos then
                local objects = minetest.get_objects_inside_radius(self.node_pos, 1)
                for _, obj in ipairs(objects) do
                    local luaent = obj:get_luaentity()
                    if luaent and luaent.name == "nodes:chest_item" then
                        obj:remove()
                    end
                end
            end
            
            self.object:remove()
            
            -- Trocar para node fechado
            if self.node_pos then
                local node = minetest.get_node(self.node_pos)
                if node.name == "nodes:oak_chest_open" then
                    minetest.swap_node(self.node_pos, {name = "nodes:oak_chest", param2 = self.original_param2})
                end
            end
        end
    end,
})

-- Detectar quando o jogador fecha o formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
    -- Verificar se é um formspec de baú
    if formname:sub(1, 16) == "nodes:oak_chest_" then
        local pos_string = formname:sub(17)
        local pos = minetest.string_to_pos(pos_string)
        
        if pos then
            local node = minetest.get_node(pos)
            
            -- Se o baú estiver aberto, fechá-lo
            if node.name == "nodes:oak_chest_open" then
                local meta = minetest.get_meta(pos)
                local current_user = meta:get_string("current_user")
                local player_name = player:get_player_name()
                
                -- Verificar se é o jogador que estava usando
                if current_user == player_name then
                    -- Limpar usuário atual
                    meta:set_string("current_user", "")
                    
                    -- Remover apenas a entidade da animação de abertura (mas manter os itens)
                    local objects = minetest.get_objects_inside_radius(pos, 0.5)
                    local chest_entity = nil
                    
                    for _, obj in ipairs(objects) do
                        local luaent = obj:get_luaentity()
                        if luaent and luaent.name == "nodes:oak_chest_entity" then
                            chest_entity = obj
                            break
                        end
                    end
                    
                    -- Criar entidade para animação de fechamento
                    local close_entity = minetest.add_entity(pos, "nodes:oak_chest_close_entity")
                    if close_entity and close_entity:get_luaentity() then
                        local luaentity = close_entity:get_luaentity()
                        luaentity.node_pos = pos
                        luaentity.original_param2 = node.param2
                        
                        -- Transferir os itens anexados para a entidade de fechamento
                        if chest_entity then
                            for _, obj in ipairs(objects) do
                                local luaent = obj:get_luaentity()
                                if luaent and luaent.name == "nodes:chest_item" then
                                    -- Re-anexar ao novo baú (fechamento)
                                    local slot = luaent.slot_index
                                    obj:set_attach(close_entity, "bone"..slot, {x=0, y=0, z=0}, {x=0, y=0, z=0})
                                end
                            end
                            
                            -- Remover a entidade antiga do baú
                            chest_entity:remove()
                        end
                        
                        -- Aplicar a rotação do baú à entidade
                        local yaw = minetest.facedir_to_dir(node.param2)
                        close_entity:set_yaw(minetest.dir_to_yaw(yaw))
                        -- Animação de fechamento (do frame aberto para fechado)
                        close_entity:set_animation({x=0.25, y=0}, 30, 0, false)
                    end
                end
            end
        end
    end
end)



-- Detectar mudanças no inventário do baú
minetest.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if action ~= "move" and action ~= "put" and action ~= "take" then
        return
    end

    if inventory_info.to_list ~= "main" and inventory_info.from_list ~= "main" then
        return
    end

    local player_name = player:get_player_name()
    local player_pos = player:get_pos()
    if not player_pos then return end

    local objects = minetest.get_objects_inside_radius(player_pos, 10)

    for _, obj in ipairs(objects) do
        if obj:is_player() then
            goto continue
        end

        local pos = obj:get_pos()
        if not pos then
            goto continue
        end

        local node = minetest.get_node_or_nil(pos)
        if not node then
            goto continue
        end

        if node.name == "nodes:oak_chest_open" then
            local meta = minetest.get_meta(pos)
            if meta:get_string("current_user") == player_name then
                oak_chest_update_items(pos)
            end
        end

        ::continue::
    end
end)

-- Som de fechamento ao sair do formspec (opcional)
--minetest.register_on_player_receive_fields(function(player, formname, fields)
--    if formname:find("nodes:oak_chest_") then
--        if fields.quit then
--            local pos_str = formname:gsub("nodes:oak_chest_", "")
--            local pos = minetest.string_to_pos(pos_str)
--            
--            if pos then
--                minetest.sound_play("default_chest_close", {
--                    pos = pos,
--                    gain = 0.3,
--                    max_hear_distance = 10,
--                }, true)
--            end
--        end
--    end
--end)


------------
-- Porta
------------

minetest.register_node("nodes:oak_door", {
    description = "Porta de Carvalho",
    initial_properties = {
        visual = "mesh",
        mesh = "porta_tablada_carvalho.obj",
        textures = {"porta_tablada_carvalho.png"},
        --visual_size = {x=1, y=2}, -- ajuste
        groups = {choppy = 2},
    },
})

---------------------------
-- FUNÇÃO DE ARREMESSO
---------------------------
local function throw_pebble(itemstack, user)
    local pos = user:get_pos()
    local dir = user:get_look_dir()
    pos.y = pos.y + 2.25 -- altura dos olhos
    local obj = minetest.add_entity(pos, "nodes:pebble_entity")
    if obj then
        obj:set_velocity(vector.multiply(dir, 13))
        obj:set_acceleration({x = 0, y = -9.81, z = 0})
        local ent = obj:get_luaentity()
        if ent then
            ent._shooter = user
        end
    end
    itemstack:take_item()
    return itemstack
end

---------------------------
-- ITEM ARREMESSÁVEL
---------------------------
minetest.register_craftitem("nodes:pebble_item", {
    description = "Seixo Arremessável",
    inventory_image = "seixo.png",

    -- Bater
    tool_capabilities = {
        full_punch_interval = 0.9,
        max_drop_level = 0,
        groupcaps = {
            cracky = {times = {[2] = 2.0, [3] = 1.0}, uses = 20, maxlevel = 1},
            crumbly = {times = {[1] = 1.5, [2] = 0.9, [3] = 0.5}, uses = 20, maxlevel = 1},
            snappy = {times = {[2] = 1.0, [3] = 0.5}, uses = 20, maxlevel = 1},
        },
        damage_groups = {fleshy = 2},
    },

    -- Botão direito = arremessa (sempre, sem precisar apontar)
    on_place = function(itemstack, placer, pointed_thing)
        return throw_pebble(itemstack, placer)
    end,
    
    -- Botão esquerdo = bate e gera som
    --on_use = function(itemstack, user, pointed_thing)
        --minetest.sound_play("default_dig_cracky", {
         --   pos = user:get_pos(),
         --   gain = 0.5,
        --})
       -- return itemstack
    --end,
    
    -- Ao soltar = arremessa
    on_drop = function(itemstack, dropper, pos)
        return throw_pebble(itemstack, dropper)
    end,
})

---------------------------
-- ENTIDADE DO PROJÉTIL
---------------------------
minetest.register_entity("nodes:pebble_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
        visual = "wielditem",
        visual_size = {x = 0.2, y = 0.2},
        textures = {"nodes:pebble"},
    },
    
    _stuck = false,
    _timer = 0,
    _stuck_timer = 0,
    _last_pos = nil,
    
    on_activate = function(self, staticdata)
        self._timer = 0
        self._stuck = false
        self._stuck_timer = 0
    end,
    
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then
            self.object:remove()
            return
        end
        
        -- Timer geral para remover após muito tempo
        self._timer = self._timer + dtime
        if self._timer > 60 then
            self.object:remove()
            return
        end
        
        -- Se já está grudado
        if self._stuck then
            self._stuck_timer = self._stuck_timer + dtime
            
            -- Após 0.1 segundo grudado, vira node
            if self._stuck_timer >= 0.1 then
                local node_pos = vector.round(pos)
                local node = minetest.get_node(node_pos)
                
                -- Tenta colocar o node na posição atual
                if node.name == "air" or not minetest.registered_nodes[node.name].walkable then
                    minetest.set_node(node_pos, {name = "nodes:pebble"})
                else
                    -- Tenta posições adjacentes
                    local offsets = {
                        {x=0, y=1, z=0},
                        {x=0, y=-1, z=0},
                        {x=1, y=0, z=0},
                        {x=-1, y=0, z=0},
                        {x=0, y=0, z=1},
                        {x=0, y=0, z=-1},
                    }
                    
                    local placed = false
                    for _, offset in ipairs(offsets) do
                        local try_pos = vector.add(node_pos, offset)
                        local try_node = minetest.get_node(try_pos)
                        if try_node.name == "air" then
                            minetest.set_node(try_pos, {name = "nodes:pebble"})
                            placed = true
                            break
                        end
                    end
                    
                    -- Se não conseguiu colocar, dropa item
                    if not placed then
                        minetest.add_item(pos, "nodes:pebble_item")
                    end
                end
                
                self.object:remove()
            end
            return
        end
        
        -- Detecção de colisão com raio maior
        local vel = self.object:get_velocity()
        if not vel then
            self.object:remove()
            return
        end
        
        local speed = vector.length(vel)
        
        -- Se a velocidade é muito baixa (parou de se mover)
        if speed < 0.5 then
            self._stuck = true
            self.object:set_velocity({x=0, y=0, z=0})
            self.object:set_acceleration({x=0, y=0, z=0})
            --minetest.sound_play("default_dug_node", {pos = pos, gain = 0.5})
            return
        end
        
        -- Verifica múltiplas posições ao longo do caminho (raycast manual)
        local step_dir = vector.normalize(vel)
        local check_distance = math.min(speed * dtime * 2, 1)
        local steps = math.ceil(check_distance / 0.2)
        
        for i = 1, steps do
            local check_pos = vector.add(pos, vector.multiply(step_dir, i * 0.2))
            local node = minetest.get_node(check_pos)
            
            if node and node.name and minetest.registered_nodes[node.name] then
                if minetest.registered_nodes[node.name].walkable then
                    -- Colidiu com bloco sólido
                    self._stuck = true
                    self.object:set_pos(check_pos)
                    self.object:set_velocity({x=0, y=0, z=0})
                    self.object:set_acceleration({x=0, y=0, z=0})
                    --minetest.sound_play("default_dug_node", {pos = check_pos, gain = 0.5})
                    return
                end
            end
        end
        
        -- Verifica colisão com entidades (jogadores, mobs)
        local objs = minetest.get_objects_inside_radius(pos, 0.6)
        for _, obj in ipairs(objs) do
            if obj ~= self.object and obj ~= self._shooter then
                    -- ADICIONE ESTE LOG:
        minetest.log("action", "[Seixo] Objeto detectado!")
            
                local is_target = obj:is_player()
                
                if not is_target then
                    local ent = obj:get_luaentity()
                    if ent and ent.name ~= "nodes:pebble_entity" and ent.hp_max then
                        is_target = true
                    end
                end
                
                if is_target then
                
                            -- ADICIONE ESTE LOG:
            minetest.log("action", "[Seixo] CAUSANDO DANO!")
                
                    minetest.sound_play("default_dig_cracky", {pos = pos, gain = 0.5})
                    
                    -- Causa dano
                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = {fleshy = 2},
                    }, vel)
                    
                    -- Dropa item no chão
                    minetest.add_item(pos, "nodes:pebble_item")
                    self.object:remove()
                    return
                end
            end
        end
        
        self._last_pos = pos
    end,
})

---------------------------
-- NODE DO SEIXO NO CHÃO
---------------------------
minetest.register_node("nodes:pebble", {
    description = "Seixo",
    tiles = {"pedra.png"},
    inventory_image = "seixo.png",
    wield_image = "seixo.png",
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 3,
        falling_node = 1,
        attached_node = 1,
    },

    node_box = {
        type = "fixed",
        fixed = {
            {-0.15, -0.5, -0.2, 0.15, -0.4, 0.15},
        },
    },

    selection_box = {
        type = "fixed",
        fixed = {-0.15, -0.5, -0.2, 0.15, -0.4, 0.15},
    },

    drop = "nodes:pebble_item",

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        minetest.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        minetest.check_for_falling(pos)
    end,
})


------------------------------------------------------------
-- EXEMPLO: REGISTRAR ITENS DE VESTUÁRIO (tá como tool por enquanto)
------------------------------------------------------------

-- Cinto
minetest.register_node("nodes:belt", {
    description = "Cinto Básico",
    inventory_image = "belt.png",
    drawtype = "mesh",
    mesh = "belt.obj",
    tiles = {"belt_overlay.png"},
    groups = {oddly_breakable_by_hand = 1, armor_waist = 1},
    
    node_box = {
        type = "fixed",
        fixed = {
            {-0.28, -0.5, -0.18, 0.28, -0.32, 0.18},
        },
    },

    selection_box = {
        type = "fixed",
        fixed = {-0.28, -0.5, -0.18, 0.28, -0.32, 0.18},
    },
   
})

-- Mochila
minetest.register_node("nodes:backchest", {
    description = "Mochila Baú",
    drawtype = "mesh",
    mesh = "backchest.obj",
    tiles = {"ChestTexture.png"},
    --inventory_image = "bag_basic.png",
    groups = {snappy = 3, oddly_breakable_by_hand = 1, armor_back = 1},
    visual = "wielditem",
    visual_size = {x=0.5, y=0.5, z=0.5},
    paramtype = "light",
    paramtype2 = "facedir",
    
})

-- Exemplo de capacete
minetest.register_tool("nodes:helmet", {
    description = "Capacete Básico",
    inventory_image = "helmet_basic.png",
    groups = {armor_head = 1},
})


-- Exemplo de armadura de tronco
minetest.register_tool("nodes:chestplate", {
    description = "Peitoral Básico",
    inventory_image = "chestplate_basic.png",
    groups = {armor_torso = 1},
})

-- Exemplo de calças
minetest.register_tool("nodes:leggings", {
    description = "Calças Básicas",
    inventory_image = "leggings_basic.png",
    groups = {armor_legs = 1},
})

-- Exemplo de botas
minetest.register_tool("nodes:boots", {
    description = "Botas Básicas",
    inventory_image = "boots_basic.png",
    groups = {armor_feet = 1},
})
