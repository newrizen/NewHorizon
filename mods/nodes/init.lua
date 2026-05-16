-- NODES
core.log("action", "[NODES] init.lua loaded")

local S                  = core.get_translator("nh_nodes")
local footstep_timer     = {}
local lava_damage_timer  = {}
local players_with_torch = {}
local LAVA_NODES         = {
    ["nh_nodes:lava"] = true,
    ["nh_nodes:lava_flowing"] = true,
    ["nh_nodes:bluelava"] = true,
    ["nh_nodes:bluelava_flowing"] = true,
}
local WATER_FULLNODES    = {
    ["nh_nodes:water"]  = true,
    ["nh_nodes:water2"] = true,
}
local WATER_MIDNODES     = {
    ["nh_nodes:water_flowing"] = true,
    ["nh_nodes:water2_flowing"] = true,
}
local LEAF_TYPES         = {
    ["nh_nodes:leaves"]        = true,
    ["nh_nodes:leaves_nut"]    = true,
    ["nh_nodes:leaves_nut2"]   = true,
    ["nh_nodes:leaves_nut3"]   = true,
    ["nh_nodes:leaves_apple"]  = true,
    ["nh_nodes:leaves_apple2"] = true,
    ["nh_nodes:leaves_apple3"] = true,
}
local DECORATIONS        = {
    ["nh_nodes:smallgrass"]        = true,
    ["nh_nodes:highgrass"]         = true,
    ["nh_nodes:rush"]              = true,
    ["nh_nodes:dandelion"]         = true,
    ["nh_nodes:grassleaves"]       = true,
    ["nh_nodes:grassleavesmedium"] = true,
    ["nh_nodes:micaceusfungus"]    = true,
    ["nh_nodes:flyamanitafungus"]  = true,
    ["nh_nodes:pebble"]            = true,
    ["nh_nodes:white_pebble"]      = true,
    ["nh_nodes:fallenstick"]       = true,
}
local FLAME_ENTITIES     = {
    ["nh_nodes:campfire_flame_entity"]  = true,
    ["nh_nodes:torch_flame_entity"]     = true,
    ["nh_nodes:palmstraw_flame_entity"] = true,
    ["nh_nodes:flame_entity"]           = true,
}
nodes                    = {}
local function detach_glow(player)
    -- busca e remove o entity de glow anterior
    for _, obj in ipairs(core.get_objects_inside_radius(player:get_pos(), 2)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "nh_nodes:glow_entity" then obj:remove() end
    end
end
-- ao trocar para litgrenade (no on_use do grenade):
local function attach_glow(player)
    -- remove glow anterior se existir
    detach_glow(player)
    local glow_obj = core.add_entity(player:get_pos(), "nh_nodes:glow_entity")
    if glow_obj then glow_obj:set_attach(player, "bone_RHand", { x = 1.25, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }) end
end
core.register_entity("nh_nodes:glow_entity", {
    initial_properties = {
        visual = "sprite",
        textures = { "spark_particle.png^[colorize:#FF8800:150" },
        visual_size = { x = 0.05, y = 0.05 },
        collisionbox = { 0, 0, 0, 0, 0, 0 },
        physical = false,
        static_save = false,
        glow = 14,
    },
    on_step = function(self, dtime)
        local rot = self.object:get_rotation()
        self.object:set_rotation({ x = rot.x, y = rot.y + 0.15, z = rot.z + 0.07, })
    end,
})

core.register_globalstep(function(dtime)
    for _, player in ipairs(core.get_connected_players()) do
        local name = player:get_player_name()
        local pos  = player:get_pos()
        -- remove o glow se o player tirar a litgrenade da mão sem arremessar
        local item = player:get_wielded_item():get_name()
        if item ~= "nh_nodes:litgrenade" then detach_glow(player) end
        -- PASSOS
        footstep_timer[name] = (footstep_timer[name] or 0) + dtime
        if footstep_timer[name] >= 0.4 then
            footstep_timer[name] = 0
            local controls = player:get_player_control()
            if controls.up or controls.down or controls.left or controls.right then
                local props       = player:get_properties()
                local cb          = props and props.collisionbox
                local feet_offset = cb and cb[2] or -1
                local below       = {
                    x = math.floor(pos.x + 0.5),
                    y = math.floor(pos.y + feet_offset),
                    z = math.floor(pos.z + 0.5),
                }
                local node        = core.get_node(below)
                local node_def    = core.registered_nodes[node.name]
                if node_def and node_def.sounds and node_def.sounds.footstep then
                    local snd = node_def.sounds.footstep
                    core.sound_play(snd.name,
                        { pos = pos, gain = snd.gain or 0.5, max_hear_distance = 10, })
                end
            end
        end

        -- ==== DANO DA LAVA ====
        lava_damage_timer[name] = (lava_damage_timer[name] or 0) + dtime
        if lava_damage_timer[name] >= 1.0 then
            lava_damage_timer[name] = 0
            local feet_node = core.get_node({ x = pos.x, y = pos.y, z = pos.z })
            local head_node = core.get_node({ x = pos.x, y = pos.y + 1, z = pos.z })
            if LAVA_NODES[feet_node.name] or LAVA_NODES[head_node.name] then player:set_hp(player:get_hp() - 22) end
        end

        -- ==== DANO DAS FOLHAS CAINDO ====
        local above_pos = { x = pos.x, y = pos.y + 2, z = pos.z }
        for _, obj in pairs(core.get_objects_inside_radius(above_pos, 1.5)) do
            local entity = obj:get_luaentity()
            if entity and entity.name == "__builtin:falling_node" then
                local node = entity.node
                if node and LEAF_TYPES[node.name] then
                    local velocity = obj:get_velocity()
                    if velocity and velocity.y < -2 then player:set_hp(player:get_hp() - 1) end
                end
            end
        end

        -- ==== TOCHA NA AGUA (troca torch2 por torch3) ====
        local head_pos  = { x = pos.x, y = pos.y + 1, z = pos.z }
        local head_node = core.get_node(head_pos)
        if core.get_item_group(head_node.name, "water") > 0 then
            local inv = player:get_inventory()
            for i = 1, inv:get_size("main") do
                local stack = inv:get_stack("main", i)
                if stack:get_name() == "nh_nodes:torch2" then
                    stack:set_name("nh_nodes:torch3")
                    inv:set_stack("main", i, stack)
                end
            end
        end

        -- ==== LUZ DA TOCHA / CRISTAL ====
        local wielded        = player:get_wielded_item()
        local light_pos_base = { x = pos.x, y = pos.y + 1, z = pos.z }
        if wielded:get_name() == "nh_nodes:torch2" or wielded:get_name() == "nh_nodes:redcrystal" or wielded:get_name() == "nh_nodes:litgrenade" then
            if not players_with_torch[name] then players_with_torch[name] = {} end
            -- Remove luz antiga
            if players_with_torch[name].pos then
                local old_pos  = players_with_torch[name].pos
                local old_node = core.get_node(old_pos)
                if old_node.name == "nh_nodes:torch_light" or old_node.name == "nh_nodes:crystal_light" then
                    core.remove_node(old_pos)
                end
            end
            -- Coloca nova luz invisivel
            local light_pos  = vector.round(light_pos_base)
            local light_node = core.get_node(light_pos)
            if light_node.name == "air" then
                core.set_node(light_pos, { name = "nh_nodes:torch_light" })
                players_with_torch[name].pos = light_pos
            elseif light_node.name == "nh_nodes:water" then
                core.set_node(light_pos, { name = "nh_nodes:crystal_light" })
                players_with_torch[name].pos = light_pos
            end
        else
            -- Remove luz se parou de segurar
            if players_with_torch[name] and players_with_torch[name].pos then
                local old_pos  = players_with_torch[name].pos
                local old_node = core.get_node(old_pos)
                if old_node.name == "nh_nodes:torch_light" or old_node.name == "nh_nodes:crystal_light" then
                    core.remove_node(old_pos)
                end
                players_with_torch[name] = nil
            end
        end
    end
end)

-- ==== DESTRUIÇÃO DE DROPS NA LAVA ====
-- Destrói qualquer item (drop) cuja face inferior toca um node de lava,
-- emitindo partículas de fogo da base ao topo do node antes de removê-lo.

local function spawn_lava_burn_particles(pos)
    -- 'pos' é a posição do node de lava (canto inferior-esquerdo = pos - 0.5)
    -- As partículas sobem da base (pos.y - 0.5) até o topo (pos.y + 0.5) do node.
    local base_y = pos.y - 0.5

    core.add_particlespawner({
        amount             = 24,  -- quantidade de partículas por emissão
        time               = 0.4, -- duração total do spawner (segundos)
        -- Origem: espalhada na face superior do node de lava
        minpos             = { x = pos.x - 0.4, y = base_y, z = pos.z - 0.4 },
        maxpos             = { x = pos.x + 0.4, y = base_y + 0.1, z = pos.z + 0.4 },
        -- Velocidade: sobem do fundo ao topo do node (1 node = 1 unidade)
        minvel             = { x = -0.15, y = 1.5, z = -0.15 },
        maxvel             = { x = 0.15, y = 3.0, z = 0.15 },
        -- Sem aceleração (fogo sobe naturalmente)
        minacc             = { x = 0, y = 0, z = 0 },
        maxacc             = { x = 0, y = 0, z = 0 },
        -- Vida das partículas: tempo suficiente para cruzar 1 node
        minexptime         = 0.2,
        maxexptime         = 0.5,
        -- Tamanho das fagulhas
        minsize            = 0.6,
        maxsize            = 1.4,
        texture            = "mobs_fire_particle.png",
        animation          = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.4, },
        glow               = 14,
        collisiondetection = false,
    })
end

local lava_drop_timer = 0
core.register_globalstep(function(dtime)
    lava_drop_timer = lava_drop_timer + dtime
    if lava_drop_timer < 0.5 then return end
    lava_drop_timer = 0

    for _, obj in ipairs(core.get_objects_in_area({ x = -30000, y = -30000, z = -30000 }, { x = 30000, y = 30000, z = 30000 })) do
        if not obj:is_player() then
            local entity = obj:get_luaentity()
            if entity and entity.name == "__builtin:item" then
                local pos = obj:get_pos()
                if pos then
                    -- Node abaixo do drop (parte inferior do item)
                    local below = {
                        x = math.floor(pos.x + 0.5),
                        y = math.floor(pos.y),
                        z = math.floor(pos.z + 0.5),
                    }
                    local node_below = core.get_node(below)
                    if LAVA_NODES[node_below.name] then
                        -- Emite partículas antes de remover
                        spawn_lava_burn_particles({
                            x = below.x,
                            y = below.y + 0.5, -- centro vertical do node
                            z = below.z,
                        })
                        obj:remove()
                    end
                end
            end
        end
    end
end)

-- ==== FLUTUAÇÃO E CORRENTEZA NAS ÁGUAS ====

local FLOATING_STUFF = {
    ["nh_nodes:oaktimber"]  = true,
    ["nh_nodes:oaklog"]     = true,
    ["nh_nodes:oakwood"]    = true,
    ["nh_nodes:stick"]      = true,
    ["nh_nodes:palmtimber"] = true,
    ["nh_nodes:palmlog"]    = true,
    ["nh_nodes:coconut"]    = true,
    ["nh_nodes:pinetimber"] = true,
    ["nh_nodes:pinelog"]    = true,
    ["nh_nodes:pinewood"]   = true,
    ["nh_nodes:pineraft"]   = true,
    ["nh_nodes:ice"]        = true,
    ["nh_nodes:ice2"]       = true,
    ["nh_nodes:orb_empty"]  = true,
}
local gravity = tonumber(core.settings:get("movement_gravity")) or 9.81
-- Calcula a direção da corrente da água.
local function get_liquid_flow_dir(pos)
    local node_here = core.get_node(pos)
    local p2_here = node_here.param2
    -- Só opera em flowing (source não tem corrente direcional)
    if not WATER_MIDNODES[node_here.name] then return nil end

    -- Bit 3 (0x08) do param2 = "liquid_fall": a água despenca verticalmente.
    -- Nesse caso a direção é para baixo, sem componente horizontal.
    local falling = (p2_here >= 8)
    local p2_level = p2_here % 8
    local flow = { x = 0, y = 0, z = 0 }
    if falling then flow.y = -1 end
    local dirs = { { x = 1, y = 0, z = 0 }, { x = -1, y = 0, z = 0 }, { x = 0, y = 0, z = 1 }, { x = 0, y = 0, z = -1 }, }
    for _, d in ipairs(dirs) do
        local nb_pos = { x = pos.x + d.x, y = pos.y, z = pos.z + d.z }
        local nb     = core.get_node(nb_pos)
        local nb_def = core.registered_nodes[nb.name]
        if not nb_def then goto next_dir end
        local is_flowing = WATER_MIDNODES[nb.name]
        -- Vizinho é source → nível máximo (param2 = 0 equivalente)
        -- Vizinho é flowing com param2 MENOR (= mais cheio) que o nosso
        -- Em ambos os casos a água VEM desse vizinho → flui para o OPOSTO
        local nb_level = nb.param2 % 8
        if (is_flowing and nb_level < p2_level) then
            -- Direção OPOSTA ao vizinho mais cheio
            flow.x = flow.x + d.x
            flow.z = flow.z + d.z
        end

        ::next_dir::
    end

    local hlen = math.sqrt(flow.x ^ 2 + flow.z ^ 2)
    if hlen > 0 then
        flow.x = flow.x / hlen
        flow.z = flow.z / hlen
    end

    if flow.x == 0 and flow.y == 0 and flow.z == 0 then return nil end
    return flow
end

local SPEED_CURRENT     = 2   -- velocidade horizontal da correnteza (m/s)
local SPEED_SINK        = 0.5 -- afundamento de drops normais (m/s)
local SPEED_FLOAT       = 0.3 -- subida de itens flutuantes (m/s)
local SPEED_FALL        = 2.0 -- queda em correnteza vertical (m/s)

-- Rastreia se o drop estava na água no tick anterior (para restaurar aceleração
-- de gravidade uma única vez ao sair, sem chamar set_acceleration toda tick)
local drop_was_in_water = {}
local drop_last_flow    = {} -- última direção de corrente detectada por drop

core.register_globalstep(function(dtime)
    for _, obj in ipairs(core.get_objects_in_area({ x = -30000, y = -30000, z = -30000 }, { x = 30000, y = 30000, z = 30000 })) do
        if obj:is_player() then goto drop_next end
        local entity = obj:get_luaentity()
        if not (entity and entity.name == "__builtin:item") then goto drop_next end
        local pos = obj:get_pos()
        if not pos then goto drop_next end
        local ipos     = {
            x = math.floor(pos.x + 0.5),
            y = math.floor(pos.y + 0.5),
            z = math.floor(pos.z + 0.5),
        }
        local node     = core.get_node(ipos)
        local in_full  = WATER_FULLNODES[node.name]
        local in_mid   = WATER_MIDNODES[node.name]
        local in_water = in_full or in_mid
        local uid      = tostring(obj)
        if not in_water then
            -- Saiu da água: restaura gravidade (uma vez só)
            if drop_was_in_water[uid] then
                drop_was_in_water[uid] = nil
                drop_last_flow[uid] = nil
                obj:set_acceleration({ x = 0, y = -gravity, z = 0 })
            end
            goto drop_next
        end
        -- Dentro da água
        -- Zera aceleração para que set_velocity abaixo seja o movimento final
        if not drop_was_in_water[uid] then
            drop_was_in_water[uid] = true
        end
        obj:set_acceleration({ x = 0, y = 0, z = 0 })

        local item_name = entity.itemstring or (entity.item and ItemStack(entity.item):get_name()) or ""
        local is_floating = FLOATING_STUFF[item_name]

        if in_full and not in_mid then
            -- ── Água source (parada)
            obj:set_velocity({ x = 0, y = is_floating and SPEED_FLOAT or -SPEED_SINK, z = 0, })
        else
            -- ── Água flowing (corrente)
            local flow = get_liquid_flow_dir(ipos)
            if flow then
                -- Guarda direção para usar no último node (onde flow vira nil)
                drop_last_flow[uid] = flow
            else
                -- Último node da corrente: vizinho à frente é ar, flow==nil.
                -- Usa a última direção conhecida para continuar o movimento.
                flow = drop_last_flow[uid]
            end
            if flow then
                obj:set_velocity({
                    x = flow.x * SPEED_CURRENT,
                    y = (flow.y < 0) and -SPEED_FALL or (is_floating and SPEED_FLOAT or -SPEED_SINK),
                    z = flow.z * SPEED_CURRENT,
                })
            else
                obj:set_velocity({ x = 0, y = is_floating and SPEED_FLOAT or -SPEED_SINK, z = 0, })
            end
        end
        ::drop_next::
    end
end)
local drop_rot_timer = 0
core.after(0, function()
    local item_ent = core.registered_entities["__builtin:item"]
    if not item_ent then return end
    -- Patch no set_item: é aqui que o automatic_rotate é definido pelo builtin
    local original_set_item = item_ent.set_item
    item_ent.set_item = function(self, item)
        original_set_item(self, item)
        -- Sobrescreve DEPOIS que o builtin definiu as propriedades
        self.object:set_properties({ automatic_rotate = 0 })
        self.object:set_rotation({ x = 0, y = 0, z = 0 })
    end

    local original_on_step = item_ent.on_step
    item_ent.on_step = function(self, dtime, moveresult)
        if original_on_step then original_on_step(self, dtime, moveresult) end
        local tremor = (math.floor(drop_rot_timer * 16) % 2 == 0) and math.rad(1) or math.rad(-1)
        self.object:set_rotation({ x = math.rad(45) + tremor, y = tremor, z = math.rad(45) + tremor, })
    end
end)
core.register_globalstep(function(dtime) drop_rot_timer = drop_rot_timer + dtime end)

-- Limpeza unificada ao deslogar
core.register_on_leaveplayer(function(player)
    local name              = player:get_player_name()
    footstep_timer[name]    = nil
    lava_damage_timer[name] = nil
    if players_with_torch[name] and players_with_torch[name].pos then
        local old_pos  = players_with_torch[name].pos
        local old_node = core.get_node(old_pos)
        if old_node.name == "nh_nodes:torch_light" or old_node.name == "nh_nodes:crystal_light" then
            core.remove_node(old_pos)
        end
        players_with_torch[name] = nil
    end
end)
-- Receitas
-- --------------------------------------------------
-- RECEITAS BASICAS (2x2)
-- Usada por: Nodes do chão
-- Inclui crafts básicos
--[[
local function craft_ingredients(ingredients, output)
    local formatted_ingredients = {}

    for k, v in pairs(ingredients) do
        local name, count
        if type(k) == "number" then
            -- Se for lista simples: {"stick", "palmstraw"} -> quantidade é 1
            name = v
            count = 1
        else
            -- Se for par chave-valor: {pebble = 2}
            name = k
            count = v
        end

        -- Garante o prefixo nh_nodes: se já não o tiver
        if not name:find(":") then
            name = "nh_nodes:" .. name
        end

        formatted_ingredients[name] = count
    end

    -- Garante o prefixo na saída também
    if not output:find(":") then
        output = "nh_nodes:" .. output
    end

    return { ingredients = formatted_ingredients, output = output }
end
]] --

