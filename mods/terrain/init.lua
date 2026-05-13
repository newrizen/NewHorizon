-- Terrain

local function table_xyz(fx, fy, fz)
    return {x = fx, y = fy, z = fz}
end

core.log("action", "[TERRAIN] init.lua loaded")
local S = core.get_translator "nh_terrain"
-- CONFIGURAÇÕES DO MUNDO
local MIN_XZ = config.MIN_XZ
local MAX_XZ = config.MAX_XZ
local VOID_Y = config.VOID_Y
local SIZE = MAX_XZ - MIN_XZ + 1
-- DESATIVAR MAPGEN NATIVO
core.set_mapgen_setting("mg_name", "singlenode", true)
local gcid        = core.get_content_id
-- REGISTRO DOS IDS
local C           = {
    ignore             = core.CONTENT_IGNORE,
    air                = core.CONTENT_AIR,
    grass              = gcid "nh_nodes:grass",
    topgrass           = gcid "nh_nodes:top_grass",
    topgrass2          = gcid "nh_nodes:top_grass2",
    top_grass_ramp     = gcid "nh_nodes:top_grass_ramp",
    top_grass_corner   = gcid "nh_nodes:top_grass_corner",
    grassinsidecorner  = gcid "nh_nodes:top_grass_insidecorner",
    dirt_ramp          = gcid "nh_nodes:dirt_ramp",
    dirt_corner        = gcid "nh_nodes:dirt_corner",
    dirt_insidecorner  = gcid "nh_nodes:dirt_insidecorner",
    sand_ramp          = gcid "nh_nodes:sand_ramp",
    sand_corner        = gcid "nh_nodes:sand_corner",
    sand_insidecorner  = gcid "nh_nodes:sand_insidecorner",
    top_grass2         = gcid "nh_nodes:top_grass2",
    grassleaves        = gcid "nh_nodes:grassleaves",
    grassleavesmedium  = gcid "nh_nodes:grassleavesmedium",
    smallgrass         = gcid "nh_nodes:smallgrass",
    highgrass          = gcid "nh_nodes:highgrass",
    rush               = gcid "nh_nodes:rush",
    dandelion          = gcid "nh_nodes:dandelion",
    micaceusfungus     = gcid "nh_nodes:micaceusfungus",
    flyamanitafungus   = gcid "nh_nodes:flyamanitafungus",
    dirt               = gcid "nh_nodes:dirt",
    pebble             = gcid "nh_nodes:pebble",
    whitepebble        = gcid "nh_nodes:white_pebble",
    sand               = gcid "nh_nodes:sand",
    wetsand            = gcid "nh_nodes:wet_sand",
    saprolite          = gcid "nh_nodes:saprolite",
    gneiss             = gcid "nh_nodes:gneiss",
    cobblestone        = gcid "nh_nodes:cobblestone",
    basalt             = gcid "nh_nodes:basalt",
    basaltramp         = gcid "nh_nodes:basalt_ramp",
    basaltcorner       = gcid "nh_nodes:basalt_corner",
    basaltinsidecorner = gcid "nh_nodes:basalt_insidecorner",
    magma              = gcid "nh_nodes:magma",
    peridotite         = gcid "nh_nodes:peridotite",
    bedrock            = gcid "nh_nodes:bedrock",
    redrock            = gcid "nh_nodes:redrock",
    oaktimber          = gcid "nh_nodes:oaktimber",
    fallenstick        = gcid "nh_nodes:fallenstick",
    appletimber        = gcid "nh_nodes:appletimber",
    pinetimber         = gcid "nh_nodes:pinetimber",
    pineleaves         = gcid "nh_nodes:pineleaves",
    oakwood            = gcid "nh_nodes:oakwood",
    oakplank           = gcid "nh_nodes:oakplank",
    oakdowel           = gcid "nh_nodes:oakdowel",
    oakchest           = gcid "nh_nodes:oak_chest",
    oakdoor            = gcid "nh_nodes:oakdoor_closed",
    oakbranch          = gcid "nh_nodes:oakbranch",
    leaves             = gcid "nh_nodes:leaves",
    leavesrelief       = gcid "nh_nodes:leavesrelief",
    kelp               = gcid "nh_nodes:kelp",
    sentinelstatue     = gcid "nh_nodes:sentinelstatue",
    leaves_nut         = gcid "nh_nodes:leaves_nut",
    leaves_nut2        = gcid "nh_nodes:leaves_nut2",
    leaves_nut3        = gcid "nh_nodes:leaves_nut3",
    appleleaves        = gcid "nh_nodes:appleleaves",
    blueberryleaves    = gcid "nh_nodes:blueberryleaves",
    leavesblueberry4   = gcid "nh_nodes:leaves_blueberry4",
    leavesapple        = gcid "nh_nodes:leaves_apple",
    leavesapple2       = gcid "nh_nodes:leaves_apple2",
    leavesapple3       = gcid "nh_nodes:leaves_apple3",
    palmtimber         = gcid "nh_nodes:palmtimber",
    palmstraws         = gcid "nh_nodes:palmstraws",
    palmleafstalks     = gcid "nh_nodes:palmleafstalks",
    palmleaf           = gcid "nh_nodes:palmleaf",
    palmstraw          = gcid "nh_nodes:palmstraw",
    coconut            = gcid "nh_nodes:coconutlinked",
    water              = gcid "nh_nodes:water",
    water2             = gcid "nh_nodes:water2",
    lava               = gcid "nh_nodes:lava",
    obsidian           = gcid "nh_nodes:obsidian",
    fireice            = gcid "nh_nodes:fireice",
    snow               = gcid "nh_nodes:snow",
    snow_ramp          = gcid "nh_nodes:snow_ramp",
    snow_corner        = gcid "nh_nodes:snow_corner",
    snow_insidecorner  = gcid "nh_nodes:snow_insidecorner",
    ice                = gcid "nh_nodes:ice",
    sphere             = gcid "nh_nodes:sphere",
    coal               = gcid "nh_nodes:coal",
    copper             = gcid "nh_nodes:copper",
    tin                = gcid "nh_nodes:tin",
    iron               = gcid "nh_nodes:iron",
    nickel             = gcid "nh_nodes:nickel",
    manganese          = gcid "nh_nodes:manganese",
    chromium           = gcid "nh_nodes:chromium",
}
-- Tabelas de tipo, definidas UMA VEZ no escopo do módulo (fora de qualquer função)
local GRASS_SOLID  -- preenchido após os content_ids serem obtidos
local GRASS_PASS  
local DIRT_SOLID  
local DIRT_EDGE   
local SAND_SOLID  
local SAND_EDGE   
local function init_slope_tables()
    GRASS_SOLID[C.topgrass]          = true
    GRASS_SOLID[C.top_grass_ramp]    = true
    GRASS_SOLID[C.top_grass_corner]  = true
    GRASS_SOLID[C.grassinsidecorner] = true
    GRASS_PASS[C.air]                = true
    GRASS_PASS[C.grassleaves]        = true
    GRASS_PASS[C.grassleavesmedium]  = true

    DIRT_SOLID[C.dirt]              = true
    DIRT_SOLID[C.dirt_ramp]         = true
    DIRT_SOLID[C.dirt_corner]       = true
    DIRT_SOLID[C.dirt_insidecorner] = true
    DIRT_EDGE[C.sand]               = true
    DIRT_EDGE[C.air]                = true

    SAND_SOLID[C.sand]              = true
    SAND_SOLID[C.sand_ramp]         = true
    SAND_SOLID[C.sand_corner]       = true
    SAND_SOLID[C.sand_insidecorner] = true
    SAND_EDGE[C.wetsand]            = true
    SAND_EDGE[C.air]                = true
end
init_slope_tables()
local terrain_slopes = dofile(
    minetest.get_modpath(minetest.get_current_modname())
    .. "/terrain_update_shape.lua"
)
terrain_slopes.init(C, DECORATION_CIDS)

-- LOOKUP TABLES GLOBAIS --
-- Nodes sólidos de grama (LBMs grass_conversion e grass_conversion2)
local SOLID_GRASS = {
    [C.topgrass]          = true,
    [C.top_grass_ramp]    = true,
    [C.top_grass_corner]  = true,
    [C.grassinsidecorner] = true,
    [C.snow]              = true,
    [C.snow_ramp]         = true,
    [C.snow_corner]       = true,
    [C.snow_insidecorner] = true,
}
-- Nodes sólidos de dirt + edges (LBM dirt_conversion)
local SOLID_DIRT = {
    [C.dirt]              = true,
    [C.sand]              = true,
    [C.dirt_ramp]         = true,
    [C.dirt_corner]       = true,
    [C.dirt_insidecorner] = true,
}
local EDGE_DIRT = {[C.sand] = true, [C.air] = true,}
-- Nodes sólidos de neve + edges (LBM snow_conversion)
local SOLID_SNOW = {
    [C.snow]              = true,
    [C.snow_ramp]         = true,
    [C.snow_corner]       = true,
    [C.snow_insidecorner] = true,
    [C.topgrass]          = true,
    [C.top_grass_ramp]    = true,
    [C.top_grass_corner]  = true,
    [C.grassinsidecorner] = true,
}
local EDGE_SNOW = {[C.air] = true,}
-- Nodes sólidos de basalt + edges (LBM basalt_conversion)
local SOLID_BASALT = {
    [C.basalt]              = true,
    [C.basaltramp]          = true,
    [C.basaltcorner]        = true,
    [C.basaltinsidecorner]  = true,
}
local EDGE_BASALT = {[C.wetsand] = true, [C.air] = true,}
-- Nodes sólidos de areia + edges (LBM sand_conversion)
local SOLID_SAND = {
    [C.wetsand]           = true,
    [C.sand]              = true,
    [C.sand_ramp]         = true,
    [C.sand_corner]       = true,
    [C.sand_insidecorner] = true,
}
local EDGE_SAND = {[C.wetsand] = true, [C.air] = true,}
-- Nodes decorativos que podem ser removidos de cima de rampas/quinas
local DECORATIONS = {
    [C.smallgrass]        = true,
    [C.highgrass]         = true,
    [C.rush]              = true,
    [C.dandelion]         = true,
    [C.grassleaves]       = true,
    [C.grassleavesmedium] = true,
    [C.micaceusfungus]    = true,
    [C.flyamanitafungus]  = true,
    [C.pebble]            = true,
    [C.whitepebble]       = true,
    [C.fallenstick]       = true,
}
-- DECORATION_CIDS é agora um alias direto (ids já são content ids)
local DECORATION_CIDS = DECORATIONS

-- Nodes que são "passáveis" para o cálculo de quinas internas de grama
local PASSABLE = {[C.air] = true}
for cid in pairs(DECORATIONS) do PASSABLE[cid] = true end

-- Função auxiliar global (sem local function dentro de loop)
local slope_area, slope_data, slope_p2, slope_y
local function slope_get(x, z)
    if slope_area:contains(x, slope_y, z) then return slope_data[slope_area:index(x, slope_y, z)] end
    return C.ignore
end
local function slope_get_below(x, z)
    if slope_area:contains(x, slope_y - 1, z) then return slope_data[slope_area:index(x, slope_y - 1, z)] end
    return C.ignore
end
local entity_positions 
local tent_generated = false
local TENT_SEARCH_RADIUS = 256
local ship_generated = false
local SHIP_SEARCH_RADIUS = 256
local house_generated = false
local HOUSE_SEARCH_RADIUS = 256
local statue_spawned = false
local statue_pos = nil
local sentinel_pos = nil
local lowest_island_pos = nil
local ship_pos = nil
-- NOISES (mantidos para compatibilidade com funções antigas)
local function populate_Pall(names)
    local father 
    for _, name in ipairs(names) do father[name] = nil end
    return father
end
local P = populate_Pall({
    "continent",
    "biome",
    "mountain",
    "hills",
    "plains",
    "roughness",
    "caves",
    "caves_lava",
    "caves_water",
    "cave_size",
    "grassleaves",
    "trees",
    "bushes",
    -- "perlin_palms",
    "saprolite",
    -- NOISES PARA MINÉRIOS (adicionar após os noises existentes)
    "ore_master",
    "coal",
    "copper",
    "tin",
    "iron",
    "nickel",
    "manganes",
    "chromium",
})
-- PERLIN MAPS (OTIMIZAÇÃO)
local PM = populate_Pall({
    "continent",
    "biome",
    "mountain",
    "hills",
    "plains",
    "roughness",
    "caves",
    "caves_lava",
    "caves_water",
    "cave_size",
    "grassleaves",
    "trees",
    "bushes",
    "saprolite",
    "ore_master",
})
-- CONFIGURAÇÃO DOS NOISES
local NOISE = {
    continent = {
        offset = 0,
        scale = 0.5,
        spread = {x = 300, y = 300, z = 300}, -- MUITO grande
        seed = 24680,
        octaves = 2,
        persist = 0.5,
   },
    mountain = {
        offset = 0,
        scale = 1,
        spread = {x = 80, y = 80, z = 80},
        seed = 12345,
        octaves = 5,
        persist = 0.6,
   },
    hills = {
        offset = 0,
        scale = 0.5,
        spread = {x = 150, y = 150, z = 150},
        seed = 67890,
        octaves = 3,
        persist = 0.5,
   },
    plains = {
        offset = 0,
        scale = 0.5,
        spread = {x = 180, y = 180, z = 180},
        seed = 99999,
        octaves = 2,
        persist = 0.4,
   },
    caves = {
        offset = 0,
        scale = 1,
        spread = {x = 50, y = 20, z = 50},
        seed = 121212,
        octaves = 3,
        persist = 0.5,
   },
    -- Para cavernas de lava
    caves_lava = {
        offset = 0,
        scale = 1,
        spread = {x = 40, y = 80, z = 40}, -- spread maior em Y = cavernas mais verticais
        seed = 424242,                       -- seed diferente
        octaves = 3,
        persist = 0.5,
   },
    -- Para cavernas de água (seed diferente!)
    caves_water = {
        offset = 0,
        scale = 1,
        spread = {x = 60, y = 30, z = 60}, -- spread menor em Y = cavernas mais horizontais
        seed = 777888,                       -- outra seed DIFERENTE
        octaves = 3,
        persist = 0.5,
   },
    cave_size = {
        offset = 0,
        scale = 1,
        spread = {x = 50, y = 50, z = 50}, -- Varia o tamanho das cavernas por região
        seed = 131313,
        octaves = 2,
        persist = 0.4,
   },
    roughness = {
        offset = 0,
        scale = 0.5,
        spread = {x = 25, y = 25, z = 25},
        seed = 11111,
        octaves = 2,
        persist = 0.6,
   },
    biome = {
        offset = 0,
        scale = 0.5,
        spread = {x = 150, y = 150, z = 150},
        seed = 77777,
        octaves = 3,
        persist = 0.6,
   },
    saprolite = {
        offset = 0,
        scale = 1,
        spread = {x = 40, y = 40, z = 40},
        seed = 9876,
        octaves = 2,
        persist = 0.5,
        lacunarity = 2.0
   },
    grassleaves = {
        offset = 0,
        scale = 10,
        spread = {x = 20, y = 20, z = 20}, -- Spread maior = mais espaçadas (era 10)
        seed = 12312,
        octaves = 3,
        persist = 0.5,
   },
    trees = {
        offset = 0,
        scale = 0.6,
        spread = {x = 10, y = 10, z = 10}, -- Spread maior = mais espaçadas (era 10)
        seed = 54321,
        octaves = 3,
        persist = 0.5,
   },
    bushes = {
        offset = 0,
        scale = 0.6,
        spread = {x = 8, y = 8, z = 8},
        seed = 98765,
        octaves = 2,
        persist = 0.4,
   },
    -- noise_palms = {
    --    offset = 0,
    --    scale = 0.6,
    --    spread = {x = 15, y = 15, z = 15},
    --    seed = 33333,
    --    octaves = 2,
    --    persist = 0.4,
    --},
    -- CONFIGURAÇÃO DOS NOISES DE MINÉRIOS
    ore_master = {
        offset = 0,
        scale = 1,
        spread = {x = 30, y = 30, z = 30},
        seed = 9130,
        octaves = 3,
        persist = 0.6,
        lacunarity = 2.0,
   },
    coal = {
        offset = 0,
        scale = 0.5,
        spread = {x = 30, y = 30, z = 30},
        seed = 19283,
        octaves = 3,
        persist = 0.6,
   },
    copper = {
        offset = 0,
        scale = 0.5,
        spread = {x = 35, y = 35, z = 35},
        seed = 28374,
        octaves = 3,
        persist = 0.6,
   },
    tin = {
        offset = 0,
        scale = 0.5,
        spread = {x = 32, y = 32, z = 32},
        seed = 37465,
        octaves = 3,
        persist = 0.6,
   },
    iron = {
        offset = 0,
        scale = 0.5,
        spread = {x = 28, y = 28, z = 28},
        seed = 46556,
        octaves = 3,
        persist = 0.6,
   },
    nickel = {
        offset = 0,
        scale = 0.5,
        spread = {x = 25, y = 25, z = 25},
        seed = 55647,
        octaves = 3,
        persist = 0.6,
   },
    manganese = {
        offset = 0,
        scale = 0.5,
        spread = {x = 22, y = 22, z = 22},
        seed = 64738,
        octaves = 3,
        persist = 0.6,
   },
    chromium = {
        offset = 0,
        scale = 0.5,
        spread = {x = 20, y = 20, z = 20},
        seed = 73829,
        octaves = 3,
        persist = 0.6,
   }
}
-- FUNÇÃO PARA VERIFICAR SE DEVE GERAR MINÉRIO
local function check_ore(x, y, z, perlin_ore, threshold, min_y, max_y)
    -- Verifica se está na faixa de altura correta
    if y < min_y or y > max_y then return false end
    -- Noise 3D para criar veios
    local ore_noise = perlin_ore:get_3d({x = x, y = y, z = z})
    -- Normaliza para 0-1
    local ore_value = (ore_noise + 1) / 2
    -- Se o valor for maior que o threshold, gera o minério
    return ore_value > threshold
