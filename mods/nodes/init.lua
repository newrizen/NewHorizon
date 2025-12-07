-----------------------------
-- NODES
-----------------------------
print("[nodes] init.lua carregado")



minetest.register_node("nodes:grass", {
    description = "Gramado",
    tiles = {"grama.png"},
    groups = {crumbly = 3},
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
    drop = "nodes:dirt",

    -- Mecânica opcional: grama morrer na sombra
    paramtype = "light",
    on_construct = function(pos)
        local node = minetest.get_node(pos)
        minetest.get_node_timer(pos):start(5)
    end,

    on_timer = function(pos, elapsed)
        local light = minetest.get_node_light(pos)
        if light and light < 4 then
            minetest.set_node(pos, {name = "nodes:dirt"})
        end
        return true
    end,
})

minetest.register_node("nodes:dirt", {
    description = "Terra",
    tiles = {"terra.png"},
    groups = {crumbly = 2},
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

minetest.register_node("nodes:gneiss", {
    description = "Gnaisse",
    tiles = {"pedra.png"},
    groups = {cracky = 3},
})

--minetest.register_node("nodes:bedrock", {
  --  description = "Bridgmanita",
  --  tiles = {"matriz.png"},
  --  groups = {cracky = 3}, --{unbreakable = 1, not_in_creative_inventory = 1},
    --drop = "",
--})


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
       and below_node.name ~= "nodes:wood" 
       and not below_node.name:find("nodes:leaves") then
        return true
    end
    
    -- Se tem um tronco abaixo, verifica se esse tronco tem suporte
    if below_node.name == "nodes:wood" then
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
minetest.register_node("nodes:wood", {
    description = "Tronco",
    tiles = {"tronco.png"},
    groups = {choppy = 3, falling_node = 1},
    
    -- Detecta quando o tronco é quebrado ou vai cair
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- Verifica se tinha suporte antes de ser quebrado
        -- Se não tinha, significa que vai cair
        local below = {x = pos.x, y = pos.y - 1, z = pos.z}
        local below_node = minetest.get_node(below)
        
        -- Se abaixo é ar ou outro tronco/folha, faz folhas caírem
        if below_node.name == "air" or below_node.name == "nodes:wood" or below_node.name:find("nodes:leaves") then
            make_leaves_fall(pos)
        end
    end,
    
    -- Detecta quando o tronco começa a se mover
    on_construct = function(pos)
        minetest.get_node_timer(pos):start(0.5)
    end,
    
    on_timer = function(pos)
        local node = minetest.get_node(pos)
        if node.name == "nodes:wood" then
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

-- Folhas normais
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

-- Folhas com 1 noz
minetest.register_node("nodes:leaves_nut", {
    description = "Folhas com noz",
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = {"folhasnoz.png"},
    groups = {snappy = 3},
    drop = {
        items = {
            {items = {"items:nut"}},
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
            {items = {"items:nut 2"}},
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
            {items = {"items:nut 3"}},
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
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local above_pos = {x = pos.x, y = pos.y + 2, z = pos.z}
        
        -- Verifica entidades de blocos caindo acima do jogador
        local objects = minetest.get_objects_inside_radius(above_pos, 1.5)
        for _, obj in pairs(objects) do
            local entity = obj:get_luaentity()
            if entity and entity.name == "__builtin:falling_node" then
                local node = entity.node
                if node and node.name and node.name:find("nodes:leaves") then
                    -- Verifica se está caindo (velocidade negativa em Y)
                    local velocity = obj:get_velocity()
                    if velocity and velocity.y < -2 then
                        player:set_hp(player:get_hp() - 1)  -- Causa 1 de dano
                    end
                end
            end
        end
    end
end)


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
    liquid_alternative_flowing = "nodes:water2_flowing",
    liquid_alternative_source = "nodes:water2",
    liquid_viscosity = 1,
    post_effect_color = {a=64, r=0, g=0, b=255},
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
    post_effect_color = {a=64, r=0, g=0, b=255},
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
    post_effect_color = {a=64, r=0, g=0, b=255},
    groups = {lava=1, liquid=1, not_in_creative_inventory=1},

})

minetest.register_node("nodes:oak_door", {
    description = "Porta de Carvalho",
    initial_properties = {
        visual = "mesh",
        mesh = "porta_tablada_carvalho.obj",
        textures = {"porta_tablada_carvalho.png"},
        visual_size = {x=1, y=2}, -- ajuste
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
            minetest.sound_play("default_dug_node", {pos = pos, gain = 0.5})
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
                    minetest.sound_play("default_dug_node", {pos = check_pos, gain = 0.5})
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