recipes_floor = {
    { ingredients = { ["nh_nodes:pebble"] = 2 },                                                              output = "nh_nodes:chippedstone" },
    { ingredients = { ["nh_nodes:pebble_item"] = 2 },                                                         output = "nh_nodes:chippedstone" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:chippedstone"] = 1 },                               output = "nh_nodes:stoneaxehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stoneaxehead"] = 1 },                               output = "nh_nodes:stonepickaxehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stonepickaxehead"] = 1 },                           output = "nh_nodes:stonehoehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stonehoehead"] = 1 },                               output = "nh_nodes:stoneadzehead" },
    { ingredients = { ["nh_nodes:oakdowel"] = 1, ["nh_nodes:oakboard"] = 1 },                                 output = "nh_nodes:rowing" },
    { ingredients = { ["nh_nodes:stoneaxehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },     output = "nh_nodes:stoneaxe" },
    { ingredients = { ["nh_nodes:stonepickaxehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 }, output = "nh_nodes:stonepickaxe" },
    { ingredients = { ["nh_nodes:stonehoehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },     output = "nh_nodes:stonehoe" },
    { ingredients = { ["nh_nodes:stoneadzehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },    output = "nh_nodes:stoneadze" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:obsidianpebble"] = 1 },                             output = "nh_nodes:obsidianblade" },
    { ingredients = { ["nh_nodes:chippedstone"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },    output = "nh_nodes:chippedstoneknife" },
    { ingredients = { ["nh_nodes:obsidianblade"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },   output = "nh_nodes:obsidianknife" },
    { ingredients = { ["nh_nodes:pebble"] = 8 },                                                              output = "nh_nodes:cobblestone" },
    { ingredients = { ["nh_nodes:pebble_item"] = 8 },                                                         output = "nh_nodes:cobblestone" },
    { ingredients = { ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },                                   output = "nh_nodes:campfiretinder" },
    {
        ingredients = { ["nh_nodes:oaklog"] = 1 },
        output = "nh_nodes:oakwood",
        required_tool = "nh_nodes:stoneadze", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:pinelog"] = 1 },
        output = "nh_nodes:pinewood",
        required_tool = "nh_nodes:stoneadze", -- ← só funciona com isso no slot
    },
    { ingredients = { ["nh_nodes:palmleaf"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:oakresin"] = 1, ["nh_nodes:grassleaves"] = 1 }, output = "nh_nodes:torch" },
    { ingredients = { ["nh_nodes:oakwood"] = 1 },                                                                                   output = "nh_nodes:oakboard 8" },
    { ingredients = { ["nh_nodes:oakwood"] = 2 },                                                                                   output = "nh_nodes:oakplank 4" },
    { ingredients = { ["nh_nodes:oakboard"] = 1 },                                                                                  output = "nh_nodes:oakdowel 8" },
    { ingredients = { ["nh_nodes:oakdowel"] = 2, ["nh_nodes:oakboard"] = 2 },                                                       output = "nh_nodes:craft_table" },
    { ingredients = { ["nh_nodes:inksac"] = 1, ["nh_nodes:bottle"] = 1 },                                                           output = "nh_nodes:inkbottle" },
    { ingredients = { ["nh_items:writedpage"] = 1, ["nh_nodes:bottle"] = 1 },                                                       output = "nh_nodes:messagebottle" },
}
-- RECEITAS DA BANCADA DE PRODUÇÃO (2x2x2)
-- Usada por: craft_table
-- Inclui tudo do floor + itens avançados (espada, baú, porta, piões...)
recipes_table = {
    { ingredients = { ["nh_nodes:pebble"] = 2 },                                    output = "nh_nodes:chippedstone" },
    { ingredients = { ["nh_nodes:pebble_item"] = 2 },                               output = "nh_nodes:chippedstone" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:chippedstone"] = 1 },     output = "nh_nodes:stoneaxehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stoneaxehead"] = 1 },     output = "nh_nodes:stonepickaxehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stonepickaxehead"] = 1 }, output = "nh_nodes:stonehoehead" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:stonehoehead"] = 1 },     output = "nh_nodes:stoneadzehead" },
    { ingredients = { ["nh_nodes:oakdowel"] = 1, ["nh_nodes:oakboard"] = 1 },       output = "nh_nodes:rowing" },
    {
        ingredients = { ["nh_nodes:pinelog"] = 6, ["nh_nodes:palmstraw"] = 2 },
        output = "nh_nodes:pineraft",
        required_tool = "nh_nodes:palmstraw", -- ← só funciona com isso no slot
    },
    { ingredients = { ["nh_nodes:stoneaxehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },     output = "nh_nodes:stoneaxe" },
    { ingredients = { ["nh_nodes:stonepickaxehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 }, output = "nh_nodes:stonepickaxe" },
    { ingredients = { ["nh_nodes:stonehoehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },     output = "nh_nodes:stonehoe" },
    { ingredients = { ["nh_nodes:stoneadzehead"] = 1, ["nh_nodes:limb"] = 1, ["nh_nodes:palmstraw"] = 1 },    output = "nh_nodes:stoneadze" },
    { ingredients = { ["nh_nodes:pebble"] = 1, ["nh_nodes:obsidianpebble"] = 1 },                             output = "nh_nodes:obsidianblade" },
    { ingredients = { ["nh_nodes:chippedstone"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },    output = "nh_nodes:chippedstoneknife" },
    { ingredients = { ["nh_nodes:obsidianblade"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },   output = "nh_nodes:obsidianknife" },
    { ingredients = { ["nh_nodes:oakboard"] = 1, ["nh_nodes:obsidianblade"] = 7 },                            output = "nh_nodes:obsidiansword" },
    { ingredients = { ["nh_nodes:pebble"] = 8 },                                                              output = "nh_nodes:cobblestone" },
    { ingredients = { ["nh_nodes:pebble_item"] = 8 },                                                         output = "nh_nodes:cobblestone" },
    { ingredients = { ["nh_nodes:stick"] = 1, ["nh_nodes:palmstraw"] = 1 },                                   output = "nh_nodes:campfiretinder" },
    {
        ingredients = { ["nh_nodes:oaklog"] = 1 },
        output = "nh_nodes:oakwood",
        required_tool = "nh_nodes:stoneadze", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:pinelog"] = 1 },
        output = "nh_nodes:pinewood",
        required_tool = "nh_nodes:stoneadze", -- ← só funciona com isso no slot
    },
    { ingredients = { ["nh_nodes:palmleaf"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:oakresin"] = 1, ["nh_nodes:grassleaves"] = 1 }, output = "nh_nodes:torch" },
    { ingredients = { ["nh_nodes:oakwood"] = 1 },                                                                                   output = "nh_nodes:oakboard 8" },
    { ingredients = { ["nh_nodes:oakwood"] = 2 },                                                                                   output = "nh_nodes:oakplank 4" },
    { ingredients = { ["nh_nodes:oakboard"] = 1 },                                                                                  output = "nh_nodes:oakdowel 8" },
    { ingredients = { ["nh_nodes:oakdowel"] = 2, ["nh_nodes:oakboard"] = 2 },                                                       output = "nh_nodes:craft_table" },
    { ingredients = { ["nh_nodes:inksac"] = 1, ["nh_nodes:bottle"] = 1 },                                                           output = "nh_nodes:inkbottle" },
    { ingredients = { ["nh_items:writedpage"] = 1, ["nh_nodes:bottle"] = 1 },                                                       output = "nh_nodes:messagebottle" },
    { ingredients = { ["nh_nodes:oakboard"] = 6 },                                                                                  output = "nh_nodes:oakchest" },
    { ingredients = { ["nh_nodes:cowfur"] = 2, ["nh_nodes:oakdowel"] = 1 },                                                         output = "nh_nodes:belt" },
    { ingredients = { ["nh_nodes:cowfur"] = 2, ["nh_nodes:oakchest"] = 1 },                                                         output = "nh_nodes:backchest" },
    { ingredients = { ["nh_nodes:cowfur"] = 5 },                                                                                    output = "nh_nodes:likeglove" },
    { ingredients = { ["nh_nodes:cowfur"] = 6 },                                                                                    output = "nh_nodes:pointglove" },
    { ingredients = { ["nh_nodes:oakboard"] = 3, ["nh_nodes:oakdowel"] = 2, ["nh_nodes:pebble"] = 2 },                              output = "nh_nodes:oakdoor_closed" },
    { ingredients = { ["nh_nodes:oaklog"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:white_pebble"] = 1 },                             output = "nh_nodes:spinningtop" },
    { ingredients = { ["nh_nodes:palmlog"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:white_pebble"] = 1 },                            output = "nh_nodes:spinningtop2" },
    { ingredients = { ["nh_nodes:pinelog"] = 1, ["nh_nodes:stick"] = 1, ["nh_nodes:white_pebble"] = 1 },                            output = "nh_nodes:spinningtop3" },
}
-- RECEITAS DA FOGUEIRA (3x3)
-- Usada por: campfire
-- Inclui: alimentos cozidos
recipes_campfire = {
    { ingredients = { ["nh_nodes:chickenegg"] = 1 }, output = "nh_nodes:friedchickenegg" },
    { ingredients = { ["nh_nodes:rawchicken"] = 1 }, output = "nh_nodes:roastchicken" },
    { ingredients = { ["nh_nodes:rawtuna"] = 1 },    output = "nh_nodes:roasttuna" },
    { ingredients = { ["nh_nodes:rawbeef"] = 1 },    output = "nh_nodes:roastbeef" },
}
-- RECEITAS DA FORNALHA (3x3)
-- Usada por: furnace
-- Inclui: carvão, alimentos cozidos, fundição de metais, vidro
recipes_furnace = {
    {
        ingredients = { ["nh_nodes:oaklog"] = 9 },
        output = "nh_nodes:charcoal 9",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:pinelog"] = 9 },
        output = "nh_nodes:charcoal 9",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:palmlog"] = 9 },
        output = "nh_nodes:charcoal2 9",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:chickenegg"] = 1 },
        output = "nh_nodes:friedchickenegg",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:rawchicken"] = 1 },
        output = "nh_nodes:roastchicken",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:rawtuna"] = 1 },
        output = "nh_nodes:roasttuna",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:rawbeef"] = 1 },
        output = "nh_nodes:roastbeef",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:coppernugget"] = 3 },
        output = "nh_nodes:copperingot",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:copperingot"] = 3 },
        output = "nh_nodes:copperhelmet",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:copperingot"] = 8 },
        output = "nh_nodes:copperchestplate",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:tinnugget"] = 3 },
        output = "nh_nodes:tiningot",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:ironnugget"] = 3 },
        output = "nh_nodes:ironingot",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:ironingot"] = 3, ["nh_nodes:coal"] = 1, ["nh_items:page"] = 1 },
        output = "nh_nodes:grenade",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:sand"] = 8 },
        output = "nh_nodes:glass 8",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:glass"] = 3, ["nh_nodes:oakwood"] = 1 },
        output = "nh_nodes:bottle 6",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    {
        ingredients = { ["nh_nodes:glass"] = 4, ["nh_nodes:chromiumingot"] = 1 },
        output = "nh_nodes:mirror 4",
        required_tool = "nh_nodes:coalnugget", -- ← só funciona com isso no slot
    },
    --{
    --    ingredients = {["nh_nodes:ironingot"] = 3},
    --    output = "nh_nodes:stellingot 3"
    --    required_tool = "nh_nodes:coal",   -- ← só funciona com isso no slot
    --},
}

-- SISTEMA GENÉRICO DE CRAFTING
local craft_stations = {}
-- Registra a entidade de display (compartilhada por todas as estações)
core.register_entity("nh_nodes:display_item", {
    initial_properties = {
        visual = "wielditem",
        visual_size = { x = 0.25, y = 0.25 },
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = true, -- Salva entre sessões
        is_visible = true,
    },
    itemstring = "",
    station_pos = nil,
    on_activate = function(self, staticdata)
        if staticdata and staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data then
                self.itemstring = data.itemstring or ""
                self.station_pos = data.station_pos
                self.object:set_properties({ wield_item = self.itemstring })
            end
        end
    end,

    get_staticdata = function(self)
        return core.serialize({ itemstring = self.itemstring, station_pos = self.station_pos })
    end,

    on_step = function(self, dtime)
        self.object:set_velocity({ x = 0, y = 0, z = 0 })
        self.object:set_acceleration({ x = 0, y = 0, z = 0 })
        local props = self.object:get_properties()
        if props.glow and props.glow > 0 then
            local rot = self.object:get_rotation()
            self.object:set_rotation({ x = 0, y = rot.y + 0.005, z = 0 })
        end
    end,
})
-- FUNÇÕES AUXILIARES
-- Remove apenas entidades desta estação específica
local function remove_item_entities(pos)
    local objects = core.get_objects_inside_radius(pos, 2)
    for _, obj in pairs(objects) do
        local entity = obj:get_luaentity()
        if entity and entity.name == "nh_nodes:display_item" then
            -- Verifica se a entidade pertence a ESTA estação
            if entity.station_pos and vector.equals(entity.station_pos, pos) then obj:remove() end
        end
    end
end

local function update_item_entities(pos, config)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()

    -- Verifica se o inventário existe antes de continuar
    if not inv or inv:get_size("craft") == 0 then
        return
    end

    remove_item_entities(pos)

    local craft_list = inv:get_list("craft")
    local output_list = inv:get_list("output")

    -- Proteção adicional
    if not craft_list or not output_list then
        return
    end

    -- Cria entidades para os slots de craft
    for i = 1, config.grid_size do
        local stack = craft_list[i]
        if not stack:is_empty() then
            local item_pos = vector.add(pos, config.positions[i])
            local obj = core.add_entity(item_pos, "nh_nodes:display_item")

            if obj then
                local entity = obj:get_luaentity()
                if entity then
                    entity.itemstring = stack:get_name()
                    entity.station_pos = pos -- Marca a estação dona
                    obj:set_properties({ wield_item = stack:get_name() })
                end
            end
        end
    end

    -- Cria entidade para o resultado
    local output_stack = output_list[1]
    if output_stack and not output_stack:is_empty() then
        local output_pos = vector.add(pos, config.output_position)
        local obj = core.add_entity(output_pos, "nh_nodes:display_item")

        if obj then
            local entity = obj:get_luaentity()
            if entity then
                entity.itemstring = output_stack:get_name()
                entity.station_pos = pos -- Marca a estação dona
                obj:set_properties({
                    wield_item = output_stack:get_name(),
                    visual_size = { x = 0.35, y = 0.35 },
                    glow = 1,
                })
            end
        end
    end
end

local function check_recipe(inv, recipe)
    local craft_list = inv:get_list("craft")
    local counts = {}

    -- Conta os itens no grid
    for i = 1, #craft_list do
        local stack = craft_list[i]
        if not stack:is_empty() then
            local name = stack:get_name()
            counts[name] = (counts[name] or 0) + 1
        end
    end

    -- Verifica se a receita corresponde
    for item, required_count in pairs(recipe.ingredients) do
        if (counts[item] or 0) < required_count then
            return false
        end
    end

    -- Verifica se não há itens extras (receita exata)
    local total_required = 0
    for _, count in pairs(recipe.ingredients) do
        total_required = total_required + count
    end

    local total_in_grid = 0
    for _, count in pairs(counts) do
        total_in_grid = total_in_grid + count
    end

    return total_in_grid == total_required
end

local function check_and_craft(pos, config)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()

    -- Lê a ferramenta no slot extra
    local tool_stack = inv:get_stack("tool", 1)
    local tool_name = tool_stack:get_name() -- "" se vazio

    for _, recipe in ipairs(config.recipes) do
        -- Se a receita exige ferramenta, verifica
        if recipe.required_tool then
            if tool_name ~= recipe.required_tool then
                goto continue -- pula esta receita
            end
        end

        if check_recipe(inv, recipe) then
            inv:set_stack("output", 1, ItemStack(recipe.output))
            core.after(0.01, function()
                update_item_entities(pos, config)
            end)
            return
        end

        ::continue::
    end

    inv:set_stack("output", 1, ItemStack(""))
    core.after(0.01, function()
        update_item_entities(pos, config)
    end)
end

local function consume_craft_materials(pos)
    local meta = core.get_meta(pos)
    local inv = meta:get_inventory()

    for i = 1, inv:get_size("craft") do
        local stack = inv:get_stack("craft", i)
        if not stack:is_empty() then
            stack:take_item(1)
            inv:set_stack("craft", i, stack)
        end
    end
end

local function show_craft_grid(player, pos, config)
    local player_name = player:get_player_name()
    local pos_string = core.pos_to_string(pos)

    local formspec = "formspec_version[4]" ..
        "size[10.7,9.7]" ..
        "label[0.5,0.5;" .. config.title .. "]"

    local y_offset = 1
    for _, layer in ipairs(config.layers) do
        formspec = formspec ..
            "label[" .. layer.x .. "," .. y_offset .. ";" .. layer.name .. "]" ..
            "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";craft;" ..
            layer.x ..
            "," .. (y_offset + 0.5) .. ";" .. layer.width .. "," .. layer.height .. ";" .. layer.start_index .. "]"
    end

    -- Posição do slot de ferramenta: usa a config se definida, senão calcula automaticamente
    local tool_x, tool_y
    if config.tool_slot_pos then
        tool_x = config.tool_slot_pos.x
        tool_y = config.tool_slot_pos.y
    else
        local grid_top = y_offset + 0.5
        local max_height = 0
        for _, layer in ipairs(config.layers) do
            if layer.height > max_height then max_height = layer.height end
        end
        tool_x = 3.3
        tool_y = grid_top + (max_height / 2) - 0.5
    end

    formspec = formspec ..
        "label[" .. tool_x .. "," .. tool_y .. ";" .. S("Tool") .. "]" ..
        "list[nodemeta:" ..
        pos.x .. "," .. pos.y .. "," .. pos.z .. ";tool;" .. tool_x .. "," .. (tool_y + 0.5) .. ";1,1;]"

    formspec = formspec ..
        "label[7,1.5;" .. S("Produces") .. "]" ..
        "list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";output;7,2;1,1;]" ..
        "button[7,3.2;1,0.8;craft_one;" .. S("Single") .. "]" ..
        "button[7,4.1;1,0.8;craft_all;" .. S("All") .. "]" ..
        "list[current_player;main;0.5,5.5;8,2;8]" ..
        "list[current_player;main;0.5,8.1;8,1;]" ..
        "listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";craft]" ..
        "listring[current_player;main]"

    core.show_formspec(player_name, config.node_name .. "_" .. pos_string, formspec)
end
-- ========================================
-- FUNÇÃO PRINCIPAL DE REGISTRO
-- ========================================

function register_craft_station(node_name, config)
    -- Validação da configuração
    assert(config.description, "Config precisa de 'description'")
    assert(config.tiles, "Config precisa de 'tiles'")
    assert(config.grid_size, "Config precisa de 'grid_size'")
    assert(config.positions, "Config precisa de 'positions'")
    assert(config.output_position, "Config precisa de 'output_position'")
    assert(config.recipes, "Config precisa de 'recipes'")
    assert(config.layers, "Config precisa de 'layers'")
    assert(config.title, "Config precisa de 'title'")

    -- Armazena a configuração
    config.node_name = node_name
    craft_stations[node_name] = config

    -- Prepara as propriedades do node
    local node_def = {
        description = config.description,
        tiles = config.tiles,
        groups = config.groups or { choppy = 2, oddly_breakable_by_hand = 1 },
        paramtype2 = "facedir",
        sounds = config.sounds,
        -- Se tiver mesh, usa drawtype mesh, senão usa normal
        drawtype = config.mesh and "mesh" or "normal",
    }

    -- Adiciona mesh apenas se fornecido
    if config.mesh then
        node_def.mesh = config.mesh
    end

    -- Adiciona propriedades extras opcionais
    if config.drop then
        node_def.drop = config.drop
    end
    if config.sunlight_propagates ~= nil then
        node_def.sunlight_propagates = config.sunlight_propagates
    end
    if config.paramtype then
        node_def.paramtype = config.paramtype
    end
    if config.collision_box then
        node_def.collision_box = config.collision_box
    end
    if config.selection_box then
        node_def.selection_box = config.selection_box
    end

    -- Para blocos de craft segurados:
    if config.wielded_bone_position then
        node_def.wielded_bone_position = config.wielded_bone_position
    end
    if config.offhand_bone_position then
        node_def.offhand_bone_position = config.offhand_bone_position
    end
    if config.wielded_visual_size then
        node_def.wielded_visual_size = config.wielded_visual_size
    end


    -- Função auxiliar para garantir que o inventário existe
    local function ensure_inventory(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        if inv:get_size("craft") == 0 then
            inv:set_size("craft", config.grid_size)
        end
        if inv:get_size("output") == 0 then
            inv:set_size("output", 1)
        end
        if inv:get_size("tool") == 0 then
            inv:set_size("tool", 1)
        end
    end


    -- ========================================
    -- PRESERVA CALLBACKS CUSTOMIZADOS
    -- ========================================
    -- Salva callbacks fornecidos no config
    local custom_on_construct = config.on_construct
    local custom_on_timer = config.on_timer

    -- MODIFICA on_construct para executar AMBOS
    local original_on_construct = node_def.on_construct
    node_def.on_construct = function(pos)
        ensure_inventory(pos)

        -- ✅ EXECUTA O CALLBACK CUSTOMIZADO PRIMEIRO
        if custom_on_construct then
            custom_on_construct(pos)
        end

        -- Depois executa o padrão do crafting
        core.after(0.5, function()
            local node = core.get_node(pos)
            if node and node.name == node_name then
                update_item_entities(pos, config)
            end
        end)
    end

    -- MODIFICA on_timer para executar AMBOS
    node_def.on_timer = function(pos, elapsed)
        -- ✅ EXECUTA O CALLBACK CUSTOMIZADO PRIMEIRO
        if custom_on_timer then
            local result = custom_on_timer(pos, elapsed)
            -- Se retornou false, para aqui
            if result == false then
                return false
            end
        end

        -- Se não tem callback customizado ou retornou true, continua normal
        return true
    end

    -- Adiciona callbacks do crafting (alterado para não dar recursão [crash] com o mobsredo)
    node_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local controls = clicker:get_player_control()

        if controls.aux1 then
            ensure_inventory(pos)
            show_craft_grid(clicker, pos, config)
            return itemstack
        end

        if itemstack and not itemstack:is_empty() then
            local item_def = core.registered_items[itemstack:get_name()]



            if item_def and item_def.type == "node" then
                local result = core.item_place_node(itemstack, clicker, pointed_thing)
                -- Toca o som de place manualmente
                if config.sounds and config.sounds.place then
                    core.sound_play(config.sounds.place.name, {
                        pos = pointed_thing.above,
                        gain = config.sounds.place.gain or 1.0,
                        max_hear_distance = 16,
                    })
                end
                return result
            end

            -- Para spawn eggs e outros itens com on_place,
            -- chama on_place mas com under substituído por "air"
            -- para evitar recursão
            if item_def and item_def.on_place then
                local safe_pointed = {
                    type = pointed_thing.type,
                    under = pointed_thing.above, -- usa "above" como "under" falso
                    above = pointed_thing.above,
                }
                return item_def.on_place(itemstack, clicker, safe_pointed)
            end
        end

        -- Mão vazia e sem (E/Aux1): mostra dica
        if itemstack:is_empty() then
            core.chat_send_player(
                clicker:get_player_name(),
                S(
                    "I need to observe (hold 'E' or 'Aux1') and reach the ground (click 'place' with empty hands) to try to craft something...")
            )
        end

        return itemstack
    end


    node_def.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "output" then return 0 end
        return stack:get_count()
    end

    node_def.allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if to_list == "output" then return 0 end
        return count
    end

    node_def.on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "craft" or listname == "tool" then
            check_and_craft(pos, config)
        end
    end

    node_def.on_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "tool" then
            check_and_craft(pos, config)
        elseif listname == "craft" then
            check_and_craft(pos, config)
        elseif listname == "output" then
            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            local player_inv = player:get_inventory()

            -- Consome materiais do primeiro craft
            consume_craft_materials(pos)

            -- Tenta craftar em loop (funciona tanto para click normal quanto shift)
            local max_crafts = 64
            local crafted = 1

            -- Pequeno delay para garantir que o primeiro item já foi movido
            core.after(0.05, function()
                while crafted < max_crafts do
                    local recipe_found = false

                    -- Verifica se ainda há receita válida
                    for _, recipe in ipairs(config.recipes) do
                        if check_recipe(inv, recipe) then
                            recipe_found = true

                            -- Verifica se o jogador tem espaço antes de craftar
                            local result_stack = ItemStack(recipe.output)

                            -- Tenta adicionar ao inventário do jogador
                            local leftover = player_inv:add_item("main", result_stack)

                            -- Se conseguiu adicionar completamente
                            if leftover:is_empty() then
                                consume_craft_materials(pos)
                                crafted = crafted + 1
                            else
                                -- Inventário cheio ou sem espaço suficiente
                                -- Coloca de volta no output se sobrou algo
                                if not leftover:is_empty() then
                                    inv:set_stack("output", 1, leftover)
                                end
                                break
                            end

                            break -- sai do loop de receitas
                        end
                    end

                    -- Se não encontrou receita válida, para
                    if not recipe_found then
                        break
                    end
                end

                -- Atualiza o crafting após o loop
                check_and_craft(pos, config)
            end)
        end
    end

    node_def.on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if from_list == "craft" or to_list == "craft" then
            check_and_craft(pos, config)
        end
    end

    node_def.on_destruct = function(pos)
        -- Dropa os itens ANTES de destruir
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        -- Dropa todos os itens do grid de craft
        for i = 1, inv:get_size("craft") do
            local stack = inv:get_stack("craft", i)
            if not stack:is_empty() then
                core.add_item(pos, stack)
            end
        end

        local tool_stack = inv:get_stack("tool", 1)
        if not tool_stack:is_empty() then
            core.add_item(pos, tool_stack)
        end

        -- Dropa o item do output também (se houver)
        local output_stack = inv:get_stack("output", 1)
        if not output_stack:is_empty() then
            core.add_item(pos, output_stack)
        end

        -- Remove as entidades de display
        remove_item_entities(pos)
    end

    -- Registra o node com todas as propriedades
    core.register_node(node_name, node_def)
end

core.register_on_player_receive_fields(function(player, formname, fields)
    -- Verifica se é um formspec de craft station
    for node_name, config in pairs(craft_stations) do
        if formname:find(node_name) then
            -- Extrai a posição do formname
            local pos_string = formname:match("_(.+)$")
            if not pos_string then return end

            local pos = core.string_to_pos(pos_string)
            if not pos then return end

            local meta = core.get_meta(pos)
            local inv = meta:get_inventory()
            local player_inv = player:get_inventory()

            if fields.craft_one then
                -- Pega apenas 1
                local output_stack = inv:get_stack("output", 1)
                if not output_stack:is_empty() then
                    local leftover = player_inv:add_item("main", output_stack)
                    if leftover:is_empty() then
                        consume_craft_materials(pos)
                        check_and_craft(pos, config)
                    end
                end
            elseif fields.craft_all then
                -- Pega tudo que conseguir
                local max_crafts = 64
                local crafted = 0

                while crafted < max_crafts do
                    local output_stack = inv:get_stack("output", 1)
                    if output_stack:is_empty() then break end

                    local leftover = player_inv:add_item("main", output_stack)
                    if leftover:is_empty() then
                        consume_craft_materials(pos)
                        check_and_craft(pos, config)
                        crafted = crafted + 1
                    else
                        break
                    end
                end
            end

            return true
        end
    end
end)

---------------------------
-- FUNÇÃO AUXILIAR PARA DANO CONSECUTIVO
---------------------------
local function apply_poison_damage(player, damage_per_tick, total_damage, interval)
    local ticks = math.ceil(total_damage / damage_per_tick)
    local current_tick = 0

    local function apply_tick()
        if not player or not player:is_player() then
            return
        end

        current_tick = current_tick + 1

        -- Aplica o dano na VIDA (HP), não na fome
        local damage_to_apply = math.min(damage_per_tick, total_damage - (current_tick - 1) * damage_per_tick)
        local current_hp = player:get_hp()
        player:set_hp(current_hp - damage_to_apply)

        -- Efeito visual/sonoro de dano (opcional)
        minetest.sound_play("player_damage", {
            to_player = player:get_player_name(),
            gain = 0.5,
        }, true)

        -- Se ainda há dano a aplicar, agenda o próximo tick
        if current_tick < ticks then
            minetest.after(interval, apply_tick)
        end
    end

    -- Inicia o primeiro tick
    apply_tick()
end


core.register_node("nh_nodes:dirt_ramp", {
    description         = "Dirt Ramp",
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_slope.obj",
    tiles               = { "dirt_slope.png" },
    -- Dentro do register_node:
    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
})

core.register_node("nh_nodes:dirt_corner", {
    description         = S("Dirt Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_vertix.obj",
    tiles               = { "dirt_slope.png" },

    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2

        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2
        },
    },
})

core.register_node("nh_nodes:dirt_insidecorner", {
    description         = S("Dirt Inside Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grassinsidecorner.obj",
    tiles               = { "dirt_slope.png" },

    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",

    sounds              = { footstep = { name = "punchtimber3", gain = 0.5 }, dug = { name = "punchtimber3", gain = 0.5 }, dig = { name = "punchtimber3", gain = 0.5 }, place = { name = "punchtimber3", gain = 0.5 }, },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod
    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, -- Base completa (metade inferior)
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 1: faixa traseira (Z-)
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 }, -- Topo braço 1: faixa traseira (Z-)
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 2: faixa lateral (X-)
        },
    },
    selection_box       = { type = "fixed", fixed = { { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, { -0.5, 0.0, 0.0, 0.0, 0.5, 0.5 }, { -0.5, 0.0, -0.5, 0.0, 0.5, 0.0 }, { 0.5, 0.0, 0.0, 0.0, 0.5, 0.5 }, }, },
})


register_craft_station("nh_nodes:dirt", {
    description = S("Dirt"),
    tiles = { "terra.png" },
    groups = { crumbly = 2 },
    sounds = { footstep = { name = "punchtimber3", gain = 0.5 }, dug = { name = "punchtimber3", gain = 0.5 }, dig = { name = "punchtimber3", gain = 0.5 }, place = { name = "punchtimber3", gain = 0.5 }, },
    -- Mecânica opcional: grama morrer na sombra
    --paramtype = "light",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    on_construct = function(pos)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        local light = core.get_node_light(above)
        --core.chat_send_all("🟤 DIRT construído em " .. core.pos_to_string(pos))
        -- core.chat_send_all("   Bloco acima: " .. node_above)
        if light and light > 4 then
            core.get_node_timer(pos):start(math.random(30, 60))
            --[[
            core.chat_send_all("   ✅ Timer iniciado!")
        else
            -- core.chat_send_all("   ❌ Timer NÃO iniciado (tem bloco escurecendo em cima)")
            ]] --
        end
    end,
    on_timer = function(pos, elapsed)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        local light = core.get_node_light(above)
        -- Bloco líquido ou lava acima impede virar grama
        local blocked_nodes = {
            ["nh_nodes:water"] = true,
            ["nh_nodes:water_flowing"] = true,
            ["nh_nodes:water2"] = true,
            ["nh_nodes:water2_flowing"] = true,
            ["nh_nodes:lava"] = true,
            ["nh_nodes:lava_flowing"] = true,
            ["nh_nodes:bluelava"] = true,
            ["nh_nodes:bluelava_flowing"] = true,
        }
        -- Para o timer; terra fica como terra
        if blocked_nodes[node_above] then return false end
        if light and light <= 4 then return false end
        if light and light > 4 then
            local neighbors = {
                -- (todo o seu código de vizinhos permanece igual)
                { x = pos.x + 1, y = pos.y, z = pos.z },
            }
            local has_grass_neighbor = false
            for _, npos in ipairs(neighbors) do
                local neighbor_name = core.get_node(npos).name
                if neighbor_name == "nh_nodes:grass" or neighbor_name == "nh_nodes:top_grass" then
                    has_grass_neighbor = true
                    break
                end
            end
            if has_grass_neighbor then
                core.set_node(pos, { name = "nh_nodes:top_grass" })
                return false
            end
        end
        return true
    end,
    title = S("2x2 Craft on the Dirt"), -- Campo obrigatório!
    grid_size = 4,
    positions = { { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 }, { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 }, },
    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo
    output_position = { x = 0, y = 1.4, z = 0 },
    layers = { { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 }, },
    recipes = recipes_floor
})
core.register_node("nh_nodes:wetdirt", {
    description = S("Wet Dirt"),
    tiles = { "wetdirt.png" },
    groups = { crumbly = 2 },
    sounds = { footstep = { name = "punchtimber3", gain = 0.5 }, dug = { name = "punchtimber3", gain = 0.5 }, dig = { name = "punchtimber3", gain = 0.5 }, place = { name = "punchtimber3", gain = 0.5 }, },
    -- Mecânica opcional: grama morrer na sombra
    --paramtype = "light",
    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
    on_construct = function(pos)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        local light = core.get_node_light(above)
        --core.chat_send_all("🟤 DIRT construído em " .. core.pos_to_string(pos))
        -- core.chat_send_all("   Bloco acima: " .. node_above)
        if light and light > 4 then
            core.get_node_timer(pos):start(math.random(30, 60))
            -- core.chat_send_all("   ✅ Timer iniciado!")
        else
            --core.chat_send_all("   ❌ Timer NÃO iniciado (tem bloco escurecendo em cima)")
        end
    end,
    on_timer = function(pos, elapsed)
        --core.chat_send_all("⏰ TIMER disparou em " .. core.pos_to_string(pos))
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        local light = core.get_node_light(above)
        --core.chat_send_all("   Bloco acima: " .. node_above)
        if light and light <= 4 then
            --core.chat_send_all("   ❌ Tem bloco em cima escurecendo, parando timer")
            return false
        end
        --local light = core.get_node_light(pos)
        --core.chat_send_all("   Luz: " .. tostring(light))
        if light and light > 4 then
            local neighbors = {
                -- Laterais
                { x = pos.x + 1, y = pos.y,     z = pos.z },
                { x = pos.x - 1, y = pos.y,     z = pos.z },
                { x = pos.x,     y = pos.y,     z = pos.z + 1 },
                { x = pos.x,     y = pos.y,     z = pos.z - 1 },
                -- Diagonais
                { x = pos.x + 1, y = pos.y,     z = pos.z + 1 },
                { x = pos.x + 1, y = pos.y,     z = pos.z - 1 },
                { x = pos.x - 1, y = pos.y,     z = pos.z + 1 },
                { x = pos.x - 1, y = pos.y,     z = pos.z - 1 },
                -- Laterais abaixo
                { x = pos.x + 1, y = pos.y - 1, z = pos.z },
                { x = pos.x - 1, y = pos.y - 1, z = pos.z },
                { x = pos.x,     y = pos.y - 1, z = pos.z + 1 },
                { x = pos.x,     y = pos.y - 1, z = pos.z - 1 },
                -- Diagonais abaixo
                { x = pos.x + 1, y = pos.y - 1, z = pos.z + 1 },
                { x = pos.x + 1, y = pos.y - 1, z = pos.z - 1 },
                { x = pos.x - 1, y = pos.y - 1, z = pos.z + 1 },
                { x = pos.x - 1, y = pos.y - 1, z = pos.z - 1 },
                -- Laterais acima
                { x = pos.x + 1, y = pos.y + 1, z = pos.z },
                { x = pos.x - 1, y = pos.y + 1, z = pos.z },
                { x = pos.x,     y = pos.y + 1, z = pos.z + 1 },
                { x = pos.x,     y = pos.y + 1, z = pos.z - 1 },
                -- Diagonais acima
                { x = pos.x + 1, y = pos.y + 1, z = pos.z + 1 },
                { x = pos.x + 1, y = pos.y + 1, z = pos.z - 1 },
                { x = pos.x - 1, y = pos.y + 1, z = pos.z + 1 },
                { x = pos.x - 1, y = pos.y + 1, z = pos.z - 1 },
            }
            local has_grass_neighbor = false
            local grass_found = ""
            for _, npos in ipairs(neighbors) do
                local neighbor_name = core.get_node(npos).name
                if neighbor_name == "nh_nodes:grass" or neighbor_name == "nh_nodes:top_grass" then
                    has_grass_neighbor = true
                    grass_found = neighbor_name .. " em " .. core.pos_to_string(npos)
                    break
                end
            end
            --[[
            core.chat_send_all("   Grama encontrada: " .. tostring(has_grass_neighbor))
            if has_grass_neighbor then
                core.chat_send_all("   🌱 " .. grass_found)
            end
            ]] --
            if has_grass_neighbor then
                core.set_node(pos, { name = "nh_nodes:top_grass" })
                --core.chat_send_all("   🟩 CONVERTEU PARA GRAMA!")
                return false
            else
                --core.chat_send_all("   ⏳ Sem grama ao redor, tentando novamente...")
            end
        else
            --core.chat_send_all("   🌙 Pouca luz (precisa > 4)")
        end

        return true
    end,
})

core.register_node("nh_nodes:tilleddirt", {
    description = S("Tilled Dirt"),
    tiles = { "tilleddirt.png", "terra.png" },
    groups = { crumbly = 2 },
    drop = "nh_nodes:dirt",
    sounds = { footstep = { name = "punchtimber3", gain = 0.5 }, dug = { name = "punchtimber3", gain = 0.5 }, dig = { name = "punchtimber3", gain = 0.5 }, place = { name = "punchtimber3", gain = 0.5 }, },
    wielded_bone_position = { pos = { x = 0.5, y = 0.5, z = 1.65 } },
    offhand_bone_position = { pos = { x = 1.5, y = 0, z = 0 } },
    on_construct = function(pos) core.get_node_timer(pos):start(math.random(30, 60)) end,
    on_timer = function(pos, elapsed)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        if node_above ~= "air" then return true end
        local laterals = {
            { x = pos.x + 1, y = pos.y, z = pos.z },
            { x = pos.x - 1, y = pos.y, z = pos.z },
            { x = pos.x,     y = pos.y, z = pos.z + 1 },
            { x = pos.x,     y = pos.y, z = pos.z - 1 },
            -- diagonais
            { x = pos.x + 1, y = pos.y, z = pos.z + 1 },
            { x = pos.x + 1, y = pos.y, z = pos.z - 1 },
            { x = pos.x - 1, y = pos.y, z = pos.z + 1 },
            { x = pos.x - 1, y = pos.y, z = pos.z - 1 },
        }
        local has_water = false
        for _, npos in ipairs(laterals) do
            local name = core.get_node(npos).name
            if name == "nh_nodes:water" or name == "nh_nodes:water2"
                or name == "nh_nodes:water_flowing" or name == "nh_nodes:water2_flowing" then
                has_water = true
                break
            end
        end

        if has_water then
            core.set_node(pos, { name = "nh_nodes:wettilleddirt" })
        else
            core.set_node(pos, { name = "nh_nodes:dirt" })
        end
        return false
    end,
})

core.register_node("nh_nodes:wettilleddirt", {
    description = S("Wet Tilled Dirt"),
    tiles = { "wettilleddirt.png", "wetdirt.png" },
    groups = { crumbly = 2 },
    drop = "nh_nodes:wetdirt",
    sounds = { footstep = { name = "punchtimber3", gain = 0.5 }, dug = { name = "punchtimber3", gain = 0.5 }, dig = { name = "punchtimber3", gain = 0.5 }, place = { name = "punchtimber3", gain = 0.5 }, },

    -- Mecânica opcional: grama morrer na sombra
    --paramtype = "light",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
    on_construct = function(pos) core.get_node_timer(pos):start(math.random(60, 120)) end,
    on_timer = function(pos, elapsed)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name
        -- tem bloco em cima, aguarda e tenta de novo
        if node_above ~= "air" then return true end
        core.set_node(pos, { name = "nh_nodes:wetdirt" })
        return false
    end,
})
core.register_node("nh_nodes:top_grass_ramp", {
    description         = "Grass Ramp",
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama
    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_slope.obj",
    tiles               = { "grass_slope.png" },
    -- Dentro do register_node:
    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",
    sounds              = { footstep = { name = "GrassFootstep", gain = 0.5 }, dug = { name = "GrassDig", gain = 0.5 }, dig = { name = "GrassDig", gain = 0.5 }, place = { name = "GrassDig", gain = 0.5 }, },
    sunlight_propagates = true,
    selection_box       = { type = "fixed", fixed = { { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, { -0.5, 0.0, 0.0, 0.5, 0.5, 0.5 }, }, },
    collision_box       = { type = "fixed", fixed = { { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, { -0.5, 0.0, 0.0, 0.5, 0.5, 0.5 }, },
    },
})

core.register_node("nh_nodes:top_grass_corner", {
    description         = "Grass Corner",
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_vertix.obj",
    tiles               = { "grass_slope.png" },

    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",

    sounds              = {
        footstep = { name = "GrassFootstep", gain = 0.5 },
        dug      = { name = "GrassDig", gain = 0.5 },
        dig      = { name = "GrassDig", gain = 0.5 },
        place    = { name = "GrassDig", gain = 0.5 },
    },

    sunlight_propagates = true,

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2

        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2
        },
    },
})

core.register_node("nh_nodes:top_grass_insidecorner", {
    description         = "Grass Inside Corner",
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grassinsidecorner.obj",
    tiles               = { "grass_slope.png" },

    groups              = { cracky = 3, soil = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:dirt",

    sounds              = {
        footstep = { name = "GrassFootstep", gain = 0.5 },
        dug      = { name = "GrassDig", gain = 0.5 },
        dig      = { name = "GrassDig", gain = 0.5 },
        place    = { name = "GrassDig", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, -- Base completa (metade inferior)
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 1: faixa traseira (Z-
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 }, -- Topo braço 1: faixa traseira (Z-)
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 2: faixa lateral (X-)
        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 },
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 },
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 },
        },
    },
})


register_craft_station("nh_nodes:top_grass", {
    description = S("Grass"),
    -- 6 texturas → top, bottom, right, left, back, front
    tiles = {
        "grama.png",            -- topo (0)
        "terra.png",            -- embaixo (1)
        "grama_terra_lado.png", -- lado direito (2)
        "grama_terra_lado.png", -- lado esquerdo (3)
        "grama_terra_lado.png", -- lado atrás (4)
        "grama_terra_lado.png"  -- lado frente (5)
    },

    sounds = {
        footstep = { name = "GrassFootstep", gain = 0.5 },
        dug      = { name = "GrassDig", gain = 0.5 },
        dig      = { name = "GrassDig", gain = 0.5 },
        place    = { name = "GrassDig", gain = 0.5 },
    },

    title = S("2x2 Craft on the Grass"),
    groups = { crumbly = 3, soil = 1 },
    -- Quando a grama é bloqueada da luz, vira terra
    drop = "nh_nodes:dirt",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    on_timer = function(pos, elapsed)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name

        -- Bloco líquido ou lava acima faz virar terra imediatamente
        local blocked_nodes = {
            ["nh_nodes:water"]            = true,
            ["nh_nodes:water_flowing"]    = true,
            ["nh_nodes:water2"]           = true,
            ["nh_nodes:water2_flowing"]   = true,
            ["nh_nodes:lava"]             = true,
            ["nh_nodes:lava_flowing"]     = true,
            ["nh_nodes:bluelava"]         = true,
            ["nh_nodes:bluelava_flowing"] = true,
        }

        if blocked_nodes[node_above] then
            core.set_node(pos, { name = "nh_nodes:dirt" })
            return false -- Grama virou terra, para o timer
        end

        -- Se NÃO é ar, verifica luz
        if node_above ~= "air" then
            local light = core.get_node_light(above)

            if light and light <= 4 then
                core.set_node(pos, { name = "nh_nodes:dirt" })
                return false
            end
        else
            return false -- Ar acima, sem ameaça, para o timer
        end

        return false
    end,


    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})


register_craft_station("nh_nodes:top_grass2", {
    description = S("Grass"),
    -- 6 texturas → top, bottom, right, left, back, front
    tiles = {
        "grama.png", -- topo (0)
        "terra.png", -- embaixo (1)
        "terra.png", -- lado direito (2)
        "terra.png", -- lado esquerdo (3)
        "terra.png", -- lado atrás (4)
        "terra.png"  -- lado frente (5)
    },

    sounds = {
        footstep = { name = "GrassFootstep", gain = 0.5 },
        dug      = { name = "GrassDig", gain = 0.5 },
        dig      = { name = "GrassDig", gain = 0.5 },
        place    = { name = "GrassDig", gain = 0.5 },
    },

    title = S("2x2 Craft on the Grass"),
    groups = { crumbly = 3, soil = 1 },
    -- Quando a grama é bloqueada da luz, vira terra
    drop = "nh_nodes:dirt",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    on_timer = function(pos, elapsed)
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name

        -- Bloco líquido ou lava acima faz virar terra imediatamente
        local blocked_nodes = {
            ["nh_nodes:water"]            = true,
            ["nh_nodes:water_flowing"]    = true,
            ["nh_nodes:water2"]           = true,
            ["nh_nodes:water2_flowing"]   = true,
            ["nh_nodes:lava"]             = true,
            ["nh_nodes:lava_flowing"]     = true,
            ["nh_nodes:bluelava"]         = true,
            ["nh_nodes:bluelava_flowing"] = true,
        }

        if blocked_nodes[node_above] then
            core.set_node(pos, { name = "nh_nodes:dirt" })
            return false -- Grama virou terra, para o timer
        end

        -- Se NÃO é ar, verifica luz
        if node_above ~= "air" then
            local light = core.get_node_light(above)

            if light and light <= 4 then
                core.set_node(pos, { name = "nh_nodes:dirt" })
                return false
            end
        else
            return false -- Ar acima, sem ameaça, para o timer
        end

        return false
    end,


    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})

register_craft_station("nh_nodes:grass", {
    description = S("Lawn"),
    tiles = { "grama.png" },
    groups = { crumbly = 3 },
    sunlight_propagates = false,
    drop = "nh_nodes:dirt",

    sounds = {
        footstep = { name = "GrassFootstep", gain = 0.5 },
        dug      = { name = "GrassDig", gain = 0.5 },
        dig      = { name = "GrassDig", gain = 0.5 },
        place    = { name = "GrassDig", gain = 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    on_timer = function(pos, elapsed)
        --core.chat_send_all("⏰ TIMER de morte da grama disparou em " .. core.pos_to_string(pos))

        -- Verifica se há um bloco bloqueando a luz acima
        local above = { x = pos.x, y = pos.y + 1, z = pos.z }
        local node_above = core.get_node(above).name

        --core.chat_send_all("   Bloco acima: " .. node_above)

        -- Se NÃO é ar, significa que está tampado
        if node_above ~= "air" then
            -- Verifica se a luz está muito baixa
            local light = core.get_node_light(above)
            --core.chat_send_all("   Luz: " .. tostring(light))

            if light and light <= 4 then
                -- Converte para terra
                core.set_node(pos, { name = "nh_nodes:dirt" })
                --core.chat_send_all("   🟫 GRAMA VIROU TERRA (sem luz)")
                return false -- Para o timer
            else
                --core.chat_send_all("   ☀️ Ainda tem luz suficiente")
            end
        else
            --core.chat_send_all("   ✅ Ar acima, cancelando timer")
            return false -- Para o timer se o bloco foi removido
        end

        -- Continua verificando
        --core.chat_send_all("   Não se torna terra, terminada a verificação")
        return false
    end,



    title = S("2x2 Craft on the Lawn"), -- ✅ Campo obrigatório!



    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})


-- ========================================
-- SISTEMA DE DETECÇÃO DE BLOCOS ACIMA DA GRAMA
-- ========================================

-- Callback global que detecta quando qualquer bloco é colocado
core.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
    -- Verifica a posição ABAIXO do bloco que foi colocado
    local below = { x = pos.x, y = pos.y - 1, z = pos.z }
    local node_below = core.get_node(below)

    -- Se o bloco abaixo é grama ou top_grass
    if node_below.name == "nh_nodes:grass" or node_below.name == "nh_nodes:top_grass" then
        --core.chat_send_all("📦 Bloco colocado acima da grama em " .. core.pos_to_string(below))

        -- Inicia o timer de morte da grama
        core.get_node_timer(below):start(math.random(3, 6))
        --core.chat_send_all("   ⏰ Timer de morte iniciado!")
    end
end)

-- Callback global que detecta quando qualquer bloco é REMOVIDO
core.register_on_dignode(function(pos, oldnode, digger)
    -- Verifica a posição ABAIXO do bloco que foi removido
    local below = { x = pos.x, y = pos.y - 1, z = pos.z }
    local node_below = core.get_node(below)

    -- Se o bloco abaixo é grama ou top_grass
    if node_below.name == "nh_nodes:grass" or node_below.name == "nh_nodes:top_grass" then
        --core.chat_send_all("🌞 Bloco removido de cima da grama em " .. core.pos_to_string(below))

        -- PARA o timer (a grama voltou a ter luz)
        core.get_node_timer(below):stop()
        --core.chat_send_all("   ⏸️ Timer cancelado (grama exposta à luz novamente)")
        -- end

        -- Se o bloco abaixo é terra
    elseif node_below.name == "nh_nodes:dirt" then
        --core.chat_send_all("🌞 Bloco removido de cima da terra em " .. core.pos_to_string(below))

        -- PARA o timer (a grama voltou a ter luz)
        core.get_node_timer(below):start(math.random(3, 6))
        --core.chat_send_all("   ⏸️ Timer iniciado (terra exposta à luz)")
    end
end)


core.register_node("nh_nodes:sand_ramp", {
    description         = S("Sand Ramp"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_slope.obj",
    tiles               = { "sand_slope.png" },
    -- Dentro do register_node:
    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
})

core.register_node("nh_nodes:sand_corner", {
    description         = S("Sand Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_vertix.obj",
    tiles               = { "sand_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2

        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2
        },
    },
})

core.register_node("nh_nodes:sand_insidecorner", {
    description         = S("Sand Inside Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grassinsidecorner.obj",
    tiles               = { "sand_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, -- Base completa (metade inferior)
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 1: faixa traseira (Z-)
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 }, -- Topo braço 1: faixa traseira (Z-)
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 2: faixa lateral (X-)
        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 },
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 },
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 },
        },
    },
})

register_craft_station("nh_nodes:sand", {
    description = S("Sand"),
    mesh = nil,
    tiles = { "areia.png" },
    title = S("2x2 Craft on the Sand"), -- ✅ Campo obrigatório!
    grid_size = 4,
    groups = { crumbly = 2, falling_node = 1 },

    sounds = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})

register_craft_station("nh_nodes:wet_sand", {
    description = S("Wet Sand"),
    tiles = { "areia_molhada.png" },
    title = S("2x2 Craft on the Wet Sand"), -- ✅ Campo obrigatório!
    groups = { crumbly = 2 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})


core.register_node("nh_nodes:saprolite", {
    description = S("Saprolite"),
    tiles = { "saprolite.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

register_craft_station("nh_nodes:gneiss", {
    description = S("Gneiss"),
    tiles = { "pedra.png" },
    groups = { cracky = 3 },
    drop = "nh_nodes:pebble_item 8",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},


    title = S("2x2 Craft on the Gneiss"), -- ✅ Campo obrigatório!



    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})

register_craft_station("nh_nodes:cobblestone", {
    description = S("Cobblestone"),
    tiles = { "cobblestone.png" },
    groups = { cracky = 3 },
    drop = "nh_nodes:pebble_item 8",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    title = "Produção 2x2 no Pedregulho", -- ✅ Campo obrigatório!



    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_floor
})

core.register_node("nh_nodes:charcoal", {
    description = S("Charcoal"),
    tiles = {
        "topdowncharcoal.png", -- topo
        "topdowncharcoal.png", -- base
        "charcoal.png",        -- lados (direita, esquerda, frente, trás)
    },
    groups = { choppy = 3, armor_head = 1 },
    stack_max = 1,
    drop = "nh_nodes:charcoalnugget 8",

    paramtype = "light",
    paramtype2 = "wallmounted",

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },


    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },
})

core.register_node("nh_nodes:charcoal2", {
    description = S("Smaller Charcoal"),
    drawtype = "mesh",
    mesh = "palm_trunk.obj",
    tiles = { "charcoal2.png" },
    stack_max = 4,
    drop = "nh_nodes:charcoalnugget 2",

    paramtype = "light",
    paramtype2 = "facedir",
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 1,
    },

    paramtype = "light",
    paramtype2 = "wallmounted",


    selection_box = {
        type = "wallmounted",
        wall_top = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_bottom = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_side = { -0.5, -0.25, -0.25, 0.5, 0.25, 0.25 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_bottom = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_side = { -0.5, -0.25, -0.5, 0.5, 0.25, 0.5 },
    },

    -- Som tocado ao bater no tronco medio (2)
    sounds = {
        dug = { name = "punchtimber2", gain = 0.5 },
        dig = { name = "punchtimber2", gain = 0.5 },
    },
})



core.register_node("nh_nodes:coal", {
    description = S("Black Coal") .. "\n" .. S("[Coal Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "coalore.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    drop = {
        items = {
            { items = { "nh_nodes:coalnugget 8" } },
        }
    },
})

core.register_node("nh_nodes:coalnugget", {
    description = S("Coal Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "coalnugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:charcoalnugget", {
    description = S("Charcoal Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "charcoalnugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:copper", {
    description = S("Chalcopyrite") .. "\n" .. S("[Copper Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_copperore.png" },
    groups = { cracky = 3 },
    drop = {
        items = {
            { items = { "nh_nodes:coppernugget" } },
            { items = { "nh_nodes:pebble 3" } },
        }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:coppernugget", {
    description = S("Copper Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "coppernugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:copperingot", {
    description = S("Copper Ingot"),
    drawtype = "mesh",
    mesh = "metalingot.obj",
    tiles = { "copperingot.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,
})

core.register_node("nh_nodes:tin", {
    description = S("Cassiterite") .. "\n" .. S("[Tin Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_tinore.png" },
    groups = { cracky = 3 },
    drop = {
        items = {
            { items = { "nh_nodes:tinnugget" } },
            { items = { "nh_nodes:pebble 3" } },
        }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:tinnugget", {
    description = S("Tin Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "tinnugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:tiningot", {
    description = S("Tin Ingot"),
    drawtype = "mesh",
    mesh = "metalingot.obj",
    tiles = { "tiningot.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,
})

core.register_node("nh_nodes:iron", {
    description = S("Pyrite") .. "\n" .. S("[Iron Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_ironore.png" },
    groups = { cracky = 3 },
    drop = {
        items = {
            { items = { "nh_nodes:ironnugget" } },
            { items = { "nh_nodes:pebble 3" } },
        }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:ironnugget", {
    description = S("Iron Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "ironnugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:ironingot", {
    description = S("Iron Ingot"),
    drawtype = "mesh",
    mesh = "metalingot.obj",
    tiles = { "ironingot.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,
})

core.register_node("nh_nodes:nickel", {
    description = S("Garnierite") .. "\n" .. S("[Nickel Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_nickelore.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:manganese", {
    description = S("Pyrolusite") .. "\n" .. S("[Manganese Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_manganeseore.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:chromium", {
    description = S("Chromite") .. "\n" .. S("[Chromium Ore]"),
    drawtype = "mesh",
    mesh = "copperore.obj",
    tiles = { "gneiss_chromeore.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:chromiumnugget", {
    description = S("Chromium Nugget"),
    drawtype = "mesh",
    mesh = "metalnugget.obj",
    tiles = { "ironnugget.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,

    collision_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.35, 0.08 },
    },
})

core.register_node("nh_nodes:chromiumingot", {
    description = S("Chromium Ingot"),
    drawtype = "mesh",
    mesh = "metalingot.obj",
    tiles = { "ironingot.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    paramtype = "light",
    walkable = false,
})

core.register_node("nh_nodes:peridotite", {
    description = S("Peridotite"),
    tiles = { "peridotite.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:redrock", {
    description = S("Ruborita"),
    tiles = { "lava.png" },
    groups = { unbreakable = 1, not_in_creative_inventory = 1 }, --{unbreakable = 1, not_in_creative_inventory = 1},
    drop = "",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})


core.register_node("nh_nodes:bedrock", {
    description = S("Bridgmanite"),
    tiles = { "matriz.png" },
    drawtype = "glasslike_framed_optional",
    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    groups = { cracky = 3 }, --{cracky = 1, oddly_breakable_by_hand = 1},

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:obsidian", {
    description = S("Obsidian"),
    tiles = { "obsidiana.png" },
    groups = { cracky = 3 }, --{cracky = 1, oddly_breakable_by_hand = 1},

    drop = "nh_nodes:obsidianpebble 8",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})


core.register_node("nh_nodes:oakresin", {
    description = S("Oak Resin"),
    drawtype = "mesh",
    mesh = "oakresin.obj",
    tiles = { "oakresin.png" },
    --drawtype = "glasslike_framed_optional",
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    walkable = false,
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 3
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, -0.45, 0.1 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, -0.45, 0.1 }
    },
})

-- Função para verificar se um nó tem suporte sólido
local function has_solid_support(pos, checked)
    checked = checked or {}
    local hash = core.hash_node_position(pos)

    if checked[hash] then return false end
    checked[hash] = true
    if #checked > 100 then return false end

    local below = { x = pos.x, y = pos.y - 1, z = pos.z }
    local below_node = core.get_node(below)
    local def = core.registered_nodes[below_node.name]
    if not def then return false end

    -- Algo sólido que NÃO seja árvore
    if below_node.name ~= "air"
        and not def.groups.tree_trunk
        and not def.groups.tree_leaves then
        return true
    end

    -- Tronco abaixo → verifica recursivamente
    if def.groups.tree_trunk then
        return has_solid_support(below, checked)
    end

    return false
end


-- Função para fazer folhas caírem
local function make_leaves_fall(pos)
    local radius_horizontal = 8 -- Alcance lateral
    local radius_vertical = 20  -- Alcance vertical (para cima e para baixo)

    for x = -radius_horizontal, radius_horizontal do
        for y = radius_vertical, -radius_vertical, -1 do -- Aumentado para pegar folhas mais altas
            for z = -radius_horizontal, radius_horizontal do
                local check_pos = { x = pos.x + x, y = pos.y + y, z = pos.z + z }
                local node = core.get_node(check_pos)

                if core.get_item_group(node.name, "tree_leaves") > 0 then
                    local delay = math.random(2, 10) / 10
                    core.after(delay, function()
                        local current_node = core.get_node(check_pos)
                        if core.get_item_group(current_node.name, "tree_leaves") > 0 then
                            core.remove_node(check_pos)
                            local obj = core.add_entity(check_pos, "__builtin:falling_node")
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
core.register_node("nh_nodes:oaktimber", {
    description = S("Oak Timber"),
    tiles = { "oaktimber.png" },
    groups = { choppy = 3, falling_node = 1, armor_head = 1 },
    stack_max = 1,

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },

    -- Detecta quando o tronco é quebrado ou vai cair
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- Verifica se tinha suporte antes de ser quebrado
        -- Se não tinha, significa que vai cair
        local below = { x = pos.x, y = pos.y - 1, z = pos.z }
        local below_node = core.get_node(below)

        -- Se abaixo é ar ou outro tronco/folha, faz folhas caírem
        if below_node.name == "air" or below_node.name == "nh_nodes:oaktimber" or below_node.name:find("nh_nodes:leaves") or below_node.name:find("nh_nodes:leaves_nut") or below_node.name:find("nh_nodes:leaves_nut2") or below_node.name:find("nh_nodes:leaves_nut3") or below_node.name:find("nh_nodes:oakbranch") then
            make_leaves_fall(pos)
        end
    end,

    -- Detecta quando o tronco começa a se mover
    on_construct = function(pos)
        core.get_node_timer(pos):start(0.5)
    end,

    on_timer = function(pos)
        local node = core.get_node(pos)
        if node.name == "nh_nodes:oaktimber" then
            -- Se não tem suporte, vai começar a cair
            if not has_solid_support(pos) then
                make_leaves_fall(pos)
                return false -- Para o timer
            end
            return true      -- Continua verificando
        end
        return false
    end,

    drop = "nh_nodes:oaklog",
})

-- Ramo
core.register_node("nh_nodes:oakbranch", {
    description = S("Oak Branch"),
    drawtype = "mesh",
    mesh = "oakbranch.obj",
    tiles = { "oaktimber.png" },
    groups = { choppy = 3, tree_leaves = 1 },
    stack_max = 3,
    paramtype = "light",
    paramtype2 = "facedir",

    selection_box = {
        type = "fixed",
        fixed = { -0.2, -0.2, -0.5, 0.2, 0.5, 0.5 },
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.2, -0.2, -0.5, 0.2, 0.5, 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },
})

core.register_node("nh_nodes:oaklog", {
    description = S("Oak Log"),
    tiles = {
        "topdownoaktimber.png", -- topo
        "topdownoaktimber.png", -- base
        "oaktimber.png",        -- lados (direita, esquerda, frente, trás)
    },
    groups = { choppy = 3, armor_head = 1 },
    stack_max = 1,

    paramtype = "light",
    paramtype2 = "wallmounted",

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },


    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },
})

-- Tronco de macieira
core.register_node("nh_nodes:appletimber", {
    description = S("Apple Timber"),
    drawtype = "mesh",
    mesh = "appletimber.obj",
    tiles = { "appletimber.png" },
    groups = { choppy = 3, falling_node = 1, armor_head = 1 },
    stack_max = 1,
    paramtype = "light",
    sunlight_propagates = true,

    collision_box = {
        type = "fixed",
        fixed = { -0.095, -0.5, -0.095, 0.095, 0.5, 0.095 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.095, -0.5, -0.095, 0.095, 0.5, 0.095 },
    },

    sounds = {
        dug = { name = "punchtimber3", gain = 0.5 },
        dig = { name = "punchtimber3", gain = 0.5 },
    },



    -- Detecta quando o tronco é quebrado ou vai cair
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local below = { x = pos.x, y = pos.y - 1, z = pos.z }
        local below_node = core.get_node(below)

        -- CORRIGIDO: Verifica TODAS as folhas de macieira
        if below_node.name == "air"
            or below_node.name == "nh_nodes:appletimber"
            or below_node.name == "nh_nodes:appleleaves"
            or below_node.name == "nh_nodes:leaves_apple"
            or below_node.name == "nh_nodes:leaves_apple2"
            or below_node.name == "nh_nodes:leaves_apple3" then
            make_leaves_fall(pos)
        end
    end,

    on_construct = function(pos)
        core.get_node_timer(pos):start(0.5)
    end,

    on_timer = function(pos)
        local node = core.get_node(pos)
        if node.name == "nh_nodes:appletimber" then
            if not has_solid_support(pos) then
                make_leaves_fall(pos)
                return false
            end
            return true
        end
        return false
    end,
})

-- Tronco 3
core.register_node("nh_nodes:pinetimber", {
    description = S("Pine Timber"),
    tiles = { "pinetimber.png" },
    groups = { choppy = 3, falling_node = 1, armor_head = 1 },
    stack_max = 1,

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },

    -- Detecta quando o tronco é quebrado ou vai cair
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        -- Verifica se tinha suporte antes de ser quebrado
        -- Se não tinha, significa que vai cair
        local below = { x = pos.x, y = pos.y - 1, z = pos.z }
        local below_node = core.get_node(below)

        -- Se abaixo é ar ou outro tronco/folha, faz folhas caírem
        if below_node.name == "air" or below_node.name == "nh_nodes:pinetimber" or below_node.name:find("nh_nodes:leaves") then
            make_leaves_fall(pos)
        end
    end,

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},


    -- Detecta quando o tronco começa a se mover
    on_construct = function(pos)
        core.get_node_timer(pos):start(0.5)
    end,

    on_timer = function(pos)
        local node = core.get_node(pos)
        if node.name == "nh_nodes:pinetimber" then
            -- Se não tem suporte, vai começar a cair
            if not has_solid_support(pos) then
                make_leaves_fall(pos)
                return false -- Para o timer
            end
            return true      -- Continua verificando
        end
        return false
    end,


    drop = "nh_nodes:pinelog",
})

core.register_node("nh_nodes:pinelog", {
    description = S("Pine Log"),
    tiles = {
        "topdownpinetimber.png", -- topo
        "topdownpinetimber.png", -- base
        "pinetimber.png",        -- lados (direita, esquerda, frente, trás)
    },
    groups = { choppy = 3, armor_head = 1 },
    stack_max = 1,

    paramtype = "light",
    paramtype2 = "wallmounted",

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },
})

-- Madeira
core.register_node("nh_nodes:oakwood", {
    description = S("Oak Wood"),
    tiles = { "oakwood.png" },
    groups = { choppy = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

-- Madeira
core.register_node("nh_nodes:pinewood", {
    description = S("Pine Wood"),
    tiles = { "pinewood.png" },
    groups = { choppy = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:bone", {
    description = S("Bone"),
    drawtype = "mesh",
    mesh = "bone.obj",
    tiles = { "bone.png" },
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    stack_max = 8,

    paramtype = "light",
    paramtype2 = "wallmounted",

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.25, y = 0, z = 0 },
        rot = { x = 90, y = 90, z = 90 },
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    --offhand_bone_position = {
    --    pos = {x = 0, y = 0, z = 0}
    --rot = {x = 0, y = 0, z = -110}
    --},
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Som tocado ao bater no tronco
    sounds = {
        dug = { name = "punchtimber", gain = 0.5 },
        dig = { name = "punchtimber", gain = 0.5 },
    },
})


-- slime
core.register_node("nh_nodes:slime", {
    description = S("Limu") .. "\n" .. S("[collectible]"),
    drawtype = "mesh",
    mesh = "planaria_slime_small2.obj",
    tiles = { "planaria_slime2.png" },
    groups = { snappy = 3 },

    paramtype = "light",
    -- BRILHO NOS OLHOS
    glow = 5, -- Intensidade de 0 a 14 (14 = mais brilhante)
    -- TRANSPARENCIA
    use_texture_alpha = "blend",

    -- Configuração mão direita
    wielded_bone_position = {
        --pos = {x = 0, y = 0, z = 1.5},
        rot = { x = 0, y = 90, z = -90 }
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 },
        rot = { x = 0, y = 90, z = -90 }
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

-- grilo
core.register_node("nh_nodes:cricket", {
    description = S("Cricket") .. "\n" .. S("[collectible]"),
    drawtype = "mesh",
    mesh = "cricket.obj",
    tiles = { "cricket.png" },
    groups = { snappy = 3 },

    paramtype = "light",
    use_texture_alpha = "clip",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

-- Madeira
core.register_node("nh_nodes:campfiretinder", {
    description = S("Campfire Tinder"),
    drawtype = "mesh",
    mesh = "iscafogueira.obj",
    tiles = { "iscafogueira.png" },
    groups = { snappy = 3 },
    use_texture_alpha = "blend",
    paramtype = "light",

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },
})


-- Tronco de carvalho fatiado
core.register_node("nh_nodes:oaktimberslice", {
    description = S("Oak Firewood"),
    drawtype = "mesh",
    mesh = "oaktimberslice.obj",
    tiles = { "oaktimber.png" },
    groups = { choppy = 3 },
    stack_max = 16,

    on_place = function(itemstack, placer, pointed_thing)
        -- Verifica se o jogador está agachado
        if placer and placer:is_player() and placer:get_player_control().sneak then
            -- Comportamento normal de colocação (com shift)
            return core.item_place(itemstack, placer, pointed_thing)
        end

        -- Se está clicando em um node (sem agachar)
        if pointed_thing.type == "node" then
            local pos = pointed_thing.under
            local node = core.get_node(pos)

            -- Verifica qual estágio está e evolui (apenas se mirar em campfiretinder)
            if node.name == "nh_nodes:campfiretinder" then
                core.set_node(pos, { name = "nh_nodes:oaktimberslice1" })
                itemstack:take_item()
                return itemstack
            elseif node.name == "nh_nodes:oaktimberslice1" then
                core.set_node(pos, { name = "nh_nodes:oaktimberslice2" })
                itemstack:take_item()
                return itemstack
            elseif node.name == "nh_nodes:oaktimberslice2" then
                core.set_node(pos, { name = "nh_nodes:oaktimberslice3" })
                itemstack:take_item()
                return itemstack
            elseif node.name == "nh_nodes:oaktimberslice3" then
                core.set_node(pos, { name = "nh_nodes:campfire" })
                itemstack:take_item()
                return itemstack
            end
        end

        -- Comportamento normal de colocação para outros casos
        return core.item_place(itemstack, placer, pointed_thing)
    end,
})

-- Lenha de carvalho 1 - 1/4 firewood
core.register_node("nh_nodes:oaktimberslice1", {
    description = S("Firewood on the Campfire 1/4"),
    drawtype = "mesh",
    mesh = "oaktimberslice1.obj",
    tiles = { "fogueira.png" },
    groups = { choppy = 3 },
    use_texture_alpha = "blend",
    paramtype = "light",
    stack_max = 16,
    drop = "nh_nodes:oaktimberslice",

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },

    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return itemstack
        end

        local pos = pointed_thing.under
        local node = core.get_node(pos)

        if placer and placer:is_player() and placer:get_player_control().sneak then
            if node.name == "nh_nodes:oaktimberslice1" and itemstack:get_name() == "nh_nodes:oaktimberslice" then
                core.set_node(pos, { name = "nh_nodes:oaktimberslice2" })
                itemstack:take_item()
                return itemstack
            end
        end

        return core.item_place(itemstack, placer, pointed_thing)
    end,
})

-- Lenha de carvalho 2 - 2/4 firewood
core.register_node("nh_nodes:oaktimberslice2", {
    description = S("Firewood on the Campfire 2/4"),
    drawtype = "mesh",
    mesh = "oaktimberslice2.obj",
    tiles = { "fogueira.png" },
    use_texture_alpha = "blend",
    paramtype = "light",
    groups = { choppy = 3 },
    stack_max = 16,
    drop = "nh_nodes:oaktimberslice 2",

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },

    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return itemstack
        end

        local pos = pointed_thing.under
        local node = core.get_node(pos)

        if placer and placer:is_player() and placer:get_player_control().sneak then
            if node.name == "nh_nodes:oaktimberslice2" and itemstack:get_name() == "nh_nodes:oaktimberslice" then
                core.set_node(pos, { name = "nh_nodes:oaktimberslice3" })
                itemstack:take_item()
                return itemstack
            end
        end

        return core.item_place(itemstack, placer, pointed_thing)
    end,
})

-- Lenha de carvalho 3 - 3/4 firewood
core.register_node("nh_nodes:oaktimberslice3", {
    description = S("Firewood on the Campfire 3/4"),
    drawtype = "mesh",
    mesh = "oaktimberslice3.obj",
    tiles = { "fogueira.png" },
    use_texture_alpha = "blend",
    paramtype = "light",
    groups = { choppy = 3 },
    stack_max = 16,
    drop = "nh_nodes:oaktimberslice 3",

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },

    on_place = function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return itemstack
        end

        local pos = pointed_thing.under
        local node = core.get_node(pos)

        if placer and placer:is_player() and placer:get_player_control().sneak then
            if node.name == "nh_nodes:oaktimberslice3" and itemstack:get_name() == "nh_nodes:oaktimberslice" then
                core.set_node(pos, { name = "nh_nodes:campfire" })
                itemstack:take_item()
                return itemstack
            end
        end

        return core.item_place(itemstack, placer, pointed_thing)
    end,
})

-- Fogueira (estágio final) - Campfire - 4/4 firewood
register_craft_station("nh_nodes:campfire", {
    description = S("Campfire"),
    drawtype = "mesh",
    mesh = "oaktimberslice4.obj",
    tiles = { "fogueira.png" },
    use_texture_alpha = "blend",

    paramtype = "light",
    groups = { choppy = 3 },
    stack_max = 1,
    drop = {
        items = {
            { items = { "nh_nodes:oaktimberslice 4" } },
            { items = { "nh_nodes:campfiretinder" } },
        }
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 }
    },


    title = "Produção 2x2 na Fogueira", -- ✅ Campo obrigatório!

    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_campfire,

    -- Quando a fogueira é colocada, verifica se deve criar chama
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        -- Se já tiver chama marcada, cria a entidade
        if meta:get_int("has_flame") == 1 then
            core.after(0.1, function()
                -- Verifica se não existe chama já
                local objs = core.get_objects_inside_radius(pos, 0.5)
                local has_flame = false
                for _, obj in ipairs(objs) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "nh_nodes:campfire_flame_entity" then
                        has_flame = true
                        break
                    end
                end

                if not has_flame then
                    local obj = core.add_entity(pos, "nh_nodes:campfire_flame_entity")
                    if obj then
                        local ent = obj:get_luaentity()
                        if ent then
                            ent._straw_pos = pos
                        end
                    end
                end
            end)
        end
    end,

    -- Quando a fogueira é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:campfire_flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._straw_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a fogueira for removida, remove as chamas
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:campfire_flame_entity" then
                obj:remove()
            end
        end
    end,
})

---------------------------
-- ENTIDADE DA CHAMA DA PALHA
---------------------------
core.register_entity("nh_nodes:campfire_flame_entity", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        selectionbox = { -0.3, -0.3, -0.3, 0.3, 0.3, 0.3 },
        collisionbox = { -0.3, -0.3, -0.3, 0.3, 0.3, 0.3 },
        visual = "mesh",
        mesh = "flame.obj",
        textures = { "fire_basic_flame_animated.png" },
        visual_size = { x = 10, y = 10 }, -- Menor que a chama da grama
        static_save = true,
        pointable = true,
        glow = 14,
    },

    _straw_pos = nil,
    _timer = 0,
    _anim_timer = 0,
    _current_frame = 0,

    on_activate = function(self, staticdata)
        if staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.straw_pos then
                self._straw_pos = data.straw_pos
            end
        end
        self._timer = 0

        self.object:set_sprite(
            { x = 0, y = 0 },
            1,
            1.0,
            false
        )

        self.object:set_texture_mod("^[verticalframe:8:0")
    end,

    get_staticdata = function(self)
        return core.serialize({ straw_pos = self._straw_pos })
    end,

    -- Detecta quando é golpeado para acender tochas
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()

        -- Verifica se está segurando uma tocha apagada
        if wielded_name == "nh_nodes:torch" then
            wielded:take_item()
            puncher:set_wielded_item(wielded)

            local inv = puncher:get_inventory()
            if inv then
                local leftover = inv:add_item("main", "nh_nodes:torch2")
                if not leftover:is_empty() then
                    local pos = puncher:get_pos()
                    core.add_item(pos, leftover)
                end
            end

            core.sound_play("fire_flint_and_steel", {
                pos = self.object:get_pos(),
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    on_step = function(self, dtime)
        self._timer = self._timer + dtime
        self._anim_timer = self._anim_timer + dtime

        -- Anima a textura
        if self._anim_timer > (1.0 / 8) then
            self._anim_timer = 0
            self._current_frame = (self._current_frame + 1) % 8
            self.object:set_texture_mod("^[verticalframe:8:" .. self._current_frame)
        end

        -- Verifica se a palha ainda existe
        if self._timer > 0.5 then
            self._timer = 0

            if not self._straw_pos then
                self.object:remove()
                return
            end

            local node = core.get_node(self._straw_pos)

            -- Se a palha foi removida, remove a chama
            if node.name ~= "nh_nodes:campfire" then
                self.object:remove()
                return
            end

            -- Verifica se ainda deve ter chama
            local meta = core.get_meta(self._straw_pos)
            if meta:get_int("has_flame") ~= 1 then
                self.object:remove()
                return
            end
        end
    end,
})

core.register_node("nh_nodes:spinningtop", {
    description = S("Oak Spinningtop") .. "\n" .. S("[Battle Toy]"),
    drawtype = "mesh",
    mesh = "piao.obj",
    tiles = { "oakpiao.png" },
    inventory_image = "oakpiaoinv.png",

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -0.25, y = 0.5, z = 0 },
        rot = { x = 0, y = 0, z = 45 },
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },

    -- Tornar comestível
    --on_use = function(itemstack, user, pointed_thing)
    --restore_hunger(user, 2)  -- Restaura 4 pontos
    --itemstack:take_item()
    --return itemstack
    --end,

    -- Spawna o mob ao colocar o node no chão
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above -- posição onde vai spawnar

        -- Spawna o mob
        local mob = minetest.add_entity(pos, "nh_mob:spinningtop")

        if mob then
            -- Aplica a rotação do jogador ao mob
            if placer then
                local yaw = placer:get_look_horizontal()
                mob:set_yaw(yaw)
            end

            -- Consome o item da mão
            itemstack:take_item()
        end

        return itemstack
    end,
})

core.register_node("nh_nodes:spinningtop2", {
    description = S("Palm Spinningtop") .. "\n" .. S("[Battle Toy]"),
    drawtype = "mesh",
    mesh = "piao.obj",
    tiles = { "palmpiao.png" },
    inventory_image = "palmpiaoinv.png",

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -0.25, y = 0.5, z = 0 },
        rot = { x = 0, y = 0, z = 45 },
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },


    -- Spawna o mob ao colocar o node no chão
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above -- posição onde vai spawnar

        -- Spawna o mob
        local mob = minetest.add_entity(pos, "nh_mob:spinningtop2")

        if mob then
            -- Aplica a rotação do jogador ao mob
            if placer then
                local yaw = placer:get_look_horizontal()
                mob:set_yaw(yaw)
            end

            -- Consome o item da mão
            itemstack:take_item()
        end

        return itemstack
    end,
})

core.register_node("nh_nodes:spinningtop3", {
    description = S("Pine Spinningtop") .. "\n" .. S("[Battle Toy]"),
    drawtype = "mesh",
    mesh = "piao.obj",
    tiles = { "pinepiao.png" },
    inventory_image = "pinepiaoinv.png",

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -0.25, y = 0.5, z = 0 },
        rot = { x = 0, y = 0, z = 45 },
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },

    -- Spawna o mob ao colocar o node no chão
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above -- posição onde vai spawnar

        -- Spawna o mob
        local mob = minetest.add_entity(pos, "nh_mob:spinningtop3")

        if mob then
            -- Aplica a rotação do jogador ao mob
            if placer then
                local yaw = placer:get_look_horizontal()
                mob:set_yaw(yaw)
            end

            -- Consome o item da mão
            itemstack:take_item()
        end

        return itemstack
    end,
})


-- ========================================
-- EXEMPLOS DE USO
-- ========================================

-- Exemplo 1: Mesa de Craft 2x2x2 (original)
register_craft_station("nh_nodes:craft_table", {
    description = S("Production Bench"),
    drawtype = "mesh",
    mesh = "craft_table.obj",
    tiles = { "craft_table.png" },
    title = "Bancada de Produção 2x2x2",
    grid_size = 8,

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    positions = {
        { x = -0.2, y = 0.7, z = -0.2 }, { x = 0.2, y = 0.7, z = -0.2 },
        { x = -0.2, y = 0.7, z = 0.2 }, { x = 0.2, y = 0.7, z = 0.2 },
        { x = -0.2, y = 1.1, z = -0.2 }, { x = 0.2, y = 1.1, z = -0.2 },
        { x = -0.2, y = 1.1, z = 0.2 }, { x = 0.2, y = 1.1, z = 0.2 },
    },

    tool_slot_pos = { x = 5.6, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.7, z = 0 },

    layers = {
        { name = "Camada Inferior", x = 0.5, width = 2, height = 2, start_index = 0 },
        { name = "Camada Superior", x = 3,   width = 2, height = 2, start_index = 4 },
    },

    recipes = recipes_table
})

-- Exemplo 2: Fornalha 3x3 simples (SEM mesh, usando drawtype normal)
register_craft_station("nh_nodes:furnace", {
    description = S("Furnace"),
    title = S("3x3 Furnace"),
    drawtype = "mesh",
    mesh = "furnace.obj",
    tiles = { "stonefurnace.png" }, --cobblestone.png
    paramtype = "light",            -- Necessário para iluminação correta
    paramtype2 = "facedir",         -- IMPORTANTE: paramtype2, não paramtype

    -- Caixas de colisão e seleção
    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 2.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 2.5, 0.5 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -2.5, y = -1, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = -1.5, y = -1, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    grid_size = 9,

    positions = {
        { x = -0.3, y = 0.9, z = -0.3 }, { x = 0, y = 0.9, z = -0.3 }, { x = 0.3, y = 0.9, z = -0.3 },
        { x = -0.3, y = 0.9, z = 0 }, { x = 0, y = 0.9, z = 0 }, { x = 0.3, y = 0.9, z = 0 },
        { x = -0.3, y = 0.9, z = 0.3 }, { x = 0, y = 0.9, z = 0.3 }, { x = 0.3, y = 0.9, z = 0.3 },
    },

    tool_slot_pos = { x = 4.3, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.2, z = 0 },

    layers = {
        { name = S("3x3 Grid"), x = 0.5, width = 3, height = 3, start_index = 0 },
    },

    recipes = recipes_furnace
})

-- Bancada Avançada 3x3x3 simples (SEM mesh)
register_craft_station("nh_nodes:advanced_bench", {
    description = S("Advanced Bench"),
    -- mesh = nil,  -- Opcional
    tiles = { "" }, --advanced_bench.png
    title = S("3x3x3 Advanced Bench"),
    grid_size = 4,

    positions = {
        { x = -0.2, y = 0.9, z = -0.2 }, { x = 0.2, y = 0.9, z = -0.2 },
        { x = -0.2, y = 0.9, z = 0.2 }, { x = 0.2, y = 0.9, z = 0.2 },
    },

    tool_slot_pos = { x = 3.1, y = 1 }, -- ajusta x e y até ficar no lugar certo

    output_position = { x = 0, y = 1.4, z = 0 },

    layers = {
        { name = S("2x2 Grid"), x = 0.5, width = 2, height = 2, start_index = 0 },
    },

    recipes = recipes_table
})


-- Prancha
core.register_node("nh_nodes:oakplank", {
    description = S("Oak Plank"),
    drawtype = "mesh",
    mesh = "oakplank.obj",
    tiles = { "oakwood.png" },
    groups = { choppy = 3 },

    paramtype = "light",
    paramtype2 = "wallmounted",

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -0.5, y = -0.9, z = 0.2 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 0, y = -0.9, z = -1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.5, 0, -0.5, 0.5, 0.5, 0.5 },
        wall_bottom = { -0.5, -0.5, -0.5, 0.5, 0, 0.5 },
        wall_side = { -0.5, -0.5, -0.5, 0, 0.5, 0.5 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { 0, 0, 0, 0, 0.5, 0 },
        wall_bottom = { 0, -0.5, 0, 0, 0, 0 },
        wall_side = { -0.5, 0, 0, -0.5, 0.5, 0 },
    },
})

-- Tábua
core.register_node("nh_nodes:oakboard", {
    description = S("Oak Board"),
    drawtype = "mesh",
    mesh = "oakboard.obj",
    tiles = { "oakwood.png" },
    groups = { choppy = 3 },
    paramtype = "light",
    paramtype2 = "facedir",

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, 0.38, 0.5, 0.5, 0.5 },
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.03, 0.5, 0.5, 0.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0, y = -0.9, z = -0.8 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 0, y = -0.9, z = -1.2 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

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
        local player_dir = core.yaw_to_dir(yaw)
        local player_facedir = core.dir_to_facedir(player_dir)

        local facedir

        if click_dir.y == 1 then
            -- Clicado no topo (chão) - tábua em pe com a lateral fina pra mim
            facedir = player_facedir
        elseif click_dir.y == -1 then
            -- Clicado embaixo (teto) - tábua deitada invertida
            facedir = player_facedir + 20
        elseif click_dir.z ~= 0 then
            -- Parede Norte/Sul (eixo Z)
            local wall_facedir = core.dir_to_facedir(click_dir)
            facedir = wall_facedir + 4
        else
            -- Parede Leste/Oeste (eixo X)
            local wall_facedir = core.dir_to_facedir(click_dir)
            facedir = wall_facedir + 12 -- Valor diferente para paredes X
        end

        return core.item_place(itemstack, placer, pointed_thing, facedir)
    end,
})

-- Tarugo
core.register_node("nh_nodes:oakdowel", {
    description = S("Oak Dowel") .. "\n" .. S("Reach: +2"),
    drawtype = "mesh",
    mesh = "oakdowel.obj",
    tiles = { "oakwood.png" },
    groups = { choppy = 3 },

    range = 5,

    paramtype = "light",
    paramtype2 = "wallmounted",

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.1, -0.5, -0.1, 0.1, 0.5, 0.1 },
        wall_bottom = { -0.1, -0.5, -0.1, 0.1, 0.5, 0.1 },
        wall_side = { -0.5, -0.1, -0.1, 0.5, 0.1, 0.1 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.0625, 0.5 - 0.5625, -0.0625, 0.0625, 0.5, 0.0625 },
        wall_bottom = { -0.0625, -0.5, -0.0625, 0.0625, -0.5 + 0.5625, 0.0625 },
        wall_side = { -0.5, -0.0625, -0.0625, -0.5 + 0.28125, 0.5, 0.0625 },
    },
})

core.register_node("nh_nodes:torch", {
    description = S("Torch"),
    drawtype = "mesh",
    mesh = "torch.obj",
    tiles = { "torch.png" },
    --inventory_image = "tocha_inventario.png",
    --wield_image = "tocha_inventario.png",

    paramtype = "light",
    --paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,

    groups = { choppy = 2, oddly_breakable_by_hand = 3, flammable = 1 }, -- dig_immediate = 3, attached_node = 1

    collision_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },

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

    -- Quando bater na tocha apagada com tocha acesa ou flame
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()

        -- Verifica se está batendo com tocha acesa ou flame
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Pega a orientação (facedir/wallmounted) da tocha apagada
            local param2 = node.param2

            -- Troca para tocha acesa mantendo a orientação
            core.set_node(pos, { name = "nh_nodes:torch2", param2 = param2 })

            -- Adiciona a chama como entidade (mesmo código do after_place_node)
            local flame_pos = { x = pos.x, y = pos.y + 1, z = pos.z }
            local obj = core.add_entity(flame_pos, "nh_nodes:torch_flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._torch_pos = pos
                end
            end

            -- Efeito sonoro de acender fogo
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)

            -- Partículas de faísca (opcional)
            core.add_particlespawner({
                amount = 5,
                time = 0.1,
                minpos = vector.subtract(pos, { x = 0.1, y = 0.1, z = 0.1 }),
                maxpos = vector.add(pos, { x = 0.1, y = 0.3, z = 0.1 }),
                minvel = { x = -0.5, y = 0.5, z = -0.5 },
                maxvel = { x = 0.5, y = 1.5, z = 0.5 },
                minacc = { x = 0, y = -2, z = 0 },
                maxacc = { x = 0, y = -1, z = 0 },
                minexptime = 0.1,
                maxexptime = 0.3,
                minsize = 0.5,
                maxsize = 1,
                glow = 14,
                texture = "spark_particle.png^[colorize:#FF8800:150",
            })
        end
    end,
})

core.register_node("nh_nodes:torch2", {
    description = S("Torch Lit"),
    drawtype = "mesh",
    mesh = "torch.obj",
    tiles = {
        "torchfire.png", -- Textura da madeira/base
    },
    --inventory_image = "tocha_inventario.png",
    --wield_image = "tocha_inventario.png",

    paramtype = "light",
    --paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    stack_max = 1,                                                       -- limita a 1 tocha acesa por slot

    light_source = 13,                                                   -- Luminosidade (0-14, onde 14 é máximo)

    groups = { choppy = 2, oddly_breakable_by_hand = 3, flammable = 1 }, -- REMOVIDO: attached_node = 1, dig_immediate = 3

    collision_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },

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

    -- Quando colocada, adiciona a chama no mesmo lugar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        -- Posição da chama (1 bloco acima)
        local flame_pos = { x = pos.x, y = pos.y + 1, z = pos.z }

        -- Cria a ENTIDADE da chama
        local obj = core.add_entity(flame_pos, "nh_nodes:torch_flame_entity")
        if obj then
            local ent = obj:get_luaentity()
            if ent then
                ent._torch_pos = pos
            end
        end
    end,

    -- Quando a tocha é destruída, remove a entidade da chama
    after_destruct = function(pos)
        local flame_pos = { x = pos.x, y = pos.y + 1, z = pos.z }
        local objs = core.get_objects_inside_radius(flame_pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:torch_flame_entity" then
                obj:remove()
            end
        end
    end,
})
-- Node invisível que emite luz
core.register_node("nh_nodes:torch_light", {
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    buildable_to = true,
    light_source = 13,
    groups = { not_in_creative_inventory = 1 },
})

-- Registra a entidade de luz
core.register_node("nh_nodes:crystal_light", {
    drawtype = "airlike", -- invisível, não cria bolsão
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false,
    buildable_to = true,
    light_source = 13,
    groups = { not_in_creative_inventory = 1 },
})

core.register_node("nh_nodes:torch_flame", {
    drawtype = "mesh",
    mesh = "torchflame.obj", -- Você precisará criar esse mesh
    tiles = {
        {
            name = "fire_basic_flame_animated.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1.0,
            },
        }
    },
    stack_max = 1,               -- limita a 1 tocha acesa por slot
    paramtype = "light",
    paramtype2 = "facedir",      -- ADICIONEI: necessário para meshes com transparência
    sunlight_propagates = true,
    use_texture_alpha = "blend", -- ADICIONEI: ativa a transparência
    walkable = false,
    pointable = true,
    diggable = false,
    buildable_to = false,
    damage_per_second = 4,
    groups = { not_in_creative_inventory = 1 },
    drop = "",

    --visual_scale = 1,

})


---------------------------
-- ENTIDADE DA CHAMA DA TOCHA
---------------------------
core.register_entity("nh_nodes:torch_flame_entity", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        -- Selection box maior e melhor posicionada
        selectionbox = { -0.2, -0.7, -0.2, 0.2, -0.3, 0.2 },
        collisionbox = { -0.2, -0.7, -0.2, 0.2, -0.3, 0.2 },
        visual = "mesh",
        mesh = "torchflame.obj",
        textures = { "fire_basic_flame_animated.png" },
        visual_size = { x = 10, y = 10 },
        static_save = true,
        pointable = true,
        glow = 14,
    },

    _torch_pos = nil,
    _timer = 0,
    _anim_timer = 0,
    _current_frame = 0,

    on_activate = function(self, staticdata)
        if staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.torch_pos then
                self._torch_pos = data.torch_pos
            end
        end
        self._timer = 0

        -- Configura a animação da textura
        self.object:set_sprite(
            { x = 0, y = 0 },
            1,
            1.0,
            false
        )

        self.object:set_texture_mod("^[verticalframe:8:0")
    end,

    get_staticdata = function(self)
        return core.serialize({ torch_pos = self._torch_pos })
    end,

    -- Detecta quando é golpeado com tocha apagada
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()

        -- Verifica se está segurando uma tocha apagada
        if wielded_name == "nh_nodes:torch" then
            -- Remove a tocha apagada do inventário
            wielded:take_item()
            puncher:set_wielded_item(wielded)

            -- Adiciona a tocha acesa ao inventário
            local inv = puncher:get_inventory()
            if inv then
                local leftover = inv:add_item("main", "nh_nodes:torch2")
                -- Se o inventário estiver cheio, dropa no chão
                if not leftover:is_empty() then
                    local pos = puncher:get_pos()
                    core.add_item(pos, leftover)
                end
            end

            -- Efeito sonoro
            core.sound_play("fire_flint_and_steel", {
                pos = self.object:get_pos(),
                gain = 0.5,
                max_hear_distance = 8,
            }, true)

            -- Partículas de faísca
            core.add_particlespawner({
                amount = 5,
                time = 0.1,
                minpos = vector.subtract(self.object:get_pos(), { x = 0.1, y = 0.1, z = 0.1 }),
                maxpos = vector.add(self.object:get_pos(), { x = 0.1, y = 0.1, z = 0.1 }),
                minvel = { x = -0.5, y = 0.5, z = -0.5 },
                maxvel = { x = 0.5, y = 1.5, z = 0.5 },
                minacc = { x = 0, y = -2, z = 0 },
                maxacc = { x = 0, y = -1, z = 0 },
                minexptime = 0.1,
                maxexptime = 0.3,
                minsize = 0.5,
                maxsize = 1,
                glow = 14,
                texture = "spark_particle.png^[colorize:#FF8800:150",
            })
        end
    end,

    on_step = function(self, dtime)
        self._timer = self._timer + dtime
        self._anim_timer = self._anim_timer + dtime

        -- Anima a textura (8 frames, 1 segundo de duração total)
        if self._anim_timer > (1.0 / 8) then
            self._anim_timer = 0
            self._current_frame = (self._current_frame + 1) % 8
            self.object:set_texture_mod("^[verticalframe:8:" .. self._current_frame)
        end

        -- Verifica se a tocha ainda existe
        if self._timer > 0.5 then
            self._timer = 0

            if not self._torch_pos then
                self.object:remove()
                return
            end

            local node = core.get_node(self._torch_pos)

            -- Se a tocha foi removida ou apagada, remove a chama
            if node.name ~= "nh_nodes:torch2" then
                self.object:remove()
                return
            end
        end
    end,
})

core.register_node("nh_nodes:flame", {
    drawtype = "mesh",
    mesh = "flame.obj", -- Você precisará criar esse mesh
    tiles = {
        {
            name = "fire_basic_flame_animated.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,
                aspect_h = 16,
                length = 1.0,
            },
        }
    },
    paramtype = "light",
    paramtype2 = "facedir",      -- ADICIONEI: necessário para meshes com transparência
    sunlight_propagates = true,
    use_texture_alpha = "blend", -- ADICIONEI: ativa a transparência
    walkable = false,
    pointable = false,
    diggable = false,
    buildable_to = true,
    damage_per_second = 4,
    groups = { not_in_creative_inventory = 1 },
    drop = "",

    --visual_scale = 1,

})

core.register_node("nh_nodes:torch3", {
    description = S("Torch Extinguished"),
    drawtype = "mesh",
    mesh = "torch.obj",
    tiles = { "torch3.png" },
    --inventory_image = "tocha_inventario.png",
    --wield_image = "tocha_inventario.png",

    --paramtype = "light",
    --paramtype2 = "wallmounted",
    --sunlight_propagates = true,
    walkable = false,

    groups = { choppy = 2, oddly_breakable_by_hand = 3, flammable = 1 }, -- dig_immediate = 3, attached_node = 1

    collision_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, 0.37, 0.1 }
    },

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

-- Folhas de carvalho
core.register_node("nh_nodes:leaves", {
    description = S("Oak Leaves"),
    drawtype = "liquid",
    waving = 3,
    --drawtype = "mesh",
    -- mesh = "oakleaves.obj",
    tiles = { "oakleaves3.png" },
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:limb" } },
            { items = { "nh_nodes:oakresin" } },
        }
    },
    walkable = false,
    use_texture_alpha = "blend",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves",
    liquid_alternative_source = "nh_nodes:leaves",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

})

-- Registra uma versão "dentro d'água" (da folha de carvalho)
core.register_node("nh_nodes:leavesrelief", {
    description = S("Leaves Relief"),
    drawtype = "plantlike_rooted",
    waving = 3,
    tiles = { "oakleaves3.png" },
    special_tiles = { { name = "leavesrelief.png", tileable_vertical = true } },
    inventory_image = "leavesrelief.png",
    wield_image = "leavesrelief.png",
    paramtype = "light",
    paramtype2 = "leveled",
    use_texture_alpha = "clip",
    groups = { snappy = 3, tree_leaves = 1 },
    walkable = false,
    drop = "", -- não dropa nada
    node_dig_prediction = "",
    node_placement_prediction = "",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, { name = "nh_nodes:leaves" })
    end,

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos)
        local node = minetest.get_node(pos)
        if node.name ~= "nh_nodes:leavesrelief" then
            return false
        end

        -- O node "pai" do plantlike_rooted é o de BAIXO
        local below = { x = pos.x, y = pos.y + 2, z = pos.z }
        local below_name = minetest.get_node(below).name

        if below_name ~= "nh_nodes:leaves" and below_name ~= "nh_nodes:leavesrelief" then
            minetest.remove_node(pos)
            return false
        end

        return true
    end,
})

core.register_node("nh_nodes:leavesrelief", {
    description = S("Leaves Relief"),
    drawtype = "plantlike_rooted",
    waving = 3,
    tiles = { "oakleaves3.png" },
    special_tiles = { { name = "leavesrelief.png", tileable_vertical = true } },
    inventory_image = "leavesrelief.png",
    wield_image = "leavesrelief.png",
    paramtype = "light",
    paramtype2 = "leveled",
    use_texture_alpha = "clip",
    groups = { snappy = 3, tree_leaves = 1 },
    walkable = false,
    drop = "", -- não dropa nada
    node_dig_prediction = "",
    node_placement_prediction = "",

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, { name = "nh_nodes:leaves" })
    end,

    on_construct = function(pos)
        minetest.get_node_timer(pos):start(1.0)
    end,

    on_timer = function(pos)
        local node = minetest.get_node(pos)
        if node.name ~= "nh_nodes:leavesrelief" then
            return false
        end

        -- O node "pai" do plantlike_rooted é o de BAIXO
        local below = { x = pos.x, y = pos.y + 2, z = pos.z }
        local below_name = minetest.get_node(below).name

        if below_name ~= "nh_nodes:leaves" and below_name ~= "nh_nodes:leavesrelief" then
            minetest.remove_node(pos)
            return false
        end

        return true
    end,
})

core.register_node("nh_nodes:kelp", {
    description = S("Kelp") .. "\n" .. S("[Algae]"),
    drawtype = "plantlike_rooted",
    waving = 1,
    tiles = { "areia_molhada.png" },
    special_tiles = { { name = "kelp.png", tileable_vertical = true } },
    inventory_image = "kelp.png",
    wield_image = "kelp.png",
    paramtype = "light",
    paramtype2 = "leveled",
    groups = { snappy = 3 },
    selection_box = {
        type = "fixed",
        fixed = { { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
            { -2 / 16, 0.5,  -2 / 16, 2 / 16, 3.5, 2 / 16 },
        },
    },
    node_dig_prediction = "nh_nodes:wet_sand",
    node_placement_prediction = "nh_nodes:wet_sand",
    --sounds = default.node_sound_sand_defaults({
    --    dig = {name = "default_dig_snappy", gain = 0.2},
    --    dug = {name = "default_grass_footstep", gain = 0.25},
    --}),
    on_place = function(itemstack, placer, pointed_thing)
        -- Call on_rightclick if the pointed node defines it
        if pointed_thing.type == "node" and not (placer and placer:is_player()
            ) then
            local node_ptu = minetest.get_node(pointed_thing.under)
            local def_ptu = minetest.registered_nodes[node_ptu.name]
            if def_ptu and def_ptu.on_rightclick then
                return def_ptu.on_rightclick(pointed_thing.under, node_ptu, placer,
                    itemstack, pointed_thing)
            end
        end
        local pos = pointed_thing.under
        if minetest.get_node(pos).name ~= "nh_nodes:wet_sand" then
            return itemstack
        end
        local height = math.random(3, 6)
        local pos_top = { x = pos.x, y = pos.y + height, z = pos.z }
        local node_top = minetest.get_node(pos_top)
        local def_top = minetest.registered_nodes[node_top.name]
        local player_name = placer:get_player_name()
        if def_top and def_top.liquidtype == "source" and
            minetest.get_item_group(node_top.name, "water") > 0 then
            if not minetest.is_protected(pos, player_name) and
                not minetest.is_protected(pos_top, player_name) then
                minetest.set_node(pos, {
                    name = "nh_nodes:kelp",
                    param2 = height * 16
                })
                if not minetest.is_creative_enabled(player_name) then
                    itemstack:take_item()
                end
            else
                minetest.chat_send_player(player_name, S("Node is protected"))
                minetest.record_protection_violation(pos, player_name)
            end
        end
        return itemstack
    end,
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        minetest.set_node(pos, { name = "nh_nodes:wet_sand" })
    end
})

-- Folhas de pinheiro
core.register_node("nh_nodes:pineleaves", {
    description = S("Pine Leaves"),
    drawtype = "mesh",
    mesh = "pineleaves.obj",
    tiles = { "pineleaves.png" },
    waving = 1,
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:limb" } },
            { items = { "nh_nodes:oakresin" } },
        }
    },
    walkable = false,
    use_texture_alpha = "blend",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:pineleaves",
    liquid_alternative_source = "nh_nodes:pineleaves",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

})

-- Folhas de macieira
core.register_node("nh_nodes:appleleaves", {
    description = S("Apple Tree Leaves"),
    drawtype = "mesh",
    mesh = "appleleaves.obj",
    tiles = { "appleleaves.png" },
    waving = 1,
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = "blend",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:appleleaves",
    liquid_alternative_source = "nh_nodes:appleleaves",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },
})

-- Folhas com 1 maça
core.register_node("nh_nodes:leaves_apple", {
    description = S("Leaves with Apple"),
    drawtype = "mesh",
    mesh = "leavesapple1.obj",
    tiles = { "appleleaves.png" },
    waving = 2,
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:apple" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = "clip",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_apple",
    liquid_alternative_source = "nh_nodes:leaves_apple",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:apple")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:appleleaves" })
        end
        return itemstack
    end,
})

-- Folhas com 2 maças
core.register_node("nh_nodes:leaves_apple2", {
    description = S("Leaves with 2 Apples"),
    drawtype = "mesh",
    mesh = "leavesapple2.obj",
    tiles = { "appleleaves.png" },
    waving = 2,
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:apple 2" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = "clip",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_apple2",
    liquid_alternative_source = "nh_nodes:leaves_apple2",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:apple")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:leaves_apple" })
        end
        return itemstack
    end,
})

-- Folhas com 3 maças
core.register_node("nh_nodes:leaves_apple3", {
    description = S("Leaves with 3 Apples"),
    drawtype = "mesh",
    mesh = "leavesapple3.obj",
    tiles = { "appleleaves.png" },
    waving = 2,
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:apple 3" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = "clip",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_apple3",
    liquid_alternative_source = "nh_nodes:leaves_apple3",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.7 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},


    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:apple")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:leaves_apple2" })
        end
        return itemstack
    end,
})

-- Folhas mirtilo
core.register_node("nh_nodes:blueberryleaves", {
    description = S("Blueberry Leaves"),
    drawtype = "liquid",
    waving = 1,
    tiles = { "folhasmirtilo.png" },
    groups = { snappy = 3 },
    drop = "nh_nodes:stick",
    walkable = false,
    use_texture_alpha = "blend",
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:blueberryleaves",
    liquid_alternative_source = "nh_nodes:blueberryleaves",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },
})

-- Folhas com 4 blueberry
core.register_node("nh_nodes:leaves_blueberry4", {
    description = S("Leaves with 4 Blueberries"),
    drawtype = "allfaces_optional",
    waving = 1,
    tiles = { "folhasmirtilo4.png" },
    groups = { snappy = 3 },
    drop = {
        items = {
            { items = { "nh_nodes:blueberry 4" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_blueberry4",
    liquid_alternative_source = "nh_nodes:leaves_blueberry4",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:blueberry 4")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:blueberryleaves" })
        end
        return itemstack
    end,
})

core.register_node("nh_nodes:giantcrabstatue", {
    description = S("Giant Crab Statue") .. "\n" .. S("[Unknown]"),
    drawtype = "mesh",
    mesh = "giantcrabstatue.obj",
    tiles = { "giantcrabstatue.png" }, --tiles = {{name = "giantcrabstatue.png", glow = 1}},
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    groups = { falling_node = 1 },

    light_source = 7,

    collision_box = {
        type = "fixed",
        fixed = { -1.75, -0.5, -1.5, 1.75, 3.75, 1.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -1.75, -0.5, -2.5, 1.75, 3.75, 1.5 }
    },

    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then return end

        local item = puncher:get_wielded_item()
        local item_name = item:get_name()

        -- Verifica se o item na mão é a esfera (qualquer variante)
        if item_name ~= "nh_nodes:sphere" and item_name ~= "nh_nodes:sphere_placed" then
            core.chat_send_player(puncher:get_player_name(), S("This won't work... I need something more powerful"))
            return
        end

        -- Efeito de partículas de destruição
        core.add_particlespawner({
            amount = 50,
            time = 2,
            minpos = { x = pos.x - 2.5, y = pos.y - 0.5, z = pos.z - 2.5 },
            maxpos = { x = pos.x + 2.5, y = pos.y + 4, z = pos.z + 2.5 },
            minvel = { x = -6, y = 6, z = -6 },
            maxvel = { x = 6, y = 12, z = 6 },
            minacc = { x = 0, y = -20, z = 0 },
            maxacc = { x = 0, y = -20, z = 0 },
            minexptime = 0.5,
            maxexptime = 1.5,
            minsize = 0.5,
            maxsize = 2,
            glow = 14,
            texture = {
                name = "spark_particle.png^[colorize:#76008d:150", -- purpura
            },
        })

        -- Som de destruição (usa o som de dano do caranguejo)
        --core.sound_play("vulto_hurt", {pos = pos, gain = 1.0, max_hear_distance = 16})

        -- Remove a estátua
        core.remove_node(pos)

        -- Coloca areia na posição da estátua imediatamente
        core.set_node(pos, { name = "nh_nodes:wet_sand" })

        -- Spawna o Giant Crab na posição da estátua
        -- Spawna o mob após 2 segundos
        core.after(0.25, function()
            core.add_entity(pos, "nh_mob:giantcrab")
        end)

        -- Consome a esfera da mão do jogador
        local inv = puncher:get_inventory()
        item:take_item(1)
        puncher:set_wielded_item(item)

        -- Avisa o jogador
        core.chat_send_player(puncher:get_player_name(), S("The statue shatters... something awakens!"))
    end,
})

core.register_node("nh_nodes:redcrystal", {
    description = S("Red Crystal") .. "\n" .. S("[Light/Air]") .. "\n" .. S("(Squat down to breathe)"),
    drawtype = "mesh",
    mesh = "redcrystal.obj",
    tiles = { "redcrystal.png" },
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    groups = { oddly_breakable_by_hand = 1 },

    light_source = 14,

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    on_punch = function(pos, node, puncher, pointed_thing)
        -- Efeito de partículas de destruição
        core.add_particlespawner({
            amount = 50,
            time = 0.5,
            minpos = { x = pos.x - 2.5, y = pos.y - 0.5, z = pos.z - 2.5 },
            maxpos = { x = pos.x + 2.5, y = pos.y + 4, z = pos.z + 2.5 },
            minvel = { x = -6, y = 6, z = -6 },
            maxvel = { x = 6, y = 12, z = 6 },
            minacc = { x = 0, y = -20, z = 0 },
            maxacc = { x = 0, y = -20, z = 0 },
            minexptime = 0.5,
            maxexptime = 1.5,
            minsize = 0.5,
            maxsize = 2,
            glow = 14,
            texture = {
                name = "spark_particle.png^[colorize:#76008d:150", -- purpura
            },
        })

        -- Som de destruição (usa o som de dano do caranguejo)
        --core.sound_play("vulto_hurt", {pos = pos, gain = 1.0, max_hear_distance = 16})
    end,
})

core.register_node("nh_nodes:sentinelstatue", {
    description = S("Sentinel Statue") .. "\n" .. S("[Unknown]"),
    drawtype = "mesh",
    mesh = "skydragon.obj",
    tiles = { "sentinelstatue.png" }, --tiles = {{name = "giantcrabstatue.png", glow = 1}},
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    groups = { falling_node = 1 },

    light_source = 7,

    collision_box = {
        type = "fixed",
        fixed = { -0.65, -0.5, -0.65, 0.65, 3.5, 0.65 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.65, -0.5, -0.65, 0.65, 3.5, 0.65 }
    },

    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then return end

        local item = puncher:get_wielded_item()
        local item_name = item:get_name()

        -- Verifica se o item na mão é a esfera (qualquer variante)
        if item_name ~= "nh_nodes:sphere" and item_name ~= "nh_nodes:sphere_placed" then
            core.chat_send_player(puncher:get_player_name(), S("This won't work... I need something more powerful"))
            return
        end

        -- Efeito de partículas de destruição
        core.add_particlespawner({
            amount = 50,
            time = 2,
            minpos = { x = pos.x - 2.5, y = pos.y - 0.5, z = pos.z - 2.5 },
            maxpos = { x = pos.x + 2.5, y = pos.y + 4, z = pos.z + 2.5 },
            minvel = { x = -6, y = 6, z = -6 },
            maxvel = { x = 6, y = 12, z = 6 },
            minacc = { x = 0, y = -20, z = 0 },
            maxacc = { x = 0, y = -20, z = 0 },
            minexptime = 0.5,
            maxexptime = 1.5,
            minsize = 0.5,
            maxsize = 2,
            glow = 1,
            texture = {
                name = "spark_particle.png^[colorize:#FF8800:150", -- dourado
            },
        })

        -- Som de destruição (usa o som de dano do caranguejo)
        --core.sound_play("vulto_hurt", {pos = pos, gain = 1.0, max_hear_distance = 16})

        -- Remove a estátua
        core.remove_node(pos)

        -- Coloca grama na posição da estátua imediatamente
        --core.set_node(pos, {name = "nh_nodes:wet_sand"})

        -- Spawna o Giant Crab na posição da estátua
        -- Spawna o mob após 2 segundos
        core.after(0.25, function()
            core.add_entity(pos, "nh_mob:sentinel")
        end)

        -- Consome a esfera da mão do jogador
        local inv = puncher:get_inventory()
        item:take_item(1)
        puncher:set_wielded_item(item)

        -- Avisa o jogador
        core.chat_send_player(puncher:get_player_name(), S("The statue shatters... something awakens!"))
    end,
})

core.register_node("nh_nodes:sphere", {
    description = S("Sphere of Vertices") .. "\n" .. S("[Unknown]"),
    drawtype = "mesh",
    mesh = "ball_crystal.obj",
    tiles = { "ball2.png" },

    sunlight_propagates = true,
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1, not_in_creative_inventory = 0 },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    -- Ao colocar: troca para a versão invisível e spawna entidades
    after_place_node = function(pos, placer, itemstack)
        core.set_node(pos, { name = "nh_nodes:sphere_placed" })
        core.add_entity(pos, "nh_nodes:sphere_anim")
        core.add_entity(pos, "nh_nodes:crystal_anim")
    end,
})

-- Nó invisível (versão que fica no mundo)
core.register_node("nh_nodes:sphere_placed", {
    description = S("Bubble of Vertices") .. "\n" .. S("[Unknown]"),
    drawtype = "mesh",
    mesh = "ball2.obj",
    tiles = { "empty.png" }, -- PNG 1x1 totalmente transparente

    sunlight_propagates = true,
    use_texture_alpha = "blend",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1, not_in_creative_inventory = 1 },
    light_source = 9,

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    -- Ao quebrar: remove entidades e dropa o item original
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        for _, obj in ipairs(core.get_objects_inside_radius(pos, 0.6)) do
            local ent = obj:get_luaentity()
            if ent and (ent.name == "nh_nodes:sphere_anim" or ent.name == "nh_nodes:crystal_anim") then
                obj:remove()
            end
        end
        -- Dropa o item visível (com textura) em vez do invisível
        digger:get_inventory():add_item("main", "nh_nodes:sphere")
    end,

    -- Sem drop automático (já feito manualmente acima)
    drop = "",
})

-- Entidade só visual, com a animação do GLB
core.register_entity("nh_nodes:sphere_anim", {
    initial_properties = {
        visual = "mesh",
        mesh = "ball.glb",
        textures = { "ball.png" },
        visual_size = { x = 10, y = 10 },
        collisionbox = { 0, 0, 0, 0, 0, 0 }, -- sem colisão própria
        physical = false,
        is_visible = true,
        glow = 4,
    },


    on_activate = function(self, staticdata)
        self.object:set_animation(
            { x = 0, y = 150 },
            15,
            0,
            true
        )
        --   self.object:set_properties({
        --       use_texture_alpha = true,
        --       textures = {
        --           "ball.png",
        --           "ball.png",
        --       },
        --   })
    end,

    on_step = function(self, dtime)
    end,

    get_staticdata = function(self)
        return "saved"
    end,
})


-- Entidade só visual, com a animação do GLB
core.register_entity("nh_nodes:crystal_anim", {
    initial_properties = {
        visual = "mesh",
        mesh = "crystal.glb",
        textures = { "ball.png" },
        visual_size = { x = 10, y = 10 },
        collisionbox = { 0, 0, 0, 0, 0, 0 }, -- sem colisão própria
        physical = false,
        is_visible = true,
        --glow = 10,
    },


    on_activate = function(self, staticdata)
        self.object:set_animation(
            { x = 0, y = 150 },
            0.05,
            0,
            true
        )
        self.object:set_properties({
            use_texture_alpha = true,
            --       textures = {
            --           "ball.png",
            --           "ball.png",
            --       },
        })
    end,

    on_step = function(self, dtime)
    end,

    get_staticdata = function(self)
        return "saved"
    end,
})


core.register_node("nh_nodes:orb_empty", {
    description = S("Orb") .. S("(Empty)") .. "\n" .. S("[Mob Catcher]"),
    drawtype = "mesh",
    mesh = "orb.obj",
    tiles = { "orb_node.png" },
    inventory_image = "orbspawner.png",

    sunlight_propagates = true,
    use_texture_alpha = "blend",

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.8, y = 0, z = 0 },
        --rot = {x = 90, y = 0, z = 90}
    },
    wielded_visual_size = { x = 0.2, y = 0.2, z = 0.2 },

    collision_box = {
        type = "fixed",
        fixed = { -0.14, -0.5, -0.14, 0.14, 0, 0.14 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.14, -0.5, -0.14, 0.14, -0.15, 0.14 }
    },
})

-- Função auxiliar para registrar o "ovo" como node com mesh
function register_orb_egg(mob_name, description, texture)
    -- "nh_mob:octopus" → "octopus_orb"
    local short_name = mob_name:match(":(.+)") .. "" -- "_orb"

    core.register_node("nh_mob:" .. short_name, {
        description = description .. "\n" .. S("[Mob Spawner]"),
        drawtype = "mesh",
        mesh = "orb.obj",
        tiles = { texture or "orb_node.png" },
        inventory_image = "orbspawner.png",

        sunlight_propagates = true,
        use_texture_alpha = "blend",
        walkable = false,
        paramtype = "light",
        paramtype2 = "facedir",
        groups = { oddly_breakable_by_hand = 1 },

        collision_box = {
            type = "fixed",
            fixed = { -0.14, -0.5, -0.14, 0.14, 0, 0.14 }
        },
        selection_box = {
            type = "fixed",
            fixed = { -0.14, -0.5, -0.14, 0.14, -0.15, 0.14 }
        },

        -- Configuração mão direita
        wielded_bone_position = {
            pos = { x = 1.8, y = 0, z = 0 },
        },
        wielded_visual_size = { x = 0.2, y = 0.2, z = 0.2 },

        -- Ao clicar com o orbe em um node, spawna o mob
        on_place = function(itemstack, placer, pointed_thing)
            if pointed_thing.type ~= "node" then return end

            -- Só spawna se o player NÃO estiver agachado
            local controls = placer:get_player_control()
            if controls.sneak then
                -- Agachado: coloca o node normalmente
                return minetest.item_place(itemstack, placer, pointed_thing)
            end

            -- Em pé: spawna o mob
            local pos = pointed_thing.above
            minetest.add_entity(pos, mob_name)

            if not minetest.settings:get_bool("creative_mode") then
                itemstack:take_item()
            end
            return itemstack
        end,
    })
end

core.register_node("nh_nodes:nut", {
    description = S("Acorn") .. "\n" .. S("(Nut)") .. "\n" .. S("Nutrition: +1"),
    drawtype = "mesh",
    mesh = "noz.obj",
    tiles = { "noz.png" },

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.30, 0.08 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.30, 0.08 }
    },

    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1) -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

-- Folhas com 1 noz
core.register_node("nh_nodes:leaves_nut", {
    description = S("Leaves with Nut"),
    drawtype = "allfaces_optional",
    waving = 3,
    tiles = { "leavesnut1.png" },
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:nut" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_nut",
    liquid_alternative_source = "nh_nodes:leaves_nut",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:nut")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:leaves" })
        end
        return itemstack
    end,
})

-- Folhas com 2 nozes
core.register_node("nh_nodes:leaves_nut2", {
    description = S("Leaves with 2 Nuts"),
    drawtype = "allfaces_optional",
    waving = 3,
    tiles = { "leavesnut2.png" },
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:nut 2" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_nut2",
    liquid_alternative_source = "nh_nodes:leaves_nut2",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:nut")
            end

            -- Transforma o node em leaves_apple2
            core.set_node(pos, { name = "nh_nodes:leaves_nut" })
        end
        return itemstack
    end,
})

-- Folhas com 3 nozes
core.register_node("nh_nodes:leaves_nut3", {
    description = S("Leaves with 3 Nuts"),
    drawtype = "allfaces_optional",
    waving = 3,
    tiles = { "leavesnut3.png" },
    groups = { snappy = 3, tree_leaves = 1 },
    drop = {
        items = {
            { items = { "nh_nodes:nut 3" } },
            { items = { "nh_nodes:stick" } },
        }
    },
    walkable = false,
    use_texture_alpha = 30,
    paramtype = "light",
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:leaves_nut3",
    liquid_alternative_source = "nh_nodes:leaves_nut3",
    liquid_viscosity = 0,
    liquid_renewable = false,
    liquid_range = 0,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },

    -- Callback ao clicar com botão direito (pegar maçã)
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if clicker and clicker:is_player() then
            -- Adiciona a maçã ao inventário do jogador
            local inv = clicker:get_inventory()
            if inv then
                inv:add_item("main", "nh_nodes:nut")
            end

            -- Transforma o node em leaves_nut2
            core.set_node(pos, { name = "nh_nodes:leaves_nut2" })
        end
        return itemstack
    end,
})


core.register_node("nh_nodes:apple", {
    description = S("Apple") .. "\n" .. S("Nutrition: +2"),
    drawtype = "mesh",
    mesh = "apple.obj",
    tiles = { "AppleTexture.png" },

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, armor_head = 1, falling_node = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },

    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 2) -- Restaura 4 pontos
        itemstack:take_item()
        return itemstack
    end,
})

core.register_node("nh_nodes:blueberry", {
    description = S("Blueberry") .. "\n" .. S("Nutrition: +1"),
    --wield_scale = {x = 10, y = 10, z = 10},
    drawtype = "mesh",
    mesh = "blueberry.obj",
    tiles = { "BlueberryTexture.png" },

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.03, -0.5, -0.03, 0.03, -0.44, 0.03 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.03, -0.5, -0.03, 0.03, -0.44, 0.03 }
    },

    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1) -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

core.register_node("nh_nodes:chickenegg", {
    description = S("Chicken Egg") .. "\n" .. S("Nutrition: +1"),
    drawtype = "mesh",
    mesh = "chickenegg.obj",
    tiles = { "chickenegg.png" },

    paramtype = "light",
    walkable = false,
    groups = { oddly_breakable_by_hand = 1, falling_node = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0.1, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.28, 0.08 }
    },
    --visual_size = {x = 15, y = 15},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 1) -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

core.register_node("nh_nodes:friedchickenegg", {
    description = S("Fried Egg") .. "\n" .. S("(Chicken Egg)") .. "\n" .. S("Nutrition: +4"),
    drawtype = "mesh",
    mesh = "friedegg.obj",
    tiles = { "friedegg.png" },

    paramtype = "light",
    walkable = false,
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0.1, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.08, -0.5, -0.08, 0.08, -0.28, 0.08 }
    },
    --visual_size = {x = 15, y = 15},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 4) -- Restaura 1 ponto
        itemstack:take_item()
        return itemstack
    end,
})

core.register_node("nh_nodes:worm", {
    description = S("Worm") .. "\n" .. S("[Mob / Item]"),
    drawtype = "mesh",
    mesh = "worm_node.obj",
    tiles = { "worm.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, -0.4, 0.1 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, -0.4, 0.1 }
    },
    visual_size = { x = 15, y = 15 },

    -- Spawna o mob ao colocar o node no chão
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above -- posição onde vai spawnar

        -- Spawna o mob
        local mob = minetest.add_entity(pos, "nh_mob:worm")

        if mob then
            -- Aplica a rotação do jogador ao mob
            if placer then
                local yaw = placer:get_look_horizontal()
                mob:set_yaw(yaw)
            end

            -- Consome o item da mão
            itemstack:take_item()
        end

        return itemstack
    end,
})

core.register_node("nh_nodes:chicken", {
    description = S("Chicken"),
    drawtype = "mesh",
    mesh = "chicken_node.obj",
    tiles = { "chicken.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },
    visual_size = { x = 15, y = 15 },

})

core.register_node("nh_nodes:rawchicken", {
    description = S("Raw Chicken") .. "\n" .. S("Nutrition: +4"),
    drawtype = "mesh",
    mesh = "raw_chicken.obj",
    tiles = { "raw_chicken.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },
    --visual_size = {x = 15, y = 15},
    --wield_scale = {x= 2, y= 2, z= 2},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 4)
        itemstack:take_item()

        local bone = ItemStack("nh_nodes:bone 2")

        if itemstack:is_empty() then
            return bone
        else
            add_item_to_visible_slots(user, bone)
            return itemstack
        end
    end,
})

core.register_node("nh_nodes:roastchicken", {
    description = S("Roast Chicken") .. "\n" .. S("Nutrition: +6"),
    drawtype = "mesh",
    mesh = "raw_chicken.obj",
    tiles = { "roastchicken.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },
    visual_size = { x = 15, y = 15 },
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 6)
        itemstack:take_item()

        local bone = ItemStack("nh_nodes:bone 2")

        if itemstack:is_empty() then
            return bone
        else
            add_item_to_visible_slots(user, bone)
            return itemstack
        end
    end,
})

core.register_node("nh_nodes:tuna", {
    description = S("Tuna"),
    drawtype = "mesh",
    mesh = "rawtuna.obj",
    tiles = { "tuna.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    use_texture_alpha = "clip",
    walkable = false,
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },

    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Spawna o mob ao colocar o node no chão ou na água
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local pos = pointed_thing.above -- posição onde vai spawnar

        -- Spawna o mob
        local mob = minetest.add_entity(pos, "nh_mob:tuna")

        if mob then
            -- Aplica a rotação do jogador ao mob
            if placer then
                local yaw = placer:get_look_horizontal()
                mob:set_yaw(yaw)
            end

            -- Consome o item da mão
            itemstack:take_item()
        end

        return itemstack
    end,
})

core.register_node("nh_nodes:rawtuna", {
    description = S("Raw Tuna") .. "\n" .. S("Nutrition: +4"),
    drawtype = "mesh",
    mesh = "rawtuna.obj",
    tiles = { "rawtuna.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    use_texture_alpha = "clip",
    walkable = false,
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },
    --visual_size = {x = 15, y = 15},
    --wield_scale = {x= 2, y= 2, z= 2},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 4)
        itemstack:take_item()
    end,
})

core.register_node("nh_nodes:roasttuna", {
    description = S("Roast Tuna") .. "\n" .. S("Nutrition: +6"),
    drawtype = "mesh",
    mesh = "rawtuna.obj",
    tiles = { "roasttuna.png" },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },
    use_texture_alpha = "clip",
    walkable = false,
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0, 0.3 }
    },
    --visual_size = {x = 15, y = 15},
    --wield_scale = {x= 2, y= 2, z= 2},
    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 6)
        itemstack:take_item()
    end,
})