end
-- FUNÇÃO PARA VERIFICAR SE HÁ ESPAÇO PARA A ÁRVORE
local function can_place_tree(area, data, pos, radius)
    -- Verifica se há espaço ao redor da base da árvore
    for dx = -radius, radius do
        for dz = -radius, radius do
            local check_x = pos.x + dx
            local check_z = pos.z + dz
            -- Verifica se a posição está dentro do chunk
            if area:contains(check_x, pos.y, check_z) then
                local vi = area:index(check_x, pos.y, check_z)
                -- Se já tem madeira ou folhas, não pode colocar
                if data[vi] == C.oaktimber or data[vi] == C.leaves or data[vi] == C.palmtimber or data[vi] == C.palmleaf then return false end
            end
        end
    end
    return true
end
-- FUNÇÃO DE SPAWN DE COQUEIRO
local function spawn_palm_tree(area, data, pos, wx, wz)
    -- Verifica se há espaço
    if not can_place_tree(area, data, pos, 3) then return end
    -- Verifica se há areia abaixo do ponto de spawn
    local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    if area:contains(below_pos.x, below_pos.y, below_pos.z) then
        local vi_below = area:index(below_pos.x, below_pos.y, below_pos.z)
        -- Cancela se não tiver areia embaixo
        if data[vi_below] ~= C.sand then return end
    else
        return -- Cancela se a posição abaixo não está no chunk
    end
    -- RNG determinístico por posição
    local seed = wx * 55555 + wz * 88888
    local rng = PseudoRandom(seed)
    -- Altura do tronco: 6 a 9 blocos
    local height = rng:next(6, 9)
    --  TRONCO
    for y = 0, height do
        local check_pos = table_xyz(pos.x,pos.y + y,pos.z)
        if area:contains(check_pos.x, check_pos.y, check_pos.z) then
            local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
            if data[vi] == C.air then
                -- Na altura dos cocos (bottom_layer - 1 = pos.y + height), usa C.palmstraws
                if y == height then data[vi] = C.palmstraws else data[vi] = C.palmtimber end
            end
        end
    end
    --  PALMLEAFSTALKS NO TOPO DO TRONCO
    local stalk_pos = table_xyz(pos.x,pos.y + height + 1, pos.z)
    if area:contains(stalk_pos.x, stalk_pos.y, stalk_pos.z) then
        local vi = area:index(stalk_pos.x, stalk_pos.y, stalk_pos.z)
        if data[vi] == C.air then data[vi] = C.palmleafstalks end
    end
    -- Camadas das folhas
    local bottom_layer = pos.y + height + 1
    local top_layer    = pos.y + height + 2
    -- Direções em cruz
    local directions   = {
        {x = 0,  z = -1, rotation = 0}, -- Norte
        {x = 1,  z = 0,  rotation = 1}, -- Leste
        {x = 0,  z = 1,  rotation = 2}, -- Sul
        {x = -1, z = 0,  rotation = 3}, -- Oeste
   }
    -- Registro opcional de folhas (se você realmente usa isso depois)
    local leaf_nodes   
    --  FOLHAS EM CRUZ - CAMADA INFERIOR
    for _, dir in ipairs(directions) do
        for i = 1, 3 do
            local leaf_pos = {x = pos.x + dir.x * i, y = bottom_layer, z = pos.z + dir.z * i}
            if not area:contains(leaf_pos.x, leaf_pos.y, leaf_pos.z) then break end
            local vi = area:index(leaf_pos.x, leaf_pos.y, leaf_pos.z)
            -- SE NÃO FOR AR → PARA ESSA DIREÇÃO
            if data[vi] ~= C.air then break end
            -- Caso contrário, coloca a folha
            data[vi] = C.palmleaf
            table.insert(leaf_nodes,
                {pos = {x = leaf_pos.x, y = leaf_pos.y, z = leaf_pos.z}, rotation = dir.rotation})
        end
    end
    --  FOLHAS EM CRUZ - CAMADA SUPERIOR
    for _, dir in ipairs(directions) do
        for i = 1, 2 do
            local leaf_pos = {x = pos.x + dir.x * i, y = top_layer, z = pos.z + dir.z * i}
            if not area:contains(leaf_pos.x, leaf_pos.y, leaf_pos.z) then break end
            local vi = area:index(leaf_pos.x, leaf_pos.y, leaf_pos.z)
            if data[vi] ~= C.air then break end
            data[vi] = C.palmleaf
            table.insert(leaf_nodes,
                {pos = {x = leaf_pos.x, y = leaf_pos.y, z = leaf_pos.z}, rotation = dir.rotation})
        end
    end

    --  COCOS (0 a 4 aleatórios)
    local num_coconuts = rng:next(0, 4)

    -- Posições possíveis para cocos (embaixo das folhas da camada inferior)
    local possible_positions = {
        {x = pos.x + 1, y = bottom_layer - 1, z = pos.z,     rotation = 1}, -- Leste
        {x = pos.x - 1, y = bottom_layer - 1, z = pos.z,     rotation = 3}, -- Oeste
        {x = pos.x,     y = bottom_layer - 1, z = pos.z + 1, rotation = 0}, -- Sul
        {x = pos.x,     y = bottom_layer - 1, z = pos.z - 1, rotation = 2}, -- Norte
   }
    -- Embaralha as posições
    for i = #possible_positions, 2, -1 do
        local j = rng:next(1, i)
        possible_positions[i], possible_positions[j] = possible_positions[j], possible_positions[i]
    end
    -- Coloca os cocos
    for i = 1, math.min(num_coconuts, #possible_positions) do
        local coco_pos = possible_positions[i]
        if area:contains(coco_pos.x, coco_pos.y, coco_pos.z) then
            local vi = area:index(coco_pos.x, coco_pos.y, coco_pos.z)
            if data[vi] == C.air then
                data[vi] = C.coconut
                table.insert(leaf_nodes,
                    {pos = {x = coco_pos.x, y = coco_pos.y, z = coco_pos.z}, rotation = coco_pos.rotation})
            end
        end
    end
    -- Retorna lista de folhas para rotacionar depois (via core.set_node)
    return leaf_nodes
end
-- FUNÇÃO DE SPAWN DE ARBUSTO (só folhas)
local function spawn_bush(area, data, pos, wx, wz)
    -- Verifica se há espaço (raio menor que árvores)
    -- Cancela se estiver muito perto
    if not can_place_tree(area, data, pos, 2) then return end
    -- RNG determinístico por posição (seed diferente das árvores)
    local seed = wx * 91823 + wz * 45678
    local rng = PseudoRandom(seed)
    -- Altura do arbusto: 1 ou 2 blocos
    local height = rng:next(1, 2)
    -- Raio do arbusto: 1 a 3 blocos
    local radius = rng:next(1, 3)
    -- Contador para limitar substituições especiais
    local max_swaps = 2
    local swaps = 0
    --  GERA ARBUSTO ESFÉRICO
    for y = 0, height do
        for dx = -radius, radius do
            for dz = -radius, radius do
                -- Calcula distância do centro (formato mais orgânico)
                local dist = (dx * dx + (y * 0.8) * (y * 0.8) + dz * dz) --local dist = math.sqrt(dx * dx + (y * 0.8) * (y * 0.8) + dz * dz)
                -- Adiciona aleatoriedade nas bordas
                local randomness = rng:next(-10, 10) / 20.0              -- -0.5 a +0.5
                -- Se estiver dentro do raio (com variação)
                if dist <= (radius + randomness) * (radius + randomness) then
                    local check_pos = {x = pos.x + dx, y = pos.y + y, z = pos.z + dz}
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                        -- Só substitui ar
                        if data[vi] == C.air then
                            data[vi] = C.blueberryleaves
                            -- Chance de substituir por folhas com blueberry
                            if swaps < max_swaps then
                                local r = rng:next(1, 100) -- 1 a 100
                                -- Distribuição enviesada:
                                if r < 0.10 then           -- 10% de chance
                                    data[vi] = C.leavesblueberry4
                                    swaps = swaps + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
-- FUNÇÃO DE SPAWN DE CARVALHO (com variação de tronco)
local function spawn_tree(area, data, param2_data, pos, wx, wz)
    -- Verifica se há espaço (raio de 5 blocos)
    -- Cancela a geração se estiver muito perto de outra árvore
    if not can_place_tree(area, data, pos, 5) then return end
    -- VERIFICAÇÃO: Verifica se há grama abaixo do ponto de spawn ***
    local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    if area:contains(below_pos.x, below_pos.y, below_pos.z) then
        local vi_below = area:index(below_pos.x, below_pos.y, below_pos.z)
        -- Cancela se não tiver grama embaixo
        if data[vi_below] ~= C.topgrass and data[vi_below] ~= C.grass then return end
    else
        return -- Cancela se a posição abaixo não está no chunk
    end
    -- RNG determinístico por posição
    local seed = wx * 73856093 + wz * 19349663
    local rng = PseudoRandom(seed)
    local height = rng:next(6, 9)
    local crown_radius = rng:next(3, 4)
    --  DETERMINA TAMANHO DO TRONCO
    local trunk_type = rng:next(2, 4) -- Sorteava entre 1 e 4
    local trunk_dx, trunk_dz
    if trunk_type == 1 then
        -- 1x1 (tronco único)
        trunk_dx = 0
        trunk_dz = 0
    elseif trunk_type == 2 then
        -- 2x1 (retangular horizontal)
        trunk_dx = 1
        trunk_dz = 0
    elseif trunk_type == 3 then
        -- 1x2 (retangular vertical)
        trunk_dx = 0
        trunk_dz = 1
    else
        -- 2x2 (quadrado)
        trunk_dx = 1
        trunk_dz = 1
    end
    --  RAIZ SUBTERRÂNEA (1 camada abaixo do solo)
    for dx = 0, trunk_dx do
        for dz = 0, trunk_dz do
            local root_pos = {x = pos.x + dx, y = pos.y - 1, z = pos.z + dz}
            if area:contains(root_pos.x, root_pos.y, root_pos.z) then
                local vi = area:index(root_pos.x, root_pos.y, root_pos.z)
                -- Substitui qualquer node de terreno pelo tronco
                data[vi] = C.oaktimber
            end
        end
    end
    --  TRONCO (tamanho variável)
    for y = 0, height do
        for dx = 0, trunk_dx do
            for dz = 0, trunk_dz do
                local check_pos = {x = pos.x + dx, y = pos.y + y, z = pos.z + dz}
                if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                    local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                    -- Só substitui ar ou folhas
                    if data[vi] == C.air or data[vi] == C.leaves then data[vi] = C.oaktimber end
                end
            end
        end
    end
    --  COPA (esférica)
    local max_swaps = 3
    local swaps = 0
    local top = pos.y + height
    -- Ajusta centro da copa para troncos maiores
    local copa_center_x = pos.x + (trunk_dx / 2)
    local copa_center_z = pos.z + (trunk_dz / 2)
    for dy = -2, 3 do
        for dx = -crown_radius, crown_radius do
            for dz = -crown_radius, crown_radius do
                local dist = (dx * dx + dy * dy + dz * dz) -- local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist <= (crown_radius + 0.5) * (crown_radius + 0.5) then
                    local check_pos = {
                        x = math.floor(copa_center_x + dx),
                        y = top + dy,
                        z = math.floor(copa_center_z + dz)
                   }
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                        if data[vi] == C.air then
                            data[vi] = C.leaves
                            -- Chance de substituir por folhas especiais
                            -- (mais pressão para NÃO trocar → distribuição enviesada)
                            if swaps < max_swaps then
                                local r = rng:next(1, 1000) / 1000.0 -- Gera 0.0 a 1.0
                                -- Distribuição enviesada:
                                -- 70% = não troca
                                -- 20% = troca muito rara
                                -- 10% = troca rara
                                if r < 0.05 then
                                    data[vi] = C.leaves_nut
                                    swaps = swaps + 1
                                elseif r < 0.1 then
                                    data[vi] = C.leaves_nut2
                                    swaps = swaps + 1
                                elseif r < 0.15 then
                                    data[vi] = C.leaves_nut3
                                    swaps = swaps + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Folha no topo (centralizada)
    local top_x = math.floor(copa_center_x)
    local top_z = math.floor(copa_center_z)
    if area:contains(top_x, top + 3, top_z) then
        local vi_top = area:index(top_x, top + 3, top_z)
        if data[vi_top] == C.air then data[vi_top] = C.leaves end
    end
    --  LEAVESRELIEF (detalhes dentro da copa)
    for dy = -2, 3 do
        for dx = -crown_radius, crown_radius do
            for dz = -crown_radius, crown_radius do
                local dist = (dx * dx + dy * dy + dz * dz)
                if dist <= (crown_radius + 0.5) * (crown_radius + 0.5) then
                    local check_pos = {
                        x = math.floor(copa_center_x + dx),
                        y = top + dy,
                        z = math.floor(copa_center_z + dz)
                   }
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi       = area:index(check_pos.x, check_pos.y, check_pos.z)
                        local vi_above = area:index(check_pos.x, check_pos.y + 1, check_pos.z)
                        -- O node BASE precisa ser folha, e o de CIMA também folha (age como "líquido")
                        if data[vi] == C.leaves and data[vi_above] == C.leaves then
                            local r = rng:next(1, 100)
                            if r <= 20 then -- 20% de chance por bloco
                                data[vi] = C.leavesrelief
                                -- param2 = altura visual (quantos blocos sobe)
                                -- 16 = 1 bloco, 32 = 2 blocos
                                param2_data[vi] = 16
                            end
                        end
                    end
                end
            end
        end
    end
    --  GALHOS CARDEAIS (na menor altura da copa)
    local branch_y = top - 2 -- Menor altura onde folhas aparecem (dy = -2)
    local branch_center_x = math.floor(copa_center_x)
    local branch_center_z = math.floor(copa_center_z)
    -- param2 facedir: Sul=0, Oeste=1, Norte=2, Leste=3
    local branch_dirs = {
        {dx = 0,  dz = -1, param2 = 0}, -- Norte  (aponta para sul)
        {dx = 0,  dz = 1,  param2 = 2}, -- Sul    (aponta para norte)
        {dx = -1, dz = 0,  param2 = 3}, -- Oeste  (aponta para leste)
        {dx = 1,  dz = 0,  param2 = 1}, -- Leste  (aponta para oeste)
   }
    for _, dir in ipairs(branch_dirs) do
        local bx = branch_center_x + dir.dx
        local bz = branch_center_z + dir.dz
        local by = branch_y

        if area:contains(bx, by, bz) then
            local vi = area:index(bx, by, bz)
            -- Substitui folha ou ar (não sobrescreve tronco)
            if data[vi] == C.leaves or data[vi] == C.leaves_nut or
                data[vi] == C.leaves_nut2 or data[vi] == C.leaves_nut3 or
                data[vi] == C.air then
                data[vi] = C.oakbranch
                -- param2 requer a tabela de param2 separada
                -- (assumindo que vm:set_param2 ou param2_data existe no seu contexto)
                param2_data[vi] = dir.param2
            end
        end
    end
    --  FALLEN STICK (50% de chance)
    --if math.random() < 0.40 then
    local rng_stick = PseudoRandom(wx * 12345 + wz * 67890)
    if rng_stick:next(1, 1000) <= 400 then -- 40% = 400/1000
        local attempts = 0
        local max_attempts = 10            -- Mais tentativas para encontrar chão válido (era 50 por arvore)
        while attempts < max_attempts do
            -- Gera posição aleatória em um raio maior (incluindo área além da copa)
            local stick_dx = rng_stick:next(-crown_radius - 2, crown_radius + 2)
            local stick_dz = rng_stick:next(-crown_radius - 2, crown_radius + 2)
            local stick_x = math.floor(copa_center_x + stick_dx)
            local stick_z = math.floor(copa_center_z + stick_dz)
            -- Busca o chão real descendo a partir da altura da árvore
            local found_ground = false
            local ground_y = nil
            -- Desce a partir do topo da árvore até alguns blocos abaixo da base
            for y = pos.y + height, pos.y - 5, -1 do
                if area:contains(stick_x, y, stick_z) and
                    area:contains(stick_x, y + 1, stick_z) then
                    local vi_ground = area:index(stick_x, y, stick_z)
                    local vi_above = area:index(stick_x, y + 1, stick_z)
                    -- Verifica se encontrou um bloco sólido válido com ar acima
                    if (data[vi_ground] == C.topgrass or
                            data[vi_ground] == C.grass or
                            data[vi_ground] == C.dirt) and
                        (data[vi_above] == C.air or data[vi_above] == C.grassleaves) then
                        ground_y = y + 1 -- Posição do graveto (1 bloco acima do chão)
                        found_ground = true
                        break
                    end
                end
            end
            -- Se encontrou um chão válido, coloca o graveto
            if found_ground and ground_y then
                local vi_stick = area:index(stick_x, ground_y, stick_z)
                data[vi_stick] = C.fallenstick
                break -- Graveto colocado com sucesso!
            end
            attempts = attempts + 1
        end
    end
    --]]--