core.register_node("nh_nodes:bull", {
    description = S("Bull") .. "\n" .. S("[collectible]"),

    drawtype = "mesh",
    mesh = "bull2.obj",
    tiles = { "bull.png" },

    paramtype = "light",

    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, armor_head = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.7, -0.7, -0.7, 0.7, -0.7, 0.7 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.7, -0.7, -0.7, 0.7, -0.7, 0.7 }
    },

})

core.register_node("nh_nodes:rawbeef", {
    description = S("Raw Beef") .. "\n" .. S("Nutrition: +3"),

    drawtype = "mesh",
    mesh = "cowmeat.obj",
    tiles = { "cowmeat.png" },

    paramtype = "light",
    walkable = false,
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },

    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 3) -- Restaura 3 pontos
        itemstack:take_item()
        return itemstack
    end,
})

core.register_node("nh_nodes:roastbeef", {
    description = S("Roast Beef") .. "\n" .. S("Nutrition: +6"),

    drawtype = "mesh",
    mesh = "cowmeat.obj",
    tiles = { "roastbeef.png" },

    paramtype = "light",
    walkable = false,
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },

    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 6) -- Restaura 6 pontos
        itemstack:take_item()
        return itemstack
    end,
})


core.register_node("nh_nodes:cowfur", {
    description = S("Bull Fur"),

    drawtype = "mesh",
    mesh = "cowleather.obj",
    tiles = { "cowleather.png" },

    paramtype = "light",
    walkable = false,
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, armor_head = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
})

core.register_node("nh_nodes:inksac", {
    description = S("Ink Sack") .. "\n" .. S("Portion: 1"),

    drawtype = "mesh",
    mesh = "inksac.obj",
    tiles = { "inksac.png" },

    paramtype = "light",
    walkable = false,
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.25, 0.15, -0.375, 0.25 }
    },
})

-- VIDRO
core.register_node("nh_nodes:glass", {
    description = S("Glass"),
    drawtype = "glasslike",
    tiles = { "ice2.png" },
    groups = { cracky = 3 },
    walkable = true,
    --is_ground_content = true,
    use_texture_alpha = "clip", --blend
    --alpha = 200,
    paramtype = "light",
    sunlight_propagates = true, -- deixa a luz passar, como gelo real         -- não flui
    --post_effect_color = {a = 15, r = 15, g = 15, b = 15},
    --connects_to = {"nh_nodes:ice"},
})

-- Converte facedir para vetor de direção frontal do espelho
local facedir_to_dir = {
    [0] = vector.new(0, 0, -1), -- sul   (frente padrão)
    [1] = vector.new(-1, 0, 0), -- oeste
    [2] = vector.new(0, 0, 1),  -- norte
    [3] = vector.new(1, 0, 0),  -- leste
}

-- Calcula posição da entidade na frente do espelho
local function get_surface_pos(mirror_pos, param2)
    local dir = facedir_to_dir[param2 % 4] or facedir_to_dir[0]
    -- 0.44 para ficar colado na face frontal do mesh
    return vector.add(mirror_pos, vector.multiply(dir, -0.435))
end

-- Busca o node sólido mais próximo abaixo
local function get_node_below(pos)
    for dy = 1, 16 do
        local candidate_pos = vector.new(pos.x, pos.y - dy, pos.z)
        local node = core.get_node(candidate_pos)
        if node.name ~= "air"
            and node.name ~= "ignore"
            and node.name ~= "nh_nodes:mirror" then
            return node
        end
    end
    return nil
end

-- Retorna a textura do topo de um node
local function get_top_texture(node_name)
    local def = core.registered_nodes[node_name]
    if not def or not def.tiles then return nil end
    local tile = def.tiles[1]
    if type(tile) == "string" then
        return tile
    elseif type(tile) == "table" then
        return tile.name
    end
    return nil
end

local function mirror_has_surface(mirror_pos, param2)
    local epos = get_surface_pos(mirror_pos, param2)
    for _, obj in ipairs(core.get_objects_inside_radius(epos, 0.15)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "nh_nodes:mirror_surface" then
            return true
        end
    end
    return false
end

-- Spawna a entidade visual na frente do espelho
-- Função auxiliar agora também guarda mirror_pos na entidade
local function spawn_surface(mirror_pos, param2)
    local below = get_node_below(mirror_pos)
    if not below then return end

    local tex = get_top_texture(below.name)
    if not tex then return end

    local epos = get_surface_pos(mirror_pos, param2)
    local ent = core.add_entity(epos, "nh_nodes:mirror_surface")
    if not ent then return end

    local luaent = ent:get_luaentity()
    if luaent then
        luaent._mirror_pos = mirror_pos -- salva referência ao dono
    end

    local dir = facedir_to_dir[param2 % 4] or facedir_to_dir[0]
    ent:set_yaw(math.atan2(-dir.x, -dir.z))
    ent:set_properties({ textures = { tex } })
end

-- Entidade visual (sprite colado na frente do espelho)
core.register_entity("nh_nodes:mirror_surface", {
    initial_properties = {
        visual               = "upright_sprite",
        visual_size          = { x = 1.0, y = 1.0 },
        textures             = { "blank.png" },
        physical             = false,
        collide_with_objects = false,
        pointable            = false,
        static_save          = false, -- precisa ser true para salvar
    },

    on_activate = function(self, staticdata, dtime_s)
        -- Ao recarregar do staticdata, verifica se o espelho ainda existe
        if staticdata and staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.mirror_pos then
                self._mirror_pos = data.mirror_pos
                local node = core.get_node(data.mirror_pos)
                if node.name ~= "nh_nodes:mirror" then
                    -- Espelho foi quebrado enquanto chunk estava fora
                    self.object:remove()
                    return
                end
            end
        end
    end,

    get_staticdata = function(self)
        -- Salva a posição do espelho dono junto com a entidade
        return core.serialize({ mirror_pos = self._mirror_pos })
    end,

    on_step = function(self, dtime)
        self._timer = (self._timer or 0) + dtime
        if self._timer < 1.0 then return end
        self._timer = 0

        if not self._mirror_pos then
            self.object:remove()
            return
        end
        local node = core.get_node(self._mirror_pos)
        if node.name ~= "nh_nodes:mirror" then
            self.object:remove()
        end
    end,
})

-- Node do espelho
core.register_node("nh_nodes:mirror", {
    description         = S("Mirror"),
    drawtype            = "mesh",
    mesh                = "mirror.obj",
    tiles               = { "mirror.png" },
    paramtype           = "light",
    paramtype2          = "facedir",
    sunlight_propagates = true,
    walkable            = false,

    collision_box       = {
        type = "fixed",
        fixed = { -0.5, -0.5, 0.435, 0.5, 0.5, 0.5 }
    },
    selection_box       = {
        type = "fixed",
        fixed = { -0.5, -0.5, 0.435, 0.5, 0.5, 0.5 }
    },
    groups              = { cracky = 2, oddly_breakable_by_hand = 1 },

    after_place_node    = function(pos, placer, itemstack, pointed_thing)
        local node = core.get_node(pos)
        -- Salva param2 nos metadados para poder recriar depois
        local meta = core.get_meta(pos)
        meta:set_int("param2", node.param2)
        spawn_surface(pos, node.param2)
    end,

    on_destruct         = function(pos)
        for _, obj in ipairs(core.get_objects_inside_radius(pos, 0.6)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:mirror_surface" then
                -- Calcula qual espelho "dono" desta entidade seria
                -- verificando se ela está próxima o suficiente do pos destruído
                -- e NÃO está na frente de outro espelho vizinho
                local epos = obj:get_pos()
                if not epos then
                    obj:remove()
                else
                    -- Checa se algum espelho vizinho reivindica esta entidade
                    local claimed_by_neighbor = false
                    local neighbors = {
                        vector.new(pos.x + 1, pos.y, pos.z),
                        vector.new(pos.x - 1, pos.y, pos.z),
                        vector.new(pos.x, pos.y, pos.z + 1),
                        vector.new(pos.x, pos.y, pos.z - 1),
                    }
                    for _, npos in ipairs(neighbors) do
                        local nnode = core.get_node(npos)
                        if nnode.name == "nh_nodes:mirror" then
                            local expected = get_surface_pos(npos, nnode.param2)
                            if vector.distance(epos, expected) < 0.1 then
                                claimed_by_neighbor = true
                                break
                            end
                        end
                    end

                    if not claimed_by_neighbor then
                        obj:remove()
                    end
                end
            end
        end
    end,

    -- Suporte a reload de mundo: spawna entidade se sumir
    on_construct        = function(pos)
        -- Usado apenas em construção manual/worldedit, não duplica com after_place_node
    end,
})

-- ABM: recria entidades de espelhos que perderam a superfície
-- (acontece ao recarregar chunks / reentrar no mundo)
core.register_abm({
    label     = "Mirror surface restore",
    nodenames = { "nh_nodes:mirror" },
    interval  = 1,
    chance    = 1,
    action    = function(pos, node)
        if not mirror_has_surface(pos, node.param2) then
            spawn_surface(pos, node.param2)
        end
    end,
})

core.register_node("nh_nodes:bottle", {
    description = S("Bottle"),
    inventory_image = "bottle.png",
    drawtype = "mesh",
    mesh = "emptybottle.obj",
    tiles = { "bottletexture.png" },

    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    walkable = false,
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
})

local function is_water_near(pos)
    local offsets = {
        { x = 0, y = 0, z = 0 },
        { x = 1, y = 0, z = 0 }, { x = -1, y = 0, z = 0 },
        { x = 0, y = 1, z = 0 }, { x = 0, y = -1, z = 0 },
        { x = 0, y = 0, z = 1 }, { x = 0, y = 0, z = -1 },
    }

    for _, off in ipairs(offsets) do
        local p = vector.add(pos, off)
        local node = core.get_node(p)

        if node and node.name then
            if node.name == "nh_nodes:water"
                or node.name == "nh_nodes:water_flowing"
                or node.name == "nh_nodes:water2"
                or node.name == "nh_nodes:water2_flowing" then
                return true
            end
        end
    end

    return false
end

-- ============================================================
--  ULEXITE – entidade de superfície (topo do bloco abaixo)
--  Adicionar logo APÓS o registro de "nh_nodes:ulexite"
-- ============================================================

-- ── Helpers (reutilizados do espelho, mas isolados para ulexita) ──────────────

-- Retorna a textura do topo do node (tiles[1])
local function ulexite_get_top_texture(node_name)
    local def = core.registered_nodes[node_name]
    if not def or not def.tiles then return nil end
    local tile = def.tiles[1]
    if type(tile) == "string" then
        return tile
    elseif type(tile) == "table" then
        return tile.name
    end
    return nil
end

-- Posição onde a entidade fica: topo da ulexita (y + 0.501, levemente acima)
local function ulexite_surface_pos(ulexite_pos)
    return vector.new(ulexite_pos.x, ulexite_pos.y + 0.501, ulexite_pos.z)
end

-- Verifica se já existe uma entidade de superfície sobre esta ulexita
local function ulexite_has_surface(ulexite_pos)
    local epos = ulexite_surface_pos(ulexite_pos)
    for _, obj in ipairs(core.get_objects_inside_radius(epos, 0.15)) do
        local ent = obj:get_luaentity()
        if ent and ent.name == "nh_nodes:ulexite_surface" then
            return true
        end
    end
    return false
end

-- Spawna a entidade visual deitada no topo da ulexita
local function ulexite_spawn_surface(ulexite_pos)
    local below = get_node_below(ulexite_pos)
    if not below then return end

    local tex = ulexite_get_top_texture(below.name)
    if not tex then return end

    local epos = ulexite_surface_pos(ulexite_pos)
    local ent  = core.add_entity(epos, "nh_nodes:ulexite_surface")
    if not ent then return end

    ent:set_properties({ textures = { tex } })

    local luaent = ent:get_luaentity()
    if luaent then
        luaent._ulexite_pos = ulexite_pos
    end
end

-- ── Entidade visual ───────────────────────────────────────────────────────────

core.register_entity("nh_nodes:ulexite_surface", {
    initial_properties = {
        -- upright_sprite igual ao mirror; rotação 90° em X o deita horizontalmente
        visual               = "upright_sprite",
        visual_size          = { x = 1.0, y = 1.0 },
        textures             = { "blank.png" },
        physical             = false,
        collide_with_objects = false,
        pointable            = false,
        static_save          = false,
    },

    on_activate = function(self, staticdata, dtime_s)
        -- Inclina o sprite 90° para ficar "deitado" (horizontal)
        self.object:set_rotation({ x = math.pi / 2, y = 0, z = 0 })

        if staticdata and staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.ulexite_pos then
                self._ulexite_pos = data.ulexite_pos
                local node = core.get_node(data.ulexite_pos)
                if node.name ~= "nh_nodes:ulexite" then
                    self.object:remove()
                    return
                end
                -- Restaura textura
                local below = get_node_below(data.ulexite_pos)
                if below then
                    local tex = ulexite_get_top_texture(below.name)
                    if tex then
                        self.object:set_properties({ textures = { tex } })
                    end
                end
            end
        end
    end,

    get_staticdata = function(self)
        return core.serialize({ ulexite_pos = self._ulexite_pos })
    end,

    on_step = function(self, dtime)
        self._timer = (self._timer or 0) + dtime
        if self._timer < 1.0 then return end
        self._timer = 0

        if not self._ulexite_pos then
            self.object:remove()
            return
        end

        -- Remove se a ulexita sumiu
        local node = core.get_node(self._ulexite_pos)
        if node.name ~= "nh_nodes:ulexite" then
            self.object:remove()
            return
        end

        -- Atualiza textura caso o bloco abaixo tenha mudado
        local below = get_node_below(self._ulexite_pos)
        if below then
            local tex = ulexite_get_top_texture(below.name)
            if tex then
                local cur = self.object:get_properties().textures
                if not cur or cur[1] ~= tex then
                    self.object:set_properties({ textures = { tex } })
                end
            end
        end
    end,
})

-- ── Hooks no node ulexite ─────────────────────────────────────────────────────
-- ATENÇÃO: substitua o registro original de "nh_nodes:ulexite" por este,
-- ou adicione after_place_node / on_destruct manualmente se preferir não
-- duplicar. O mais simples é substituir o bloco original pelo abaixo.

-- (apague o core.register_node("nh_nodes:ulexite", {...}) anterior e use este)
core.register_node("nh_nodes:ulexite", {
    description = S("Ulexite"),
    drawtype = "normal",
    tiles = {"ulexitetopdown.png", "ulexitetopdown.png", "ulexitesides.png"},
    groups = {cracky = 3},
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        ulexite_spawn_surface(pos)
    end,

    on_destruct = function(pos)
        local epos = ulexite_surface_pos(pos)
        for _, obj in ipairs(core.get_objects_inside_radius(epos, 0.15)) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:ulexite_surface" then
                obj:remove()
            end
        end
    end,
})

-- ── ABM: recria entidades que sumiram ao recarregar chunks ────────────────────

core.register_abm({
    label     = "Ulexite surface restore",
    nodenames = { "nh_nodes:ulexite" },
    interval  = 2,
    chance    = 1,
    action    = function(pos, node)
        if not ulexite_has_surface(pos) then
            ulexite_spawn_surface(pos)
        end
    end,
})

core.register_node("nh_nodes:messagebottle", {
    description = S("Bottle with Message") .. "\n" .. S("[Floating Item]"),
    inventory_image = "bottlepage.png",
    drawtype = "mesh",
    mesh = "bottlepage.obj",
    tiles = { "bottlepagetexture.png" },

    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    walkable = false,
    paramtype2 = "facedir",
    groups = { oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },

    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Quando o nó é colocado, verifica se está na água
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local ctrl = placer:get_player_control()
            if ctrl.sneak then
                return
            end
        end
        -- Sem agachar: vira entidade normalmente
        if is_water_near(pos) then
            core.remove_node(pos)
            core.add_entity(pos, "nh_mob:messagebottle")
        end
    end,

    -- Cobre o caso de água chegar até o nó depois que ele já está parado
    on_flood = function(pos, oldnode, newnode)
        core.remove_node(pos)
        core.add_entity(pos, "nh_mob:messagebottle")
        return false
    end,
})

core.register_node("nh_nodes:fireflybottle", {
    description = S("Bottle with Firefly"),
    inventory_image = "bottlefirefly.png",
    drawtype = "mesh",
    mesh = "bottlefirefly.obj",
    tiles = { "bottlefireflytexture.png" },

    paramtype = "light",
    light_source = 5,
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    backface_culling = false,
    walkable = false,
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.6, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    offhand_bone_position = {
        pos = { x = 1.6, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
})

core.register_node("nh_nodes:inkbottle", {
    description = S("Bottle with Ink"),
    inventory_image = "inkbottle.png",
    drawtype = "mesh",
    mesh = "bottle.obj",
    tiles = { "inkbottletexture.png" },

    paramtype = "light",
    sunlight_propagates = true,
    use_texture_alpha = "blend",
    walkable = false,
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.18, -0.5, -0.18, 0.18, -0.05, 0.18 }
    },
})


-- Função auxiliar para verificar se o jogador tem os itens necessários
writing_utils = {}
function writing_utils.player_has_writing_tools(player)
    local inv = player:get_inventory()
    local has_feather = false
    local has_ink = false

    for i = 1, 8 do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == "nh_items:feather" then
            has_feather = true
            break
        end
    end

    if inv:contains_item("main", "nh_nodes:inkbottle") then
        has_ink = true
    end

    return has_feather, has_ink
end

function writing_utils.consume_ink(player)
    local inv = player:get_inventory()
    inv:remove_item("main", "nh_nodes:inkbottle")
    inv:add_item("main", "nh_nodes:bottle")
end

function player_has_writing_tools(player)
    local inv = player:get_inventory()
    local has_feather = false
    local has_ink = false

    -- Verificar se tem pena na hotbar (slots 1-8)
    for i = 1, 8 do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == "nh_items:feather" then
            has_feather = true
            break
        end
    end

    -- Verificar se tem tinta em qualquer lugar do inventário
    if inv:contains_item("main", "nh_nodes:inkbottle") then
        has_ink = true
    end

    return has_feather, has_ink
end

function consume_ink(player)
    local inv = player:get_inventory()
    -- Remover um frasco de tinta e devolver frasco vazio
    inv:remove_item("main", "nh_nodes:inkbottle")
    inv:add_item("main", "nh_nodes:bottle")
end

core.register_node("nh_nodes:coconutlinked", {
    description = S("Fixed Coconut"),
    drawtype = "mesh",
    mesh = "coconutlinked.obj",
    tiles = { "CocoTexture.png" },

    waving = 2,
    drop = "nh_nodes:coconut",

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, tree_leaves = 1, oddly_breakable_by_hand = 1, falling_node = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.5, 0.25, 0.5, 0 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.25, 0, -0.5, 0.25, 0.5, 0 }
    },
})