end
-- FUNÇÃO DE SPAWN DE PINHEIRO
local function spawn_pine_tree(area, data, pos, wx, wz)
    -- Verifica se há espaço (raio de 4 blocos)
    if not can_place_tree(area, data, pos, 4) then return end
    -- RNG determinístico por posição
    local seed = wx * 73856093 + wz * 19349663
    local rng = PseudoRandom(seed)
    local height = rng:next(8, 12) -- Pinheiros mais altos
    --  RAIZ SUBTERRÂNEA (1 camada abaixo do solo)
    local pine_root_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    if area:contains(pine_root_pos.x, pine_root_pos.y, pine_root_pos.z) then
        local vi = area:index(pine_root_pos.x, pine_root_pos.y, pine_root_pos.z)
        -- Substitui qualquer node de terreno pelo tronco
        data[vi] = C.pinetimber
    end
    --  TRONCO (sempre 1x1)
    for y = 0, height do
        local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
        if area:contains(check_pos.x, check_pos.y, check_pos.z) then
            local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
            if data[vi] == C.air or data[vi] == C.pineleaves then data[vi] = C.pinetimber end
        end
    end
    --  COPA CÔNICA (base mais baixa)
    local top           = pos.y + height
    local canopy_start  = pos.y + math.floor(height * 0.25) -- começa mais baixo
    local canopy_end    = top + 3                           -- estende acima do topo
    local canopy_height = canopy_end - canopy_start
    local max_radius    = 4
    for y = canopy_end, canopy_start, -1 do
        local layer = canopy_end - y
        local t = layer / canopy_height -- 0 no topo, 1 na base
        -- Raio cresce suavemente para baixo
        local radius = math.floor(t * max_radius)
        if radius < 1 then radius = 1 end
        for dx = -radius, radius do
            for dz = -radius, radius do
                local dist = (dx * dx + dz * dz) --local dist = math.sqrt(dx * dx + dz * dz)
                -- Cone mais fechado no topo
                local limit = radius - (1 - t) * 0.25
                -- Irregularidade leve
                local noise = rng:next(0, 100) / 350
                if dist <= (limit + noise) * (limit + noise) then
                    local check_pos = {x = pos.x + dx, y = y, z = pos.z + dz}
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                        if data[vi] == C.air then data[vi] = C.pineleaves end
                    end
                end
            end
        end
    end
end
-- FUNÇÃO DE SPAWN DE MACIEIRA
local function spawn_apple_tree(area, data, pos, wx, wz)
    -- Verifica se há espaço (raio de 4 blocos)
    if not can_place_tree(area, data, pos, 4) then return end
    -- VERIFICAÇÃO: Verifica se há dirt abaixo do ponto de spawn ***
    local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    if area:contains(below_pos.x, below_pos.y, below_pos.z) then
        local vi_below = area:index(below_pos.x, below_pos.y, below_pos.z)
        -- Cancela se não tiver grama embaixo
        if data[vi_below] ~= C.dirt then return end
    else
        return -- Cancela se a posição abaixo não está no chunk
    end
    -- RNG determinístico por posição
    local seed = wx * 73856093 + wz * 19349663
    local rng = PseudoRandom(seed)
    local height = rng:next(3, 6) -- macieiras mais altos
    --  TRONCO (sempre 1x1)
    for y = 0, height do
        local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
        if area:contains(check_pos.x, check_pos.y, check_pos.z) then
            local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
            if data[vi] == C.air or data[vi] == C.appleleaves then data[vi] = C.appletimber end
        end
    end
    --  COPA (esférica)
    local max_swaps = 3
    local swaps = 0
    local top = pos.y + height
    -- Ajusta centro da copa para troncos maiores
    local copa_center_x = pos.x
    local copa_center_z = pos.z
    local crown_radius = rng:next(1, 2)
    for dy = -2, 3 do
        for dx = -crown_radius, crown_radius do
            for dz = -crown_radius, crown_radius do
                local dist = (dx * dx + dy * dy + dz * dz) --local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist <= (crown_radius + 0.5) * (crown_radius + 0.5) then
                    local check_pos = {
                        x = math.floor(copa_center_x + dx),
                        y = top + dy,
                        z = math.floor(copa_center_z + dz)
                   }
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                        if data[vi] == C.air then
                            data[vi] = C.appleleaves
                            -- Chance de substituir por folhas especiais
                            -- (mais pressão para NÃO trocar → distribuição enviesada)
                            if swaps < max_swaps then
                                local r = rng:next(1, 100) -- 1 a 100
                                -- Distribuição enviesada:
                                if r < 5 then              -- 5%
                                    data[vi] = C.leavesapple3
                                    swaps = swaps + 1
                                elseif r < 10 then -- 10%
                                    data[vi] = C.leavesapple2
                                    swaps = swaps + 1
                                elseif r < 15 then -- 15%
                                    data[vi] = C.leavesapple
                                    swaps = swaps + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Folha no topo (centralizada)
    local top_x = math.floor(copa_center_x)
    local top_z = math.floor(copa_center_z)
    if area:contains(top_x, top + 2, top_z) then
        local vi_top = area:index(top_x, top + 2, top_z)
        if data[vi_top] == C.air then data[vi_top] = C.leavesapple end
    end
end

-- FUNÇÃO DE CÁLCULO DE ALTURA (OTIMIZADA COM ARRAYS)
local MAX_TERRAIN_Y = 80
local function calculate_height_batch(minp, maxp, SEA_LEVEL, CENTER_X, CENTER_Z, MAX_RADIUS, continent_2d, biome_2d,
                                      mountain_2d, hills_2d, plains_2d, rough_2d)
    local heights 
    local biome_factors 
    local sidelen = maxp.x - minp.x + 1
    local index = 1
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- Coordenadas toroidais
            local wx = ((x - MIN_XZ) % SIZE) + MIN_XZ
            local wz = ((z - MIN_XZ) % SIZE) + MIN_XZ
            -- Distância do centro
            local dx = wx - CENTER_X
            local dz = wz - CENTER_Z
            local dist_from_center_sq = dx * dx + dz * dz -- quadrado
            local MAX_RADIUS_SQ = MAX_RADIUS * MAX_RADIUS
            -- Fator continental (normalizado de 0 a 1)
            local continent_factor = math.max(0, 1.0 - (dist_from_center_sq / MAX_RADIUS_SQ))
            -- FORÇAR bordas a serem oceano
            -- Quando dist > 0.85 * MAX_RADIUS, começar a afundar drasticamente
            local edge_threshold = MAX_RADIUS * 0.5 -- fator de terra firme: até 30% do raio
            local edge_threshold_sq = edge_threshold * edge_threshold
            if dist_from_center_sq > edge_threshold_sq then
                local edge_factor = (dist_from_center_sq - edge_threshold_sq) / (MAX_RADIUS_SQ - edge_threshold_sq)
                continent_factor = continent_factor * (1.0 - edge_factor * 0.8)
            end
            -- Fator continental dos noise maps (já normalizados)
            local cont_noise = (continent_2d[index] + 1) / 2
            local continent_lands = math.pow(cont_noise, 1.8)
            -- Bioma
            local biome_noise = biome_2d[index]
            local biome_factor = (biome_noise + 1) / 2
            -- Noises já normalizados
            local mountain_noise = mountain_2d[index]
            local hills_noise = hills_2d[index]
            local plains_noise = plains_2d[index]
            local rough_noise = rough_2d[index]
            local mn = (mountain_noise + 1) / 2
            local hn = (hills_noise + 1) / 2
            local pn = (plains_noise + 1) / 2
            local rn = (rough_noise + 1) / 2
            local cl = continent_lands
            -- Mistura baseada no bioma
            local terrain_height
            if biome_factor > 0.7 then
                local mountain_weight = (biome_factor - 0.6) / 0.4
                terrain_height = (mn * 0.5 + hn * 0.3 + rn * 0.2 + cl * 0.3) * (1.0 + mountain_weight)
            elseif biome_factor < 0.3 then
                local plains_weight = (0.4 - biome_factor) / 0.4
                terrain_height = (pn * 0.7 + rn * 0.3 + cl * 0.2) * (0.3 + plains_weight * 0.25)
            else
                terrain_height = hn * 0.6 + pn * 0.2 + rn * 0.2 + cl * 0.1
            end
            -- Aplica fator continental
            local final_height = terrain_height * continent_factor
            local height = math.floor(final_height * 65 + SEA_LEVEL - 19)
            -- Limites
            if height > MAX_TERRAIN_Y then height = MAX_TERRAIN_Y end
            if height < -20 then height = -20 end
            heights[index] = height
            biome_factors[index] = biome_factor
            index = index + 1
        end
    end
    return heights, biome_factors
end
-- FUNÇÃO PARA VERIFICAR SE É CAVERNA (OTIMIZADA COM ARRAYS 3D)
local function is_cave_lava_batch(x, y, z, cave_lava_3d, cave_size_3d, area, minp)
    -- Apenas gera cavernas na camada de gneiss (ajustado conforme a minha lógica)
    if y > 23 or y < -37 then return false end
    -- Calcula índice no array 3D
    local vi = area:index(x, y, z)
    -- Noise 3D principal para cavernas
    local cave_noise = cave_lava_3d[vi]
    -- Noise para variar o tamanho das cavernas
    local size_noise = cave_size_3d[vi]
    local size_factor = (size_noise + 1) / 2 -- Normaliza para 0-1
    -- Threshold dinâmico: ajusta a "abertura" das cavernas
    -- Valores menores = cavernas maiores
    -- Valores maiores = cavernas menores/raras
    local threshold = 0.6 + (size_factor * 0.7) -- Varia entre 0.6 e 0.8
    -- Se o noise absoluto for maior que o threshold, é caverna
    return math.abs(cave_noise) > threshold
end
local function is_cave_water_batch(x, y, z, cave_water_3d, cave_size_3d, area, minp)
    -- Apenas gera cavernas na camada de gneiss (ajustado conforme a minha lógica)
    if y > 23 or y < -37 then return false end
    -- Calcula índice no array 3D
    local vi = area:index(x, y, z)
    -- Noise 3D principal para cavernas
    local cave_noise = cave_water_3d[vi]
    -- Noise para variar o tamanho das cavernas
    local size_noise = cave_size_3d[vi]
    local size_factor = (size_noise + 1) / 2 -- Normaliza para 0-1
    -- Threshold dinâmico: ajusta a "abertura" das cavernas
    -- Valores menores = cavernas maiores
    -- Valores maiores = cavernas menores/raras
    local threshold = 0.6 + (size_factor * 0.5) -- Varia entre 0.6 e 0.8
    -- Se o noise absoluto for maior que o threshold, é caverna
    return math.abs(cave_noise) > threshold
end
local function is_cave_batch(x, y, z, cave_3d, cave_size_3d, area, minp)
    -- Apenas gera cavernas na camada de gneiss (ajustado conforme a minha lógica)
    if y > 23 or y < -37 then return false end
    -- Calcula índice no array 3D
    local vi = area:index(x, y, z)
    -- Noise 3D principal para cavernas
    local cave_noise = cave_3d[vi]
    -- Noise para variar o tamanho das cavernas
    local size_noise = cave_size_3d[vi]
    local size_factor = (size_noise + 1) / 2 -- Normaliza para 0-1
    -- Threshold dinâmico: ajusta a "abertura" das cavernas
    -- Valores menores = cavernas maiores
    -- Valores maiores = cavernas menores/raras
    local threshold = 0.6 + (size_factor * 0.2) -- Varia entre 0.6 e 0.8
    -- Se o noise absoluto for maior que o threshold, é caverna
    return math.abs(cave_noise) > threshold
end
-- Modelo da tenda de coqueiro
local function can_spawn_tent(area, data, base_pos)
    local width = 4
    local depth = 5
    local height = 4 -- 3 troncos + teto
    -- chão: areia molhada
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            local vi = area:index(base_pos.x + dx, base_pos.y - 1, base_pos.z + dz)
            if data[vi] ~= C.wetsand then return false end
        end
    end
    -- volume livre
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            for dy = 0, height do
                local vi = area:index(base_pos.x + dx, base_pos.y + dy, base_pos.z + dz)
                if data[vi] ~= C.air then return false end
            end
        end
    end
    return true