core.register_node("nh_nodes:coconut", {
    description = S("Coconut") .. "\n" .. S("Nutrition: +3") .. "\n" .. S("Floating Item"),
    drawtype = "mesh",
    mesh = "coconut.obj",
    tiles = { "CocoTexture.png" },

    walkable = false,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { snappy = 3, tree_leaves = 1, oddly_breakable_by_hand = 1, falling_node = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.25, -0.5, -0.25, 0.25, 0, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.25, -0.5, -0.25, 0.25, 0, 0.25 }
    },

    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Tornar comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, 3) -- Restaura 3 pontos
        itemstack:take_item()
        return itemstack
    end,

    -- Quando o nó é colocado, verifica se está na água
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local ctrl = placer:get_player_control()
            if ctrl.sneak then
                return
            end
        end
        -- Sem agachar: vira entidade normalmente
        if is_water_near(pos) then
            core.remove_node(pos)
            core.add_entity(pos, "nh_mob:coconut")
        end
    end,

    -- Cobre o caso de água chegar até o nó depois que ele já está parado
    on_flood = function(pos, oldnode, newnode)
        core.remove_node(pos)
        core.add_entity(pos, "nh_mob:coconut")
        return false
    end,
})

core.register_node("nh_nodes:palmtimber", {
    description = S("Palm Trunk"),
    drawtype = "mesh",
    mesh = "palm_trunk.obj",
    tiles = { "coqueirotexture.png" },
    stack_max = 4,
    drop = "nh_nodes:palmlog",

    --waving = 2,
    paramtype = "light",
    paramtype2 = "facedir",
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 1,
        falling_node = 1,
        tree_trunk = 1
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 }
    },

    -- Som tocado ao bater no tronco medio (2)
    sounds = {
        dug = { name = "punchtimber2", gain = 0.5 },
        dig = { name = "punchtimber2", gain = 0.5 },
    },

    after_dig_node = function(pos)
        local below = { x = pos.x, y = pos.y - 1, z = pos.z }
        local below_node = core.get_node(below)

        if below_node.name == "air"
            or core.get_item_group(below_node.name, "tree_trunk") > 0
            or core.get_item_group(below_node.name, "tree_leaves") > 0 then
            make_leaves_fall(pos)
        end
    end,

    on_construct = function(pos)
        core.get_node_timer(pos):start(0.5)
    end,

    on_timer = function(pos)
        if not has_solid_support(pos) then
            make_leaves_fall(pos)
            return false
        end
        return true
    end,
})


core.register_node("nh_nodes:palmstraws", {
    description = S("Palm Trunk with Straws"),
    drawtype = "mesh",
    mesh = "coconutstraws.obj",
    tiles = { "strawstimbertexture.png" },
    stack_max = 4,

    waving = 2,
    drop = {
        items = {
            { items = { "nh_nodes:palmtimber" } },
            { items = { "nh_nodes:palmstraw 4" } },
        }
    },

    paramtype = "light",
    paramtype2 = "facedir",
    groups = {
        choppy = 3,
        falling_node = 1,
        tree_trunk = 1
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } -- Porta na lateral quando aberta
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } -- Colisão fina na lateral
    },

    -- Som tocado ao bater no tronco medio (2)
    sounds = {
        dug = { name = "punchtimber2", gain = 0.5 },
        dig = { name = "punchtimber2", gain = 0.5 },
    },
})

core.register_node("nh_nodes:palmlog", {
    description = S("Palm Log"),
    drawtype = "mesh",
    mesh = "palm_trunk.obj",
    tiles = { "coqueirotexture.png" },
    stack_max = 4,

    paramtype = "light",
    paramtype2 = "wallmounted",
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 1,
        --falling_node = 1,
        --tree_trunk = 1
    },

    selection_box = {
        type = "wallmounted",
        wall_top = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_bottom = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_side = { -0.5, -0.25, -0.25, 0.5, 0.25, 0.25 },
    },

    node_box = {
        type = "wallmounted",
        wall_top = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_bottom = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
        wall_side = { -0.5, -0.25, -0.25, 0.5, 0.25, 0.25 },
    },

    -- Som tocado ao bater no tronco medio (2)
    sounds = {
        dug = { name = "punchtimber2", gain = 0.5 },
        dig = { name = "punchtimber2", gain = 0.5 },
    },
})

core.register_node("nh_nodes:palmleafstalks", {
    description = S("Palm Leaves Stalks"),

    drawtype = "mesh",
    mesh = "TaloCoqueiro.obj",
    tiles = { "PalmLeafTexture.png" },

    waving = 2,
    paramtype = "light",
    walkable = false,
    sunlight_propagates = true,
    shaded = false,           -- Desabilita sombreamento por face
    backface_culling = false, -- Renderiza ambos os lados das faces
    use_texture_alpha = "blend",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, tree_leaves = 1, armor_head = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
})

-- Registrar o node da folha de coqueiro
core.register_node("nh_nodes:palmleaf", {
    description = S("Palm Leaf"),

    drawtype = "mesh",
    mesh = "palm_leaf.obj",
    tiles = { "PalmLeafTexture.png" },
    waving = 2,
    paramtype = "light",
    walkable = false,
    sunlight_propagates = true,
    shaded = false,
    backface_culling = false,
    use_texture_alpha = "blend",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, tree_leaves = 1, armor_head = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },

    -- Quando o node é colocado, iniciar o timer
    on_place = function(itemstack, placer, pointed_thing)
        -- Primeiro, fazer o placement normal
        local pos = core.item_place(itemstack, placer, pointed_thing)

        -- Se o placement foi bem-sucedido, iniciar o timer
        if pos then
            local timer = core.get_node_timer(pointed_thing.above)
            timer:start(60) -- 60 segundos = 1 minuto
        end

        return itemstack
    end,

    -- Quando o timer terminar
    on_timer = function(pos)
        -- Verificar se está sob luz do sol
        local light_level = core.get_node_light(pos, 0.5)

        if light_level and light_level >= 12 then -- 12+ é luz solar direta
            -- Trocar para o node de palha
            core.set_node(pos, { name = "nh_nodes:palmstraw" })
            return false -- Não reiniciar o timer
        else
            -- Se não estiver no sol, reiniciar o timer
            return true
        end
    end,
})

---------------------------
-- NODE DE PALHA COM CHAMAS
---------------------------
core.register_node("nh_nodes:palmstraw", {
    description = S("Palm Straw"),

    drawtype = "mesh",
    mesh = "palmstraw.obj",
    tiles = { "PalmStrawTexture.png" },

    paramtype = "light",
    walkable = false,
    sunlight_propagates = true,
    shaded = false,
    backface_culling = false,
    use_texture_alpha = "blend",
    paramtype2 = "facedir",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, tree_leaves = 1, flammable = 3 },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.3, 0.5 }
    },

    -- Quando a palha é colocada, verifica se deve criar chama
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        -- Se já tiver chama marcada, cria a entidade
        if meta:get_int("has_flame") == 1 then
            core.after(0.1, function()
                -- Verifica se não existe chama já
                local objs = core.get_objects_inside_radius(pos, 0.5)
                local has_flame = false
                for _, obj in ipairs(objs) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "nh_nodes:palmstraw_flame_entity" then
                        has_flame = true
                        break
                    end
                end

                if not has_flame then
                    local obj = core.add_entity(pos, "nh_nodes:palmstraw_flame_entity")
                    if obj then
                        local ent = obj:get_luaentity()
                        if ent then
                            ent._straw_pos = pos
                        end
                    end
                end
            end)
        end
    end,

    -- Quando a palha é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:palmstraw_flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._straw_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a palha for removida, remove as chamas
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:palmstraw_flame_entity" then
                obj:remove()
            end
        end
    end,
})

---------------------------
-- ENTIDADE DA CHAMA DA PALHA
---------------------------
core.register_entity("nh_nodes:palmstraw_flame_entity", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        selectionbox = { -0.3, -0.3, -0.3, 0.3, 0.3, 0.3 },
        collisionbox = { -0.3, -0.3, -0.3, 0.3, 0.3, 0.3 },
        visual = "mesh",
        mesh = "flame.obj",
        textures = { "fire_basic_flame_animated.png" },
        visual_size = { x = 10, y = 10 }, -- Menor que a chama da grama
        static_save = true,
        pointable = true,
        glow = 14,
    },

    _straw_pos = nil,
    _timer = 0,
    _anim_timer = 0,
    _current_frame = 0,

    on_activate = function(self, staticdata)
        if staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.straw_pos then
                self._straw_pos = data.straw_pos
            end
        end
        self._timer = 0

        self.object:set_sprite(
            { x = 0, y = 0 },
            1,
            1.0,
            false
        )

        self.object:set_texture_mod("^[verticalframe:8:0")
    end,

    get_staticdata = function(self)
        return core.serialize({ straw_pos = self._straw_pos })
    end,

    -- Detecta quando é golpeado para acender tochas
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()

        -- Verifica se está segurando uma tocha apagada
        if wielded_name == "nh_nodes:torch" then
            wielded:take_item()
            puncher:set_wielded_item(wielded)

            local inv = puncher:get_inventory()
            if inv then
                local leftover = inv:add_item("main", "nh_nodes:torch2")
                if not leftover:is_empty() then
                    local pos = puncher:get_pos()
                    core.add_item(pos, leftover)
                end
            end

            core.sound_play("fire_flint_and_steel", {
                pos = self.object:get_pos(),
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    on_step = function(self, dtime)
        self._timer = self._timer + dtime
        self._anim_timer = self._anim_timer + dtime

        -- Anima a textura
        if self._anim_timer > (1.0 / 8) then
            self._anim_timer = 0
            self._current_frame = (self._current_frame + 1) % 8
            self.object:set_texture_mod("^[verticalframe:8:" .. self._current_frame)
        end

        -- Verifica se a palha ainda existe
        if self._timer > 0.5 then
            self._timer = 0

            if not self._straw_pos then
                self.object:remove()
                return
            end

            local node = core.get_node(self._straw_pos)

            -- Se a palha foi removida, remove a chama
            if node.name ~= "nh_nodes:palmstraw" then
                self.object:remove()
                return
            end

            -- Verifica se ainda deve ter chama
            local meta = core.get_meta(self._straw_pos)
            if meta:get_int("has_flame") ~= 1 then
                self.object:remove()
                return
            end
        end
    end,
})


core.register_node("nh_nodes:fireice", {
    description = S("Fire Ice"),
    tiles = { "neve.png" },
    drawtype = "normal",
    groups = { crumbly = 3, falling_node = 1 }, -- como areia, mas sem fluir
    --sounds = default.node_sound_snow_defaults(),
})

core.register_node("nh_nodes:snow_ramp", {
    description         = S("Snow Ramp"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_slope.obj",
    tiles               = { "snow_slope.png" },
    -- Dentro do register_node:
    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
})

core.register_node("nh_nodes:snow_corner", {
    description         = S("Snow Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_vertix.obj",
    tiles               = { "snow_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2

        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2
        },
    },
})

core.register_node("nh_nodes:snow_insidecorner", {
    description         = S("Snow Inside Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grassinsidecorner.obj",
    tiles               = { "snow_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:sand",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, -- Base completa (metade inferior)
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 1: faixa traseira (Z-) -- faixa Z-
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 }, -- Topo braço 1: faixa traseira (Z-)-- faixa Z-
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 2: faixa lateral (X-)-- faixa X-
        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 },
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 },
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 },
        },
    },
})

core.register_node("nh_nodes:snow", {
    description = S("Snow"),
    tiles = { "neve.png" },
    drawtype = "normal",
    groups = { crumbly = 3, falling_node = 1 }, -- como areia, mas sem fluir
    sounds = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },
})

core.register_node("nh_nodes:avalanche", {
    description = S("Avalanche"),
    liquidtype = "source",
    drawtype = "liquid",
    tiles = { "neve.png" },
    groups = { liquid = 3, crumbly = 3, falling_node = 1 }, -- como areia e flui
    sounds = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    walkable = false,
    liquid_alternative_flowing = "nh_nodes:avalanche_flowing",
    liquid_alternative_source = "nh_nodes:avalanche",
    liquid_viscosity = 0,
    liquid_renewable = false,
    post_effect_color = { a = 15, r = 15, g = 15, b = 15 },
})

core.register_node("nh_nodes:avalanche_flowing", {
    description = S("Flowing Avalanche"),
    liquidtype = "flowing",
    drawtype = "flowingliquid",
    tiles = { "neve.png" },
    groups = { liquid = 3, not_in_creative_inventory = 1 },
    special_tiles = {
        {
            name = "neve_flowing_animated.png",
            backface_culling = false,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0 },
        },
        {
            name = "neve_flowing_animated.png",
            backface_culling = true,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0 },
        },
    },
    --use_texture_alpha = "blend",
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquid_alternative_flowing = "nh_nodes:avalanche_flowing",
    liquid_alternative_source = "nh_nodes:avalanche",

    liquid_viscosity = 0,
    liquid_renewable = false,
})

core.register_node("nh_nodes:water", {
    description = S("Water"),
    drawtype = "liquid",
    liquidtype = "source",
    tiles = { "agua.png" },
    tiles = { {
        name = "agua_animated.png",
        backface_culling = false,
        animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 10.0 }
    },
        "agua.png" }, -- resto das faces
    paramtype = "light",
    waving = 3,
    liquid_renewable = false,
    use_texture_alpha = "blend",
    --paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquid_alternative_flowing = "nh_nodes:water_flowing",
    liquid_alternative_source = "nh_nodes:water",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 0, g = 0, b = 255 },
    drowning = 1, -- ADICIONE ESTA LINHA (dano por segundo quando sem ar)
    groups = { water = 1, liquid = 1 },

    after_place_node = function(pos)
        local neighbors = {
            { x = 1, y = 0, z = 0 }, { x = -1, y = 0, z = 0 },
            { x = 0, y = 1, z = 0 }, { x = 0, y = -1, z = 0 },
            { x = 0, y = 0, z = 1 }, { x = 0, y = 0, z = -1 },
        }
        for _, d in ipairs(neighbors) do
            local npos = vector.add(pos, d)
            local node = core.get_node(npos)
            -- força remesh do vizinho
            core.swap_node(npos, node)
        end
    end,
})

core.register_node("nh_nodes:water_flowing", {
    description = S("Flowing Water"),
    drawtype = "flowingliquid",
    tiles = { "agua.png" },
    special_tiles = {
        {
            name = "agua_flowing_animated.png",
            backface_culling = false,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
        {
            name = "agua_flowing_animated.png",
            backface_culling = true,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nh_nodes:water_flowing",
    liquid_alternative_source = "nh_nodes:water",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 0, g = 0, b = 255 },
    drowning = 1, -- ADICIONEI ESSA LINHA
    groups = { water = 1, liquid = 1, not_in_creative_inventory = 1 },
})


core.register_node("nh_nodes:barrier", {
    description = S("Barrier"),
    drawtype = "glasslike",
    tiles = { "ice2.png" },
    groups = { not_in_creative_inventory = 1 },
    --is_ground_content = true,
    use_texture_alpha = "clip", --blend
    --alpha = 200,
    paramtype = "light",

    walkable = true,
    pointable = false,          -- não pode ser selecionado
    diggable = false,           -- inquebrável
    buildable_to = false,
    sunlight_propagates = true, -- deixa a luz passar, como gelo real         -- não flui
    --post_effect_color = {a = 15, r = 15, g = 15, b = 15},
    --connects_to = {"nh_nodes:ice"},
})

minetest.register_chatcommand("cleardome", {
    privs = { server = true },
    func = function(name)
        local player = minetest.get_player_by_name(name)
        local pos = player:get_pos()
        local count = 0
        for x = -80, 80 do
            for y = -80, 80 do
                for z = -80, 80 do
                    local p = {
                        x = math.floor(pos.x + x),
                        y = math.floor(pos.y + y),
                        z = math.floor(pos.z + z)
                    }
                    if minetest.get_node(p).name == "nh_nodes:barrier" then
                        minetest.set_node(p, { name = "air" })
                        count = count + 1
                    end
                end
            end
        end
        return true, count .. " barriers removidos."
    end
})

-- Gelo
core.register_node("nh_nodes:ice", {
    description = S("Ice"),
    drawtype = "glasslike",
    tiles = { "ice2.png" },
    groups = { cracky = 3, slippery = 3 },
    walkable = true,
    --is_ground_content = true,
    use_texture_alpha = "clip", --blend
    --alpha = 200,
    paramtype = "light",
    sunlight_propagates = true, -- deixa a luz passar, como gelo real         -- não flui
    --post_effect_color = {a = 15, r = 15, g = 15, b = 15},
    --connects_to = {"nh_nodes:ice"},

    drop = "nh_nodes:ice2",
})

core.register_node("nh_nodes:ice2", {
    description = S("Ice"),
    drawtype = "glasslike",
    tiles = { "ice.png" },
    groups = { cracky = 3, slippery = 3 },
    walkable = true,
    --is_ground_content = true,
    use_texture_alpha = "blend", --blend
    --alpha = 200,
    paramtype = "light",
    sunlight_propagates = true, -- deixa a luz passar, como gelo real         -- não flui
    --post_effect_color = {a = 15, r = 15, g = 15, b = 15},
    --connects_to = {"nh_nodes:ice"},


    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Quando o nó é colocado, verifica se está na água
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local ctrl = placer:get_player_control()
            if ctrl.sneak then
                return
            end
        end
        -- Sem agachar: vira entidade normalmente
        if is_water_near(pos) then
            core.remove_node(pos)
            core.add_entity(pos, "nh_mob:iceberg")
        end
    end,

    -- Cobre o caso de água chegar até o nó depois que ele já está parado
    on_flood = function(pos, oldnode, newnode)
        core.remove_node(pos)
        core.add_entity(pos, "nh_mob:iceberg")
        return false
    end,
})

core.register_node("nh_nodes:ice2ramp", {
    description = S("Ice Ramp"),
    drawtype = "mesh",
    mesh = "grass_slope.obj",
    tiles = { "ice2ramp.png" },
    groups = { cracky = 3, slippery = 3 },
    walkable = true,
    --is_ground_content = true,
    use_texture_alpha = "blend", --blend
    --alpha = 200,
    paramtype = "light",
    paramtype2 = "facedir",
    sunlight_propagates = true, -- deixa a luz passar, como gelo real         -- não flui
    --post_effect_color = {a = 15, r = 15, g = 15, b = 15},
    --connects_to = {"nh_nodes:ice2"},

    selection_box = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
    collision_box = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },

    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Quando o nó é colocado, verifica se está na água
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        if placer and placer:is_player() then
            local ctrl = placer:get_player_control()
            if ctrl.sneak then
                return
            end
        end
        -- Sem agachar: vira entidade normalmente
        if is_water_near(pos) then
            core.remove_node(pos)
            core.add_entity(pos, "nh_mob:iceberg")
        end
    end,

    -- Cobre o caso de água chegar até o nó depois que ele já está parado
    on_flood = function(pos, oldnode, newnode)
        core.remove_node(pos)
        core.add_entity(pos, "nh_mob:iceberg")
        return false
    end,
})

core.register_node("nh_nodes:water2", {
    description = S("Fresh Water"),
    drawtype = "liquid",
    tiles = { "water2.png" },
    tiles = { {
        name = "water2_animated.png",
        backface_culling = false,
        animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 4 }
    },
        "water2.png" },
    --special_tiles = {{name = "agua2_animated.png", animation = {type="vertical_frames", aspect_w=16, aspect_h=16, length=0.9}},},
    use_texture_alpha = "blend",
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:water2_flowing",
    liquid_alternative_source = "nh_nodes:water2",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 0, g = 0, b = 255 },
    drowning = 1, -- ADICIONE ESTA LINHA
    groups = { water = 1, liquid = 1 },
})

core.register_node("nh_nodes:water2_flowing", {
    description = S("Flowing Fresh Water"),
    drawtype = "flowingliquid",
    tiles = { "water2.png" },
    special_tiles = {
        {
            name = "agua2_flowing_animated.png",
            backface_culling = false,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
        {
            name = "agua2_flowing_animated.png", -- Corrigido (estava agua_flowing)
            backface_culling = true,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nh_nodes:water2_flowing",
    liquid_alternative_source = "nh_nodes:water2",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 0, g = 0, b = 255 },
    drowning = 1, -- ADICIONE ESTA LINHA
    groups = { water = 1, liquid = 1, not_in_creative_inventory = 1 },
})


core.register_node("nh_nodes:basalt", {
    description = S("Basalt"),
    tiles = { "basalt.png" },
    groups = { cracky = 3 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

core.register_node("nh_nodes:basalt_ramp", {
    description = S("Basalt Ramp"),
    paramtype   = "light",
    paramtype2  = "facedir",
    drawtype    = "mesh",
    mesh        = "grass_slope.obj",
    tiles       = { "basalt_slope.png" },
    groups      = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop        = "nh_nodes:basalt",

    sounds      = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },


    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,

    selection_box = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
    collision_box = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.5, 0.5, 0.5 },
        },
    },
})

core.register_node("nh_nodes:basalt_corner", {
    description         = S("Basalt Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grass_vertix.obj",
    tiles               = { "basalt_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:basalt",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2

        },
    },
    selection_box       = {
        type = "fixed",
        fixed = {
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- topo
            { -0.5, -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base principal
            { -0.5, -0.5, -0.5, 0.0, 0.0, 0.0 }, -- Base braço 1
            { 0.5,  -0.5, 0.0,  0.0, 0.0, 0.5 }, -- Base braço 2
        },
    },
})

core.register_node("nh_nodes:basalt_insidecorner", {
    description         = S("Basalt Inside Corner"),
    -- Mesmas texturas do top_grass: topo=grama, baixo=dirt, lados=dirt+grama

    paramtype           = "light",
    paramtype2          = "facedir",
    drawtype            = "mesh",
    mesh                = "grassinsidecorner.obj",
    tiles               = { "basalt_slope.png" },

    groups              = { cracky = 3, soil = 1, falling_node = 1, not_blocking_trains = 1 },
    drop                = "nh_nodes:basalt",

    sounds              = {
        footstep = { name = "punchtimber3", gain = 0.5 },
        dug      = { name = "punchtimber3", gain = 0.5 },
        dig      = { name = "punchtimber3", gain = 0.5 },
        place    = { name = "punchtimber3", gain = 0.5 },
    },

    -- E adicione essa propriedade:
    sunlight_propagates = true,
    --sounds = nh_nodes.sounds.dirt,  -- ajuste para o som correto do seu mod

    collision_box       = {
        type = "fixed",
        fixed = {
            { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 }, -- Base completa (metade inferior)
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 1: faixa traseira (Z-)
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 }, -- Topo braço 1: faixa traseira (Z-)
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, -- Topo braço 2: faixa lateral (X-)
        },
    },
    selection_box       = {
        type = "fixed",
        fixed = { { -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
            { -0.5, 0.0,  0.0,  0.0, 0.5, 0.5 },
            { -0.5, 0.0,  -0.5, 0.0, 0.5, 0.0 },
            { 0.5,  0.0,  0.0,  0.0, 0.5, 0.5 }, },
    },
})

core.register_node("nh_nodes:magma", {
    description = S("Magma"),
    tiles = { "magma.png" },
    groups = { cracky = 3, hot = 1 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.65 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 1.5, y = 0, z = 0 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})

-- ABM: Lava + água fluindo = basalto
minetest.register_abm({
    label = "Lava solidifica em basalto ou obsidiana",
    nodenames = { "nh_nodes:lava", "nh_nodes:lava_flowing", "nh_nodes:bluelava", "nh_nodes:bluelava_flowing" },
    neighbors = { "nh_nodes:water", "nh_nodes:water2", "nh_nodes:water_flowing", "nh_nodes:water2_flowing" },
    interval = 1,
    chance = 1,
    action = function(pos, node)
        local directions = {
            { x = 0,  y = 1,  z = 0 },
            { x = 0,  y = -1, z = 0 },
            { x = 1,  y = 0,  z = 0 },
            { x = -1, y = 0,  z = 0 },
            { x = 0,  y = 0,  z = 1 },
            { x = 0,  y = 0,  z = -1 },
        }

        local is_source = (node.name == "nh_nodes:lava" or node.name == "nh_nodes:bluelava")
        local is_flowing = (node.name == "nh_nodes:lava_flowing" or node.name == "nh_nodes:bluelava_flowing")

        for _, dir in ipairs(directions) do
            local neighbor_pos = vector.add(pos, dir)
            local neighbor = minetest.get_node(neighbor_pos)
            local is_water_source = (neighbor.name == "nh_nodes:water" or neighbor.name == "nh_nodes:water2")
            local is_water_flowing = (neighbor.name == "nh_nodes:water_flowing" or neighbor.name == "nh_nodes:water2_flowing")

            if is_source and is_water_source then
                -- Lava/bluelava source + água source = obsidiana, água some
                minetest.set_node(pos, { name = "nh_nodes:obsidian" })
                minetest.set_node(neighbor_pos, { name = "air" })
                return
            elseif is_source and is_water_flowing then
                -- Lava/bluelava source + água flowing = obsidiana, água some
                minetest.set_node(pos, { name = "nh_nodes:obsidian" })
                minetest.set_node(neighbor_pos, { name = "air" })
                return
            elseif is_flowing and is_water_source then
                -- Lava/bluelava flowing + qualquer água = gneiss, água some
                minetest.set_node(pos, { name = "nh_nodes:basalt" })
                minetest.set_node(neighbor_pos, { name = "air" })
                return
            elseif is_flowing and is_water_flowing then
                -- Lava/bluelava flowing + qualquer água = gneiss, água some
                minetest.set_node(pos, { name = "nh_nodes:gneiss" })
                minetest.set_node(neighbor_pos, { name = "air" })
                return
            end
        end
    end,
})

core.register_node("nh_nodes:lava", {
    description = S("Lava"),
    drawtype = "liquid",
    tiles = { "lava.png" },
    tiles = { {
        name = "lava_animated.png",
        backface_culling = false,
        animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 2.0 }
    },
        "lava.png" }, -- resto das faces
    use_texture_alpha = "blend",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:lava_flowing",
    liquid_alternative_source = "nh_nodes:lava",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 255, g = 0, b = 0 },
    groups = { lava = 1, liquid = 1, hot = 1 },
})

core.register_node("nh_nodes:lava_flowing", {
    description = S("Flowing Lava"),
    drawtype = "flowingliquid",
    tiles = { "lava.png" },
    special_tiles = {
        {
            name = "lava_flowing_animated.png",
            backface_culling = false,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
        {
            name = "lava_flowing_animated.png",
            backface_culling = true,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nh_nodes:lava_flowing",
    liquid_alternative_source = "nh_nodes:lava",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 255, g = 0, b = 0 },
    groups = { lava = 1, liquid = 1, hot = 1, not_in_creative_inventory = 1 },
})

core.register_node("nh_nodes:bluelava", {
    description = S("Blue Lava"),
    drawtype = "liquid",
    tiles = { "bluelava.png" },
    tiles = { {
        name = "bluelava_animated.png",
        backface_culling = false,
        animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 4.0 }
    },
        "bluelava.png" }, -- resto das faces
    use_texture_alpha = "blend",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_flowing = "nh_nodes:bluelava_flowing",
    liquid_alternative_source = "nh_nodes:bluelava",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 255, g = 0, b = 0 },
    groups = { lava = 1, liquid = 1, hot = 1 },
})

core.register_node("nh_nodes:bluelava_flowing", {
    description = S("Flowing Blue Lava"),
    drawtype = "flowingliquid",
    tiles = { "bluelava.png" },
    special_tiles = {
        {
            name = "bluelava_flowing_animated.png",
            backface_culling = false,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
        {
            name = "bluelava_flowing_animated.png",
            backface_culling = true,
            animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 0.9 }
        },
    },
    use_texture_alpha = "blend",
    paramtype = "light",
    light_source = 14,
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_flowing = "nh_nodes:bluelava_flowing",
    liquid_alternative_source = "nh_nodes:bluelava",
    liquid_viscosity = 1,
    post_effect_color = { a = 64, r = 255, g = 0, b = 0 },
    groups = { lava = 1, liquid = 1, hot = 1, not_in_creative_inventory = 1 },

})

-- ABM que verifica jogadores próximos ao nó de magma
core.register_abm({
    label = "Magma damage",
    nodenames = { "nh_nodes:magma" },
    interval = 1.0, -- checa a cada 1 segundo
    chance = 1,     -- 100% de chance de executar

    action = function(pos, node)
        -- Pega todos os objetos em raio de 1 bloco (toca as faces)
        local objects = core.get_objects_inside_radius(pos, 1.1)
        for _, obj in ipairs(objects) do
            if obj:is_player() then
                obj:set_hp(obj:get_hp() - 2) -- tira 1 coração por segundo
            end
        end
    end,
})

-- Limpa o timer quando jogador sai
core.register_on_leaveplayer(function(player)
    lava_damage_timer[player:get_player_name()] = nil
end)

core.register_abm({
    label = "Lava damage",
    nodenames = { "nh_nodes:lava", "nh_nodes:lava_flowing" },
    interval = 1.0,
    chance = 1,
    action = function(pos, node)
        local objects = core.get_objects_inside_radius(pos, 1.1)
        for _, obj in ipairs(objects) do
            if obj:is_player() then
                -- Evita double damage se já está dentro (coberto pelo globalstep)
                local ppos = obj:get_pos()
                local feet = core.get_node({ x = ppos.x, y = ppos.y, z = ppos.z })
                local head = core.get_node({ x = ppos.x, y = ppos.y + 1, z = ppos.z })

                local inside = feet.name == "nh_nodes:lava" or
                    feet.name == "nh_nodes:lava_flowing" or
                    head.name == "nh_nodes:lava" or
                    head.name == "nh_nodes:lava_flowing"

                if not inside then
                    obj:set_hp(obj:get_hp() - 11)
                end
            end
        end
    end,
})

-------
-- Papeis
-------

-- Node para Página em branco
core.register_node("nh_nodes:page_node", {
    description = S("Paper"),
    drawtype = "mesh",
    mesh = "page.obj",
    tiles = { "page.png" },
    inventory_image = "page.png",
    wield_image = "page.png",
    wield_scale = { x = 0.5, y = 0.5, z = 0.01 },
    visual_scale = 1.0,
    paramtype = "light",
    paramtype2 = "wallmounted", -- MUDOU PARA WALLMOUNTED
    sunlight_propagates = true,
    walkable = false,
    use_texture_alpha = "clip",
    selection_box = {
        type = "wallmounted",
        wall_top = { -0.31, -0.49, -0.44, 0.31, -0.45, 0.44 },
        wall_bottom = { -0.31, 0.5, -0.44, 0.31, 0.49, 0.44 },
        wall_side = { 0.5, -0.44, -0.31, 0.49, 0.44, 0.31 },
    },
    groups = { choppy = 2, oddly_breakable_by_hand = 3, flammable = 3 },
    drop = "",

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then
            return
        end

        local player_name = clicker:get_player_name()
        local has_feather, has_ink = writing_utils.player_has_writing_tools(clicker)
        if not has_feather or not has_ink then
            local msg = S("I think I need ")
            if not has_feather and not has_ink then
                msg = msg .. S("a feather in the hotbar and an ink bottle in the inventory to write.")
            elseif not has_feather then
                msg = msg .. S("a feather in the hotbar to write.")
            else
                msg = msg .. S("an ink bottle in the inventory to write.")
            end
            core.chat_send_player(player_name, msg)
            return
        end

        core.show_formspec(player_name, "nh_nodes:page_writer:" .. core.pos_to_string(pos),
            "size[8,6]" ..
            "label[0.3,0;" .. S("Write on the Page:") .. "]" ..
            "textarea[0.3,0.5;8,4.5;page_text;;]" ..
            "button[2,5;2,1;save;" .. S("Save") .. "]" ..
            "button[4,5;2,1;cancel;" .. S("Cancel") .. "]"
        )
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        if digger and digger:is_player() then
            local inv = digger:get_inventory()
            local itemstack = ItemStack("nh_items:page")
            if inv:room_for_item("main", itemstack) then
                inv:add_item("main", itemstack)
            else
                core.add_item(pos, itemstack)
            end
        end
    end,
})

-- Node para Página escrita
core.register_node("nh_nodes:writedpage_node", {
    description = S("Writed Paper"),
    drawtype = "mesh",
    mesh = "page.obj",
    tiles = { "writedpage.png" },
    inventory_image = "writedpage.png",
    wield_image = "writedpage.png",
    wield_scale = { x = 0.5, y = 0.5, z = 0.01 },
    paramtype = "light",
    paramtype2 = "wallmounted",
    sunlight_propagates = true,
    walkable = false,
    use_texture_alpha = "clip",
    selection_box = {
        type = "wallmounted",
        wall_top = { -0.31, -0.49, -0.44, 0.31, -0.45, 0.44 },
        wall_bottom = { -0.31, 0.5, -0.44, 0.31, 0.49, 0.44 },
        wall_side = { 0.5, -0.44, -0.31, 0.49, 0.44, 0.31 },
    },
    groups = { choppy = 2, oddly_breakable_by_hand = 3, flammable = 3, not_in_creative_inventory = 1 },
    drop = "",

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        if not clicker or not clicker:is_player() then
            return
        end

        local player_name = clicker:get_player_name()
        local meta = core.get_meta(pos)
        local text = meta:get_string("text")

        if text == "" then
            text = S("Blank Paper")
        end

        core.show_formspec(player_name, "nh_nodes:page_reader",
            "size[8,6]" ..
            "textarea[0.3,0.3;8,5;page_text;;" .. core.formspec_escape(text) .. "]" ..
            "button_exit[3,5.3;2,1;close;" .. S("Close") .. "]"
        )
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        if digger and digger:is_player() then
            local inv = digger:get_inventory()
            local itemstack = ItemStack("nh_items:writedpage")
            local meta = itemstack:get_meta()
            meta:set_string("text", oldmetadata.fields.text or "")

            if inv:room_for_item("main", itemstack) then
                inv:add_item("main", itemstack)
            else
                core.add_item(pos, itemstack)
            end
        end
    end,
})

-- Modificar os craftitems originais para colocar os nodes
core.override_item("nh_items:page", {
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local under = pointed_thing.under
        local above = pointed_thing.above

        if core.is_protected(above, placer:get_player_name()) then
            return itemstack
        end

        local node = core.get_node(above)
        if node.name ~= "air" then
            return itemstack
        end

        -- Calcular wallmounted - MUITO MAIS SIMPLES
        local dir = vector.subtract(above, under)
        local wallmounted = core.dir_to_wallmounted(dir)

        core.set_node(above, { name = "nh_nodes:page_node", param2 = wallmounted })
        core.sound_play("default_place_node", { pos = above, gain = 1.0 })

        if not core.is_creative_enabled(placer:get_player_name()) then
            itemstack:take_item()
        end

        return itemstack
    end,
})

core.override_item("nh_items:writedpage", {
    on_place = function(itemstack, placer, pointed_thing)
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        local under = pointed_thing.under
        local above = pointed_thing.above

        if core.is_protected(above, placer:get_player_name()) then
            return itemstack
        end

        local node = core.get_node(above)
        if node.name ~= "air" then
            return itemstack
        end

        local dir = vector.subtract(above, under)
        local wallmounted = core.dir_to_wallmounted(dir)

        core.set_node(above, { name = "nh_nodes:writedpage_node", param2 = wallmounted })
        core.sound_play("default_place_node", { pos = above, gain = 1.0 })

        local item_meta = itemstack:get_meta()
        local node_meta = core.get_meta(above)
        node_meta:set_string("text", item_meta:get_string("text"))

        if not core.is_creative_enabled(placer:get_player_name()) then
            itemstack:take_item()
        end

        return itemstack
    end,
})

if not nodes then nodes = {} end

function nodes.place_written_page(pos, text, facedir)
    core.set_node(pos, {
        name = "nh_nodes:writedpage_node",
        param2 = facedir
    })
    local meta = core.get_meta(pos)
    meta:set_string("text", text)
end

-- Handler para salvar o texto
core.register_on_player_receive_fields(function(player, formname, fields)
    local prefix = "nh_items:page_writer:"
    if formname:sub(1, #prefix) == "nh_items:page_writer:" then
        if fields.save and fields.page_text then
            local pos_str = formname:sub(#prefix + 1)
            local pos = core.string_to_pos(pos_str)

            if pos then
                local node = core.get_node(pos)
                if node.name == "nh_nodes:page_node" then
                    -- Substituir por página escrita mantendo a rotação
                    core.set_node(pos, { name = "nh_nodes:writedpage_node", param2 = node.param2 })
                    local meta = core.get_meta(pos)
                    meta:set_string("text", fields.page_text)

                    -- Consumir tinta (adapte conforme sua função)
                    if consume_ink then
                        writing_utils.consume_ink(player)
                    end

                    core.chat_send_player(player:get_player_name(), S("Text saved on the page!"))
                end
            end
        end
    end
end)

---------
-- Baú geral
--------
-- Verifica se o jogador tem o backchest equipado no slot de costas
local function player_has_backchest_equipped(player)
    local inv = player:get_inventory()
    local back_list = inv:get_list("armor_back")
    if not back_list then return false end
    for _, stack in ipairs(back_list) do
        if stack:get_name() == "nh_nodes:backchest" then
            return true
        end
    end
    return false
end

-- Monta o formspec do baú dinamicamente conforme o backchest estar equipado
local function build_chest_formspec(clicker)
    local chest_slots = "list[current_name;main;0,0.3;8,2;]"
    local player_slots

    if player_has_backchest_equipped(clicker) then
        player_slots =
            "list[current_player;main;0,5.85;8,2;8]" ..
            "list[current_player;main;0,8.05;8,1;]" ..
            "listring[current_name;main]" ..
            "listring[current_player;main]"
    else
        player_slots =
            "list[current_player;main;0,8.05;8,1;]" ..
            "listring[current_name;main]" ..
            "listring[current_player;main]"
    end

    return "size[8,9]" .. chest_slots .. player_slots
end

-- Função para atualizar itens visuais no baú
-- Mapa de node aberto → nome da entidade do baú correspondente
local CHEST_ENTITY_BY_NODE = {
    ["nh_nodes:oak_chest_open"]  = "nh_nodes:oak_chest_entity",
    ["nh_nodes:back_chest_open"] = "nh_nodes:back_chest_entity",
}

function chest_update_items(pos)
    local node = core.get_node(pos)
    local entity_name = CHEST_ENTITY_BY_NODE[node.name]
    if not entity_name then
        return
    end

    local meta    = core.get_meta(pos)
    local inv     = meta:get_inventory()

    -- Remover entidades de itens antigas
    local objects = core.get_objects_inside_radius(pos, 1)
    for _, obj in ipairs(objects) do
        if obj:get_luaentity() and obj:get_luaentity().name == "nh_nodes:chest_item" then
            obj:remove()
        end
    end

    -- Procurar a entidade do baú aberto para anexar os itens
    local chest_entity = nil
    for _, obj in ipairs(objects) do
        local luaent = obj:get_luaentity()
        if luaent and luaent.name == entity_name then
            chest_entity = obj
            break
        end
    end

    -- Se não houver entidade do baú, criar uma invisível para servir de base
    if not chest_entity then
        chest_entity = core.add_entity(pos, entity_name)
        if chest_entity and chest_entity:get_luaentity() then
            local luaent        = chest_entity:get_luaentity()
            luaent.node_pos     = pos
            luaent.is_invisible = true
            -- Aplicar rotação
            local yaw           = core.facedir_to_dir(node.param2)
            chest_entity:set_yaw(core.dir_to_yaw(yaw))
        end
    end

    if not chest_entity then
        return
    end

    -- Criar novas entidades para cada item (máximo 16 bones)
    for i = 1, math.min(16, inv:get_size("main")) do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            local entity = core.add_entity(pos, "nh_nodes:chest_item")
            if entity and entity:get_luaentity() then
                local luaent      = entity:get_luaentity()
                luaent.chest_pos  = pos
                luaent.slot_index = i
                luaent:update_item(stack:get_name())
                -- Anexar ao bone correspondente do baú
                entity:set_attach(chest_entity, "bone" .. i, { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
            end
        end
    end
end

-- Aliases para compatibilidade retroativa (redirecionam para chest_update_items)
oak_chest_update_items  = chest_update_items
back_chest_update_items = chest_update_items

-- Entidade para representar itens no baú
core.register_entity("nh_nodes:chest_item", {
    initial_properties = {
        visual = "wielditem",
        wield_item = "air",
        visual_size = { x = 0.15, y = 0.15 }, -- Tamanho reduzido (o tamanho do modelo é 10 e dos bones 1)
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
    },

    chest_pos = nil,
    slot_index = 0,

    on_activate = function(self, staticdata)
        self.object:set_armor_groups({ immortal = 1 })
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

        local node = core.get_node(self.chest_pos)
        if node.name ~= "nh_nodes:oak_chest_open" and node.name ~= "nh_nodes:back_chest_open" then
            self.object:remove()
        end
    end,
})

core.register_node("nh_nodes:oak_chest_open", {
    drawtype = "mesh",
    mesh = "chestopen.obj",         -- modelo sem tampa
    tiles = { "ChestTexture.png" }, -- mesma textura
    walkable = true,
    pointable = true,
    paramtype = "light",
    paramtype2 = "facedir",

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    groups = { not_in_creative_inventory = 1 },

    -- Quando clicar no baú aberto, mostrar inventário
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = core.get_meta(pos)
        local player_name = clicker:get_player_name()

        -- Marcar que o jogador está usando o baú
        meta:set_string("current_user", player_name)

        core.show_formspec(player_name, "nh_nodes:oak_chest_" .. core.pos_to_string(pos),
            build_chest_formspec(clicker))

        return itemstack
    end,

    -- Atualizar itens visuais quando o node é construído
    on_construct = function(pos)
        core.after(0.1, function()
            oak_chest_update_items(pos)
        end)
    end,

    -- Atualizar itens visuais após colocar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        core.after(0.1, function()
            oak_chest_update_items(pos)
        end)
    end,
})

core.register_node("nh_nodes:oakchest", {
    description = S("Oak Chest"),
    drawtype = "mesh",
    mesh = "chest.glb",
    tiles = { "ChestTexture.png" },
    walkable = true,
    pointable = true,

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { choppy = 2, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    -- Criar inventário quando o node é construído
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        -- Criar inventário com 32 slots (8x4)
        inv:set_size("main", 8 * 2) -- O bau é quadrado escolhi 4x4, mas na forma do inventário 8x2

        -- Definir formspec do inventário
        meta:set_string("formspec",
            "size[8,9]" ..
            "list[current_name;main;0,0.3;8,2;]" ..
            "list[current_player;main;0,5.85;8,2;8]" ..
            "list[current_player;main;0,8.05;8,1;]" ..
            "listring[current_name;main]" ..
            "listring[current_player;main]"
        )

        meta:set_string("infotext", S("Oak Chest"))
    end,

    -- Verificar se pode cavar (não permitir se tiver itens)
    can_dig = function(pos, player)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    -- Ao clicar com botão direito
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- Tocar som de abertura
        --core.sound_play("default_chest_open", {
        --    pos = pos,
        --    gain = 0.3,
        --    max_hear_distance = 10,
        --}, true)

        -- Substitui o node pelo baú aberto
        local current_node = core.get_node(pos)
        core.swap_node(pos, { name = "nh_nodes:oak_chest_open", param2 = current_node.param2 })

        -- Retira a entidade baú depois da animação
        local objects = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:get_luaentity() and obj:get_luaentity().name == "nh_nodes:oak_chest_entity" then
                obj:remove()
            end
        end

        -- Criar entidade para animação
        local entity = core.add_entity(pos, "nh_nodes:oak_chest_entity")
        if entity and entity:get_luaentity() then
            local luaentity = entity:get_luaentity()
            luaentity.node_pos = pos
            luaentity.original_param2 = current_node.param2
            -- Aplicar a rotação do baú à entidade
            local yaw = core.facedir_to_dir(current_node.param2)
            entity:set_yaw(core.dir_to_yaw(yaw))
            entity:set_animation({ x = 0, y = 0.25 }, 1, 0, false) -- 0 a 0.25s a 30fps = frames 0-7.5
        end

        -- Abrir inventário
        local meta = core.get_meta(pos)
        local player_name = clicker:get_player_name()

        -- Marcar que o jogador está usando o baú
        meta:set_string("current_user", player_name)

        -- Atualizar itens visuais
        oak_chest_update_items(pos)

        core.show_formspec(player_name, "nh_nodes:oak_chest_" .. core.pos_to_string(pos),
            build_chest_formspec(clicker))

        return itemstack
    end,

    -- Preservar inventário ao cavar
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local items = {}

        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                table.insert(items, stack:to_string())
            end
        end

        if #items > 0 then
            drops[1]:get_meta():set_string("items", core.serialize(items))
        end
    end,

    -- Restaurar inventário ao colocar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = core.get_meta(pos)
        local item_meta = itemstack:get_meta()
        local items = item_meta:get_string("items")

        if items ~= "" then
            items = core.deserialize(items)
            local inv = meta:get_inventory()

            for i, item_str in ipairs(items) do
                inv:set_stack("main", i, ItemStack(item_str))
            end
        end
    end,
})

core.register_node("nh_nodes:oak_chest", {
    description = S("Oak Chest") .. "\n" .. S("[with items]"),
    drawtype = "mesh",
    mesh = "chest.glb",
    tiles = { "ChestTexture.png" },
    walkable = true,
    pointable = true,

    paramtype = "light",
    paramtype2 = "facedir",
    groups = { choppy = 2, oddly_breakable_by_hand = 1 },
    --sounds = default.node_sound_wood_defaults(),

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },
    drop = "nh_nodes:oakchest", -- sem "_"

    -- Criar inventário quando o node é construído
    on_construct = function(pos)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()

        -- Criar inventário com 32 slots (8x4)
        inv:set_size("main", 8 * 2) -- O bau é quadrado escolhi 4x4, mas na forma do inventário 8x2

        -- Adiciona páginas com textos pré-definidos
        local page1 = items.create_page_with_text(
            S("Day 1: I found this abandoned place. It seems someone lived here a long time ago.")
        )

        local page2 = items.create_page_with_text(
            S("Day 15: Supplies are running out. I need to find a way out before it's too late.")
        )

        local page3 = items.create_page_with_text(
            S("Day 30: I heard strange sounds during the night. I'm not alone here...")
        )

        inv:set_stack("main", 1, page1)
        inv:set_stack("main", 2, page2)
        inv:set_stack("main", 3, page3)

        -- Adiciona páginas em branco
        inv:set_stack("main", 4, ItemStack("nh_items:page 5"))      -- 5 páginas em branco

        inv:set_stack("main", 5, ItemStack("nh_items:feather"))     -- pena de escrever
        inv:set_stack("main", 6, ItemStack("nh_nodes:inkbottle"))   -- frasco com tinta
        inv:set_stack("main", 7, ItemStack("nh_nodes:torch2"))      -- tocha acesa

        inv:set_stack("main", 8, ItemStack("nh_nodes:apple 2"))     -- 2 maças
        inv:set_stack("main", 9, ItemStack("nh_nodes:blueberry 2")) -- 2 mitilos
        inv:set_stack("main", 10, ItemStack("nh_nodes:coconut 2"))  -- 2 cocos
        inv:set_stack("main", 11, ItemStack("nh_nodes:palmlog 1"))
        inv:set_stack("main", 12, ItemStack("nh_nodes:palmleaf 1"))

        -- Definir formspec do inventário
        meta:set_string("formspec",
            "size[8,9]" ..
            "list[current_name;main;0,0.3;8,2;]" ..
            "list[current_player;main;0,5.85;8,2;8]" ..
            "list[current_player;main;0,8.05;8,1;]" ..
            "listring[current_name;main]" ..
            "listring[current_player;main]"
        )

        meta:set_string("infotext", S("Lost Oak Chest"))
    end,

    -- Verificar se pode cavar (não permitir se tiver itens)
    can_dig = function(pos, player)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    -- Ao clicar com botão direito
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- Tocar som de abertura
        --core.sound_play("default_chest_open", {
        --    pos = pos,
        --    gain = 0.3,
        --    max_hear_distance = 10,
        --}, true)

        -- Substitui o node pelo baú aberto
        local current_node = core.get_node(pos)
        core.swap_node(pos, { name = "nh_nodes:oak_chest_open", param2 = current_node.param2 })

        -- Retira a entidade baú depois da animação
        local objects = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:get_luaentity() and obj:get_luaentity().name == "nh_nodes:oak_chest_entity" then
                obj:remove()
            end
        end

        -- Criar entidade para animação
        local entity = core.add_entity(pos, "nh_nodes:oak_chest_entity")
        if entity and entity:get_luaentity() then
            local luaentity = entity:get_luaentity()
            luaentity.node_pos = pos
            luaentity.original_param2 = current_node.param2
            -- Aplicar a rotação do baú à entidade
            local yaw = core.facedir_to_dir(current_node.param2)
            entity:set_yaw(core.dir_to_yaw(yaw))
            entity:set_animation({ x = 0, y = 0.25 }, 1, 0, false) -- 0 a 0.25s a 30fps = frames 0-7.5
        end

        -- Abrir inventário
        local meta = core.get_meta(pos)
        local player_name = clicker:get_player_name()

        -- Marcar que o jogador está usando o baú
        meta:set_string("current_user", player_name)

        -- Atualizar itens visuais
        oak_chest_update_items(pos)

        core.show_formspec(player_name, "nh_nodes:oak_chest_" .. core.pos_to_string(pos),
            build_chest_formspec(clicker))

        return itemstack
    end,

    -- Preservar inventário ao cavar
    preserve_metadata = function(pos, oldnode, oldmeta, drops)
        local meta = core.get_meta(pos)
        local inv = meta:get_inventory()
        local items = {}

        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if not stack:is_empty() then
                table.insert(items, stack:to_string())
            end
        end

        if #items > 0 then
            drops[1]:get_meta():set_string("items", core.serialize(items))
        end
    end,

    -- Restaurar inventário ao colocar
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = core.get_meta(pos)
        local item_meta = itemstack:get_meta()
        local items = item_meta:get_string("items")

        if items ~= "" then
            items = core.deserialize(items)
            local inv = meta:get_inventory()

            for i, item_str in ipairs(items) do
                inv:set_stack("main", i, ItemStack(item_str))
            end
        end
    end,
})

-- Entidade invisível para animação
core.register_entity("nh_nodes:oak_chest_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "chest.glb",
        textures = { "ChestTexture.png" },
        visual_size = { x = 1, y = 1, z = 1 },
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
        self.object:set_armor_groups({ immortal = 1 })
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
            self.object:set_animation({ x = 0.25, y = 0.25 }, 0, 0, false)
        end
    end,
})

-- Entidade para animação de fechamento
core.register_entity("nh_nodes:oak_chest_close_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "chest.glb",
        textures = { "ChestTexture.png" },
        visual_size = { x = 1, y = 1, z = 1 },
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
        self.object:set_armor_groups({ immortal = 1 })
    end,

    on_step = function(self, dtime)
        self.timer = self.timer + dtime

        -- Remover entidade e fechar baú após a animação
        if self.timer > 0.3 then
            -- Remover todos os itens anexados
            if self.node_pos then
                local objects = core.get_objects_inside_radius(self.node_pos, 1)
                for _, obj in ipairs(objects) do
                    local luaent = obj:get_luaentity()
                    if luaent and luaent.name == "nh_nodes:chest_item" then
                        obj:remove()
                    end
                end
            end

            self.object:remove()

            -- Trocar para node fechado
            if self.node_pos then
                local node = core.get_node(self.node_pos)
                if node.name == "nh_nodes:oak_chest_open" then
                    core.swap_node(self.node_pos, { name = "nh_nodes:oak_chest", param2 = self.original_param2 })
                end
            end
        end
    end,
})

-- Detectar quando o jogador fecha o formspec
core.register_on_player_receive_fields(function(player, formname, fields)
    local prefix = "nh_nodes:oak_chest_"
    -- Verificar se é um formspec de baú
    if formname:sub(1, #prefix) == "nh_nodes:oak_chest_" then
        local pos_string = formname:sub(#prefix + 1)
        local pos = core.string_to_pos(pos_string)

        if pos then
            local node = core.get_node(pos)

            -- Se o baú estiver aberto, fechá-lo
            if node.name == "nh_nodes:oak_chest_open" then
                local meta = core.get_meta(pos)
                local current_user = meta:get_string("current_user")
                local player_name = player:get_player_name()

                -- Verificar se é o jogador que estava usando
                if current_user == player_name then
                    -- Limpar usuário atual
                    meta:set_string("current_user", "")

                    -- Remover apenas a entidade da animação de abertura (mas manter os itens)
                    local objects = core.get_objects_inside_radius(pos, 0.5)
                    local chest_entity = nil

                    for _, obj in ipairs(objects) do
                        local luaent = obj:get_luaentity()
                        if luaent and luaent.name == "nh_nodes:oak_chest_entity" then
                            chest_entity = obj
                            break
                        end
                    end

                    -- Criar entidade para animação de fechamento
                    local close_entity = core.add_entity(pos, "nh_nodes:oak_chest_close_entity")
                    if close_entity and close_entity:get_luaentity() then
                        local luaentity = close_entity:get_luaentity()
                        luaentity.node_pos = pos
                        luaentity.original_param2 = node.param2

                        -- Transferir os itens anexados para a entidade de fechamento
                        if chest_entity then
                            for _, obj in ipairs(objects) do
                                local luaent = obj:get_luaentity()
                                if luaent and luaent.name == "nh_nodes:chest_item" then
                                    -- Re-anexar ao novo baú (fechamento)
                                    local slot = luaent.slot_index
                                    obj:set_attach(close_entity, "bone" .. slot, { x = 0, y = 0, z = 0 },
                                        { x = 0, y = 0, z = 0 })
                                end
                            end

                            -- Remover a entidade antiga do baú
                            chest_entity:remove()
                        end

                        -- Aplicar a rotação do baú à entidade
                        local yaw = core.facedir_to_dir(node.param2)
                        close_entity:set_yaw(core.dir_to_yaw(yaw))
                        -- Animação de fechamento (do frame aberto para fechado)
                        close_entity:set_animation({ x = 0.25, y = 0 }, 30, 0, false)
                    end
                end
            end
        end
    end
end)



-- Detectar mudanças no inventário do baú
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if action ~= "move" and action ~= "put" and action ~= "take" then
        return
    end

    if inventory_info.to_list ~= "main" and inventory_info.from_list ~= "main" then
        return
    end

    local player_name = player:get_player_name()
    local player_pos = player:get_pos()
    if not player_pos then return end

    local objects = core.get_objects_inside_radius(player_pos, 10)

    for _, obj in ipairs(objects) do
        if obj:is_player() then
            goto continue
        end

        local pos = obj:get_pos()
        if not pos then
            goto continue
        end

        local node = core.get_node_or_nil(pos)
        if not node then
            goto continue
        end

        if node.name == "nh_nodes:oak_chest_open" then
            local meta = core.get_meta(pos)
            if meta:get_string("current_user") == player_name then
                oak_chest_update_items(pos)
            end
        end

        ::continue::
    end
end)

-- Som de fechamento ao sair do formspec (opcional)
--core.register_on_player_receive_fields(function(player, formname, fields)
--    if formname:find("nh_nodes:oak_chest_") then
--        if fields.quit then
--            local pos_str = formname:gsub("nh_nodes:oak_chest_", "")
--            local pos = core.string_to_pos(pos_str)
--
--            if pos then
--                core.sound_play("default_chest_close", {
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

--core.register_node("nh_nodes:oak_door", {
--    description = "Porta de Carvalho",
--    initial_properties = {
--        visual = "mesh",
--        mesh = "porta_tablada_carvalho.obj",
--        textures = {"porta_tablada_carvalho.png"},
--        --visual_size = {x=1, y=2}, -- ajuste
--        groups = {choppy = 2},
--    },
--})

---------------------------
-- FUNÇÃO DE ARREMESSO
---------------------------
local function throw_pebble(itemstack, user)
    local pos = user:get_pos()
    local dir = user:get_look_dir()
    pos.y = pos.y + 2.25 -- altura dos olhos
    local obj = core.add_entity(pos, "nh_nodes:pebble_entity")
    if obj then
        obj:set_velocity(vector.multiply(dir, 13))
        obj:set_acceleration({ x = 0, y = -9.81, z = 0 })
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

-- FUNÇÃO DE ARREMESSO
local function throw_pebble(itemstack, placer)
    if not placer or not placer:is_player() then
        return itemstack
    end

    local pos = placer:get_pos()
    pos.y = pos.y + 1.5 -- altura dos olhos

    local dir = placer:get_look_dir()
    local obj = core.add_entity(pos, "nh_nodes:pebble_entity")

    if obj then
        obj:set_velocity(vector.multiply(dir, 18))
        obj:set_acceleration({ x = 0, y = -10, z = 0 })

        -- ✅ Define o atirador para não se machucar
        local ent = obj:get_luaentity()
        if ent then
            ent._shooter = placer
        end
    end

    -- Remove 1 item do stack
    itemstack:take_item(1)
    return itemstack
end

-- ITEM SEIXO ARREMESSÁVEL
local function update_neighbors(pos)
    local offsets = {
        { x = 0,  y = 1,  z = 0 },
        { x = 0,  y = -1, z = 0 },
        { x = 1,  y = 0,  z = 0 },
        { x = -1, y = 0,  z = 0 },
        { x = 0,  y = 0,  z = 1 },
        { x = 0,  y = 0,  z = -1 },
    }
    for _, off in ipairs(offsets) do
        local npos = vector.add(pos, off)
        -- Dispara física de falling_node (areia, cascalho, neve, etc.)
        core.check_for_falling(npos)
    end
end

core.register_craftitem("nh_nodes:pebble_item", {
    description = S("Pebble") .. "\n" .. S("[Throwable]") .. "\n" .. S("Damage: +1") .. "\n" .. S("(Throw: Q / drop)"),
    inventory_image = "seixoarremessavel.png",
    wield_image = "seixoarremessavel.png",
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = -0.25, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
    },
    wielded_visual_size = { x = 0.15, y = 0.15, z = 0.15 },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },

    -- Botão direito = arremessa
    on_place = function(itemstack, placer, pointed_thing)
        return throw_pebble(itemstack, placer)
    end,

    -- Ao soltar = arremessa
    on_drop = function(itemstack, dropper, pos)
        return throw_pebble(itemstack, dropper)
    end

})

---------------------------
-- ENTIDADE DO PROJÉTIL
---------------------------
core.register_entity("nh_nodes:pebble_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
        visual = "wielditem",
        visual_size = { x = 0.5, y = 0.5 },
        textures = { "nh_nodes:pebble" },
    },

    _stuck = false,
    _timer = 0,
    _stuck_timer = 0,
    _last_pos = nil,
    _shooter = nil, -- ✅ Declarado aqui para ficar visível

    on_activate = function(self, staticdata)
        self._timer = 0
        self._stuck = false
        self._stuck_timer = 0
        self._shooter = nil
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
                local node = core.get_node(node_pos)

                if node.name == "air" or not core.registered_nodes[node.name].walkable then
                    core.set_node(node_pos, { name = "nh_nodes:pebble" })
                    update_neighbors(node_pos)
                else
                    local offsets = {
                        { x = 0,  y = 1,  z = 0 },
                        { x = 0,  y = -1, z = 0 },
                        { x = 1,  y = 0,  z = 0 },
                        { x = -1, y = 0,  z = 0 },
                        { x = 0,  y = 0,  z = 1 },
                        { x = 0,  y = 0,  z = -1 },
                    }

                    local placed = false
                    for _, offset in ipairs(offsets) do
                        local try_pos = vector.add(node_pos, offset)
                        local try_node = core.get_node(try_pos)
                        if try_node.name == "air" then
                            core.set_node(try_pos, { name = "nh_nodes:pebble" })
                            update_neighbors(try_pos)
                            placed = true
                            break
                        end
                    end

                    if not placed then
                        core.add_item(pos, "nh_nodes:pebble_item")
                    end
                end

                self.object:remove()
            end
            return
        end

        local vel = self.object:get_velocity()
        if not vel then
            self.object:remove()
            return
        end

        local speed = vector.length(vel)

        -- Se a velocidade é muito baixa (parou de se mover)
        if speed < 0.5 then
            self._stuck = true
            self.object:set_velocity({ x = 0, y = 0, z = 0 })
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
            return
        end

        -- Verifica colisão com blocos sólidos via raycast manual
        local step_dir = vector.normalize(vel)
        local check_distance = math.min(speed * dtime * 2, 1)
        local steps = math.ceil(check_distance / 0.2)

        for i = 1, steps do
            local check_pos = vector.add(pos, vector.multiply(step_dir, i * 0.2))
            local node = core.get_node(check_pos)

            if node and node.name and core.registered_nodes[node.name] then
                if core.registered_nodes[node.name].walkable then
                    self._stuck = true
                    self.object:set_pos(check_pos)
                    self.object:set_velocity({ x = 0, y = 0, z = 0 })
                    self.object:set_acceleration({ x = 0, y = 0, z = 0 })
                    return
                end
                if node.name == "nh_nodes:coconutlinked" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:coconut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
            end
        end

        local objs = core.get_objects_inside_radius(pos, 1.2) -- Raio aumentado de 0.6 para 1.2 para não passar pelo mob
        for _, obj in ipairs(objs) do
            -- Ignora o próprio projétil e o atirador
            if obj ~= self.object and obj ~= self._shooter then
                local is_target = obj:is_player()

                if not is_target then
                    local ent = obj:get_luaentity()
                    -- Usa get_hp() no lugar de ent.hp_max, compatível com MobsRedo
                    if ent and ent.name ~= "nh_nodes:pebble_entity" then
                        local hp = obj:get_hp()
                        if hp and hp > 0 then
                            is_target = true
                        end
                    end
                end

                if is_target then
                    core.log("action", "[Seixo] Acertou alvo em " .. core.pos_to_string(pos))

                    core.sound_play("default_dig_cracky", { pos = pos, gain = 0.5 })

                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = { fleshy = 2 },
                    }, vel)

                    core.add_item(pos, "nh_nodes:pebble_item")
                    self.object:remove()
                    return
                end
            end
        end

        self._last_pos = pos
    end,
})

core.register_node("nh_nodes:limb", {
    description = S("Limb") .. "\n" .. S("Reach: +2") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 10"),
    drawtype = "mesh",
    mesh = "branch.obj",
    tiles = { "branchtex.png" }, --oaktimber.png

    paramtype = "light",

    range = 5, -- AUMENTA O ALCANCE

    groups = {

        oddly_breakable_by_hand = 3,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- desgasta ao cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 6552 -- ~10 usos (65535 / 10)
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = { -0.06, -0.5, -0.12, 0.06, 1.05, 0.07 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.06, -0.5, -0.12, 0.06, 1.05, 0.07 },
    },
})

core.register_node("nh_nodes:stick", {
    description = S("Stick") .. "\n" .. S("Reach: +1") .. "\n" .. S("Uses: 5"),
    drawtype = "mesh",
    mesh = "stick.obj",
    tiles = { "stick.png" },
    range = 4,
    groups = { oddly_breakable_by_hand = 1, flammable = 2, falling_node = 1 },
    paramtype = "light",

    collision_box = {
        type = "fixed",
        fixed = { -0.04, -0.5, -0.12, 0.04, 0.5, 0.07 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.04, -0.5, -0.12, 0.04, 0.5, 0.07 },
    },

    -- desgasta ao cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 13107 -- ~5 usos (65535 / 5)
        itemstack:set_wear(wear)
        return itemstack
    end,
})

core.register_node("nh_nodes:fallenstick", {
    description = S("Fallen stick"),
    drawtype = "mesh",
    mesh = "stick2.obj",
    tiles = { "stick.png" },

    drop = "nh_nodes:stick",

    paramtype = "light",
    walkable = false,

    groups = { oddly_breakable_by_hand = 1, flammable = 2, falling_node = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.12, 0.5, -0.435, 0.065 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.12, 0.5, -0.435, 0.065 },
    },
})


---------------------------
-- NODE DO SEIXO DE OBSIDIANA
---------------------------
core.register_node("nh_nodes:obsidianpebble", {
    description = S("Obsidian Pebble") .. "\n" .. S("Damage: +1"),
    drawtype = "mesh",
    mesh = "pebble.obj",         --
    tiles = { "obsidiana.png" }, -- tiles = {"pedra.png"},
    --inventory_image = "seixo.png",
    --wield_image = "seixo.png",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    drop = "nh_nodes:obsidianpebble_item",

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        oddly_breakable_by_hand = 3,
        falling_node = 1,
        attached_node = 1,
    },

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },
})

---------------------------
-- FUNÇÃO DE ARREMESSO
---------------------------
local function throw_pebble(itemstack, placer)
    if not placer or not placer:is_player() then
        return itemstack
    end

    local pos = placer:get_pos()
    pos.y = pos.y + 1.5 -- altura dos olhos

    local dir = placer:get_look_dir()
    local obj = core.add_entity(pos, "nh_nodes:obsidianpebble_entity")

    if obj then
        obj:set_velocity(vector.multiply(dir, 18))
        obj:set_acceleration({ x = 0, y = -10, z = 0 })

        -- ✅ Define o atirador para não se machucar
        local ent = obj:get_luaentity()
        if ent then
            ent._shooter = placer
        end
    end

    -- Remove 1 item do stack
    itemstack:take_item(1)
    return itemstack
end

---------------------------
-- ITEM
---------------------------
core.register_craftitem("nh_nodes:obsidianpebble_item", {
    description = S("Obsidian Pebble") ..
        "\n" .. S("[Throwable]") .. "\n" .. S("Damage: +1") .. "\n" .. S("(Throw: Q / drop)"),
    inventory_image = "obsidiana_seixo_arremessavel.png",
    wield_image = "obsidiana_seixo_arremessavel.png",
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = -0.25, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
    },
    wielded_visual_size = { x = 0.15, y = 0.15, z = 0.15 },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },

    -- Botão direito = arremessa
    on_place = function(itemstack, placer, pointed_thing)
        return throw_pebble(itemstack, placer)
    end,

    -- Ao soltar = arremessa
    on_drop = function(itemstack, dropper, pos)
        return throw_pebble(itemstack, dropper)
    end,
})


---------------------------
-- ENTIDADE DO PROJÉTIL
---------------------------
core.register_entity("nh_nodes:obsidianpebble_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
        visual = "wielditem",
        visual_size = { x = 0.5, y = 0.5 },
        textures = { "nh_nodes:obsidianpebble" },
    },

    _stuck = false,
    _timer = 0,
    _stuck_timer = 0,
    _last_pos = nil,
    _shooter = nil, -- ✅ Declarado aqui para ficar visível

    on_activate = function(self, staticdata)
        self._timer = 0
        self._stuck = false
        self._stuck_timer = 0
        self._shooter = nil
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
                local node = core.get_node(node_pos)

                if node.name == "air" or not core.registered_nodes[node.name].walkable then
                    core.set_node(node_pos, { name = "nh_nodes:obsidianpebble" })
                else
                    local offsets = {
                        { x = 0,  y = 1,  z = 0 },
                        { x = 0,  y = -1, z = 0 },
                        { x = 1,  y = 0,  z = 0 },
                        { x = -1, y = 0,  z = 0 },
                        { x = 0,  y = 0,  z = 1 },
                        { x = 0,  y = 0,  z = -1 },
                    }

                    local placed = false
                    for _, offset in ipairs(offsets) do
                        local try_pos = vector.add(node_pos, offset)
                        local try_node = core.get_node(try_pos)
                        if try_node.name == "air" then
                            core.set_node(try_pos, { name = "nh_nodes:obsidianpebble" })
                            placed = true
                            break
                        end
                    end

                    if not placed then
                        core.add_item(pos, "nh_nodes:obsidianpebble_item")
                    end
                end

                self.object:remove()
            end
            return
        end

        local vel = self.object:get_velocity()
        if not vel then
            self.object:remove()
            return
        end

        local speed = vector.length(vel)

        -- Se a velocidade é muito baixa (parou de se mover)
        if speed < 0.5 then
            self._stuck = true
            self.object:set_velocity({ x = 0, y = 0, z = 0 })
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
            return
        end

        -- Verifica colisão com blocos sólidos via raycast manual
        local step_dir = vector.normalize(vel)
        local check_distance = math.min(speed * dtime * 2, 1)
        local steps = math.ceil(check_distance / 0.2)

        for i = 1, steps do
            local check_pos = vector.add(pos, vector.multiply(step_dir, i * 0.2))
            local node = core.get_node(check_pos)

            if node and node.name and core.registered_nodes[node.name] then
                if core.registered_nodes[node.name].walkable then
                    self._stuck = true
                    self.object:set_pos(check_pos)
                    self.object:set_velocity({ x = 0, y = 0, z = 0 })
                    self.object:set_acceleration({ x = 0, y = 0, z = 0 })
                    return
                end
                if node.name == "nh_nodes:coconutlinked" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:coconut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
            end
        end

        -- ✅ Raio aumentado de 0.6 para 1.2 para não passar pelo mob
        local objs = core.get_objects_inside_radius(pos, 1.2)
        for _, obj in ipairs(objs) do
            -- Ignora o próprio projétil e o atirador
            if obj ~= self.object and obj ~= self._shooter then
                local is_target = obj:is_player()

                if not is_target then
                    local ent = obj:get_luaentity()
                    -- ✅ Usa get_hp() no lugar de ent.hp_max, compatível com MobsRedo
                    if ent and ent.name ~= "nh_nodes:obsidianpebble_entity" then
                        local hp = obj:get_hp()
                        if hp and hp > 0 then
                            is_target = true
                        end
                    end
                end

                if is_target then
                    core.log("action", "[Seixo de Obsidiana] Acertou alvo em " .. core.pos_to_string(pos))

                    core.sound_play("default_dig_cracky", { pos = pos, gain = 0.5 })

                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = { fleshy = 2 },
                    }, vel)

                    core.add_item(pos, "nh_nodes:obsidianpebble_item")
                    self.object:remove()
                    return
                end
            end
        end

        self._last_pos = pos
    end,
})


---------------------------
-- NODE DO SEIXO DE OBSIDIANA
---------------------------
core.register_node("nh_nodes:obsidianblade", {
    description = S("Obsidian Blade"),
    drawtype = "mesh",
    mesh = "obsidianblade.obj",  --
    tiles = { "obsidiana.png" }, -- tiles = {"pedra.png"},
    --inventory_image = "seixo.png",
    --wield_image = "seixo.png",
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

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})

---------------------------
-- NODE DA FERRAMENTA REMO
---------------------------
core.register_node("nh_nodes:rowing", {
    description = S("Rowing") .. "\n" .. S("Reach: +3") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "rowing.obj",       --
    tiles = { "oakwood.png" }, -- tiles = {"pedra.png"},
    --inventory_image = "seixo.png",
    --wield_image = "seixo.png",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    range = 6, -- AUMENTA O ALCANCE

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,


    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.5, 0.125, -0.435, 1.35 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.5, 0.125, -0.435, 1.35 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 3, y = 0, z = 1.8 },
        rot = { x = 90, y = 0, z = -90 },
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})