end
local function spawn_tent(area, data, base_pos)
    local width = 4
    local depth = 5
    local trunk_height = 3
    local roof_y = base_pos.y + trunk_height
    local corners = {{0, 0}, {3, 0}, {0, 4}, {3, 4},}
    -- troncos
    for _, c in ipairs(corners) do
        for y = 0, trunk_height - 1 do
            data[area:index(base_pos.x + c[1], base_pos.y + y, base_pos.z + c[2])] = C.palmtimber
        end
    end
    -- teto
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            data[area:index(base_pos.x + dx, roof_y, base_pos.z + dz)] = C.palmstraw
        end
    end
end
-- Modelo do navio afundado
local function can_spawn_ship(area, data, base_pos)
    local width = 4
    local depth = 8
    local height = 4 -- 3 blocs paredes + teto
    -- chão: areia molhada
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            local vi = area:index(base_pos.x + dx, base_pos.y - 1, base_pos.z + dz)
            if data[vi] ~= C.wetsand then return false end
        end
    end
    -- volume livre
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            for dy = 0, height do
                local vi = area:index(base_pos.x + dx, base_pos.y + dy, base_pos.z + dz)
                if data[vi] ~= C.water then return false end
            end
        end
    end
    return true
end
--Barco
local function spawn_ship(area, data, base_pos)
    local width = 5
    local depth = 8
    local pillar_height = 3
    local roof_y = base_pos.y + pillar_height
    local corners = {{0, 0}, {width - 1, 0}, {0, depth - 1}, {width - 1, depth - 1},}
    -- conves
    for dx = -2, width + 1 do
        for dz = -3, depth + 3 do
            data[area:index(
                base_pos.x + dx,
                base_pos.y,
                base_pos.z + dz
            )] = C.oakwood
        end
    end
    -- teto
    for dx = 0, width - 1 do
        for dz = 0, depth - 3 do
            data[area:index(base_pos.x + dx, roof_y + 1, base_pos.z + dz)] = C.oakwood
        end
    end
    -- parede frontal janela (dz = 0)
    for dx = 0, width - 1 do
        for y = 0, pillar_height - 2 do
            data[area:index(base_pos.x + dx, base_pos.y + y, base_pos.z)] = C.oakwood
        end
    end
    -- parede traseira porta
    for dx = 0, width - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x + dx, base_pos.y + y, base_pos.z + depth - 3)] = C.oakwood
        end
    end
    -- porta traseira (gap em dx = width-2, dz = depth-3)
    local door_pos = {x = base_pos.x + width - 2, y = base_pos.y + 1, z = base_pos.z + depth - 3}
    core.after(0, function()
        -- confirma que o chão embaixo existe antes de colocar
        core.set_node(door_pos, {
            name   = "nh_nodes:oakdoor_closed", -- substitua pelo nome real do C.oakdoor
            param2 = 2                          -- rotação: 3 = virada para o sul (+Z), ajuste se precisar
       })
    end)
    -- parede lateral esquerda fechada (dx = 0)
    for dz = 0, depth - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x, base_pos.y + y, base_pos.z + dz)] = C.oakwood
        end
    end
    -- parede lateral direita fechada (dx = width-1)
    for dz = 0, depth - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x + width - 1, base_pos.y + y, base_pos.z + dz)] = C.oakwood
        end
    end
    -- parede do fundo (dz = depth-1) fica ABERTA — entrada da cabine
end
local function place_tent_chest(area, data, base_pos)
    local candidates 
    for dx = 1, 2 do
        for dz = 1, 3 do table.insert(candidates, {dx = dx, dz = dz}) end
    end
    if #candidates == 0 then return end
    local rng_chest = PseudoRandom(base_pos.x * 11111 + base_pos.z * 22222)
    local idx = rng_chest:next(1, #candidates)
    local c = candidates[idx]
    local chest_pos = {x = base_pos.x + c.dx, y = base_pos.y, z = base_pos.z + c.dz}
    -- Passa chest_pos como argumento ao core.after para evitar
    -- condição de corrida entre threads de emerge paralelos
    core.after(0, function(pos)
        core.set_node(pos, {name = "nh_nodes:oak_chest", param2 = 2})
        local def = core.registered_nodes["nh_nodes:oak_chest"]
        if def and def.on_construct then def.on_construct(pos) end
    end, chest_pos)
end
local function safe_index(area, x, y, z, minp, maxp)
    if x < minp.x or x > maxp.x or y < minp.y or y > maxp.y or z < minp.z or z > maxp.z then return nil end
    return area:index(x, y, z)
end
--Casa
-- Modelo da casa
local function can_spawn_house(area, data, base_pos)
    local width = 5
    local depth = 8
    local height = 5 -- pillar_height (3) + teto + margem
    -- chão: precisa ser C.grass ou C.topgrass diretamente abaixo
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            local vi_floor = area:index(base_pos.x + dx, base_pos.y - 1, base_pos.z + dz)
            local floor_node = data[vi_floor]
            if floor_node ~= C.grass and floor_node ~= C.topgrass then return false end
        end
    end
    -- volume acima deve ser apenas air, grassleaves ou grassleavesmedium
    local allowed = {
        [C.air]               = true,
        [C.grassleaves]       = true,
        [C.grassleavesmedium] = true,
   }
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            for dy = 0, height do
                local vi = area:index(base_pos.x + dx, base_pos.y + dy, base_pos.z + dz)
                if not allowed[data[vi]] then return false end
            end
        end
    end
    return true
end
local function spawn_house(area, data, base_pos)
    local width = 5
    local depth = 8
    local pillar_height = 3
    local roof_y = base_pos.y + pillar_height
    local corners = {{0, 0}, {width - 1, 0}, {0, depth - 1}, {width - 1, depth - 1},}
    -- piso
    for dx = -2, width + 1 do
        for dz = -2, depth - 1 do
            data[area:index(base_pos.x + dx, base_pos.y, base_pos.z + dz)] = C.oakwood
        end
    end
    -- teto
    for dx = 0, width + 1 do
        for dz = 0, depth - 1 do
            data[area:index(base_pos.x + dx - 1, roof_y + 1, base_pos.z + dz - 1)] = C.oakwood
        end
    end
    -- parede traseira (dz = 0)
    for dx = 0, width - 1 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x + dx, base_pos.y + y, base_pos.z)] = C.cobblestone
        end
    end
    -- parede frontal, da porta
    for dx = 0, width - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x + dx, base_pos.y + y, base_pos.z + depth - 3)] = C.cobblestone
        end
    end
    -- porta traseira (gap em dx = width-2, dz = depth-3)
    local door_pos = {x = base_pos.x + width - 2, y = base_pos.y + 1, z = base_pos.z + depth - 3}
    core.after(0, function()
        -- confirma que o chão embaixo existe antes de colocar
        core.set_node(door_pos, {
            name   = "nh_nodes:oakdoor_closed", -- substitua pelo nome real do C.oakdoor
            param2 = 2                          -- rotação: 3 = virada para o sul (+Z), ajuste se precisar
       })
    end)
    -- parede lateral esquerda fechada (dx = 0)
    for dz = 0, depth - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x, base_pos.y + y, base_pos.z + dz)] = C.cobblestone
        end
    end
    -- parede lateral direita fechada (dx = width-1)
    for dz = 0, depth - 3 do
        for y = 0, pillar_height do
            data[area:index(base_pos.x + width - 1, base_pos.y + y, base_pos.z + dz)] = C.cobblestone
        end
    end
    -- parede do fundo (dz = depth-1) fica ABERTA — entrada da cabine