---------------------------
-- ENTIDADE DA JANGADA (versão navegável)
---------------------------
core.register_entity("nh_nodes:pineraft_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "pineraft_entity.obj",
        textures = { "pineraft.png" },
        visual_size = { x = 2.5, y = 2.5, z = 2.5 },
        collisionbox = { -1, 0, -1.5, 1, 0.9, 1.5 },
        physical = true,
        is_visible = true,
        hp_max = 4, -- "durabilidade": quantos socos para quebrar
        -- Adicione isso:
        automatic_face_movement_dir = false,
        stepheight = 0.5,
        gravity = { x = 0, y = -9.81, z = 0 },
    },

    driver = nil,

    on_activate = function(self, staticdata)
        self.object:set_armor_groups({ immortal = 0, fleshy = 100 })
        self.object:set_hp(8)
        self.object:set_velocity({ x = 0, y = 0, z = 0 })
        self.object:set_acceleration({ x = 0, y = -9.81, z = 0 })
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        -- Desmonta se for o motorista
        if self.driver and puncher == self.driver then
            self.driver:set_detach()
            if self._driver_visual_size then
                self.driver:set_properties({ visual_size = self._driver_visual_size })
                self._driver_visual_size = nil
            end
            self.driver = nil
            return
        end

        -- Só permite quebrar com a mão (sem ferramenta)
        local item = puncher:get_wielded_item()
        if item:get_name() ~= "" then
            -- tem ferramenta na mão, não quebra (opcional, remova se quiser)
            return
        end

        local hp = self.object:get_hp()
        hp = hp - 1

        if hp <= 0 then
            -- Dropa o item da jangada
            local pos = self.object:get_pos()
            core.add_item(pos, "nh_nodes:pineraft")
            self.object:remove()
        else
            self.object:set_hp(hp)
            -- Feedback visual: pisca (opcional)
            -- self.object:punch(puncher, ...) -- deixa o engine piscar
        end
    end,

    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then return end

        local node_at     = core.get_node({ x = pos.x, y = pos.y + 0.5, z = pos.z })
        local node_below  = core.get_node({ x = pos.x, y = pos.y - 0.5, z = pos.z })
        local node_below2 = core.get_node({ x = pos.x, y = pos.y + 0.35, z = pos.z }) -- logo abaixo do centro

        local water_nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }

        local submerged   = water_nodes[node_at.name]                       -- entidade está dentro da água
        local on_surface  = water_nodes[node_below2.name] and not submerged -- entidade está na superfície

        local vel         = self.object:get_velocity()

        if submerged then
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
            self.object:set_velocity({ x = vel.x, y = 2, z = vel.z })
        elseif on_surface then
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
            self.object:set_velocity({ x = vel.x, y = 0, z = vel.z })
        else
            -- No ar: gravidade age normalmente
            self.object:set_acceleration({ x = 0, y = -9.81, z = 0 })
            if vel.y > 0 then
                self.object:set_velocity({ x = vel.x, y = 0, z = vel.z })
            end
        end
        if self.driver then
            -- Verifica se o jogador tem o remo na hotbar
            local has_oar = false
            local inv = self.driver:get_inventory()
            if inv then
                local hotbar_size = 8
                if self.driver.hud_get_hotbar_itemcount then
                    hotbar_size = self.driver:hud_get_hotbar_itemcount()
                end
                for i = 1, hotbar_size do
                    local stack = inv:get_stack("main", i)
                    if stack:get_name() == "nh_nodes:rowing" then
                        has_oar = true
                        break
                    end
                end
                for i = 1, hotbar_size do
                    local stack = inv:get_stack("main", i)
                    if stack:get_name() == "nh_nodes:rowing" then
                        has_oar = true
                        break
                    end
                end

                -- Mensagem FORA do loop, e só envia uma vez usando um cooldown
                if not has_oar then
                    if not self._oar_msg_timer or self._oar_msg_timer <= 0 then
                        core.chat_send_player(self.driver:get_player_name(),
                            "Acho que preciso de um remo pra mover a jangada...")
                        self._oar_msg_timer = 5 -- segundos antes de repetir
                    end
                end

                if self._oar_msg_timer and self._oar_msg_timer > 0 then
                    self._oar_msg_timer = self._oar_msg_timer - dtime
                end
            end

            local speed    = 3
            local raft_yaw = self.object:get_yaw()

            if has_oar then
                local ctrl       = self.driver:get_player_control()
                local mouse_yaw  = self.driver:get_look_horizontal()
                local turn_speed = 1.5

                -- Rotação suave em direção ao mouse
                local diff       = mouse_yaw - raft_yaw
                while diff > math.pi do diff = diff - 2 * math.pi end
                while diff < -math.pi do diff = diff + 2 * math.pi end
                local new_yaw = raft_yaw + diff * turn_speed * dtime

                if ctrl.left then new_yaw = new_yaw + 0.05 end
                if ctrl.right then new_yaw = new_yaw - 0.05 end

                self.object:set_yaw(new_yaw)

                local vx, vz = 0, 0
                if ctrl.up then
                    vx = math.sin(-new_yaw) * speed; vz = math.cos(-new_yaw) * speed
                end
                if ctrl.down then
                    vx = -math.sin(-new_yaw) * speed; vz = -math.cos(-new_yaw) * speed
                end

                local vel = self.object:get_velocity()
                self.object:set_velocity({ x = vx, y = vel.y, z = vz })
            else
                -- Sem remo: para a jangada gradualmente (atrito)
                local vel = self.object:get_velocity()
                self.object:set_velocity({
                    x = vel.x * 0.85,
                    y = vel.y,
                    z = vel.z * 0.85,
                })
            end
        end

        local half_width = 2.7  --/ 2
        local half_length = 2.9 --/ 2
        local half_height = 1.5 --/ 2

        local search_radius = 4 -- só para busca inicial (ligeiramente maior)

        local being_pushed = false

        for _, obj in ipairs(core.get_objects_inside_radius(pos, search_radius)) do
            if obj:is_player() and obj ~= self.driver then
                local ppos = obj:get_pos()

                local dx = ppos.x - pos.x
                local dy = ppos.y - pos.y
                local dz = ppos.z - pos.z

                -- ✅ filtro retangular (caixa)
                if math.abs(dx) <= half_width and
                    math.abs(dy) <= half_height and
                    math.abs(dz) <= half_length then
                    local pvel = obj:get_velocity()
                    local speed_sq = pvel.x * pvel.x + pvel.z * pvel.z

                    if speed_sq > 0.1 then
                        local spd = math.sqrt(speed_sq)
                        local force = 1.75
                        local cur_vel = self.object:get_velocity()

                        self.object:set_velocity({
                            x = cur_vel.x + (pvel.x / spd) * force * dtime,
                            y = cur_vel.y,
                            z = cur_vel.z + (pvel.z / spd) * force * dtime,
                        })

                        being_pushed = true
                    end
                end
            end
        end

        -- Atrito só quando ninguém está empurrando e não há driver
        if not self.driver and not being_pushed then
            local cur_vel = self.object:get_velocity()
            self.object:set_velocity({
                x = cur_vel.x * 0.93, -- suave, desliza um pouco
                y = cur_vel.y,
                z = cur_vel.z * 0.93,
            })
        end
    end,

    on_rightclick = function(self, clicker)
        if not clicker or not clicker:is_player() then return end

        if self.driver == nil then
            self.driver = clicker

            -- Salva as propriedades originais do player
            self._driver_visual_size = clicker:get_properties().visual_size

            -- Contra-escala: 1 / 2.5 = 0.4
            -- Assim o player aparece no tamanho normal mesmo dentro da entidade escalonada
            clicker:set_properties({
                visual_size = {
                    x = 1 / 2.5,
                    y = 1 / 2.5,
                    z = 1 / 2.5,
                }
            })

            clicker:set_attach(self.object, "", { x = 0, y = 3, z = 0 }, { x = 0, y = 0, z = 0 })
        elseif self.driver == clicker then
            clicker:set_detach()
            self.driver = nil

            -- Restaura as propriedades originais
            if self._driver_visual_size then
                clicker:set_properties({
                    visual_size = self._driver_visual_size
                })
                self._driver_visual_size = nil
            end
        end
    end,

    on_death = function(self)
        if self.driver then
            self.driver:set_detach()
            if self._driver_visual_size then
                self.driver:set_properties({ visual_size = self._driver_visual_size })
                self._driver_visual_size = nil
            end
            self.driver = nil
        end
        local pos = self.object:get_pos()
        if pos then
            core.add_item(pos, "nh_nodes:pineraft")
        end
    end,
})

---------------------------
-- NODE DA JANGADA PRIMITIVA
---------------------------
core.register_node("nh_nodes:pineraft", {
    description = S("Pine Raft"),
    drawtype = "mesh",
    mesh = "pineraft.obj",      --
    tiles = { "pineraft.png" }, -- tiles = {"pedra.png"},
    inventory_image = "pineraft_inv.png",

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        oddly_breakable_by_hand = 1,
        --falling_node = 1,
    },


    collision_box = {
        type = "fixed",
        fixed = { -1, -0.5, -1.5, 1, 0.5, 1.5 },
    },

    selection_box = {
        type = "fixed",
        fixed = { -1, -0.5, -1.5, 1, 0.5, 1.5 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -2, y = -2, z = 1.8 },
        rot = { x = 90, y = 0, z = -90 },
    },
    --wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 0, y = -1, z = -0.5 },
        rot = { x = 90, y = 0, z = 90 },
    },

    pointabilities = {
        nodes = {
            ["nh_nodes:water"]          = true,
            ["nh_nodes:water_flowing"]  = true,
            ["nh_nodes:water2"]         = true,
            ["nh_nodes:water2_flowing"] = true,
        }
    },

    -- Quando o nó é colocado, verifica se está na água
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        -- Se segurou agachar, deixa como nó estático (não vira entidade)
        if placer and placer:is_player() then
            local ctrl = placer:get_player_control()
            if ctrl.sneak then
                return -- coloca normalmente como nó, não faz nada
            end
        end
        -- Sem agachar: vira entidade normalmente
        core.remove_node(pos)
        core.add_entity(pos, "nh_nodes:pineraft_entity")
    end,

    -- Cobre o caso de água chegar até o nó depois que ele já está parado
    on_flood = function(pos, oldnode, newnode)
        core.add_entity(pos, "nh_nodes:pineraft_entity")
        return false
    end,
})

---------------------------
-- NODE DA ESPADA DE OBSIDIANA
---------------------------
core.register_node("nh_nodes:obsidiansword", {
    description = S("Obsidian Sword") .. "\n" .. S("Reach: +3") .. "\n" .. S("Damage: +6") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "obsidiansword.obj",      --
    tiles = { "obsidiansword.png" }, -- tiles = {"pedra.png"},
    --inventory_image = "seixo.png",
    --wield_image = "seixo.png",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        --fleshy = 1, -- mobs, carne
        --snappy  = 2, -- folhas, plantas
        --crumbly = 3, -- terra, areia, argila
        oddly_breakable_by_hand = 3,
        falling_node = 1,
    },

    range = 6, -- AUMENTA O ALCANCE

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 7 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,


    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.5, 0.125, -0.435, 1.35 },
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.5, 0.125, -0.435, 1.35 },
    },
    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 3, y = 0, z = 1.8 },
        rot = { x = 90, y = 0, z = -90 },
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})

-- NODE DO SEIXO NO CHÃO
core.register_node("nh_nodes:pebble", {
    description = S("Pebble") .. "\n" .. S("Damage: +1"),
    drawtype = "mesh",
    mesh = "pebble.obj",     --
    tiles = { "seixo.png" }, -- tiles = {"pedra.png"},
    --inventory_image = "seixo.png",
    --wield_image = "seixo.png",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        oddly_breakable_by_hand = 3,
        falling_node = 1,
        attached_node = 1,
    },

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    drop = "nh_nodes:pebble_item",

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },
})


---------------------------
-- NODE DA PEDRA LASCADA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:chippedstone", {
    description = S("Chipped Stone") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "pedralascada.obj",
    tiles = { "pedralascada.png" },             -- Ícone 2D no inventário
    inventory_image = "inv_stoneknifehead.png", -- Ícone 2D no inventário
    --wield_image = "pedralascada.png",       -- Ou deixe vazio para não mostrar nada na mão
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})


---------------------------
-- NODE DA CABEÇA DE MACHADO DE PEDRA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:stoneaxehead", {
    description = S("Stone Axe Head") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stoneaxehead.obj",
    tiles = { "pedralascada.png" },       -- Ícone 2D no inventário
    inventory_image = "pedralascada.png", -- Ícone 2D no inventário
    --wield_image = "pedralascada.png",       -- Ou deixe vazio para não mostrar nada na mão
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})


---------------------------
-- NODE DA CABEÇA DE PICARETA DE PEDRA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:stonepickaxehead", {
    description = S("Stone Pickaxe Head") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stonepickaxehead.obj",
    tiles = { "pedralascada.png" },               -- Ícone 2D no inventário
    inventory_image = "inv_stonepickaxehead.png", -- Ícone 2D no inventário
    --wield_image = "pedralascada.png",       -- Ou deixe vazio para não mostrar nada na mão
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})


---------------------------
-- NODE DA CABEÇA DE PICARETA DE PEDRA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:stonehoehead", {
    description = S("Stone Pickaxe Head") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stonehoehead.obj",
    tiles = { "pedralascada.png" },           -- Ícone 2D no inventário
    inventory_image = "inv_stonehoehead.png", -- Ícone 2D no inventário
    --wield_image = "pedralascada.png",       -- Ou deixe vazio para não mostrar nada na mão
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})


---------------------------
-- NODE DA CABEÇA DE PICARETA DE PEDRA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:stoneadzehead", {
    description = S("Stone Adze Head") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stoneadzehead.obj",
    tiles = { "pedralascada.png" },            -- Ícone 2D no inventário
    inventory_image = "inv_stoneadzehead.png", -- Ícone 2D no inventário
    --wield_image = "pedralascada.png",       -- Ou deixe vazio para não mostrar nada na mão
    --wield_scale = {x = 0.5, y = 0.5, z = 0.5},
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.095, 0.125, -0.435, 0.095 },
    },

    -----------------------------
    -- FAZ O SEIXO CAIR SOZINHO
    -----------------------------
    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,
})



---------------------------
-- NODE DA ESPADA ENFERRUJADA (FERRAMENTA)
---------------------------
core.register_node("nh_nodes:rustironsword", {
    description = S("Rusty Iron Sword") .. "\n" .. S("Reach: +3") .. "\n" .. S("Damage: +4") .. "\n" .. S("Uses: 10"),
    drawtype = "mesh",
    mesh = "rustsword.obj",
    tiles = { "rustsword.png" },
    paramtype = "light",
    use_texture_alpha = "clip",
    backface_culling = false,
    sunlight_propagates = true,
    walkable = false,

    range = 6, -- AUMENTA O ALCANCE

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 5 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 6552 -- ~10 usos (65535 / 10)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 6552
        itemstack:set_wear(wear)
        return itemstack
    end,

    --drop = "nh_items:rustironsword",

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.05, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.03, -0.5, -0.115, 0.03, 0.5, 0.115 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.3, y = 0, z = 0 },
        rot = { x = 270, y = -90, z = 0 },
    },
    wielded_visual_size = { x = 0.325, y = 0.325, z = 0.325 },
})


core.register_node("nh_nodes:stoneaxe", {
    description = S("Stone Axe") .. "\n" .. S("Reach: +2") .. "\n" .. S("Damage: +3") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stoneaxe.obj",
    tiles = { "stoneaxe.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 5,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 2,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 20, [2] = 15, [3] = 10.00 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.50, [2] = 1.10, [3] = 0.70 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 4 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.25, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.25, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})


core.register_node("nh_nodes:stonepickaxe", {
    description = S("Stone Pickaxe") .. "\n" .. S("Reach: +2") .. "\n" .. S("Damage: +3") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stonepickaxe.obj",
    tiles = { "stonepickaxe.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 5,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        --fleshy = 1, -- mobs, carne
        --snappy  = 2, -- folhas, plantas
        --crumbly = 3, -- terra, areia, argila
        --oddly_breakable_by_hand = 3,
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 2,
        max_drop_level = 1,

        groupcaps = {
            crumbly = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
            cracky = { times = { [1] = 20, [2] = 15, [3] = 10 }, uses = 10, maxlevel = 1 },
            choppy = { times = { [1] = 30, [2] = 25, [3] = 20 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 4 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.25, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.25, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})

core.register_node("nh_nodes:stoneadze", {
    description = S("Stone Adze") .. "\n" .. S("Reach: +2") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stoneadze.obj",
    tiles = { "stoneadze.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 5,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 2,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 20, [2] = 15, [3] = 10.00 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.50, [2] = 1.10, [3] = 0.70 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- bater em node / transformar em terra arada
    node_placement_prediction = "",

    on_place = function(itemstack, puncher, pointed_thing)
        local controls = puncher:get_player_control()

        if controls.sneak then
            if pointed_thing.type == "node" then
                local pos = pointed_thing.under
                local node = core.get_node(pos)

                -- Mapeamento: tora -> madeira
                local conversions = {
                    ["nh_nodes:oaklog"]  = "nh_nodes:oakwood",
                    ["nh_nodes:pinelog"] = "nh_nodes:pinewood",
                }

                local result = conversions[node.name]
                if result then
                    core.set_node(pos, { name = result })
                    local wear = itemstack:get_wear()
                    itemstack:set_wear(wear + 4369)
                end
            end
            return itemstack
        else
            return core.item_place(itemstack, puncher, pointed_thing)
        end
    end,

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.25, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.25, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})

core.register_node("nh_nodes:stonehoe", {
    description = S("Stone Hoe") .. "\n" .. S("Reach: +2") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "stonehoe.obj",
    tiles = { "stonehoe.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 5,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        dig_immediate = 1,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 2,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 20, [2] = 15, [3] = 10.00 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.50, [2] = 1.10, [3] = 0.70 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- bater em node / transformar em terra arada
    node_placement_prediction = "",

    on_place = function(itemstack, puncher, pointed_thing)
        local controls = puncher:get_player_control()

        if controls.sneak then
            if pointed_thing.type == "node" then
                local pos = pointed_thing.under
                local node = core.get_node(pos)
                local convertible = {
                    ["nh_nodes:dirt"]      = true,
                    ["nh_nodes:grass"]     = true,
                    ["nh_nodes:top_grass"] = true,
                }
                if convertible[node.name] then
                    core.set_node(pos, { name = "nh_nodes:tilleddirt" })
                    local wear = itemstack:get_wear()
                    wear = wear + 4369
                    itemstack:set_wear(wear)
                end
            end
            return itemstack -- Sempre cancela o place quando agachado
        else
            return core.item_place(itemstack, puncher, pointed_thing)
        end
    end,

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    --after_punch = function(itemstack, user, target)
    --    local wear = itemstack:get_wear()
    --     wear = wear + 4369
    --     itemstack:set_wear(wear)
    --     return itemstack
    --end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.25, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.25, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    wielded_visual_size = { x = 0.25, y = 0.25, z = 0.25 },
})


---------------------------
-- NODE DA PEDRA LASCADA (FERRAMENTA E ITEM DE FERRAMENTA)
---------------------------
core.register_node("nh_nodes:chippedstoneknife", {
    description = S("Chipped Stone Knife") .. "\n" .. S("Reach: +1") .. "\n" .. S("Damage: +2") .. "\n" .. S("Uses: 15"),
    drawtype = "mesh",
    mesh = "chippedstoneknife.obj",
    tiles = { "chippedstoneknife.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 4,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        --fleshy = 1, -- mobs, carne
        --snappy  = 2, -- folhas, plantas
        --crumbly = 3, -- terra, areia, argila
        oddly_breakable_by_hand = 3,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 3 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 4369 -- ~15 usos (65535 / 15)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.05, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.05, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})


core.register_node("nh_nodes:obsidianknife", {
    description = S("Obsidian Knife") .. "\n" .. S("Reach: +1") .. "\n" .. S("Damage: +4") .. "\n" .. S("Uses: 10"),
    drawtype = "mesh",
    mesh = "obsidianknife.obj",
    tiles = { "obsidianknife.png" },
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,

    range = 4,

    -- falling_node faz ele cair,
    -- attached_node previne ficar flutuando encostado
    groups = {
        --fleshy = 1, -- mobs, carne
        --snappy  = 2, -- folhas, plantas
        --crumbly = 3, -- terra, areia, argila
        oddly_breakable_by_hand = 3,
        falling_node = 1,
    },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            snappy = { times = { [1] = 1.20, [2] = 0.80, [3] = 0.40 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 5 },
    },

    -- cavar node
    after_use = function(itemstack, user, node, digparams)
        local wear = itemstack:get_wear()
        wear = wear + 6552 -- ~10 usos (65535 / 10)
        itemstack:set_wear(wear)
        return itemstack
    end,

    -- bater em mob
    after_punch = function(itemstack, user, target)
        local wear = itemstack:get_wear()
        wear = wear + 4369
        itemstack:set_wear(wear)
        return itemstack
    end,

    collision_box = {
        type = "fixed",
        fixed = {
            { -0.08, -0.5, -0.035, 0.08, 0.05, 0.035 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.075, -0.5, -0.03, 0.075, 0.05, 0.03 },
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 1.1, y = 0, z = 0.1 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},
})


---------------------------
-- FUNÇÃO DE ARREMESSO (SEIXO branco)
---------------------------
local function throw_white_pebble(itemstack, user)
    local pos = user:get_pos()
    local dir = user:get_look_dir()
    pos.y = pos.y + 2.25
    local obj = core.add_entity(pos, "nh_nodes:white_pebble_entity")
    if obj then
        obj:set_velocity(vector.multiply(dir, 13))
        obj:set_acceleration({ x = 0, y = -9.81, z = 0 })
        local ent = obj:get_luaentity()
        if ent then
            ent._shooter = user
        end
    end
    itemstack:take_item()
    return itemstack
end

---------------------------
-- ITEM ARREMESSÁVEL (SEIXO branco)
---------------------------
core.register_craftitem("nh_nodes:white_pebble_item", {
    description = S("White Pebble") ..
        "\n" .. S("[Throwable]") .. "\n" .. S("Damage: +1") .. "\n" .. S("(Throw: Q / drop)"),
    inventory_image = "white_seixo_arremessavel.png", -- Use uma textura diferente

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = -0.25, z = 0 },
        rot = { x = 0, y = 0, z = 0 },
    },
    wielded_visual_size = { x = 0.15, y = 0.15, z = 0.15 },

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },

    on_place = function(itemstack, placer, pointed_thing)
        return throw_white_pebble(itemstack, placer)
    end,

    on_drop = function(itemstack, dropper, pos)
        return throw_white_pebble(itemstack, dropper)
    end,
})

---------------------------
-- ENTIDADE DO PROJÉTIL (SEIXO branco)
---------------------------
core.register_entity("nh_nodes:white_pebble_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.1, 0.1 },
        visual = "wielditem",
        visual_size = { x = 0.2, y = 0.2 },
        textures = { "nh_nodes:white_pebble" },
    },

    _stuck = false,
    _timer = 0,
    _stuck_timer = 0,
    _last_pos = nil,
    _shooter = nil, -- ✅ Declarado aqui para ficar visível

    on_activate = function(self, staticdata)
        self._timer = 0
        self._stuck = false
        self._stuck_timer = 0
        self._shooter = nil
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
                local node = core.get_node(node_pos)

                if node.name == "air" or not core.registered_nodes[node.name].walkable then
                    core.set_node(node_pos, { name = "nh_nodes:white_pebble" })
                else
                    local offsets = {
                        { x = 0,  y = 1,  z = 0 },
                        { x = 0,  y = -1, z = 0 },
                        { x = 1,  y = 0,  z = 0 },
                        { x = -1, y = 0,  z = 0 },
                        { x = 0,  y = 0,  z = 1 },
                        { x = 0,  y = 0,  z = -1 },
                    }

                    local placed = false
                    for _, offset in ipairs(offsets) do
                        local try_pos = vector.add(node_pos, offset)
                        local try_node = core.get_node(try_pos)
                        if try_node.name == "air" then
                            core.set_node(try_pos, { name = "nh_nodes:white_pebble" })
                            placed = true
                            break
                        end
                    end

                    if not placed then
                        core.add_item(pos, "nh_nodes:white_pebble_item")
                    end
                end

                self.object:remove()
            end
            return
        end

        local vel = self.object:get_velocity()
        if not vel then
            self.object:remove()
            return
        end

        local speed = vector.length(vel)

        -- Se a velocidade é muito baixa (parou de se mover)
        if speed < 0.5 then
            self._stuck = true
            self.object:set_velocity({ x = 0, y = 0, z = 0 })
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
            return
        end

        -- Verifica colisão com blocos sólidos via raycast manual
        local step_dir = vector.normalize(vel)
        local check_distance = math.min(speed * dtime * 2, 1)
        local steps = math.ceil(check_distance / 0.2)

        for i = 1, steps do
            local check_pos = vector.add(pos, vector.multiply(step_dir, i * 0.2))
            local node = core.get_node(check_pos)

            if node and node.name and core.registered_nodes[node.name] then
                if core.registered_nodes[node.name].walkable then
                    self._stuck = true
                    self.object:set_pos(check_pos)
                    self.object:set_velocity({ x = 0, y = 0, z = 0 })
                    self.object:set_acceleration({ x = 0, y = 0, z = 0 })
                    return
                end
                if node.name == "nh_nodes:coconutlinked" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:coconut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_nut3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:nut", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple" })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple2" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 2 })
                    update_neighbors(check_pos)
                    return
                end
                if node.name == "nh_nodes:leaves_apple3" then
                    core.sound_play("default_dig_cracky", { pos = check_pos, gain = 0.5 })
                    core.set_node(check_pos, { name = "nh_nodes:fallenstick" })
                    core.add_item(check_pos, { name = "nh_nodes:apple", count = 3 })
                    update_neighbors(check_pos)
                    return
                end
            end
        end

        -- ✅ Raio aumentado de 0.6 para 1.2 para não passar pelo mob
        local objs = core.get_objects_inside_radius(pos, 1.2)
        for _, obj in ipairs(objs) do
            -- Ignora o próprio projétil e o atirador
            if obj ~= self.object and obj ~= self._shooter then
                local is_target = obj:is_player()

                if not is_target then
                    local ent = obj:get_luaentity()
                    -- ✅ Usa get_hp() no lugar de ent.hp_max, compatível com MobsRedo
                    if ent and ent.name ~= "nh_nodes:white_pebble_entity" then
                        local hp = obj:get_hp()
                        if hp and hp > 0 then
                            is_target = true
                        end
                    end
                end

                if is_target then
                    core.log("action", "[Seixo Branco] Acertou alvo em " .. core.pos_to_string(pos))

                    core.sound_play("default_dig_cracky", { pos = pos, gain = 0.5 })

                    obj:punch(self.object, 1.0, {
                        full_punch_interval = 1.0,
                        damage_groups = { fleshy = 2 },
                    }, vel)

                    core.add_item(pos, "nh_nodes:white_pebble_item")
                    self.object:remove()
                    return
                end
            end
        end

        self._last_pos = pos
    end,
})

---------------------------
-- ENTIDADE DA CHAMA
---------------------------
core.register_entity("nh_nodes:flame_entity", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        selectionbox = { -0.5, 0, -0.5, 0.5, 1.5, 0.5 },
        collisionbox = { -0.5, 0, -0.5, 0.5, 1.5, 0.5 },
        visual = "mesh",
        mesh = "flame.obj",
        textures = { "fire_basic_flame_animated.png" },
        visual_size = { x = 5, y = 5 },
        static_save = true,
        pointable = true,
        glow = 14, -- Emite luz
    },

    _grass_pos = nil,
    _timer = 0,
    _anim_timer = 0,
    _current_frame = 0,

    on_activate = function(self, staticdata)
        if staticdata ~= "" then
            local data = core.deserialize(staticdata)
            if data and data.grass_pos then
                self._grass_pos = data.grass_pos
            end
        end
        self._timer = 0

        -- Configura a animação da textura
        self.object:set_sprite(
            { x = 0, y = 0 }, -- Posição inicial
            1,                -- Número de frames (colunas)
            1.0,              -- Duração do frame
            false             -- Não usar alpha
        )

        -- Define a animação de textura
        self.object:set_texture_mod("^[verticalframe:8:0")
    end,

    get_staticdata = function(self)
        return core.serialize({ grass_pos = self._grass_pos })
    end,

    -- NOVO: Detecta quando é golpeado
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()

        -- Verifica se está segurando uma tocha apagada
        if wielded_name == "nh_nodes:torch" then
            -- Remove a tocha apagada do inventário
            wielded:take_item()
            puncher:set_wielded_item(wielded)

            -- Adiciona a tocha acesa ao inventário
            local inv = puncher:get_inventory()
            if inv then
                local leftover = inv:add_item("main", "nh_nodes:torch2")
                -- Se o inventário estiver cheio, dropa no chão
                if not leftover:is_empty() then
                    local pos = puncher:get_pos()
                    core.add_item(pos, leftover)
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = self.object:get_pos(),
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    on_step = function(self, dtime)
        self._timer = self._timer + dtime
        self._anim_timer = self._anim_timer + dtime

        -- Anima a textura (16 frames, 1 segundo de duração total)
        if self._anim_timer > (1.0 / 8) then
            self._anim_timer = 0
            self._current_frame = (self._current_frame + 1) % 8
            self.object:set_texture_mod("^[verticalframe:8:" .. self._current_frame)
        end

        -- Verifica a cada 0.5 segundo se a grama ainda existe
        if self._timer > 0.5 then
            self._timer = 0

            if not self._grass_pos then
                self.object:remove()
                return
            end

            local node = core.get_node(self._grass_pos)

            -- Se a grama foi removida, remove a chama
            if node.name ~= "nh_nodes:grassleaves" then
                self.object:remove()
                return
            end
        end
    end,
})


---------------------------
-- NODE DO SEIXO BRANCO NO CHÃO
---------------------------
core.register_node("nh_nodes:white_pebble", {
    description = S("White Pebble"),
    tiles = { "whitepebble.png" },
    inventory_image = "seixo_branco.png",
    wield_image = "seixo_branco.png",
    drawtype = "nodebox",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    groups = {
        snappy = 3,
        oddly_breakable_by_hand = 3,
        falling_node = 1,
        attached_node = 1,
    },
    node_box = {
        type = "fixed",
        fixed = {
            { -0.15, -0.5, -0.2, 0.15, -0.4, 0.15 },
        },
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.15, -0.5, -0.2, 0.15, -0.4, 0.15 },
    },
    drop = "nh_nodes:white_pebble_item",

    tool_capabilities = {
        full_punch_interval = 1.5,
        max_drop_level = 1,

        groupcaps = {
            choppy = { times = { [1] = 25, [2] = 20, [3] = 15 }, uses = 10, maxlevel = 1 },
            fleshy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            snappy = { times = { [1] = 1.30, [2] = 0.90, [3] = 0.50 }, uses = 10, maxlevel = 1 },
            crumbly = { times = { [1] = 1.40, [2] = 1.00, [3] = 0.60 }, uses = 10, maxlevel = 1 },
        },

        damage_groups = { fleshy = 2 },
    },

    on_construct = function(pos)
        core.check_for_falling(pos)
    end,

    after_place_node = function(pos)
        core.check_for_falling(pos)
    end,

    -- Quando bater em um seixo branco com outro seixo branco
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher then return end

        -- Verifica se está batendo com outro seixo branco
        local wielded = puncher:get_wielded_item()
        if wielded:get_name() ~= "nh_nodes:white_pebble_item" then
            return
        end

        -- Som de fricção/faísca
        core.sound_play("default_dig_cracky", {
            pos = pos,
            gain = 0.7,
        })

        -- PARTÍCULAS AMARELAS LUMINOSAS (FAÍSCAS)
        core.add_particlespawner({
            amount = 10, -- Quantidade de partículas
            time = 0.3,  -- Duração do spawn
            minpos = vector.subtract(pos, { x = 0.2, y = 0.2, z = 0.2 }),
            maxpos = vector.add(pos, { x = 0.2, y = 0.2, z = 0.2 }),
            minvel = { x = -2, y = 1, z = -2 }, -- Velocidade mínima
            maxvel = { x = 2, y = 4, z = 2 },   -- Velocidade máxima (para cima)
            minacc = { x = 0, y = -3, z = 0 },  -- Aceleração (gravidade)
            maxacc = { x = 0, y = -2, z = 0 },
            minexptime = 0.1,                   -- Tempo mínimo de vida
            maxexptime = 0.3,                   -- Tempo máximo de vida
            minsize = 0.1,                      -- Tamanho mínimo
            maxsize = 0.3,                      -- Tamanho máximo
            collisiondetection = true,
            collision_removal = false,
            glow = 14,                                             -- Brilho máximo (importante para o efeito luminoso)
            texture = {
                name = "spark_particle.png^[colorize:#FFAA00:150", -- Dourado
                -- Se não tiver a textura spark_particle.png, use:
                -- name = "default_item_smoke.png^[colorize:#FFFF00:200",
            },
        })

        -- Verifica todas as direções adjacentes para acender grama
        local directions = {
            { x = 1,  y = 0,  z = 0 },  -- Leste
            { x = -1, y = 0,  z = 0 },  -- Oeste
            { x = 0,  y = 1,  z = 0 },  -- Cima
            { x = 0,  y = -1, z = 0 },  -- Baixo
            { x = 0,  y = 0,  z = 1 },  -- Sul
            { x = 0,  y = 0,  z = -1 }, -- Norte
            { x = 0,  y = 1,  z = 1 },
            { x = 0,  y = -1, z = -1 },
            { x = 1,  y = 0,  z = 1 },
            { x = -1, y = 0,  z = -1 },
            { x = -1, y = 0,  z = 1 },
            { x = 1,  y = 0,  z = -1 },
        }

        for _, dir in ipairs(directions) do
            local check_pos = vector.add(pos, dir)
            local check_node = core.get_node(check_pos)

            -- ACENDE GRAMA
            if check_node.name == "nh_nodes:grassleaves" then
                local has_flame = false
                local objs = core.get_objects_inside_radius(check_pos, 0.5)
                for _, obj in ipairs(objs) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "nh_nodes:flame_entity" then
                        has_flame = true
                        break
                    end
                end

                if not has_flame then
                    local flame_pos = {
                        x = check_pos.x,
                        y = check_pos.y,
                        z = check_pos.z
                    }

                    local obj = core.add_entity(flame_pos, "nh_nodes:flame_entity")
                    if obj then
                        local ent = obj:get_luaentity()
                        if ent then
                            ent._grass_pos = check_pos
                        end
                    end
                end
            end

            -- ACENDE PALHA
            if check_node.name == "nh_nodes:palmstraw" then
                local meta = core.get_meta(check_pos)

                -- Se a palha já tem chama, não faz nada
                if meta:get_int("has_flame") == 1 then
                    goto continue
                end

                -- Verifica se já não tem uma chama nessa posição
                local has_flame = false
                local objs = core.get_objects_inside_radius(check_pos, 0.5)
                for _, obj in ipairs(objs) do
                    local ent = obj:get_luaentity()
                    if ent and ent.name == "nh_nodes:palmstraw_flame_entity" then
                        has_flame = true
                        break
                    end
                end

                if not has_flame then
                    -- Marca que tem chama
                    meta:set_int("has_flame", 1)

                    -- Cria a entidade da chama
                    local obj = core.add_entity(check_pos, "nh_nodes:palmstraw_flame_entity")
                    if obj then
                        local ent = obj:get_luaentity()
                        if ent then
                            ent._straw_pos = check_pos
                        end
                    end

                    -- Efeito sonoro (opcional)
                    core.sound_play("fire_flint_and_steel", {
                        pos = check_pos,
                        gain = 0.5,
                        max_hear_distance = 8,
                    }, true)
                end
            end

            ::continue::
        end
    end,
})

-- FUNÇÃO DE ARREMESSO
local function throw_grenade(itemstack, placer, lit)
    if not placer or not placer:is_player() then
        return itemstack
    end
    detach_glow(placer)

    local pos = placer:get_pos()
    pos.y = pos.y + 1.5

    local dir = placer:get_look_dir()

    local entity_name = lit and "nh_nodes:litgrenade_entity" or "nh_nodes:grenade_entity"

    local obj = core.add_entity(pos, entity_name)

    if obj then
        obj:set_velocity(vector.multiply(dir, 14))
        obj:set_acceleration({ x = 0, y = -10, z = 0 })
        local ent = obj:get_luaentity()
        if ent then
            ent._shooter = placer
        end
    end

    itemstack:take_item(1)
    return itemstack
end

core.register_node("nh_nodes:grenade", {
    description = S("Grenade"),
    drawtype = "mesh",
    mesh = "grenade.obj",
    tiles = { "fusegrenade.png" },

    walkable = false,
    paramtype = "light",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, falling_node = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    on_place = function(itemstack, placer, pointed_thing)
        return throw_grenade(itemstack, placer, false)
    end,
    on_drop = function(itemstack, dropper, pos)
        return throw_grenade(itemstack, dropper, false)
    end,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type == "object" then
            local ent = pointed_thing.ref:get_luaentity()
            if ent and FLAME_ENTITIES[ent.name] then
                itemstack:set_name("nh_nodes:litgrenade")
                attach_glow(user)
                return itemstack
            end
        end
    end,
})

core.register_entity("nh_nodes:grenade_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        pointable = true,
        static_save = false,

        visual = "mesh",
        mesh = "grenade.obj",
        textures = { "fusegrenade.png" },

        visual_size = { x = 10, y = 10 },

        collisionbox = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 },
    },

    _timer = 0,
    _shooter = nil,

    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then return end

        self._timer = self._timer + dtime

        -- rotação
        local rot = self.object:get_rotation()
        self.object:set_rotation({
            x = rot.x + 0.003,
            y = rot.y + 0.2,
            z = rot.z,
        })

        local vel = self.object:get_velocity()

        -- se praticamente parou OU timer expirou, vira node
        if vector.length(vel) < 0.2 or self._timer >= 5 then
            local place_pos = vector.round({
                x = pos.x,
                y = pos.y - 0.1,
                z = pos.z
            })

            local node = core.get_node(place_pos)

            if DECORATIONS[node.name] or node.name == "air" then
                -- substitui a decoração pela granada
                core.set_node(place_pos, { name = "nh_nodes:grenade" })
            else
                -- node sólido abaixo: coloca no air acima
                local above_pos = vector.round({
                    x = pos.x,
                    y = pos.y + 0.9,
                    z = pos.z
                })
                local above_node = core.get_node(above_pos)
                if above_node.name == "air" then
                    core.set_node(above_pos, { name = "nh_nodes:grenade" })
                end
            end

            self.object:remove()
            return
        end
    end
})

core.register_node("nh_nodes:litgrenade", {
    description = S("Lit Grenade"),
    drawtype = "mesh",
    mesh = "grenade.obj",
    tiles = { "litgrenade.png" },

    walkable = false,
    paramtype = "light",
    groups = { snappy = 3, oddly_breakable_by_hand = 1, falling_node = 1 },

    collision_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    selection_box = {
        type = "fixed",
        fixed = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 }
    },
    on_place = function(itemstack, placer, pointed_thing)
        return throw_grenade(itemstack, placer, true)
    end,
    on_drop = function(itemstack, dropper, pos)
        return throw_grenade(itemstack, dropper, true)
    end,
})

core.register_entity("nh_nodes:litgrenade_entity", {
    initial_properties = {
        physical = true,
        collide_with_objects = true,
        pointable = true,
        static_save = false,

        visual = "mesh",
        mesh = "grenade.obj",
        textures = { "litgrenade.png" },

        glow = 8,

        visual_size = { x = 10, y = 10 },

        collisionbox = { -0.125, -0.5, -0.125, 0.125, -0.25, 0.125 },
    },

    _timer = 0,
    _shooter = nil,

    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then return end

        self._timer = self._timer + dtime

        local rot = self.object:get_rotation()
        self.object:set_rotation({
            x = rot.x + 0.003,
            y = rot.y + 0.2,
            z = rot.z,
        })

        -- explode após 5 segundos
        if self._timer >= 5 then
            core.sound_play("tnt_explode", {
                pos = pos,
                gain = 1.0,
                max_hear_distance = 32,
            })

            core.add_particlespawner({
                amount = 50,
                time = 0.3,
                glow = 14,

                minpos = vector.subtract(pos, 0.5),
                maxpos = vector.add(pos, 0.5),

                minvel = { x = -4, y = -4, z = -4 },
                maxvel = { x = 4, y = 4, z = 4 },

                minexptime = 0.5,
                maxexptime = 1.5,

                minsize = 0.5,
                maxsize = 1,

                texture = "spark_particle.png^[colorize:#FF8800:150",
            })

            -- dano em área
            for _, obj in ipairs(core.get_objects_inside_radius(pos, 4)) do
                if obj ~= self.object then
                    obj:punch(self.object, 1.0, {
                        damage_groups = { fleshy = 12 },
                    })
                end
            end

            -- transforma neve em avalanche
            local radius = 4

            for x = -radius, radius do
                for y = -radius, radius do
                    for z = -radius, radius do
                        local p = {
                            x = pos.x + x,
                            y = pos.y + y,
                            z = pos.z + z
                        }

                        if vector.distance(pos, p) <= radius then
                            local node = core.get_node(p)

                            if node.name == "nh_nodes:snow_ramp"
                                or node.name == "nh_nodes:snow_insidecorner"
                                or node.name == "nh_nodes:snow_corner" then
                                core.set_node(p, {
                                    name = "nh_nodes:avalanche"
                                })
                            end
                        end
                    end
                end
            end

            self.object:remove()
            return
        end

        -- colisão com parede/chão
        local node = core.get_node(vector.round(pos))

        if core.registered_nodes[node.name]
            and core.registered_nodes[node.name].walkable then
            self.object:set_velocity({ x = 0, y = 0, z = 0 })
            self.object:set_acceleration({ x = 0, y = 0, z = 0 })
        end
    end,
})

-- NODE DAS FOLHAS DE GRAMA
core.register_node("nh_nodes:grassleaves", {
    --drawtype = "mesh",
    --mesh = "grassleaves.obj",
    --tiles = {"grassleaves.png"},
    description = S("Grass Leaves") .. "\n" .. S("[Small]"),
    drawtype = "plantlike",
    tiles = { "grassleavesbasic.png" },

    waving = 1,

    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },

    -- Quando a palha é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._grass_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a grama for removida, remove as chamas nela
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:flame_entity" then
                obj:remove()
            end
        end
    end,
})


---------------------------
-- NODE DAS FOLHAS DE GRAMA
---------------------------
core.register_node("nh_nodes:grassleavesmedium", {
    description = S("Grass Leaves") .. "\n" .. S("[Medium]"),
    --drawtype = "mesh",
    --mesh = "grassleavesmedium.obj",
    --tiles = {"grama.png"},
    drawtype = "plantlike",
    tiles = { "grassleavesbasic2.png" },

    waving = 1,
    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },

    -- Quando a palha é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._grass_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a grama for removida, remove as chamas nela
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:flame_entity" then
                obj:remove()
            end
        end
    end,
})