end
local function place_ship_chest(area, data, base_pos)
    local candidates 
    for dx = 1, 2 do
        for dz = 1, 3 do table.insert(candidates, {dx = dx, dz = dz}) end
    end
    if #candidates == 0 then return end
    local rng_chest = PseudoRandom(base_pos.x * 11111 + base_pos.z * 22222)
    local idx = rng_chest:next(1, #candidates)
    local c = candidates[idx]
    local chest_pos = {x = base_pos.x + c.dx, y = base_pos.y, z = base_pos.z + c.dz}
    core.after(0, function(pos)
        core.set_node(pos, {name = "nh_nodes:oak_chest", param2 = 2})
        local def = core.registered_nodes["nh_nodes:oak_chest"]
        if def and def.on_construct then def.on_construct(pos) end
    end, chest_pos)
end
local function safe_index(area, x, y, z, minp, maxp)
    if x < minp.x or x > maxp.x or y < minp.y or y > maxp.y or z < minp.z or z > maxp.z then return nil end
    return area:index(x, y, z)
end
-- FUNÇÃO DE INICIALIZAÇÃO DOS PERLIN MAPS
local function init_perlin_maps()
    local gpl = core.get_perlin
    local gplm = core.get_perlin_map
    -- Já inicializados
    if biome then return end
    -- Mantém os perlins antigos para compatibilidade com funções que ainda os usam
    P.continent     = gpl(NOISE.continent)
    P.mountain      = gpl(NOISE.mountain)
    P.hills         = gpl(NOISE.hills)
    P.plains        = gpl(NOISE.plains)
    P.caves         = gpl(NOISE.caves)
    P.caves_lava    = gpl(NOISE.caves_lava)
    P.caves_water   = gpl(NOISE.caves_water)
    P.cave_size     = gpl(NOISE.cave_size)
    P.roughness     = gpl(NOISE.roughness)
    P.biome         = gpl(NOISE.biome)
    P.grassleaves   = gpl(NOISE.grassleaves)
    P.trees         = gpl(NOISE.trees)
    P.bushes        = gpl(NOISE.bushes)
    P.saprolite     = gpl(NOISE.saprolite)
    P.ore_master    = gpl(NOISE.ore_master)
    -- NOVOS PERLIN MAPS OTIMIZADOS
    local chunksize = {x = 80, y = 80, z = 80}
    PM.continent    = gplm(NOISE.continent, chunksize)
    PM.biome        = gplm(NOISE.biome, chunksize)
    PM.mountain     = gplm(NOISE.mountain, chunksize)
    PM.hills        = gplm(NOISE.hills, chunksize)
    PM.plains       = gplm(NOISE.plains, chunksize)
    PM.roughness    = gplm(NOISE.roughness, chunksize)
    PM.caves        = gplm(NOISE.caves, chunksize)
    PM.caves_lava   = gplm(NOISE.caves_lava, chunksize)
    PM.caves_water  = gplm(NOISE.caves_water, chunksize)
    PM.cave_size    = gplm(NOISE.cave_size, chunksize)
    PM.grassleaves  = gplm(NOISE.grassleaves, chunksize)
    PM.trees        = gplm(NOISE.trees, chunksize)
    PM.bushes       = gplm(NOISE.bushes, chunksize)
    PM.saprolite    = gplm(NOISE.saprolite, chunksize)
    PM.ore_master   = gplm(NOISE.ore_master, chunksize)
end
core.log("action", "[terrain] Perlin and Perlin Maps initialized")
-- FUNÇÃO DE GERAÇÃO DOS NOISE MAPS EM BATCH
local function generate_noise_maps(minp, maxp)
    local minposxz = {x = minp.x, y = minp.z}
    -- Noise maps 2D (para altura do terreno)
    local continent_2d = PM.continent:get_2d_map_flat(minposxz)
    local biome_2d = PM.biome:get_2d_map_flat(minposxz)
    local mountain_2d = PM.mountain:get_2d_map_flat(minposxz)
    local hills_2d = PM.hills:get_2d_map_flat(minposxz)
    local plains_2d = PM.plains:get_2d_map_flat(minposxz)
    local rough_2d = PM.roughness:get_2d_map_flat(minposxz)
    local grassleaves_2d = PM.grassleaves:get_2d_map_flat(minposxz)
    local trees_2d = PM.trees:get_2d_map_flat(minposxz)
    local bushes_2d = PM.bushes:get_2d_map_flat(minposxz)
    -- Noise maps 3D (para cavernas e minérios)
    local caves_3d = PM.caves:get_3d_map_flat(minp)
    local caves_lava_3d = PM.caves_lava:get_3d_map_flat(minp)
    local caves_water_3d = PM.caves_water:get_3d_map_flat(minp)
    local cave_size_3d = PM.cave_size:get_3d_map_flat(minp)
    local saprolite_3d = PM.saprolite:get_3d_map_flat(minp)
    local ore_master_3d = PM.ore_master:get_3d_map_flat(minp)

    return {-- 2D maps
        continent_2d = continent_2d,
        biome_2d = biome_2d,
        mountain_2d = mountain_2d,
        hills_2d = hills_2d,
        plains_2d = plains_2d,
        rough_2d = rough_2d,
        grassleaves_2d = grassleaves_2d,
        trees_2d = trees_2d,
        bushes_2d = bushes_2d,
        -- 3D maps
        caves_3d = caves_3d,
        caves_lava_3d = caves_lava_3d,
        caves_water_3d = caves_water_3d,
        cave_size_3d = cave_size_3d,
        saprolite_3d = saprolite_3d,
        ore_master_3d = ore_master_3d,
   }
end
-- FUNÇÃO AUXILIAR: EPICENTROS DE NEVE
local SNOW_RADIUS = 350
local EPICENTER_NE = {x = MAX_XZ * 0.5, z = MAX_XZ * 0.5}
local EPICENTER_SW = {x = MIN_XZ * 0.5, z = MIN_XZ * 0.5}
local function inside_snow_area(x, z)
    local dx1 = x - EPICENTER_NE.x
    local dz1 = z - EPICENTER_NE.z
    local d1 = dx1 * dx1 + dz1 * dz1
    local dx2 = x - EPICENTER_SW.x
    local dz2 = z - EPICENTER_SW.z
    local d2 = dx2 * dx2 + dz2 * dz2
    return (d1 <= SNOW_RADIUS * SNOW_RADIUS) or (d2 <= SNOW_RADIUS * SNOW_RADIUS)
end
-- FUNÇÃO DE GERAÇÃO DO TERRENO BASE
local function generate_terrain_base(minp, maxp, area, data, heights, biome_factors, noise_maps)
    local SEA_LEVEL = 0
    local index_2d = 1
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local wx = ((x - MIN_XZ) % SIZE) + MIN_XZ
            local wz = ((z - MIN_XZ) % SIZE) + MIN_XZ
            -- ✅ RNG determinístico por coluna
            local rng_terrain = PseudoRandom(wx * 99991 + wz * 77773)
            local height = heights[index_2d]
            local biome_factor = biome_factors[index_2d]
            for y = math.max(minp.y, -50), math.min(maxp.y, MAX_TERRAIN_Y) do
                local vi = area:index(x, y, z)
                local is_snow_area = inside_snow_area(x, z)
                -- Pular blocos obviamente vazios acima do terreno
                if y > height + 10 then
                    data[vi] = C.air
                    goto skip_block
                end
                -- OTIMIZAÇÃO - CACHE DE CAVERNAS
                local is_cave = false
                local is_cave_lava = false
                local is_cave_water = false

                -- Só calcula se estiver na faixa de altura relevante
                if y > -37 and y <= 23 then
                    is_cave = is_cave_batch(x, y, z, noise_maps.caves_3d, noise_maps.cave_size_3d, area, minp)
                    is_cave_lava = is_cave_lava_batch(x, y, z, noise_maps.caves_lava_3d, noise_maps.cave_size_3d, area,
                        minp)
                    is_cave_water = is_cave_water_batch(x, y, z, noise_maps.caves_water_3d, noise_maps.cave_size_3d, area,
                        minp)
                end
                if y <= -50 then
                    data[vi] = C.redrock
                elseif y <= -48 then
                    data[vi] = C.peridotite
                elseif y <= -46 then
                    data[vi] = C.bedrock
                elseif y <= -43 then
                    data[vi] = C.peridotite
                elseif y <= -40 then
                    data[vi] = C.lava
                elseif y <= -35 then
                    data[vi] = C.basalt
                elseif y <= height - 7 then
                    -- Verifica caverna primeiro
                    if is_cave then
                        data[vi] = C.ignore
                        -- 5%
                        if y <= -34 and rng_terrain:next(1, 1000) <= 50 then data[vi] = C.obsidian end
                    elseif is_cave_lava then
                        data[vi] = C.ignore
                        if y < -30 then --and rng_terrain:next(1, 1000) <= 900 then  -- 90%
                            data[vi] = C.lava
                        end
                    elseif is_cave_water then
                        data[vi] = C.ignore
                        if y < -28 then --and rng_terrain:next(1, 1000) <= 900 then  -- 90%
                            data[vi] = C.water2
                        end
                    else
                        -- Gneiss e minérios
                        local node_type = C.gneiss
                        local ore_noise = noise_maps.ore_master_3d[vi]
                        if y > -10 and y < 5 and ore_noise > 0.85 then        -- 15% de chance
                            node_type = C.coal
                        elseif y > -20 and y < -10 and ore_noise > 0.88 then  --  (12% chance)
                            node_type = C.copper
                        elseif y > -25 and y <= -20 and ore_noise > 0.90 then -- 10% chance
                            node_type = C.tin
                        elseif y > -30 and y <= -25 and ore_noise > 0.92 then -- 8% chance
                            node_type = C.iron
                        elseif y > -32 and y <= -30 and ore_noise > 0.94 then -- 6% chance
                            node_type = C.nickel
                        elseif y > -33 and y <= -32 and ore_noise > 0.96 then -- 4% chance
                            node_type = C.manganese
                        elseif y > -35 and y <= -33 and ore_noise > 0.98 then -- 2% chance
                            node_type = C.chromium
                        end
                        data[vi] = node_type
                    end
                elseif y <= height - 4 then
                    -- Saprolite
                    local saprolite_2d_value = P.saprolite:get_2d({x = wx, y = wz})
                    local saprolite_thickness = math.floor((saprolite_2d_value + 1) * 1.5 + 0.5)
                    if y > height - 4 - saprolite_thickness then data[vi] = C.saprolite else data[vi] = C.gneiss end
                elseif y <= height - 1 then
                    if height <= SEA_LEVEL + 5 then data[vi] = C.sand else data[vi] = C.dirt end
                elseif y == height then
                    local is_mountain = (height > SEA_LEVEL + 8)
                    if is_mountain and is_snow_area then
                        data[vi] = C.snow
                    elseif height <= SEA_LEVEL then
                        data[vi] = C.wetsand
                        -- Propagar areia molhada para baixo
                        local by = y - 1
                        while by >= minp.y do
                            local bvi = area:index(x, by, z)
                            if data[bvi] == C.sand then
                                data[bvi] = C.wetsand
                                by = by - 1
                            else
                                break
                            end
                        end
                    elseif height <= SEA_LEVEL + 5 then
                        data[vi] = C.sand
                    elseif height <= SEA_LEVEL + 6 then
                        data[vi] = C.dirt
                    elseif height <= SEA_LEVEL + 7 then
                        data[vi] = C.topgrass
                    else
                        -- Porções aleatórias de dirt no lugar de topgrass
                        -- 0.5% de chance
                        if rng_terrain:next(1, 1000) <= 2 then data[vi] = C.dirt else data[vi] = C.topgrass end
                    end
                    --elseif y <= SEA_LEVEL and data[vi] == C.air then
                    --data[vi] = C.water
                else
                    data[vi] = C.air
                end
                ::skip_block::
            end

            -- Preenche com água todos os blocos de ar abaixo do nível do mar
            local is_snow_col = inside_snow_area(x, z)
            for y = math.max(minp.y, -50), SEA_LEVEL do
                local vi = area:index(x, y, z)
                if data[vi] == C.air then
                    -- Na área de neve, a camada superficial (y == SEA_LEVEL) vira gelo
                    -- usando o mesmo ruído de grassleaves para variação natural nas bordas
                    if is_snow_col and y == SEA_LEVEL and noise_maps.grassleaves_2d[index_2d] > 0.0 then
                        data[vi] = C.ice
                    else
                        data[vi] = C.water
                    end
                end
                -- Fireice sobre wet_sand entre y -19 e -16 (mesma área das ilhas)
                if y >= -19 and y <= -16 and x <= -500 and x >= -850 and z >= 500 and z <= 850 then
                    if data[vi] == C.water then
                        local bvi = area:index(x, y - 1, z)
                        if area:contains(x, y - 1, z) and data[bvi] == C.wetsand then
                            -- RNG determinístico por posição para esparsidade
                            local rng_fi = PseudoRandom(x * 73856093 + y * 19349663 + z * 83492791)
                            -- ~8% de chance
                            if rng_fi:next(1, 100) <= 1 then data[vi] = C.fireice end
                        end
                    end
                end
            end
            for y = math.max(minp.y, -50), math.min(maxp.y, height) do
                local vi = area:index(x, y, z)
                -- restaura o ar das cavernas
                if data[vi] == C.ignore then data[vi] = C.air end
            end
            index_2d = index_2d + 1
        end
    end
    return grass_positions
end

-- CONFIGURAÇÃO DA ILHA VULCÂNICA
local VOLCANO_RADIUS = 100 -- Raio da ilha
local VOLCANO_HEIGHT = 40  -- Altura do vulcão
local CRATER_RADIUS = 10   -- Raio da cratera
local CRATER_DEPTH = 70    -- Profundidade da cratera
local BEACH_WIDTH = 50     -- Largura da praia

-- Posição aleatória no oceano (será calculada uma vez)
local VOLCANO_POS = nil

-- FUNÇÃO PARA ENCONTRAR POSIÇÃO VÁLIDA PARA O VULCÃO
local function find_volcano_position()
    if VOLCANO_POS then return VOLCANO_POS end
    local CENTER_X = (MIN_XZ + MAX_XZ) / 2
    local CENTER_Z = (MIN_XZ + MAX_XZ) / 2
    local MAX_RADIUS = (SIZE / 2) * 0.85
    -- Define área onde o vulcão pode aparecer (no oceano, longe do centro e das bordas)
    local min_dist = MAX_RADIUS * 0.7  -- Mínimo 50% do raio (oceano profundo)
    local max_dist = MAX_RADIUS * 0.85 -- Máximo 75% do raio (antes das bordas)
    -- Gera posição aleatória
    local angle = math.random() * math.pi * 2
    local distance = min_dist + math.random() * (max_dist - min_dist)
    VOLCANO_POS = {x = CENTER_X + math.cos(angle) * distance, z = CENTER_Z + math.sin(angle) * distance}
    core.log("action", "[terrain] Volcano generated in: x=" .. VOLCANO_POS.x .. ", z=" .. VOLCANO_POS.z)
    return VOLCANO_POS
end
-- FUNÇÃO DE GERAÇÃO DA ILHA VULCÂNICA
local function generate_volcano(area, data, minp, maxp, volcano_pos)
    local SEA_LEVEL = 0
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- Calcula distância do centro do vulcão
            local dx = x - volcano_pos.x
            local dz = z - volcano_pos.z
            local dist_sq = dx * dx + dz * dz
            local dist = math.sqrt(dist_sq) -- calcular UMA vez
            local VOLCANO_RADIUS_SQ = VOLCANO_RADIUS * VOLCANO_RADIUS
            local rng_volcano = PseudoRandom(x * 13579 + z * 24680)
            -- Se está dentro do raio da ilha (vulcão)
            if dist_sq <= VOLCANO_RADIUS_SQ then
                local height_factor = 1.0 - (dist_sq / VOLCANO_RADIUS_SQ)
                -- Usar potência maior para cone mais íngreme (convexo)
                local base_height = math.floor(height_factor ^ 3 * VOLCANO_HEIGHT)
                -- Adiciona rugosidade à superfície
                local noise_x = x * 0.1
                local noise_z = z * 0.1
                local roughness = (P.roughness:get_2d({x = noise_x, y = noise_z}) + 1) * 2
                local volcano_height = SEA_LEVEL + base_height + math.floor(roughness)
                -- Determina se está na zona de praia (parte baixa do vulcão)
                local is_beach_zone = dist >= VOLCANO_RADIUS - BEACH_WIDTH
                -- Encontra o terreno oceânico existente neste ponto
                local ocean_floor_here = SEA_LEVEL
                for y = SEA_LEVEL, minp.y, -1 do
                    if area:contains(x, y, z) then
                        local vi = area:index(x, y, z)
                        if data[vi] ~= C.water and data[vi] ~= C.air then
                            ocean_floor_here = y
                            break
                        end
                    end
                end
                -- Calcula a base do cone a partir do chão oceânico real
                local total_cone_height = volcano_height - ocean_floor_here
                --  CRATERA (cálculo correto)
                local in_crater = dist <= CRATER_RADIUS
                local crater_factor = 1 - (dist / CRATER_RADIUS)
                if crater_factor < 0 then crater_factor = 0 end
                local crater_depth_here = (crater_factor ^ 3) * CRATER_DEPTH
                -- Fundo real da cratera neste ponto
                local crater_floor = volcano_height - crater_depth_here
                -- **COMEÇA DO CHÃO OCEÂNICO ATÉ O TOPO**
                for y = math.max(minp.y, ocean_floor_here), math.min(maxp.y, volcano_height + 10) do
                    if not area:contains(x, y, z) then goto continue_y end
                    local vi = area:index(x, y, z)
                    -- Calcula qual deveria ser o raio do cone nesta altura Y
                    local height_from_base = y - ocean_floor_here
                    local progress = height_from_base / total_cone_height -- 0 na base, 1 no topo
                    -- Cone mais íngreme: reduz raio mais rapidamente com a altura
                    local cone_radius_at_y = VOLCANO_RADIUS * (height_factor ^ 2) * (1.0 - progress ^ 1.5)
                    -- Verifica se estamos dentro do cone nesta altura
                    local inside_cone = dist <= cone_radius_at_y
                    -- CRATERA (tem prioridade máxima)
                    if in_crater and y >= crater_floor and y <= volcano_height then
                        -- Nível FIXO do lago de lava (horizontal)
                        local crater_center_floor = volcano_height - CRATER_DEPTH
                        local lava_level = crater_center_floor + 55
                        if y <= lava_level then data[vi] = C.lava else data[vi] = C.air end
                        -- INTERIOR DO CONE (sólido, mas só onde o cone existe)
                    elseif inside_cone and y < volcano_height - 3 then
                        -- Se está na zona de praia E submerso, usa areia
                        if is_beach_zone and y <= SEA_LEVEL then data[vi] = C.sand else data[vi] = C.basalt end
                        -- SUPERFÍCIE DO CONE
                    elseif inside_cone and y <= volcano_height then
                        -- Se está na zona de praia E perto do nível do mar, usa areia
                        if is_beach_zone and y <= SEA_LEVEL + 3 then
                            data[vi] = C.sand
                        else
                            -- 70%
                            if rng_volcano:next(1, 1000) <= 700 then data[vi] = C.basalt else data[vi] = C.magma end
                        end
                    end
                    ::continue_y::
                end
            end
        end
    end
end
-- SPAWN ÚNICO DA ESTÁTUA DO CARANGUEJO (próxima ao vulcão)
local function try_spawn_crab_statue(minp, maxp, volcano_pos)
    if statue_spawned then return end
    if not volcano_pos then return end
    -- Só tenta se este chunk cobre a área do vulcão (margem aumentada para 80)
    local chunk_center_x = (minp.x + maxp.x) / 2
    local chunk_center_z = (minp.z + maxp.z) / 2
    local dist_chunk = math.sqrt((chunk_center_x - volcano_pos.x) ^ 2 + (chunk_center_z - volcano_pos.z) ^ 2)
    if dist_chunk > (VOLCANO_RADIUS + BEACH_WIDTH + 80) then return end
    local search_min_r = VOLCANO_RADIUS - 10          -- borda da ilha
    local search_max_r = VOLCANO_RADIUS + BEACH_WIDTH -- praia submersa
    -- Duas passagens: 1ª prefere posições com kelp, 2ª aceita qualquer wet_sand
    for pass = 1, 2 do
        for attempts = 1, 200 do
            local angle = (attempts / 200) * math.pi * 2
            local radius = search_min_r + (attempts % 7) * (search_max_r - search_min_r) / 7
            local cx = math.floor(volcano_pos.x + math.cos(angle) * radius)
            local cz = math.floor(volcano_pos.z + math.sin(angle) * radius)
            -- Varre Y na mesma faixa de profundidade do kelp (-18 a -13)
            for cy = -18, -13 do
                local node = core.get_node({x = cx, y = cy, z = cz})
                if node.name == "nh_nodes:wet_sand" then
                    -- Bloco acima deve ser água (estamos submersos)
                    local above = core.get_node({x = cx, y = cy + 1, z = cz})
                    if above.name == "nh_nodes:water" then
                        local ok = false
                        if pass == 1 then
                            -- 1ª passagem: exige kelp por perto
                            for kx = -3, 3 do
                                for kz = -3, 3 do
                                    for ky = -2, 3 do
                                        if core.get_node({x = cx + kx, y = cy + ky, z = cz + kz}).name == "nh_nodes:kelp" then
                                            ok = true
                                            break
                                        end
                                    end
                                    if ok then break end
                                end
                                if ok then break end
                            end
                        else
                            -- 2ª passagem: aceita qualquer wet_sand submerso (kelp pode não ter carregado)
                            ok = true
                            core.log("action", "[terrain] Crab Statue: Fallback without kelp (pass 2)")
                        end
                        if ok then
                            core.set_node({x = cx, y = cy, z = cz}, {name = "nh_nodes:giantcrabstatue"})
                            statue_spawned = true
                            statue_pos = {x = cx, y = cy, z = cz}
                            core.log("action",
                                "[terrain] Crab statue placed in x=" ..
                                cx .. " y=" .. (cy + 1) .. " z=" .. cz .. " (pass " .. pass .. ")")
                            return
                        end
                    end
                end
            end
        end
    end
end
-- ILHAS FLUTUANTES (-X, +Z, y 500-1000)
local FLOATING_ISLAND_RADIUS = SNOW_RADIUS
local FLOATING_ISLANDS = nil
-- INICIALIZA ILHAS (AGORA COM 2–3 CONES)
local function init_floating_islands()
    if FLOATING_ISLANDS then return end
    FLOATING_ISLANDS 
    local rng = PseudoRandom(314159)
    local count = 12
    for i = 1, count do
        local angle = rng:next(0, 3141) / 1000.0
        local t = rng:next(0, 1000) / 1000.0
        local dist = math.sqrt(t) * FLOATING_ISLAND_RADIUS * 0.9
        local center_x = -MAX_XZ / 2
        local center_z = MAX_XZ / 2
        local ix = center_x - math.abs(math.cos(angle) * dist)
        local iz = center_z + math.abs(math.sin(angle) * dist)
        if ix >= 0 then ix = -(30 + rng:next(0, 50)) end
        if iz <= 0 then iz = 30 + rng:next(0, 50) end
        local base_y = rng:next(520, 940)
        local top_radius = rng:next(18, 45)
        local cone_height = rng:next(40, 100)
        -- 🔻 2 a 3 cones por ilha
        local cone_count = rng:next(3, 4)
        local cones 
        local spread = 0.4 -- afastamento dos cones
        for c = 1, cone_count do
            local offset_x = rng:next(-top_radius * spread, top_radius * spread)
            local offset_z = rng:next(-top_radius * spread, top_radius * spread)
            table.insert(cones, {
                x = math.floor(ix + offset_x),
                z = math.floor(iz + offset_z),
                top_radius = top_radius *
                    (0.7 + rng:next(0, 30) / 100),
                cone_height = cone_height * (0.8 + rng:next(0, 40) / 100)
           })
        end
        table.insert(FLOATING_ISLANDS, {base_y = base_y, cones = cones})
    end
end

-- RELEVO NO TOPO (RUÍDO SIMPLES)
local function get_top_variation(x, z)
    local n1 = math.sin(x * 0.04 + z * 0.02)
    local n2 = math.sin(x * 0.09 - z * 0.05) * 0.5
    local n3 = math.cos(z * 0.06 + x * 0.03) * 0.3
    local n = n1 + n2 + n3
    -- curva suave (flatten peaks)
    n = n * 2
    return n * 2
end

-- VERIFICA SE PONTO ESTÁ NA ILHA (MÚLTIPLOS CONES)
local function point_in_island(x, y, z, island)
    local y_top = island.base_y
    if y > y_top then return false end
    if y < 500 or y > 1000 then return false end
    for _, cone in ipairs(island.cones) do
        local y_tip = y_top - cone.cone_height
        if y < y_tip then goto next_cone end
        local t = (y - y_tip) / cone.cone_height
        -- 🔻 laterais menos arredondadas
        t = t ^ 0.85
        local dx = x - cone.x
        local dz = z - cone.z
        local angle = math.atan2(dz, dx)
        local base_radius = cone.top_radius * t
        -- ruído angular (irregularidade da borda)
        local noise = math.sin(angle * 3 + cone.x * 0.1) * 0.15 + math.sin(angle * 5 + cone.z * 0.1) * 0.10
        local radius = base_radius * (1 + noise)
        -- limite mínimo (evita buracos feios)
        if radius < base_radius * 0.6 then radius = base_radius * 0.6 end
        if (dx * dx + dz * dz) <= (radius * radius) then return true end
        ::next_cone::
    end
    return false
end
-- GERAÇÃO DAS ILHAS
local function generate_floating_islands(area, data, minp, maxp)
    init_floating_islands()
    if maxp.y < 500 or minp.y > 1000 then return end
    if maxp.x < MIN_XZ or minp.x > 0 then return end
    if maxp.z < 0 or minp.z > MAX_XZ then return end
    for _, island in ipairs(FLOATING_ISLANDS) do
        -- 🔻 margem baseada no maior cone
        local margin = 0
        for _, cone in ipairs(island.cones) do margin = math.max(margin, cone.top_radius) end
        margin = margin + 4
        -- checagem de chunk
        local skip = true
        for _, cone in ipairs(island.cones) do
            if not (cone.x + margin < minp.x or cone.x - margin > maxp.x or cone.z + margin < minp.z or cone.z - margin > maxp.z) then
                skip = false
                break
            end
        end
        if skip then goto next_island end
        for y = minp.y, maxp.y do
            if y < 500 or y > 1000 then goto next_y end
            for z = minp.z, maxp.z do
                if z <= 0 then goto next_z end
                for x = minp.x, maxp.x do
                    if x >= 0 then goto next_x end
                    if not area:contains(x, y, z) then goto next_x end
                    local vi = area:index(x, y, z)
                    if point_in_island(x, y, z, island) then
                        -- 🔻 topo com relevo
                        local top_variation = math.floor(get_top_variation(x, z))
                        local effective_top = island.base_y + top_variation
                        if y > effective_top then
                            data[vi] = C.air
                        elseif y == effective_top then
                            local has_solid_neighbor = false
                            local neighbors = {{x + 1, y, z}, {x - 1, y, z}, {x, y, z + 1}, {x, y, z - 1}}
                            for _, nb in ipairs(neighbors) do
                                if area:contains(nb[1], nb[2], nb[3]) then
                                    local nvi = area:index(nb[1], nb[2], nb[3])
                                    if data[nvi] ~= C.air then
                                        has_solid_neighbor = true
                                        break
                                    end
                                end
                            end
                            data[vi] = has_solid_neighbor and C.topgrass or C.topgrass --or C.grass
                        elseif y >= effective_top - 6 then
                            data[vi] = C.dirt
                        elseif y >= effective_top - 8 then
                            data[vi] = C.saprolite
                        else
                            data[vi] = C.gneiss
                        end
                    end
                    ::next_x::
                end
                ::next_z::
            end
            ::next_y::
        end
        ::next_island::
    end
    -- 🗿 Coloca sentinelstatue no topo da ilha mais alta
    local tallest = nil
    for _, island in ipairs(FLOATING_ISLANDS) do
        if not tallest or island.base_y > tallest.base_y then tallest = island end
    end
    if tallest then
        -- Usa o primeiro cone como centro principal
        local main_cone = tallest.cones[1]
        local sx = main_cone.x
        local sz = main_cone.z
        -- Calcula o topo efetivo com a mesma variação usada na geração
        local top_variation = math.floor(get_top_variation(sx, sz))
        local statue_y = tallest.base_y + top_variation + 1 -- +1 = sobre o dirt
        -- Só coloca se o chunk atual contém essa posição
        if sx >= minp.x and sx <= maxp.x and sz >= minp.z and sz <= maxp.z and statue_y >= minp.y and statue_y <= maxp.y and area:contains(sx, statue_y, sz) then
            local vi = area:index(sx, statue_y, sz)
            data[vi] = C.sentinelstatue
            -- Salva a posição da estátua do sentinela
            sentinel_pos = {x = sx, y = statue_y, z = sz} -- ADICIONE ESTA LINHA
        end
    end
    -- Salva o topo da ilha mais BAIXA para o comando /lowisland
    local lowest = nil
    for _, island in ipairs(FLOATING_ISLANDS) do
        if not lowest or island.base_y < lowest.base_y then lowest = island end
    end
    if lowest then
        local main_cone = lowest.cones[1]
        local lx = main_cone.x
        local lz = main_cone.z
        local top_variation = math.floor(get_top_variation(lx, lz))
        local low_y = lowest.base_y + top_variation + 1
        if lx >= minp.x and lx <= maxp.x and lz >= minp.z and lz <= maxp.z and low_y >= minp.y and low_y <= maxp.y and area:contains(lx, low_y, lz) then
            lowest_island_pos = {x = lx, y = low_y, z = lz}
        end
    end
end
-- FUNÇÃO DE GERAÇÃO DE DECORAÇÕES (ÁRVORES, PEBBLES, ETC)
local function generate_decorations(minp, maxp, heights, biome_factors, noise_maps)
    local SEA_LEVEL = 0
    local grassleaves_positions 
    local tree_positions 
    local pebble_positions 
    local pebble_positions2 
    local palm_positions 
    local index_2d = 1
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            local wx = ((x - MIN_XZ) % SIZE) + MIN_XZ
            local wz = ((z - MIN_XZ) % SIZE) + MIN_XZ
            local height = heights[index_2d]
            local biome_factor = biome_factors[index_2d]
            -- Folhas de grama (não gera em área de neve)
            if not inside_snow_area(x, z) and height > SEA_LEVEL + 6 and height >= minp.y and height <= maxp.y then
                local grassleaves_density = biome_factor < 0.4 and 0.9 or (biome_factor > 0.7 and 0.8 or 0.9)
                if noise_maps.grassleaves_2d[index_2d] > grassleaves_density then
                    table.insert(grassleaves_positions, {x = x, y = height + 1, z = z})
                end
            end
            -- Carvalhos e Macieiras
            if not inside_snow_area(x, z) and height > SEA_LEVEL + 4 and height >= minp.y and height <= maxp.y then
                if noise_maps.trees_2d[index_2d] > 0.70 then
                    local tree_type = "tree" -- default: carvalho
                    -- Macieiras aparecem em alturas mais baixas (zona de transição)
                    if height <= SEA_LEVEL + 6 then tree_type = "apple" end
                    table.insert(tree_positions, {x = x, y = height + 1, z = z, wx = wx, wz = wz, type = tree_type})
                end
            end
            -- Pinheiros
            if inside_snow_area(x, z) and height > SEA_LEVEL + 6 and height >= minp.y and height <= maxp.y then
                if noise_maps.trees_2d[index_2d] > 0.65 then
                    table.insert(tree_positions, {x = x, y = height + 1, z = z, wx = wx, wz = wz, type = "pine"})
                end
            end
            -- Arbustos
            if not inside_snow_area(x, z) and height > SEA_LEVEL + 6 and height >= minp.y and height <= maxp.y then
                local bush_density = biome_factor < 0.5 and 0.72 or (biome_factor > 0.7 and 0.80 or 0.75)
                if noise_maps.bushes_2d[index_2d] > bush_density then
                    table.insert(tree_positions, {x = x, y = height + 1, z = z, wx = wx, wz = wz, type = "bush"})
                end
            end
            -- Coqueiros
            if not inside_snow_area(x, z) and height >= SEA_LEVEL - 2 and height <= SEA_LEVEL + 3 and height >= minp.y and height <= maxp.y then
                if noise_maps.trees_2d[index_2d] > 0.7 then
                    table.insert(palm_positions, {x = x, y = height + 1, z = z, wx = wx, wz = wz})
                end
            end
            -- Kelp (em wet_sand entre altitude -18 e -13)
            if height >= -18 and height <= -13 and height >= minp.y and height <= maxp.y then
                local grassleaves_density = 0.85
                if noise_maps.grassleaves_2d[index_2d] > grassleaves_density then
                    table.insert(grassleaves_positions, {x = x, y = height + 1, z = z, is_kelp = true})
                end
            end
            -- sobre a wet_sand na altitude -19)
            if height == -19 and height >= minp.y and height <= maxp.y then
                local grassleaves_density = 0.7 -- mesmo threshold das kelps
                if noise_maps.grassleaves_2d[index_2d] > grassleaves_density then
                    table.insert(grassleaves_positions, {x = x, y = height + 1, z = z, is_wetsand = true})
                end
            end
            -- Pebbles
            if height > SEA_LEVEL + 5 and height <= SEA_LEVEL + 6 then
                local rng_pebble = PseudoRandom(x * 33333 + z * 44444)
                -- 0.05% = 1/2000
                if rng_pebble:next(1, 2000) == 1 then table.insert(pebble_positions2, {x = x, y = height + 1, z = z}) end
                -- 0.1% = 1/1000
                if rng_pebble:next(1, 1000) == 1 then table.insert(pebble_positions, {x = x, y = height + 1, z = z}) end
            end
            index_2d = index_2d + 1
        end
    end
    return {
        grassleaves = grassleaves_positions,
        trees = tree_positions,
        pebbles = pebble_positions,
        pebbles2 = pebble_positions2,
        palms = palm_positions,
   }
end
-- FUNÇÃO DE APLICAÇÃO DAS DECORAÇÕES
local function apply_decorations(area, data, param2_data, decorations)
    local palm_leaf_rotations 

    -- Gera árvores
    for _, spawn_data in ipairs(decorations.trees) do
        if spawn_data.type == "tree" then
            spawn_tree(area, data, param2_data, spawn_data, spawn_data.wx, spawn_data.wz)
            local rng_page = PseudoRandom(spawn_data.wx * 31337 + spawn_data.wz * 13337)
            if rng_page:next(1, 15) == 1 then
                local dirs = {{x = 1, y = 0, z = 0}, {x = -1, y = 0, z = 0}, {x = 0, y = 0, z = 1}, {x = 0, y = 0, z = -1},}
                local dir = dirs[rng_page:next(1, 4)]
                core.after(0.1, function()
                    local found_y = nil
                    for try_y = spawn_data.y + 2, spawn_data.y + 1, -1 do
                        local trunk_pos  = {x = spawn_data.x, y = try_y, z = spawn_data.z}
                        local side_pos   = {x = spawn_data.x + dir.x, y = try_y, z = spawn_data.z + dir.z}
                        local trunk_node = core.get_node(trunk_pos).name
                        local side_node  = core.get_node(side_pos).name
                        if trunk_node == "nh_nodes:oaktimber" and side_node == "air" then
                            found_y = try_y
                            break
                        end
                    end
                    if found_y then
                        local page_pos = {x = spawn_data.x + dir.x, y = found_y, z = spawn_data.z + dir.z,}
                        local dir_to_param2 = {[1] = {[0] = 2}, [-1] = {[0] = 3}, [0] = {[1] = 4, [-1] = 5},}
                        local param2 = dir_to_param2[dir.x] and dir_to_param2[dir.x][dir.z]
                        if param2 then
                            core.set_node(page_pos, {name = "nh_nodes:writedpage_node", param2 = param2})
                            local meta = core.get_meta(page_pos)
                            local list = page_texts.message
                            local text = list[rng_page:next(1, #list)]
                            meta:set_string("text", text)
                        end
                    end
                end)
            end
        elseif spawn_data.type == "apple" then
            spawn_apple_tree(area, data, spawn_data, spawn_data.wx, spawn_data.wz)
        elseif spawn_data.type == "pine" then
            spawn_pine_tree(area, data, spawn_data, spawn_data.wx, spawn_data.wz)
        elseif spawn_data.type == "bush" then
            spawn_bush(area, data, spawn_data, spawn_data.wx, spawn_data.wz)
        end
    end
    -- Gera coqueiros
    for _, palm_data in ipairs(decorations.palms) do
        local leaf_nodes = spawn_palm_tree(area, data, palm_data, palm_data.wx, palm_data.wz)
        if leaf_nodes then
            for _, leaf_info in ipairs(leaf_nodes) do
                table.insert(palm_leaf_rotations, leaf_info)
            end
        end
    end
    -- Gera folhas de grama (com algumas pedras aleatórias)
    for _, grass_pos in ipairs(decorations.grassleaves) do
        if area:contains(grass_pos.x, grass_pos.y, grass_pos.z) then
            local vi = area:index(grass_pos.x, grass_pos.y, grass_pos.z)
            if grass_pos.is_kelp then
                -- Kelp fica embaixo d'água, então aceita C.water também
                if data[vi] == C.water then --data[vi] == C.air or data[vi] == C.water2 or
                    local height_val = math.random(3, 10)
                    data[vi] = C.kelp
                    param2_data[vi] = height_val * 16
                end
            elseif grass_pos.is_wetsand then
                -- Kelp fica embaixo d'água, então aceita C.water também
                if data[vi] == C.water then --data[vi] == C.air or data[vi] == C.water2 or
                    data[vi] = C.wetsand
                end
            elseif data[vi] == C.air then
                local rng_grass = PseudoRandom(grass_pos.x * 54321 + grass_pos.z * 98765)
                local r = rng_grass:next(1, 1000)
                if r <= 1 then
                    data[vi] = C.micaceusfungus
                elseif r <= 2 then
                    data[vi] = C.rush
                elseif r <= 3 then
                    data[vi] = C.dandelion
                elseif r <= 4 then
                    data[vi] = C.highgrass
                elseif r <= 5 then
                    data[vi] = C.smallgrass
                elseif r <= 250 then
                    data[vi] = C.grassleavesmedium
                else
                    data[vi] = C.grassleaves
                end
            end
        end
    end
    -- Gera pebbles
    for _, pebble_pos in ipairs(decorations.pebbles2) do
        if area:contains(pebble_pos.x, pebble_pos.y, pebble_pos.z) then
            local vi = area:index(pebble_pos.x, pebble_pos.y, pebble_pos.z)
            if data[vi] == C.air then data[vi] = C.whitepebble end
        end
    end
    for _, pebble_pos in ipairs(decorations.pebbles) do
        if area:contains(pebble_pos.x, pebble_pos.y, pebble_pos.z) then
            local vi = area:index(pebble_pos.x, pebble_pos.y, pebble_pos.z)
            if data[vi] == C.air then
                data[vi] = C.pebble
                local chest_y = pebble_pos.y - 2
                if area:index(pebble_pos.x, chest_y, pebble_pos.z) then
                    local chest_vi = area:index(pebble_pos.x, chest_y, pebble_pos.z)
                    data[chest_vi] = C.oakchest
                end
            end
        end
    end
    return palm_leaf_rotations, decorations.pebbles
end
-- FUNÇÃO DE GERAÇÃO DE TORRES DE OBSIDIANA
local function generate_obsidian_towers(area, data, minp, maxp)
    local TOWER_MIN_Y = -50
    local TOWER_MAX_Y = 80
    local tower_bases = {{x = MIN_XZ, z = MIN_XZ}, {x = MAX_XZ - 1, z = MIN_XZ}, {x = MIN_XZ, z = MAX_XZ - 1}, {x = MAX_XZ - 1, z = MAX_XZ - 1},}
    for _, base in ipairs(tower_bases) do
        for y = TOWER_MIN_Y, TOWER_MAX_Y do
            for dx = 0, 4 do
                for dz = 0, 4 do
                    local vi = safe_index(area, base.x + dx, y, base.z + dz, minp, maxp)
                    if vi then data[vi] = C.obsidian end
                end
            end
        end
        -- Place C.sphere centered at the top of the tower
        local sx, sy, sz = base.x + 2, TOWER_MAX_Y + 2, base.z + 2
        local vi = safe_index(area, sx, sy, sz, minp, maxp)
        if vi then
            data[vi] = C.sphere
            -- Agenda as trocas e spawns após o chunk ser finalizado
            local pos = {x = sx, y = sy, z = sz}
            core.after(0, function()
                local node = core.get_node(pos)
                if node.name == "nh_nodes:sphere" then
                    core.set_node(pos, {name = "nh_nodes:sphere_placed"})
                    core.add_entity(pos, "nh_nodes:sphere_anim")
                    core.add_entity(pos, "nh_nodes:crystal_anim")
                end
            end)
        end
    end
end
-- FUNÇÃO DE TENTATIVA DE SPAWN DA TENDA
local function try_spawn_tent(area, data, minp, maxp)
    if tent_generated then return false end
    if math.abs(minp.x) > TENT_SEARCH_RADIUS or math.abs(minp.z) > TENT_SEARCH_RADIUS then return false end
    local SEA_LEVEL = 0
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            if (x * x + z * z) <= (TENT_SEARCH_RADIUS * TENT_SEARCH_RADIUS) then
                for y = SEA_LEVEL + 1, SEA_LEVEL + 6 do
                    local base_pos = {x = x, y = y, z = z}
                    if area:contains(x, y, z) and can_spawn_tent(area, data, base_pos) then
                        spawn_tent(area, data, base_pos)
                        place_tent_chest(area, data, base_pos)
                        tent_generated = true
                        return true
                    end
                end
            end
            if tent_generated then return true end
        end
        if tent_generated then return true end
    end
    return false
end
-- FUNÇÃO DE TENTATIVA DE SPAWN DO BARCO AFUNDADO
local function try_spawn_ship(area, data, minp, maxp)
    if ship_generated then return false end
    if math.abs(minp.x) > SHIP_SEARCH_RADIUS or math.abs(minp.z) > SHIP_SEARCH_RADIUS then return false end
    local SEA_LEVEL = 0
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            if (x * x + z * z) <= (SHIP_SEARCH_RADIUS * SHIP_SEARCH_RADIUS) then
                for y = SEA_LEVEL - 7, SEA_LEVEL - 2 do
                    local base_pos = {x = x, y = y, z = z}
                    if area:contains(x, y, z) and can_spawn_ship(area, data, base_pos) then
                        spawn_ship(area, data, base_pos)
                        place_ship_chest(area, data, {x = base_pos.x, y = base_pos.y + 1, z = base_pos.z})
                        ship_generated = true
                        ship_pos = {x = base_pos.x + 2, y = base_pos.y + 4, z = base_pos.z + 4}
                        return true
                    end
                end
            end
            if ship_generated then return true end
        end
        if ship_generated then return true end
    end
    return false
end
-- FUNÇÃO DE TENTATIVA DE SPAWN DA CASA
local function try_spawn_house(area, data, minp, maxp)
    if house_generated then return false end
    if math.abs(minp.x) > HOUSE_SEARCH_RADIUS or math.abs(minp.z) > HOUSE_SEARCH_RADIUS then return false end
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            if (x * x + z * z) <= (HOUSE_SEARCH_RADIUS * HOUSE_SEARCH_RADIUS) then
                for y = 22, 50 do -- ← altitude da casa em terra firme
                    if area:contains(x, y, z) and can_spawn_house(area, data, {x = x, y = y, z = z}) then
                        spawn_house(area, data, {x = x, y = y, z = z})
                        place_tent_chest(area, data, {x = x, y = y + 1, z = z})
                        house_generated = true -- ← corrigido (estava "house_generated")
                        return true
                    end
                end
            end
            if house_generated then return true end
        end
        if house_generated then return true end
    end
    return false
end


-- GERAÇÃO DO MUNDO (OTIMIZADA E REFATORADA)
core.register_on_generated(function(minp, maxp)
    -- Inicializa Perlin maps (apenas uma vez)
    init_perlin_maps()
    -- Otimização: ignora chunks muito altos ou muito baixos
    if maxp.y < -100 or minp.y > 1000 then return end
    -- Setup do voxelmanip
    local vm = core.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local area = VoxelArea:new {MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()
    local param2_data = vm:get_param2_data()
    -- Configurações
    local SEA_LEVEL = 0
    local CENTER_X = (MIN_XZ + MAX_XZ) / 2
    local CENTER_Z = (MIN_XZ + MAX_XZ) / 2
    local MAX_RADIUS = (SIZE / 2) * 0.85
    -- Gera todos os noise maps em batch
    local noise_maps = generate_noise_maps(minp, maxp)
    -- Encontra/define posição do vulcão
    local volcano_pos = find_volcano_position()
    -- Verifica se este chunk está próximo do vulcão
    local chunk_near_volcano = false
    if volcano_pos then
        local chunk_center_x = (minp.x + maxp.x) / 2
        local chunk_center_z = (minp.z + maxp.z) / 2
        local dist = math.sqrt((chunk_center_x - volcano_pos.x) ^ 2 + (chunk_center_z - volcano_pos.z) ^ 2)
        chunk_near_volcano = dist < (VOLCANO_RADIUS + 80) -- Margem de segurança
    end
    -- Calcula alturas em batch
    local heights, biome_factors = calculate_height_batch(minp, maxp, SEA_LEVEL, CENTER_X, CENTER_Z, MAX_RADIUS,
        noise_maps.continent_2d, noise_maps.biome_2d, noise_maps.mountain_2d, noise_maps.hills_2d, noise_maps.plains_2d,
        noise_maps.rough_2d)
    -- Gera terreno base
    --generate_terrain_base(minp, maxp, area, data, heights, biome_factors, noise_maps)
    local grass_positions = generate_terrain_base(minp, maxp, area, data, heights, biome_factors, noise_maps)
    -- Ilhas flutuantes
    generate_floating_islands(area, data, minp, maxp)
    -- Gera ilha vulcânica se o chunk estiver próximo
    if chunk_near_volcano then
        generate_volcano(area, data, minp, maxp, volcano_pos)
        --add_eruption_effects(area, data, minp, maxp, volcano_pos)
    end
    -- Gera decorações (árvores, arbustos, etc)
    local decorations = generate_decorations(minp, maxp, heights, biome_factors, noise_maps)
    local palm_leaf_rotations, pebble_positions = apply_decorations(area, data, param2_data, decorations)
        -- Aplica decorações no terreno ANTES dos slopes,
    -- para que terrain_slopes.apply encontre as decorações no array data
    -- e as remova imediatamente ao converter ramp/corner/insidecorner.
    terrain_slopes.apply(area, data, param2_data, minp, maxp, C, DECORATION_CIDS)
    -- Gera torres de obsidiana
    generate_obsidian_towers(area, data, minp, maxp)
    -- Grava dados no voxelmanip
    vm:set_data(data)
    vm:set_param2_data(param2_data)
    vm:write_to_map()
    vm:update_map()
    -- Tentativa de spawnar tenda (APÓS gravar o terreno)
    local tent_spawned = try_spawn_tent(area, data, minp, maxp)
    if tent_spawned then
        -- Regrava apenas se modificou
        vm:set_data(data)
        vm:write_to_map()
        vm:update_map()
    end
    -- Tentativa de spawnar tenda (APÓS gravar o terreno)
    local ship_spawned = try_spawn_ship(area, data, minp, maxp)
    if ship_spawned then
        -- Regrava apenas se modificou
        vm:set_data(data)
        vm:write_to_map()
        vm:update_map()
    end
    local house_spawned = try_spawn_house(area, data, minp, maxp)
    if house_spawned then
        -- Regrava apenas se modificou
        vm:set_data(data)
        vm:write_to_map()
        vm:update_map()
    end
    -- Rotaciona folhas de coqueiro e inicializa baús
    core.after(0, function()
        -- Spawna estátua do caranguejo perto do vulcão (uma única vez)
        if chunk_near_volcano and not statue_spawned then
            core.after(0.5, function() try_spawn_crab_statue(minp, maxp, volcano_pos) end)
        end
        -- Rotação das folhas de palmeira
        for _, leaf_info in ipairs(palm_leaf_rotations) do
            local node = core.get_node(leaf_info.pos)
            if node.name == "nh_nodes:palmleaf" then
                core.set_node(leaf_info.pos, {name = "nh_nodes:palmleaf", param2 = leaf_info.rotation})
            elseif node.name == "nh_nodes:coconutlinked" then
                core.set_node(leaf_info.pos, {name = "nh_nodes:coconutlinked", param2 = leaf_info.rotation})
            end
        end
        -- Inicializa baús do pebble
        for _, pebble_pos in ipairs(pebble_positions) do
            local chest_pos = {x = pebble_pos.x, y = pebble_pos.y - 2, z = pebble_pos.z}
            local node = core.get_node(chest_pos)
            if node.name == "nh_nodes:oak_chest" then
                local node_def = core.registered_nodes["nh_nodes:oak_chest"]
                if node_def and node_def.on_construct then node_def.on_construct(chest_pos) end
            end
        end
    end)
end) -- FIM do register_on_generated
if not core.registered_nodes["nh_nodes:grass"] then core.log("warning", "[terrain] nh_nodes:grass is not registered.") end


--  FUNÇÕES AUXILIARES COMPARTILHADAS PELOS LBMs DE RAMPA
local function clear_above(pos)
    local above = {x = pos.x, y = pos.y + 1, z = pos.z}
    if DECORATIONS[gcid(core.get_node(above).name)] then
        core.set_node(above, {name = "air"})
    end
end

-- Converte o nó abaixo se for "nh_nodes:dirt" para `target`
local function convert_below(pos, src, target)
    local below = {x = pos.x, y = pos.y - 1, z = pos.z}
    if core.get_node(below).name == src then
        core.set_node(below, {name = target})
    end
end

--  REGISTRO DOS LBMs SIMPLIFICADOS
core.register_lbm({
    name             = "nh_terrain:grass_conversion",
    nodenames        = {"nh_nodes:top_grass"},
    run_at_every_load = true,
    action = function(pos)
        local x, y, z = pos.x, pos.y, pos.z
        local current = core.get_node(pos).name

        local function is_solid_below(p)
            return SOLID_GRASS[gcid(core.get_node({x = p.x, y = p.y - 1, z = p.z}).name)] == true
        end
        local function is_solid_same(p)
            return SOLID_GRASS[gcid(core.get_node(p).name)] == true
        end
        local function is_passthrough(p)
            local cid = gcid(core.get_node(p).name)
            if not PASSABLE[cid] then return false end
            return SOLID_GRASS[gcid(core.get_node({x = p.x, y = p.y - 1, z = p.z}).name)] == true
        end

        local below = {
            north = is_solid_below({x = x,     y = y, z = z - 1}),
            south = is_solid_below({x = x,     y = y, z = z + 1}),
            east  = is_solid_below({x = x + 1, y = y, z = z    }),
            west  = is_solid_below({x = x - 1, y = y, z = z    }),
        }
        local same = {
            north = is_solid_same({x = x,     y = y, z = z - 1}),
            south = is_solid_same({x = x,     y = y, z = z + 1}),
            east  = is_solid_same({x = x + 1, y = y, z = z    }),
            west  = is_solid_same({x = x - 1, y = y, z = z    }),
        }

        local drops 
        if below.north then drops[#drops+1] = "south" end
        if below.south then drops[#drops+1] = "north" end
        if below.east  then drops[#drops+1] = "west"  end
        if below.west  then drops[#drops+1] = "east"  end

        local any_below = below.north or below.south or below.east or below.west

        -- PRIORIDADE 1: INSIDE CORNER (roda para top_grass e variantes)
        if not any_below then
            if same.south and same.west and is_passthrough({x = x - 1, y = y, z = z + 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 2})
                clear_above(pos)
                return
            end
            if same.west and same.north and is_passthrough({x = x - 1, y = y, z = z - 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 1})
                clear_above(pos)
                return
            end
            if same.north and same.east and is_passthrough({x = x + 1, y = y, z = z - 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 0})
                clear_above(pos)
                return
            end
            if same.east and same.south and is_passthrough({x = x + 1, y = y, z = z + 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 3})
                clear_above(pos)
                return
            end
        end

        -- Ramp/corner só para top_grass puro
        if current ~= "nh_nodes:top_grass" then return end

        -- PRIORIDADE 2: CORNER EXTERNO
        if #drops == 2 then
            local a, b = drops[1], drops[2]
            local function match(x1, x2) return (a == x1 and b == x2) or (a == x2 and b == x1) end
            if match("south", "west") then
                core.set_node(pos, {name = "nh_nodes:top_grass_corner", param2 = 0})
                clear_above(pos)
                convert_below(pos, "nh_nodes:dirt", "nh_nodes:top_grass2")
            elseif match("west", "north") then
                core.set_node(pos, {name = "nh_nodes:top_grass_corner", param2 = 3})
                clear_above(pos)
                convert_below(pos, "nh_nodes:dirt", "nh_nodes:top_grass2")
            elseif match("north", "east") then
                core.set_node(pos, {name = "nh_nodes:top_grass_corner", param2 = 2})
                clear_above(pos)
                convert_below(pos, "nh_nodes:dirt", "nh_nodes:top_grass2")
            elseif match("east", "south") then
                core.set_node(pos, {name = "nh_nodes:top_grass_corner", param2 = 1})
                clear_above(pos)
                convert_below(pos, "nh_nodes:dirt", "nh_nodes:top_grass2")
            end
            return
        end

        -- PRIORIDADE 3: RAMPA
        if below.north and not below.south then
            core.set_node(pos, {name = "nh_nodes:top_grass_ramp", param2 = 0})
            clear_above(pos)
        elseif below.south and not below.north then
            core.set_node(pos, {name = "nh_nodes:top_grass_ramp", param2 = 2})
            clear_above(pos)
        elseif below.east and not below.west then
            core.set_node(pos, {name = "nh_nodes:top_grass_ramp", param2 = 3})
            clear_above(pos)
        elseif below.west and not below.east then
            core.set_node(pos, {name = "nh_nodes:top_grass_ramp", param2 = 1})
            clear_above(pos)
        end
    end,
})

--[[
-- FONTE GENÉRICA PARA LBMs DE RAMPA E QUINAS
local function make_slope_lbm(cfg)
    local solid        = cfg.solid
    local edge         = cfg.edge
    local passable     = cfg.passable or edge
    local nodes        = cfg.nodes
    local req_air      = cfg.require_air_above ~= false
    local do_clear     = cfg.clear ~= false
    local on_corner    = cfg.on_corner
    local on_ic        = cfg.on_insidecorner

    local function get_node_name(p) return core.get_node(p).name end

    local function is_edge(p)
        return edge[get_node_name(p)] == true
    end
    local function is_solid(p)
        return solid[get_node_name(p)] == true
    end
    local function is_passthrough(p)
        local name = get_node_name(p)
        if not passable[name] then return false end
        return solid[get_node_name({x = p.x, y = p.y - 1, z = p.z})] == true
    end

    local function action(pos)
        if req_air and get_node_name({x = pos.x, y = pos.y + 1, z = pos.z}) ~= "air" then return end

        local x, y, z = pos.x, pos.y, pos.z

        local b = {
            north = is_edge({x = x,     y = y, z = z - 1}),
            south = is_edge({x = x,     y = y, z = z + 1}),
            east  = is_edge({x = x + 1, y = y, z = z    }),
            west  = is_edge({x = x - 1, y = y, z = z    }),
        }
        local s = {
            north = is_solid({x = x,     y = y, z = z - 1}),
            south = is_solid({x = x,     y = y, z = z + 1}),
            east  = is_solid({x = x + 1, y = y, z = z    }),
            west  = is_solid({x = x - 1, y = y, z = z    }),
        }

        local drops 
        if b.north then drops[#drops+1] = "south" end
        if b.south then drops[#drops+1] = "north" end
        if b.east  then drops[#drops+1] = "west"  end
        if b.west  then drops[#drops+1] = "east"  end

        local any_below = b.north or b.south or b.east or b.west

        -- PRIORIDADE 1: INSIDE CORNER
        if not any_below then
            local ic_cases = {
                {s.south and s.west, {x=x-1,y=y,z=z+1}, 2},
                {s.west  and s.north,{x=x-1,y=y,z=z-1}, 1},
                {s.north and s.east, {x=x+1,y=y,z=z-1}, 0},
                {s.east  and s.south,{x=x+1,y=y,z=z+1}, 3},
            }
            for _, ic in ipairs(ic_cases) do
                if ic[1] and is_passthrough(ic[2]) then
                    core.set_node(pos, {name = nodes.insidecorner, param2 = ic[3]})
                    if do_clear then clear_above(pos) end
                    if on_ic then on_ic(pos) end
                    return
                end
            end
        end

        -- PRIORIDADE 2: CORNER EXTERNO  (só se nó atual for o trigger primário)
        if #drops == 2 then
            local a, b2 = drops[1], drops[2]
            local function match(x1, x2) return (a==x1 and b2==x2) or (a==x2 and b2==x1) end
            local corner_map = {
                {match("south","west"),  0},
                {match("west", "north"), 3},
                {match("north","east"),  2},
                {match("east", "south"), 1},
            }
            for _, cm in ipairs(corner_map) do
                if cm[1] then
                    core.set_node(pos, {name = nodes.corner, param2 = cm[2]})
                    if do_clear then clear_above(pos) end
                    if on_corner then on_corner(pos) end
                    return
                end
            end
            return
        end

        -- PRIORIDADE 3: RAMPA
        local ramp_map = {
            {b.north and not b.south, 0},
            {b.south and not b.north, 2},
            {b.east  and not b.west,  3},
            {b.west  and not b.east,  1},
        }
        for _, rm in ipairs(ramp_map) do
            if rm[1] then
                core.set_node(pos, {name = nodes.ramp, param2 = rm[2]})
                if do_clear then clear_above(pos) end
                return
            end
        end
    end

    core.register_lbm({
        name             = cfg.lbm_name,
        nodenames        = cfg.nodenames,
        run_at_every_load = true,
        action           = action,
    })
end


-- DIRT
make_slope_lbm({
    lbm_name  = "nh_terrain:dirt_conversion",
    nodenames = {"nh_nodes:dirt"},
    solid     = SOLID_DIRT,
    edge      = EDGE_DIRT,
    nodes = {
        insidecorner = "nh_nodes:dirt_insidecorner",
        corner       = "nh_nodes:dirt_corner",
        ramp         = "nh_nodes:dirt_ramp",
    },
    on_corner = function(pos) convert_below(pos, "nh_nodes:dirt", "nh_nodes:sand") end,
})

-- NEVE
make_slope_lbm({
    lbm_name  = "nh_terrain:snow_conversion",
    nodenames = {"nh_nodes:snow"},
    solid     = SOLID_SNOW,
    edge      = EDGE_SNOW,
    nodes = {
        insidecorner = "nh_nodes:snow_insidecorner",
        corner       = "nh_nodes:snow_corner",
        ramp         = "nh_nodes:snow_ramp",
    },
    on_corner = function(pos) convert_below(pos, "nh_nodes:dirt", "nh_nodes:snow") end,
})

-- BASALTO
make_slope_lbm({
    lbm_name  = "nh_terrain:basalt_conversion",
    nodenames = {"nh_nodes:basalt"},
    solid     = SOLID_BASALT,
    edge      = EDGE_BASALT,
    nodes = {
        insidecorner = "nh_nodes:basalt_insidecorner",
        corner       = "nh_nodes:basalt_corner",
        ramp         = "nh_nodes:basalt_ramp",
    },
    -- sem on_corner (convert estava comentado no original)
})

-- AREIA
make_slope_lbm({
    lbm_name  = "nh_terrain:sand_conversion",
    nodenames = {"nh_nodes:sand"},
    solid     = SOLID_SAND,
    edge      = EDGE_SAND,
    nodes = {
        insidecorner = "nh_nodes:sand_insidecorner",
        corner       = "nh_nodes:sand_corner",
        ramp         = "nh_nodes:sand_ramp",
    },
    -- sem on_corner (convert_wetsand estava comentado no original)
})
]]--
--core.register_abm({
--    name = "nh_terrain:corner_dirt_conversion",
--    nodenames = {"nh_nodes:top_grass_corner"},
--    interval = 1,
--    chance = 1,
--    catch_up = false,

--    action = function(pos, node)
--        local below = {x = pos.x, y = pos.y - 1, z = pos.z}
--        if core.get_node(below).name == "nh_nodes:dirt" then
--            core.set_node(below, {name = "nh_nodes:top_grass2"})
--        end
--    end
--})

core.register_abm({
    name = "nh_terrain:grass_conversion2",
    nodenames = {"nh_nodes:top_grass2"},
    interval = 1,
    chance = 2,
    catch_up = true,
    action = function(pos, node)
        local x, y, z = pos.x, pos.y, pos.z
        local current = core.get_node(pos).name

        local function is_solid_below(p)
            return SOLID_GRASS[gcid(core.get_node({x = p.x, y = p.y - 1, z = p.z}).name)] == true
        end
        local function is_solid_same(p)
            return SOLID_GRASS[gcid(core.get_node(p).name)] == true
        end

        local function is_passthrough(p)
            local cid = gcid(core.get_node(p).name)
            if not PASSABLE[cid] then return false end

            local below_diag = gcid(core.get_node({x = p.x, y = p.y - 1, z = p.z}).name)
            return SOLID_GRASS[below_diag] == true
        end

        local below = {
            north = is_solid_below({x = x, y = y, z = z - 1}),
            south = is_solid_below({x = x, y = y, z = z + 1}),
            east  = is_solid_below({x = x + 1, y = y, z = z}),
            west  = is_solid_below({x = x - 1, y = y, z = z}),
       }

        local same = {
            north = is_solid_same({x = x, y = y, z = z - 1}),
            south = is_solid_same({x = x, y = y, z = z + 1}),
            east  = is_solid_same({x = x + 1, y = y, z = z}),
            west  = is_solid_same({x = x - 1, y = y, z = z}),
       }

        local drops 
        if below.north then table.insert(drops, "south") end
        if below.south then table.insert(drops, "north") end
        if below.east then table.insert(drops, "west") end
        if below.west then table.insert(drops, "east") end

        local any_below = below.north or below.south or below.east or below.west

        -- PRIORIDADE 1: INSIDE CORNER
        -- Roda para top_grass e grass
        if not any_below then
            if same.south and same.west and is_passthrough({x = x - 1, y = y, z = z + 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 2})
                clear_above(pos)
                return
            end
            if same.west and same.north and is_passthrough({x = x - 1, y = y, z = z - 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 1})
                clear_above(pos)
                return
            end
            if same.north and same.east and is_passthrough({x = x + 1, y = y, z = z - 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 0})
                clear_above(pos)
                return
            end
            if same.east and same.south and is_passthrough({x = x + 1, y = y, z = z + 1}) then
                core.set_node(pos, {name = "nh_nodes:top_grass_insidecorner", param2 = 3})
                clear_above(pos)
                return
            end
        end
    end
})


-----------------------------
-- LBM: LIMPA DECORAÇÕES SOBRE NODES DE TRANSIÇÃO
-- Rampas, quinas e quinas internas têm colisão de meia altura,
-- então qualquer decoração gerada em cima deles fica flutuando.
-----------------------------
--[[
core.register_abm({
    name = "nh_terrain:clear_decorations_on_slopes",
    nodenames = {
        "nh_nodes:top_grass_ramp",
        "nh_nodes:top_grass_corner",
        "nh_nodes:top_grass_insidecorner",
   },
    interval = 4,
    chance = 25,
    catch_up = false,

    action = function(pos, node)
        local above = {x = pos.x, y = pos.y + 1, z = pos.z}
        if DECORATIONS[gcid(core.get_node(above).name)] then
            core.set_node(above, {name = "air"})
        end
    end
})
]]--

-- Pré-geração da área
core.after(1, function()
    core.log("action", "[terrain] Pre-generating spawn area...")
    core.emerge_area(
        {x = -48, y = -16, z = -48},
        {x = 48, y = 80, z = 48},
        function(blockpos, action, calls_remaining)
            if calls_remaining == 0 then
                core.log("action", "[terrain] Spawn area successfully pre-generated")
            end
        end)
end)

-- COMANDO PARA VOLTAR A ORIGEM
core.register_chatcommand("origin", {
    description = S("Teleport to the origin"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        -- Teleporta 2 blocos acima da estátua
        local tp_pos = {x = 0, y = 50, z = 0}
        player:set_pos(tp_pos)

        return true, S("Teleported to the origin at X: 0 Y: 50 Z: 0")
    end,
})

-- COMANDO PARA IR AO BARCO AFUNDADO
core.register_chatcommand("ship", {
    description = S("Teleport to the sunken ship"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        if not ship_pos then
            return false, S("The sunken ship has not yet been generated. Explore the ocean near spawn first")
        end

        player:set_pos(ship_pos)

        return true,
            S("Teleported to the sunken ship at X:") ..
            ship_pos.x .. " Y:" .. ship_pos.y .. " Z:" .. ship_pos.z
    end,
})
-- Comando só para ver as coordenadas do barco
core.register_chatcommand("local_ship", {
    description = S("Shows the coordinates of the sunken ship"),
    func = function(name)
        if not ship_pos then
            return false, S("The sunken ship has not yet been generated. Explore the ocean near spawn first")
        end

        return true,
            S("Sunken ship at X:") .. ship_pos.x .. " Y:" .. ship_pos.y .. " Z:" .. ship_pos.z
    end,
})

-- COMANDO PARA ENCONTRAR O VULCÃO
core.register_chatcommand("vulcan", {
    description = S("Teleport to the volcanic island"),
    privs = {teleport = true}, -- Requer privilégio de teleporte
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        local volcano_pos = find_volcano_position()

        if not volcano_pos then
            return false, S("The volcano has not yet been generated. Please wait a moment")
        end

        -- Teleporta para o topo do vulcão
        local tp_pos = {
            x = volcano_pos.x - 8,
            y = VOLCANO_HEIGHT - 1, -- Pouco abaixo da altura da cratera
            z = volcano_pos.z - 8
       }

        player:set_pos(tp_pos)

        return true,
            S("Teleported to the volcano in X:") .. math.floor(volcano_pos.x) .. " Z:" .. math.floor(volcano_pos.z)
    end,
})
-- Comando alternativo sem necessidade de privilégios (para testes)
core.register_chatcommand("local_vulcan", {
    description = S("Shows the coordinates of the volcanic island"),
    func = function(name)
        local volcano_pos = find_volcano_position()

        if not volcano_pos then
            return false, S("The volcano has not yet been generated. Please wait a moment")
        end

        return true, S("Volcanic island at X:") .. math.floor(volcano_pos.x) .. " Z:" .. math.floor(volcano_pos.z)
    end,
})

-- COMANDO PARA IR ATÉ O CARANGUEJO
core.register_chatcommand("crab", {
    description = S("Teleport to the giant crab statue"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        if not statue_pos then
            return false, S("The crab statue has not yet been generated. Explore the volcano area first")
        end

        -- Teleporta 2 blocos acima da estátua para não ficar preso na água
        local tp_pos = {x = statue_pos.x, y = statue_pos.y + 2, z = statue_pos.z}
        player:set_pos(tp_pos)

        return true,
            S("Teleported to the giant crab statue at X:") ..
            statue_pos.x .. " Y:" .. statue_pos.y .. " Z:" .. statue_pos.z
    end,
})
-- Comando para só ver as coordenadas sem teleportar
core.register_chatcommand("local_crab", {
    description = S("Show the coordinates of the giant crab statue"),
    func = function(name)
        if not statue_pos then
            return false, S("The crab statue has not yet been generated. Explore the volcano area first")
        end

        return true, S("Giant crab statue at X:") .. statue_pos.x .. " Y:" .. statue_pos.y .. " Z:" .. statue_pos.z
    end,
})

-- COMANDO PARA IR ATÉ O MAR DE AR
core.register_chatcommand("airsea", {
    description = S("Teleport to the air sea"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        -- Teleporta 2 blocos acima da estátua
        local tp_pos = {x = -700, y = 1, z = 700}
        player:set_pos(tp_pos)

        return true, S("Teleported to the air sea at X: -700, Y = 1, Z = 700")
    end,
})

-- COMANDO PARA IR ATÉ A ILHA MAIS BAIXA
core.register_chatcommand("flyisland", {
    description = S("Teleport to the fly island"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        if not lowest_island_pos then
            return false, S("The flying island hasn't been generated yet. Explore the sky of the Air Sea first")
        end

        local tp_pos = {x = lowest_island_pos.x, y = lowest_island_pos.y + 2, z = lowest_island_pos.z}
        player:set_pos(tp_pos)

        return true,
            S("Teleported to the fly island at X:") ..
            lowest_island_pos.x .. " Y:" .. lowest_island_pos.y .. " Z:" .. lowest_island_pos.z
    end,
})
-- Comando para só ver as coordenadas sem teleportar
core.register_chatcommand("local_flyisland", {
    description = S("Shows the coordinates of the fly island"),
    func = function(name)
        if not lowest_island_pos then
            return false, S("The flying island hasn't been generated yet. Explore the sky of the Air Sea first")
        end

        return true,
            S("Fly island at X:") .. lowest_island_pos.x .. " Y:" .. lowest_island_pos.y .. " Z:" .. lowest_island_pos.z
    end,
})

-- COMANDO PARA IR ATÉ O SENTINELA
core.register_chatcommand("sentinel", {
    description = S("Teleport to the sentinel statue"),
    privs = {teleport = true},
    func = function(name)
        local player = core.get_player_by_name(name)
        if not player then
            return false, S("Player not found")
        end

        if not sentinel_pos then
            return false, S("The sentinel statue has not yet spawned. Explore the floating islands first")
        end

        -- Teleporta 2 blocos acima da estátua
        local tp_pos = {x = sentinel_pos.x, y = sentinel_pos.y + 2, z = sentinel_pos.z}
        player:set_pos(tp_pos)

        return true,
            S("Teleported to the sentinel statue at X:") ..
            sentinel_pos.x .. " Y:" .. sentinel_pos.y .. " Z:" .. sentinel_pos.z
    end,
})
-- Comando para só ver as coordenadas sem teleportar
core.register_chatcommand("local_sentinel", {
    description = S("Shows the coordinates of the sentinel statue"),
    func = function(name)
        if not sentinel_pos then
            return false, S("The sentinel statue has not yet spawned. Explore the floating islands first")
        end

        return true, S("Sentinel statue at X:") .. sentinel_pos.x .. " Y:" .. sentinel_pos.y .. " Z:" .. sentinel_pos.z
    end,
})

core.log("action", "[TERRAIN] Continental generation with biomes, trees, coconut palms and more loaded")