---------------------------
-- NODE DAS FOLHAS DE GRAMA
---------------------------
core.register_node("nh_nodes:smallgrass", {
    description = S("Short Grass"),
    drawtype = "mesh",
    mesh = "smallgrass.obj",
    tiles = { "highgrass.png" },
    --drawtype = "plantlike",
    --tiles = {"grassleavesbasic2.png"},

    waving = 1,
    use_texture_alpha = "clip",
    paramtype = "light",
    walkable = false,
    --buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 }
    },

    -- Quando a palha é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._grass_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a grama for removida, remove as chamas nela
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:flame_entity" then
                obj:remove()
            end
        end
    end,
})

core.register_node("nh_nodes:highgrass", {
    description = S("Tall Grass"),
    drawtype = "mesh",
    mesh = "highgrass.obj",
    tiles = { "highgrass.png" },
    --drawtype = "plantlike",
    --tiles = {"grassleavesbasic2.png"},

    waving = 1,
    use_texture_alpha = "clip",
    paramtype = "light",
    walkable = false,
    --buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 1.5, 0.5 }
    },

    -- Quando a palha é atingida com tocha
    on_punch = function(pos, node, puncher, pointed_thing)
        if not puncher or not puncher:is_player() then
            return
        end

        local wielded = puncher:get_wielded_item()
        local wielded_name = wielded:get_name()
        local meta = core.get_meta(pos)

        -- Se já tem chama, não faz nada
        if meta:get_int("has_flame") == 1 then
            return
        end

        -- Verifica se está segurando uma tocha acesa
        if wielded_name == "nh_nodes:torch2" or wielded_name == "nh_nodes:flame" then
            -- Marca que tem chama
            meta:set_int("has_flame", 1)

            -- Cria a entidade da chama
            local obj = core.add_entity(pos, "nh_nodes:flame_entity")
            if obj then
                local ent = obj:get_luaentity()
                if ent then
                    ent._grass_pos = pos
                end
            end

            -- Efeito sonoro (opcional)
            core.sound_play("fire_flint_and_steel", {
                pos = pos,
                gain = 0.5,
                max_hear_distance = 8,
            }, true)
        end
    end,

    -- Quando a grama for removida, remove as chamas nela
    after_dig_node = function(pos, oldnode, oldmetadata, digger)
        local objs = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objs) do
            local ent = obj:get_luaentity()
            if ent and ent.name == "nh_nodes:flame_entity" then
                obj:remove()
            end
        end
    end,
})

---------------------------
-- NODE DAS FLORES DE DENTE DE LEAO
---------------------------
core.register_node("nh_nodes:dandelion", {
    description = S("Dandelion"),
    drawtype = "mesh",
    mesh = "dandelion.obj",
    tiles = { "dandelion.png" },

    --waving = 1,

    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },

})


---------------------------
-- NODE DE JUNCO
---------------------------
core.register_node("nh_nodes:rush", {
    description = S("Rush"),
    drawtype = "plantlike",
    tiles = { "rushplant.png" },

    waving = 1,

    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },

})

---------------------------
-- NODE DO COGUMELO MICACEUS
---------------------------
core.register_node("nh_nodes:micaceusfungus", {
    description = S("Micaceus Fungus"),
    drawtype = "mesh",
    mesh = "micaceusfungus.obj",
    tiles = { "micaceusfungus.png" },

    --waving = 1,

    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },

    -- Tornar não comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, -2)               -- retira 2 pontos de fome
        apply_poison_damage(user, 0.5, 1, 1.0) -- 0.5 de dano a cada 1 segundo = 4 ticks para completar 2 pontos
        itemstack:take_item()
        return itemstack
    end,
})

---------------------------
-- NODE DO COGUMELO AMANITA (VERMELHO)
---------------------------
core.register_node("nh_nodes:flyamanitafungus", {
    description = S("Fly Agaric Fungus"),
    drawtype = "mesh",
    mesh = "flyagaricfungus.obj",
    tiles = { "flyagaricfungus.png" },

    --waving = 1,

    paramtype = "light",
    walkable = false,
    buildable_to = true,
    groups = { snappy = 3, oddly_breakable_by_hand = 1, flammable = 2 },

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 }
    },


    -- Tornar não comestível
    on_use = function(itemstack, user, pointed_thing)
        restore_hunger(user, -4)             -- retira 4 pontos de fome
        apply_poison_damage(user, 1, 2, 1.0) -- 1 ponto de dano a cada 1 segundo = 4 ticks para completar 4 pontos
        itemstack:take_item()
        return itemstack
    end,
})

------------------------------------------------------------
-- EXEMPLO: REGISTRAR ITENS DE VESTUÁRIO (tá como tool por enquanto)
------------------------------------------------------------

-- Cinto
core.register_node("nh_nodes:belt", {
    description = S("Basic Belt"),
    inventory_image = "belt_icon.png",
    --wield_image = "belt_icon2.png",
    drawtype = "mesh",
    mesh = "belt.obj",
    tiles = { "belt_overlay.png" },
    groups = { oddly_breakable_by_hand = 1, armor_waist = 1 },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    node_box = {
        type = "fixed",
        fixed = {
            { -0.28, -0.5, -0.18, 0.28, -0.32, 0.18 },
        },
    },

    selection_box = {
        type = "fixed",
        fixed = { -0.28, -0.5, -0.18, 0.28, -0.32, 0.18 },
    },


    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0, y = 1, z = 0.6 },
        rot = { x = 0, y = 180, z = 0 },
    },
    wielded_visual_size = { x = 0.2, y = 0.2, z = 0.2 },

    offhand_bone_position = {
        pos = { x = 0, y = -0.8, z = -1.6 },
        rot = { x = -90, y = 0, z = 90 },
    },
})

-- Mochila
-- ============================================================
-- BACKCHEST – funciona exatamente como o oakchest
-- ============================================================

-- =============================================================
-- Tabela global: armazena conteúdo de backchests quebrados
-- Chave: ID único (string) gravado no meta do item dropado
-- =============================================================
backchest_stored_items = backchest_stored_items or {}

local function backchest_new_id()
    -- ID baseado em tempo + número aleatório para ser único
    return tostring(os.time()) .. "_" .. tostring(math.random(1, 999999))
end

local function backchest_save_inv(pos)
    local meta  = core.get_meta(pos)
    local inv   = meta:get_inventory()
    local slots = {}
    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        -- Salva todos os slots (vazios como ""), preservando posições exatas
        slots[i] = stack:to_string()
    end
    return slots
end

local function backchest_restore_inv(pos, slots)
    local meta = core.get_meta(pos)
    local inv  = meta:get_inventory()
    for i, item_str in ipairs(slots) do
        inv:set_stack("main", i, ItemStack(item_str))
    end
end

-- Função auxiliar: atualiza itens visuais no backchest aberto


-- Node: backchest aberto (estado intermediário)
core.register_node("nh_nodes:back_chest_open", {
    drawtype         = "mesh",
    mesh             = "backchest_open.obj",
    tiles            = { "BackChest.png" },
    walkable         = true,
    pointable        = true,
    paramtype        = "light",
    paramtype2       = "facedir",

    selection_box    = { type = "fixed", fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } },
    collision_box    = { type = "fixed", fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } },

    groups           = { not_in_creative_inventory = 1 },

    on_rightclick    = function(pos, node, clicker, itemstack, pointed_thing)
        local meta        = core.get_meta(pos)
        local player_name = clicker:get_player_name()
        meta:set_string("current_user", player_name)
        core.show_formspec(player_name,
            "nh_nodes:back_chest_" .. core.pos_to_string(pos),
            build_chest_formspec(clicker))
        return itemstack
    end,

    on_construct     = function(pos)
        core.after(0.1, function() back_chest_update_items(pos) end)
    end,

    after_place_node = function(pos, placer, itemstack, pointed_thing)
        core.after(0.1, function() back_chest_update_items(pos) end)
    end,

    -- Permite quebrar o baú mesmo estando aberto
    can_dig          = function(pos, player)
        return true
    end,

    -- Mesma lógica de salvamento do node fechado
    on_dig           = function(pos, node, digger)
        local meta      = core.get_meta(pos)
        local inv       = meta:get_inventory()
        local has_items = not inv:is_empty("main")

        local chest_id  = meta:get_string("chest_id")
        if chest_id == "" then
            chest_id = backchest_new_id()
        end

        if has_items then
            backchest_stored_items[chest_id] = backchest_save_inv(pos)
        else
            backchest_stored_items[chest_id] = nil
            chest_id = ""
        end

        local drop = ItemStack("nh_nodes:backchest")
        if chest_id ~= "" then
            local drop_meta = drop:get_meta()
            drop_meta:set_string("chest_id", chest_id)
            drop_meta:set_string("description",
                S("Backpack Chest") .. "\n" .. S("(contains items)"))
        end

        core.remove_node(pos)
        core.add_item(pos, drop)

        -- Remove todas as entidades visuais ligadas ao baú aberto
        for _, obj in ipairs(core.get_objects_inside_radius(pos, 1)) do
            local ent = obj:get_luaentity()
            if ent and (
                    ent.name == "nh_nodes:chest_item" or
                    ent.name == "nh_nodes:back_chest_entity" or
                    ent.name == "nh_nodes:back_chest_close_entity"
                ) then
                obj:remove()
            end
        end
    end,
})

-- Entidade de animação de abertura do backchest
core.register_entity("nh_nodes:back_chest_entity", {
    initial_properties = {
        visual               = "mesh",
        mesh                 = "backchest.glb",
        textures             = { "BackChest.png" },
        visual_size          = { x = 1, y = 1, z = 1 },
        physical             = false,
        collide_with_objects = false,
        pointable            = false,
        static_save          = false,
        paramtype            = "light",
        paramtype2           = "facedir",
    },

    node_pos           = nil,
    original_param2    = 0,
    timer              = 0,
    animation_finished = false,
    is_invisible       = false,

    on_activate        = function(self, staticdata)
        self.object:set_armor_groups({ immortal = 1 })
    end,

    on_step            = function(self, dtime)
        if self.is_invisible then return end
        self.timer = self.timer + dtime
        if self.timer > 0.3 and not self.animation_finished then
            self.animation_finished = true
            self.object:set_animation({ x = 0.25, y = 0.25 }, 0, 0, false)
        end
    end,
})

-- Entidade de animação de fechamento do backchest
core.register_entity("nh_nodes:back_chest_close_entity", {
    initial_properties = {
        visual               = "mesh",
        mesh                 = "backchest.glb",
        textures             = { "BackChest.png" },
        visual_size          = { x = 1, y = 1, z = 1 },
        physical             = false,
        collide_with_objects = false,
        pointable            = false,
        static_save          = false,
        paramtype            = "light",
        paramtype2           = "facedir",
    },

    node_pos           = nil,
    original_param2    = 0,
    timer              = 0,

    on_activate        = function(self, staticdata)
        self.object:set_armor_groups({ immortal = 1 })
    end,

    on_step            = function(self, dtime)
        self.timer = self.timer + dtime
        if self.timer > 0.3 then
            -- Remove itens visuais
            if self.node_pos then
                local objects = core.get_objects_inside_radius(self.node_pos, 1)
                for _, obj in ipairs(objects) do
                    local luaent = obj:get_luaentity()
                    if luaent and luaent.name == "nh_nodes:chest_item" then
                        obj:remove()
                    end
                end
            end

            self.object:remove()

            -- Troca de volta para node fechado
            if self.node_pos then
                local node = core.get_node(self.node_pos)
                if node.name == "nh_nodes:back_chest_open" then
                    core.swap_node(self.node_pos,
                        { name = "nh_nodes:backchest", param2 = self.original_param2 })
                end
            end
        end
    end,
})

-- Detectar fechamento do formspec do backchest
core.register_on_player_receive_fields(function(player, formname, fields)
    local prefix = "nh_nodes:back_chest_"
    if formname:sub(1, #prefix) ~= prefix then return end

    local pos_string = formname:sub(#prefix + 1)
    local pos        = core.string_to_pos(pos_string)
    if not pos then return end

    local node = core.get_node(pos)
    if node.name ~= "nh_nodes:back_chest_open" then return end

    local meta         = core.get_meta(pos)
    local current_user = meta:get_string("current_user")
    local player_name  = player:get_player_name()

    if current_user ~= player_name then return end

    meta:set_string("current_user", "")

    local objects      = core.get_objects_inside_radius(pos, 0.5)
    local chest_entity = nil
    for _, obj in ipairs(objects) do
        local luaent = obj:get_luaentity()
        if luaent and luaent.name == "nh_nodes:back_chest_entity" then
            chest_entity = obj
            break
        end
    end

    local close_entity = core.add_entity(pos, "nh_nodes:back_chest_close_entity")
    if close_entity and close_entity:get_luaentity() then
        local luaentity           = close_entity:get_luaentity()
        luaentity.node_pos        = pos
        luaentity.original_param2 = node.param2

        if chest_entity then
            for _, obj in ipairs(objects) do
                local luaent = obj:get_luaentity()
                if luaent and luaent.name == "nh_nodes:chest_item" then
                    local slot = luaent.slot_index
                    obj:set_attach(close_entity, "bone" .. slot, { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 })
                end
            end
            chest_entity:remove()
        end

        local yaw = core.facedir_to_dir(node.param2)
        close_entity:set_yaw(core.dir_to_yaw(yaw) + math.pi)
        close_entity:set_animation({ x = 0.25, y = 0 }, 30, 0, false)
    end
end)

-- Detectar mudanças no inventário do backchest (atualiza itens visuais)
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    if action ~= "move" and action ~= "put" and action ~= "take" then return end
    if inventory_info.to_list ~= "main" and inventory_info.from_list ~= "main" then return end

    local player_name = player:get_player_name()
    local player_pos  = player:get_pos()
    if not player_pos then return end

    for _, obj in ipairs(core.get_objects_inside_radius(player_pos, 10)) do
        if obj:is_player() then goto backcontinue end
        local pos = obj:get_pos()
        if not pos then goto backcontinue end
        local node = core.get_node_or_nil(pos)
        if not node then goto backcontinue end
        if node.name == "nh_nodes:back_chest_open" then
            local meta = core.get_meta(pos)
            if meta:get_string("current_user") == player_name then
                back_chest_update_items(pos)
            end
        end
        ::backcontinue::
    end
end)

-- Node principal: backchest (fechado)
core.register_node("nh_nodes:backchest", {
    description           = S("Backpack Chest"),
    drawtype              = "mesh",
    mesh                  = "backchest.obj",
    tiles                 = { "BackChest.png" },
    walkable              = true,
    pointable             = true,

    paramtype             = "light",
    paramtype2            = "facedir",
    groups                = { snappy = 3, oddly_breakable_by_hand = 1, armor_back = 1 },
    stack_max             = 1,

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.7 }
    },
    offhand_bone_position = {
        pos = { x = -1, y = -0.5, z = 1.8 }
    },

    collision_box         = { type = "fixed", fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } },
    selection_box         = { type = "fixed", fixed = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 } },

    -- Criar inventário ao construir
    on_construct          = function(pos)
        local meta = core.get_meta(pos)
        local inv  = meta:get_inventory()
        inv:set_size("main", 8 * 2)
        meta:set_string("formspec",
            "size[8,9]" ..
            "list[current_name;main;0,0.3;8,2;]" ..
            "list[current_player;main;0,5.85;8,2;8]" ..
            "list[current_player;main;0,8.05;8,1;]" ..
            "listring[current_name;main]" ..
            "listring[current_player;main]"
        )
        meta:set_string("infotext", S("Backpack Chest"))
    end,

    -- Permite quebrar mesmo com itens dentro
    can_dig               = function(pos, player)
        return true
    end,

    -- Ao quebrar: salva o conteúdo na tabela global e grava o ID no item dropado
    on_dig                = function(pos, node, digger)
        local meta      = core.get_meta(pos)
        local inv       = meta:get_inventory()
        local has_items = not inv:is_empty("main")

        -- Gera ou reutiliza ID existente (caso o baú já tenha sido colocado antes)
        local chest_id  = meta:get_string("chest_id")
        if chest_id == "" then
            chest_id = backchest_new_id()
        end

        if has_items then
            -- Salva todos os slots na tabela global
            backchest_stored_items[chest_id] = backchest_save_inv(pos)
        else
            -- Sem itens: limpa entrada antiga se existir
            backchest_stored_items[chest_id] = nil
            chest_id = ""
        end

        -- Remove o node e dropa o item
        local drop = ItemStack("nh_nodes:backchest")
        if chest_id ~= "" then
            local drop_meta = drop:get_meta()
            drop_meta:set_string("chest_id", chest_id)
            -- Mostra indicação visual no item de que tem conteúdo
            drop_meta:set_string("description",
                S("Backpack Chest") .. "\n" .. S("(contains items)"))
        end

        core.remove_node(pos)
        core.add_item(pos, drop)

        -- Remove entidades visuais que possam ter sobrado
        for _, obj in ipairs(core.get_objects_inside_radius(pos, 1)) do
            local ent = obj:get_luaentity()
            if ent and (
                    ent.name == "nh_nodes:chest_item" or
                    ent.name == "nh_nodes:back_chest_entity" or
                    ent.name == "nh_nodes:back_chest_close_entity"
                ) then
                obj:remove()
            end
        end
    end,

    -- Abrir baú ao clicar
    on_rightclick         = function(pos, node, clicker, itemstack, pointed_thing)
        local current_node = core.get_node(pos)
        core.swap_node(pos, { name = "nh_nodes:back_chest_open", param2 = current_node.param2 })

        -- Remove entidades de animação antigas
        local objects = core.get_objects_inside_radius(pos, 0.5)
        for _, obj in ipairs(objects) do
            if obj:get_luaentity() and obj:get_luaentity().name == "nh_nodes:back_chest_entity" then
                obj:remove()
            end
        end

        -- Cria entidade de animação de abertura
        local entity = core.add_entity(pos, "nh_nodes:back_chest_entity")
        if entity and entity:get_luaentity() then
            local luaentity           = entity:get_luaentity()
            luaentity.node_pos        = pos
            luaentity.original_param2 = current_node.param2
            local yaw                 = core.facedir_to_dir(current_node.param2)
            entity:set_yaw(core.dir_to_yaw(yaw) + math.pi)
            entity:set_animation({ x = 0, y = 0.25 }, 1, 0, false)
        end

        local meta        = core.get_meta(pos)
        local player_name = clicker:get_player_name()
        meta:set_string("current_user", player_name)

        back_chest_update_items(pos)

        core.show_formspec(player_name,
            "nh_nodes:back_chest_" .. core.pos_to_string(pos),
            build_chest_formspec(clicker))

        return itemstack
    end,

    -- Ao colocar: restaura inventário a partir da tabela global via ID do item
    after_place_node      = function(pos, placer, itemstack, pointed_thing)
        local item_meta = itemstack:get_meta()
        local chest_id  = item_meta:get_string("chest_id")

        if chest_id ~= "" and backchest_stored_items[chest_id] then
            local meta = core.get_meta(pos)
            -- Grava o mesmo ID no node para futuras quebras
            meta:set_string("chest_id", chest_id)
            backchest_restore_inv(pos, backchest_stored_items[chest_id])
            -- Libera da tabela: agora o inventário vive no node
            backchest_stored_items[chest_id] = nil
        end
    end,
})


-- Exemplo de luvas gestuais
core.register_node("nh_nodes:likeglove", {
    description = S("Like Glove"),
    drawtype = "mesh",
    mesh = "likeglove.obj",
    tiles = { "likeglove.png" },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
        armor_hands = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0.9, y = 0, z = 0 },  -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = -90 } -- Ajuste Y para girar (90° = direita)
    },
})

-- Exemplo de luvas gestuais
core.register_node("nh_nodes:pointglove", {
    description = S("Point Glove"),
    drawtype = "mesh",
    mesh = "pointglove.obj",
    tiles = { "pointglove.png" },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
        armor_hands = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0.9, y = 0, z = 0 },  -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = -90 } -- Ajuste Y para girar (90° = direita)
    },
})

-- Exemplo de capacete
core.register_node("nh_nodes:copperhelmet", {
    description = S("Copper Helmet"),
    drawtype = "mesh",
    mesh = "helmet.obj",
    tiles = { "copperhelmet.png" },
    stack_max = 1, -- limita a 1 por slot

    groups = {
        armor_head = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    paramtype = "light",
    paramtype2 = "facedir",


    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0, y = 2.7, z = 0 }, -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = 0 }  -- Ajuste Y para girar (90° = direita)
    },

    --armor_texture = "copperhelmet.png",
    --armor_groups = {fleshy = 5},  -- Proteção
})


-- Exemplo de armadura de tronco
core.register_node("nh_nodes:copperchestplate", {
    description = S("Copper Chestplate"),
    drawtype = "mesh",
    mesh = "chestplate.obj",
    tiles = { "copperchest.png" },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
        armor_torso = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0.6, y = 4.1, z = 0 }, -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = 0 }    -- Ajuste Y para girar (90° = direita)
    },
})

-- Armadura de cintura
core.register_node("nh_nodes:fauld", {
    description = S("Copper Fauld"),
    drawtype = "mesh",
    mesh = "leggings.obj",
    tiles = { "copperlegging.png" },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
        armor_waist = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0.6, y = 2.1, z = 0 }, -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = 0 }    -- Ajuste Y para girar (90° = direita)
    },
})

-- Exemplo de calças
core.register_node("nh_nodes:leggings", {
    description = S("Copper Leggings"),
    drawtype = "mesh",
    mesh = "leggings.obj",
    tiles = { "copperlegging.png" },
    stack_max = 1, -- limita a 1 por slot

    paramtype = "light",
    paramtype2 = "facedir",

    groups = {
        armor_legs = 1,
        oddly_breakable_by_hand = 3,
        snappy = 3,
        fleshy = 5,
    },

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },
    collision_box = {
        type = "fixed",
        fixed = { -0.3, -0.5, -0.3, 0.3, 0.1, 0.3 }
    },

    -- Define posição customizada quando equipado
    armor_bone_position = {
        pos = { x = 0.6, y = 2.1, z = 0 }, -- Ajuste Y para descer
        rot = { x = 0, y = -90, z = 0 }    -- Ajuste Y para girar (90° = direita)
    },
})


-- Exemplo de botas
--core.register_node("nh_nodes:boots", {
--    description = "Botas Básicas",
--    inventory_image = "boots_basic.png",
--    groups = {armor_feet = 1},
--    stack_max = 1,  -- limita a 1 por slot

--    paramtype = "light",
--    paramtype2 = "facedir",
--})



-- ========================================
-- PORTA DE CARVALHO 3x1
-- ========================================

-- Porta fechada
core.register_node("nh_nodes:oakdoor_closed", {
    description = S("Oak Door"),
    drawtype = "mesh",
    mesh = "oakdoor_closed.obj", -- Um único mesh 3x1
    tiles = { "oakwood3x1.png" },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { choppy = 3, door = 1 },
    --sounds = default.node_sound_wood_defaults(),

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.5, 0.5, 2.5, -0.375 } -- 3 blocos de altura, fina
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.3, 0.5, 2.5, 0.05 }
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = 0.5, z = 1.7 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -2, y = -0.9, z = 1.35 }
        --rot = {x = 0, y = 0, z = -110}
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 3, y = -1, z = 0.7 },
        rot = { x = 0, y = 0, z = 90 }
    },

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- Abre a porta
        core.set_node(pos, { name = "nh_nodes:oakdoor_open", param2 = node.param2 })
        core.sound_play("door_open", { pos = pos, gain = 0.3, max_hear_distance = 10 })
    end,
})

-- Porta aberta
core.register_node("nh_nodes:oakdoor_open", {
    description = S("Oak Door") .. "\n" .. S("(Open)"),
    drawtype = "mesh",
    mesh = "oakdoor_open.obj", -- Mesmo mesh mas rotacionado/aberto
    tiles = { "oakwood3x1.png" },
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { choppy = 3, door = 1, not_in_creative_inventory = 1 },
    drop = "nh_nodes:oakdoor_closed",
    --sounds = default.node_sound_wood_defaults(),

    walkable = false,

    selection_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.38, -0.375, 2.5, 0.63 } -- Porta na lateral quando aberta
    },

    collision_box = {
        type = "fixed",
        fixed = { -0.5, -0.5, -0.38, -0.375, 2.5, 0.63 } -- Colisão fina na lateral
    },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = -2, y = -1, z = 1.35 },
        rot = { x = 0, y = -90, z = -90 }
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    -- Configuração mão esquerda
    offhand_bone_position = {
        pos = { x = 3, y = -1, z = -1.4 },
        rot = { x = 0, y = 90, z = 90 }
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        -- Fecha a porta
        core.set_node(pos, { name = "nh_nodes:oakdoor_closed", param2 = node.param2 })
        core.sound_play("door_close", { pos = pos, gain = 0.3, max_hear_distance = 10 })
    end,
})






-----------------------------
-- GRIMÓRIO DE MATERIALIZAÇÃO - Archion

local ITEMS_PER_PAGE  = 40
local GRID_W          = 8
local GRID_H          = 5

local item_cache      = {}
local item_desc_index = {} -- [lang_code][item_name] = {desc_traduzida, desc_original}

local function build_item_cache()
    if next(item_cache) then return end
    for name, def in pairs(core.registered_items) do
        if name ~= "" then
            table.insert(item_cache, name)
        end
    end
    table.sort(item_cache)
end

local function ensure_desc_index(lang_code)
    if item_desc_index[lang_code] then return end
    item_desc_index[lang_code] = {}

    for _, name in ipairs(item_cache) do
        local def        = core.registered_items[name]
        local raw_desc   = (def and def.description) or ""

        -- Traduz a description completa para o idioma do jogador
        local translated = core.get_translated_string(lang_code, raw_desc)
        local original   = raw_desc

        -- Indexa TODAS as linhas (nome principal + subtítulos como [Mob Spawner])
        local terms      = {}
        for line in (translated .. "\n"):gmatch("([^\n]*)\n") do
            local trimmed = line:match("^%s*(.-)%s*$") -- remove espaços
            if trimmed ~= "" then
                table.insert(terms, trimmed:lower())
            end
        end
        -- Adiciona também as linhas originais em inglês como fallback
        for line in (original .. "\n"):gmatch("([^\n]*)\n") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                table.insert(terms, trimmed:lower())
            end
        end

        item_desc_index[lang_code][name] = terms
    end
end

local function filter_items(search, lang_code)
    build_item_cache()
    if not search or search == "" then return item_cache end

    lang_code = lang_code or "en"
    ensure_desc_index(lang_code)

    local result = {}
    local term   = search:lower()
    local index  = item_desc_index[lang_code]

    for _, name in ipairs(item_cache) do
        local matched = name:lower():find(term, 1, true)

        if not matched and index[name] then
            for _, desc in ipairs(index[name]) do
                if desc:find(term, 1, true) then
                    matched = true
                    break
                end
            end
        end

        if matched then
            table.insert(result, name) -- corrigido: era `matched` por engano
        end
    end

    return result
end


-- ─── Entidade Grimório ─────────────────────────────────

core.register_entity("nh_nodes:grimoire_entity", {
    initial_properties = {
        visual       = "mesh",
        mesh         = "grimorie.glb",
        textures     = { "grimorie.png" },
        visual_size  = { x = 10, y = 10 },
        collisionbox = { 0, 0, 0, 0, 0, 0 }, -- sem colisão
        physical     = false,
        static_save  = false,                -- não persiste ao reiniciar
    },

    on_activate = function(self, staticdata)
        -- Animação de abertura: frames 0 → 0.5 s  (ex.: 30 fps → frame 0 a 15)
        self.object:set_animation(
            { x = 0, y = 0.5 }, -- intervalo de frames
            30,                 -- fps
            0,                  -- frame_blend
            false               -- loop
        )
        self._closing = false
    end,

    on_step = function(self, dtime)
        if not self._closing then return end

        self._close_timer = (self._close_timer or 0) + dtime

        -- Espera a animação de fechamento terminar (~0.5 s) e então limpa tudo
        if self._close_timer >= 0.6 then
            local pos = self.object:get_pos()

            -- Restaura o node original
            if self._node_pos then
                core.set_node(self._node_pos, { name = "nh_nodes:archion", param2 = self._node_param2 or 0 })
            end

            self.object:remove()
        end
    end,
})


-- ─── Helpers de swap ──

-- Guarda: player_name → {entity, node_pos, node_param2}
local open_grimoires = {}

local function spawn_grimoire_entity(pos, param2, player_name)
    -- Esconde o node substituindo por air
    local node_param2 = core.get_node(pos).param2
    core.set_node(pos, { name = "air" })

    -- Spawna a entidade no mesmo lugar
    local obj = core.add_entity(pos, "nh_nodes:grimoire_entity")
    if not obj then
        -- Fallback: restaura o node se falhar
        core.set_node(pos, { name = "nh_nodes:archion", param2 = node_param2 })
        return nil
    end

    -- Aplica a mesma rotação do node (facedir → yaw)
    local function facedir_to_yaw(param2)
        -- Pega o vetor de direção frontal do facedir
        local dir = core.facedir_to_dir(param2)
        -- Converte o vetor XZ em yaw (atan2 com eixos do Minetest)
        return math.atan2(-dir.x, dir.z)
    end
    obj:set_yaw(facedir_to_yaw(param2 % 4))


    local ent                   = obj:get_luaentity()
    ent._node_pos               = vector.copy(pos)
    ent._node_param2            = node_param2
    ent._player_name            = player_name

    open_grimoires[player_name] = {
        entity      = obj,
        node_pos    = vector.copy(pos),
        node_param2 = node_param2,
    }

    return obj
end

local function close_grimoire_entity(player_name)
    local data = open_grimoires[player_name]
    if not data then return end

    local obj = data.entity
    if not obj or not obj:get_pos() then
        -- Entidade já sumiu; só restaura o node
        core.set_node(data.node_pos, { name = "nh_nodes:archion", param2 = data.node_param2 })
        open_grimoires[player_name] = nil
        return
    end

    local ent = obj:get_luaentity()
    if not ent then
        obj:remove()
        core.set_node(data.node_pos, { name = "nh_nodes:archion", param2 = data.node_param2 })
        open_grimoires[player_name] = nil
        return
    end

    -- Animação de fechamento: frames 0.5 → 1 s  (ex.: 30 fps → frame 15 a 30)
    obj:set_animation(
        { x = 0.5, y = 1 },
        30,
        0,
        false
    )

    ent._closing                = true
    ent._close_timer            = 0
    -- on_step cuidará de remover a entidade e restaurar o node

    open_grimoires[player_name] = nil
end


-- ─── Formspec ───

function show_grimoire(player, page, search)
    page            = page or 1
    search          = search or ""

    local name      = player:get_player_name()
    -- Pega o lang_code do jogador (ex: "pt", "en", "de")
    local info      = core.get_player_information(name)
    local lang_code = (info and info.lang_code) or "en"

    local items     = filter_items(search, lang_code) -- <-- passa lang_code
    local max_page  = math.max(1, math.ceil(#items / ITEMS_PER_PAGE))
    page            = math.min(page, max_page)

    local start     = (page - 1) * ITEMS_PER_PAGE + 1
    local fs        = {
        "formspec_version[4]",
        "size[14,13]",
        "label[0.3,0.3;" .. S("Complete Materialization Grimoire") .. "]",
        "field[0.3,0.9;6,0.8;search;;" .. core.formspec_escape(search) .. "]",
        "field_close_on_enter[search;false]",
        "button[6.4,0.9;1.2,0.8;do_search;" .. S("Search") .. "]",
        "button[8,0.9;1,0.8;prev;<]",
        "label[9.2,1.05;" .. page .. "/" .. max_page .. "]",
        "button[10.3,0.9;1,0.8;next;>]",
    }

    local x0, y0    = 0.3, 1.8
    local i         = start
    for y = 0, GRID_H - 1 do
        for x = 0, GRID_W - 1 do
            if not items[i] then break end
            table.insert(fs,
                "item_image_button[" ..
                (x0 + x * 1.1) .. "," ..
                (y0 + y * 1.1) .. ";1,1;" ..
                items[i] .. ";item_" .. i .. ";]"
            )
            i = i + 1
        end
    end

    table.insert(fs, "list[current_player;main;1,8.6;8,2;8]")
    table.insert(fs, "list[current_player;main;1,11.3;8,1;]")
    table.insert(fs, "listring[current_player;main]")

    core.show_formspec(name, "nh_nodes:materialization", table.concat(fs))
end

-- ─── Node ─────

core.register_node("nh_nodes:archion", {
    description           = S("Archion") ..
        "\n" ..
        S("Grimoire of Materialization") .. "\n" .. S("(completed)") .. "\n" .. S("[only active in creative mode]"),
    drawtype              = "mesh",
    mesh                  = "grimorie.obj",
    tiles                 = { "grimorie.png" },

    walkable              = false,
    max_stake             = 1,
    paramtype             = "light",
    paramtype2            = "facedir",

    groups                = { snappy = 3, oddly_breakable_by_hand = 3, falling_node = 1 },

    -- Configuração mão direita
    wielded_bone_position = {
        pos = { x = 0.5, y = -1, z = 1.15 },
        rot = { x = 90, y = 0, z = 90 }
    },
    wielded_visual_size   = { x = 0.2, y = 0.2, z = 0.2 },

    offhand_bone_position = {
        pos = { x = 0.5, y = -1, z = -1.15 },
        rot = { x = -90, y = 0, z = 270 }
    },
    -- wielded_visual_size = {x = 0.25, y = 0.25, z = 0.25},

    collision_box         = {
        type  = "fixed",
        fixed = { -0.1, -0.5, -0.1, 0.1, -0.45, 0.1 }
    },
    selection_box         = {
        type  = "fixed",
        fixed = { -0.375, -0.5, -0.5, 0.375, -0.25, 0.5 }
    },

    on_rightclick         = function(pos, node, player, itemstack, pointed_thing)
        local controls = player:get_player_control()

        if controls.aux1 then
            if not core.is_creative_enabled(player:get_player_name()) then
                core.chat_send_player(player:get_player_name(), "[O Archion só funciona no modo criativo]")
                return itemstack
            end

            -- Spawna a entidade e abre o formspec
            spawn_grimoire_entity(pos, node.param2, player:get_player_name())
            show_grimoire(player, 1, "")
            return itemstack
        end

        if itemstack and not itemstack:is_empty() then
            local item_def = core.registered_items[itemstack:get_name()]
            if item_def and item_def.type == "node" then
                return core.item_place_node(itemstack, player, pointed_thing)
            end
            if item_def and item_def.on_place then
                local safe_pointed = {
                    type  = pointed_thing.type,
                    under = pointed_thing.above,
                    above = pointed_thing.above,
                }
                return item_def.on_place(itemstack, player, safe_pointed)
            end
        end

        if itemstack:is_empty() then
            core.chat_send_player(
                player:get_player_name(),
                S(
                    "I need to observe (hold 'E' or 'Aux1') and reach the ground (click 'place' with empty hands) to open...")
            )
        end

        return itemstack
    end,
})


-- ─── Recebimento de campos

local player_state = {}

core.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "nh_nodes:materialization" then return end

    local name = player:get_player_name()
    player_state[name] = player_state[name] or { page = 1, search = "" }
    local state = player_state[name]

    -- Fechamento do formspec (clique em X ou pressiona Esc)
    if fields.quit then
        close_grimoire_entity(name)
        return
    end

    if fields.do_search or fields.key_enter_field == "search" then
        state.search = fields.search or ""
        state.page   = 1
        show_grimoire(player, state.page, state.search)
        return
    end

    if fields.next then
        state.page = state.page + 1
        show_grimoire(player, state.page, state.search)
        return
    end

    if fields.prev then
        state.page = math.max(1, state.page - 1)
        show_grimoire(player, state.page, state.search)
        return
    end

    for field, _ in pairs(fields) do
        if field:sub(1, 5) == "item_" then
            local index     = tonumber(field:sub(6))
            local info      = core.get_player_information(name)
            local lang_code = (info and info.lang_code) or "en"
            local items     = filter_items(state.search, lang_code)
            local item      = items[index]
            if item then
                player:get_inventory():add_item("main", item)
            end
            return
        end
    end
end)


-- ─── Limpeza ao deslogar ──

core.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    -- Fecha "na força" sem animação para não deixar entidade órfã
    local data = open_grimoires[name]
    if data then
        if data.entity and data.entity:get_pos() then
            data.entity:remove()
        end
        core.set_node(data.node_pos, { name = "nh_nodes:archion", param2 = data.node_param2 })
        open_grimoires[name] = nil
    end
    player_state[name] = nil
end)


core.register_on_newplayer(function(player)
    local inv = player:get_inventory()

    local page = ItemStack("nh_items:writedpage")
    local meta = page:get_meta()
    meta:set_string("text",
        S("--- THE NEW HORIZON ---") .. "\n\n" ..
        S(
            "If you're reading this, it's because you've lost your memory or perhaps you've never experienced this before...") ..
        "\n\n" ..
        S("Walk (directional keys / WASD), jump (hold ↑ / space) and sneak (hold ↓ / shift) to explore.") .. "\n" ..
        S("Anywhere you can also:") .. "\n" ..
        "- " .. S("Wall jump (Quick jump x2 in front of small walls, to climb them)") .. "\n\n" ..
        "- " ..
        S(
            "Vertical climbing (hold jump in front of walls or tree trunks at least 4 blocks high) [If you can't reach a foothold but keep holding jump in contact with the vertical surface, you will fall more slowly sliding down it]") ..
        "\n\n" ..
        "- " .. S("Crawl (press sneak + hold sneak)") .. "\n" ..
        "- " .. S("Sit (hold sneak + 2x Aux1 / E)") .. "\n" ..
        "- " .. S("Lie down (sitting press: 2x Aux1 / E) [Return to sitting: 2x Aux1 / E]") .. "\n\n" ..
        S("General guide:") .. "\n\n" ..
        "- " .. S("Collect pebbles on the ground to craft a tool") .. "\n" ..
        "- " .. S("Some pebbles create sparks when struck together") .. "\n" ..
        "- " .. S("Try to make fire by spreading a spark onto nearby material") .. "\n" ..
        "- " .. S("Light torches by using them on fire") .. "\n" ..
        "- " .. S("Activate your observation (Aux1 / E) and touch ground blocks to idealize crafts") .. "\n" ..
        "- " ..
        S(
            "Crafting doesn't depend on the arrangement of the items. Just spread the correct quantities across the grid slots.") ..
        "\n" ..
        "- " .. S("There are hidden chests around the world, but don't expect great rewards") .. "\n" ..
        "- " ..
        S("They say there is a lost book called Archion that can grant everything this world has to offer") .. "\n" ..
        "- " ..
        S(
            "Someone could have summoned the book using their unlimited creative power by saying: '/grantme all' and '/giveme nh_nodes:archion'") ..
        "\n" ..
        "- " .. S("According to legend, there are also creatures that only appear in specific locations") .. "\n" ..
        "- " .. S("Some tried to escape, but couldn't — this world seems to have no limits.") .. "\n" ..
        "- " .. S("Check the other pages if in doubt") .. "\n\n" ..
        S("Good luck...") .. "\n\n" ..
        "                                                                                                 9"
    )

    inv:set_stack("main", 2, page)
end)
