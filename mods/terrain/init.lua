-----------------------------
-- CONFIGURAÇÕES DO MUNDO
-----------------------------
local MIN_XZ = config.MIN_XZ
local MAX_XZ = config.MAX_XZ
local VOID_Y = config.VOID_Y

local SIZE = MAX_XZ - MIN_XZ + 1

-----------------------------
-- DESATIVAR MAPGEN NATIVO
-----------------------------
minetest.set_mapgen_setting("mg_name", "singlenode", true)

-----------------------------
-- REGISTRO DOS IDS
-----------------------------
local c_grass   = minetest.get_content_id("nodes:grass")
local c_topgrass = minetest.get_content_id("nodes:top_grass")
local c_dirt    = minetest.get_content_id("nodes:dirt")
local c_pebble  = minetest.get_content_id("nodes:pebble")
local c_sand    = minetest.get_content_id("nodes:sand")
local c_wetsand = minetest.get_content_id("nodes:wet_sand")
local c_saprolite = minetest.get_content_id("nodes:saprolite")
local c_gneiss  = minetest.get_content_id("nodes:gneiss")
local c_basalt = minetest.get_content_id("nodes:basalt")
local c_peridotite = minetest.get_content_id("nodes:peridotite")
local c_bedrock = minetest.get_content_id("nodes:bedrock")
local c_redrock = minetest.get_content_id("nodes:redrock")
local c_oaktimber = minetest.get_content_id("nodes:oaktimber")
local c_oakwood = minetest.get_content_id("nodes:oakwood")
local c_oakplank = minetest.get_content_id("nodes:oakplank")
local c_oakdowel = minetest.get_content_id("nodes:oakdowel")
local c_oakchest = minetest.get_content_id("nodes:oak_chest")
local c_oakdoor = minetest.get_content_id("nodes:oak_door")
local c_leaves  = minetest.get_content_id("nodes:leaves")
local c_blueberryleaves = minetest.get_content_id("nodes:blueberryleaves")
local c_leavesblueberry4  = minetest.get_content_id("nodes:leaves_blueberry4")
local c_leaves_nut  = minetest.get_content_id("nodes:leaves_nut")
local c_leaves_nut2 = minetest.get_content_id("nodes:leaves_nut2")
local c_leaves_nut3 = minetest.get_content_id("nodes:leaves_nut3")
local c_palmtrunk = minetest.get_content_id("nodes:palm_trunk")
local c_palmleaf = minetest.get_content_id("nodes:palm_leaf")
local c_coconut = minetest.get_content_id("nodes:coconut")
local c_water   = minetest.get_content_id("nodes:water")
local c_water2  = minetest.get_content_id("nodes:water2")
local c_lava    = minetest.get_content_id("nodes:lava")
local c_obsidian = minetest.get_content_id("nodes:obsidian")
local c_snow    = minetest.get_content_id("nodes:snow")
local c_air     = minetest.CONTENT_AIR
print("[terrain] content_ids obtidos")

local entity_positions = {}
local tent_generated = false
local TENT_SEARCH_RADIUS = 256

-----------------------------
-- FUNÇÃO PARA VERIFICAR SE HÁ ESPAÇO PARA A ÁRVORE
-----------------------------
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
                if data[vi] == c_oaktimber or data[vi] == c_leaves or data[vi] == c_palmtrunk or data[vi] == c_palmleaf then
                    return false
                end
            end
        end
    end
    return true
end

-----------------------------
-- FUNÇÃO DE SPAWN DE COQUEIRO
-----------------------------
local function spawn_palm_tree(area, data, pos, wx, wz)
    -- Verifica se há espaço
    if not can_place_tree(area, data, pos, 3) then
        return
    end
    
    -- Verifica se há areia abaixo do ponto de spawn
    local below_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
    if area:contains(below_pos.x, below_pos.y, below_pos.z) then
        local vi_below = area:index(below_pos.x, below_pos.y, below_pos.z)
        if data[vi_below] ~= c_sand then
            return  -- Cancela se não tiver areia embaixo
        end
    else
        return  -- Cancela se a posição abaixo não está no chunk
    end
    
    -- RNG determinístico por posição
    local seed = wx * 55555 + wz * 88888
    local rng = PseudoRandom(seed)
    
    -- Altura do tronco: 6 a 9 blocos
    local height = rng:next(6, 9)
    
    -- =============== TRONCO ===============
    for y = 0, height do
        local check_pos = {x = pos.x, y = pos.y + y, z = pos.z}
        
        if area:contains(check_pos.x, check_pos.y, check_pos.z) then
            local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
            if data[vi] == c_air then
                data[vi] = c_palmtrunk
            end
        end
    end
    
    -- =============== FOLHAS EM CRUZ (COM ROTAÇÃO) ===============
    local top = pos.y + height + 1
    
    -- Tabela de direções com suas respectivas rotações em param2
    -- param2 para facedir: 0=Norte(+Z), 1=Leste(+X), 2=Sul(-Z), 3=Oeste(-X)
    local directions = {
        {x = 0, z = -1, rotation = 0},  -- Norte (-Z)
        {x = 1, z = 0, rotation = 1},   -- Leste (+X)
        {x = 0, z = 1, rotation = 2},   -- Sul (+Z)
        {x = -1, z = 0, rotation = 3},  -- Oeste (-X)
    }
    
    -- Cria lista para armazenar folhas que precisam de rotação
    local leaf_nodes = {}
    
    for _, dir in ipairs(directions) do
        for i = 1, 3 do  -- 2 blocos em cada direção
            local leaf_pos = {
                x = pos.x + dir.x * i,
                y = top,
                z = pos.z + dir.z * i
            }
            
            if area:contains(leaf_pos.x, leaf_pos.y, leaf_pos.z) then
                local vi = area:index(leaf_pos.x, leaf_pos.y, leaf_pos.z)
                if data[vi] == c_air then
                    data[vi] = c_palmleaf
                    -- Armazena posição e rotação para aplicar depois
                    table.insert(leaf_nodes, {
                        pos = {x = leaf_pos.x, y = leaf_pos.y, z = leaf_pos.z},
                        rotation = dir.rotation
                    })
                end
            end
        end
    end
    
    -- =============== COCOS (0 a 4 aleatórios) ===============
    local num_coconuts = rng:next(0, 4)
    
    -- Posições possíveis para cocos (embaixo das folhas)
    local possible_positions = {
        {x = pos.x + 1, y = top - 1, z = pos.z},
        {x = pos.x - 1, y = top - 1, z = pos.z},
        {x = pos.x, y = top - 1, z = pos.z + 1},
        {x = pos.x, y = top - 1, z = pos.z - 1},
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
            if data[vi] == c_air then
                data[vi] = c_coconut
            end
        end
    end
    
    -- Retorna lista de folhas para rotacionar depois (via minetest.set_node)
    return leaf_nodes
end

-----------------------------
-- FUNÇÃO DE SPAWN DE ARBUSTO (só folhas)
-----------------------------
local function spawn_bush(area, data, pos, wx, wz)
    -- Verifica se há espaço (raio menor que árvores)
    if not can_place_tree(area, data, pos, 2) then
        return  -- Cancela se estiver muito perto
    end
    
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
    
    -- =============== GERA ARBUSTO ESFÉRICO ===============
    for y = 0, height do
        for dx = -radius, radius do
            for dz = -radius, radius do
                -- Calcula distância do centro (formato mais orgânico)
                local dist = math.sqrt(dx * dx + (y * 0.8) * (y * 0.8) + dz * dz)
                
                -- Adiciona aleatoriedade nas bordas
                local randomness = rng:next(-10, 10) / 20.0  -- -0.5 a +0.5
                
                -- Se estiver dentro do raio (com variação)
                if dist <= radius + randomness then
                    local check_pos = {
                        x = pos.x + dx,
                        y = pos.y + y,
                        z = pos.z + dz
                    }
                    
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                        -- Só substitui ar
                        if data[vi] == c_air then
                            data[vi] = c_blueberryleaves
                            
                            -- Chance de substituir por folhas com blueberry
                            if swaps < max_swaps then
                                local r = math.random()
                                
                                -- Distribuição enviesada:
                                -- 70% = não troca (folhas normais)
                                -- 30% = troca para blueberry
                                if r < 0.30 then
                                    data[vi] = c_leavesblueberry4
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

-----------------------------
-- FUNÇÃO DE SPAWN DE ÁRVORE (com variação de tronco)
-----------------------------
local function spawn_tree(area, data, pos, wx, wz)
    -- Verifica se há espaço (raio de 5 blocos)
    if not can_place_tree(area, data, pos, 5) then
        return  -- Cancela a geração se estiver muito perto de outra árvore
    end
    
    -- RNG determinístico por posição
    local seed = wx * 73856093 + wz * 19349663
    local rng = PseudoRandom(seed)
    local height = rng:next(6, 9)
    local crown_radius = rng:next(4, 5)
    
    -- =============== DETERMINA TAMANHO DO TRONCO ===============
    local trunk_type = rng:next(1, 4)  -- Sorteia entre 1 e 4
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
    
    -- =============== TRONCO (tamanho variável) ===============
    for y = 0, height do
        for dx = 0, trunk_dx do
            for dz = 0, trunk_dz do
                local check_pos = {x = pos.x + dx, y = pos.y + y, z = pos.z + dz}
                
                if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                    local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
                    -- Só substitui ar ou folhas
                    if data[vi] == c_air or data[vi] == c_leaves then
                        data[vi] = c_oaktimber
                    end
                end
            end
        end
    end
    
    -- =============== COPA (esférica) ===============
    local max_swaps = 3
    local swaps = 0

    
    local top = pos.y + height
    -- Ajusta centro da copa para troncos maiores
    local copa_center_x = pos.x + (trunk_dx / 2)
    local copa_center_z = pos.z + (trunk_dz / 2)
    
    for dy = -2, 3 do
        for dx = -crown_radius, crown_radius do
            for dz = -crown_radius, crown_radius do
                local dist = math.sqrt(dx * dx + dy * dy + dz * dz)
                if dist <= crown_radius + 0.5 then
                    local check_pos = {
                        x = math.floor(copa_center_x + dx), 
                        y = top + dy, 
                        z = math.floor(copa_center_z + dz)
                    }
                    if area:contains(check_pos.x, check_pos.y, check_pos.z) then
                        local vi = area:index(check_pos.x, check_pos.y, check_pos.z)
			if data[vi] == c_air then
			    data[vi] = c_leaves

			    -- Chance de substituir por folhas especiais
			    -- (mais pressão para NÃO trocar → distribuição enviesada)
			    if swaps < max_swaps then
				local r = math.random()

				-- Distribuição enviesada:
				-- 70% = não troca
				-- 20% = troca muito rara
				-- 10% = troca rara
				if r < 0.10 then
				    data[vi] = c_leaves_nut
				    swaps = swaps + 1
				elseif r < 0.20 then
				    data[vi] = c_leaves_nut2
				    swaps = swaps + 1
				elseif r < 0.30 then
				    data[vi] = c_leaves_nut3
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
        if data[vi_top] == c_air then
            data[vi_top] = c_leaves
        end
    end
end
-----------------------------
-- NOISES MELHORADOS
-----------------------------
local noise_mountain = {
    offset = 0,
    scale = 2,  
    spread = {x = 80, y = 80, z = 80},
    seed = 12345,
    octaves = 5,
    persist = 0.6,
}

local noise_hills = {
    offset = 0,
    scale = 1,
    spread = {x = 150, y = 150, z = 150},
    seed = 67890,
    octaves = 3,
    persist = 0.5,
}

local noise_plains = {
    offset = 0,
    scale = 1,
    spread = {x = 180, y = 180, z = 180},
    seed = 99999,
    octaves = 2,
    persist = 0.4,
}

local noise_caves = {
    offset = 0,
    scale = 1,
    spread = {x = 60, y = 30, z = 60},  -- spread menor em Y = cavernas mais horizontais
    seed = 424242,
    octaves = 3,
    persist = 0.5,
}

local noise_cave_size = {
    offset = 0,
    scale = 1,
    spread = {x = 50, y = 50, z = 50},  -- Varia o tamanho das cavernas por região
    seed = 131313,
    octaves = 2,
    persist = 0.4,
}


local noise_roughness = {
    offset = 0,
    scale = 1,
    spread = {x = 25, y = 25, z = 25},
    seed = 11111,
    octaves = 2,
    persist = 0.6,
}

local noise_biome = {
    offset = 0,
    scale = 1,
    spread = {x = 150, y = 150, z = 150},
    seed = 77777,
    octaves = 3,
    persist = 0.6,
}

local noise_trees = {
    offset = 0,
    scale = 0.6,
    spread = {x = 10, y = 10, z = 10},  -- Spread maior = mais espaçadas (era 10)
    seed = 54321,
    octaves = 3,
    persist = 0.5,
}

-----------------------------
-- FUNÇÃO DE CÁLCULO DE ALTURA
-----------------------------
local function calculate_height(wx, wz, SEA_LEVEL, CENTER_X, CENTER_Z, MAX_RADIUS)
    -- Distância do centro
    local dx = wx - CENTER_X
    local dz = wz - CENTER_Z
    local dist_from_center = math.sqrt(dx * dx + dz * dz)
    
    -- Fator continental
    local continent_factor =
    (1.0 - (dist_from_center / MAX_RADIUS)) * 0.45 +
    ((minetest.get_perlin(noise_biome):get_2d({x=wx, y=wz}) + 1) / 2) * 0.2
    
    -- Bioma
    local biome_noise = minetest.get_perlin(noise_biome):get_2d({x = wx, y = wz})
    local biome_factor = (biome_noise + 1) / 2
    
    -- Noises
    local mountain_noise = minetest.get_perlin(noise_mountain):get_2d({x = wx, y = wz})
    local hills_noise = minetest.get_perlin(noise_hills):get_2d({x = wx, y = wz})
    local plains_noise = minetest.get_perlin(noise_plains):get_2d({x = wx, y = wz})
    local rough_noise = minetest.get_perlin(noise_roughness):get_2d({x = wx, y = wz})
    
    local mn = (mountain_noise + 1) / 2
    local hn = (hills_noise + 1) / 2
    local pn = (plains_noise + 1) / 2
    local rn = (rough_noise + 1) / 2
    
    -- Mistura baseada no bioma
    local terrain_height
    if biome_factor > 0.6 then
        local mountain_weight = (biome_factor - 0.6) / 0.4
        terrain_height = (mn * 0.5 + hn * 0.3 + rn * 0.2) * (1.0 + mountain_weight)
    elseif biome_factor < 0.4 then
        local plains_weight = (0.4 - biome_factor) / 0.4
        terrain_height = (pn * 0.7 + rn * 0.3) * (0.3 + plains_weight * 0.25)
    else
        terrain_height = hn * 0.6 + pn * 0.2 + rn * 0.2
    end
    
    -- Aplica fator continental
    local final_height = terrain_height * continent_factor
    local height = math.floor(final_height * 50 + SEA_LEVEL - 3)
    
    -- Garante bordas baixas
    if continent_factor < 0.25 then
        height = math.floor(height * continent_factor / 0.25)
    end
    
    -- Limites
    if height > 70 then height = 70 end
    if height < -20 then height = -20 end
    
    return height, biome_factor
end

-----------------------------
-- FUNÇÃO PARA VERIFICAR SE É CAVERNA
-----------------------------
local function is_cave(x, y, z)
    -- Apenas gera cavernas na camada de gneiss (ajuste conforme sua lógica)
    if y > 23 or y < -37 then
        return false
    end
    
    -- Noise 3D principal para cavernas
    local cave_noise = minetest.get_perlin(noise_caves):get_3d({x = x, y = y, z = z})
    
    -- Noise para variar o tamanho das cavernas
    local size_noise = minetest.get_perlin(noise_cave_size):get_3d({x = x, y = y, z = z})
    local size_factor = (size_noise + 1) / 2  -- Normaliza para 0-1
    
    -- Threshold dinâmico: ajusta a "abertura" das cavernas
    -- Valores menores = cavernas maiores
    -- Valores maiores = cavernas menores/raras
    local threshold = 0.6 + (size_factor * 0.2)  -- Varia entre 0.6 e 0.8
    
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
            if data[vi] ~= c_wetsand then
                return false
            end
        end
    end

    -- volume livre
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            for dy = 0, height do
                local vi = area:index(base_pos.x + dx, base_pos.y + dy, base_pos.z + dz)
                if data[vi] ~= c_air then
                    return false
                end
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

    local corners = {
        {0, 0},
        {3, 0},
        {0, 4},
        {3, 4},
    }

    -- troncos
    for _, c in ipairs(corners) do
        for y = 0, trunk_height - 1 do
            data[area:index(
                base_pos.x + c[1],
                base_pos.y + y,
                base_pos.z + c[2]
            )] = c_palmtrunk
        end
    end

    -- teto
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            data[area:index(
                base_pos.x + dx,
                roof_y,
                base_pos.z + dz
            )] = c_palmleaf
        end
    end
end

local function place_random_chest(area, data, base_pos)
    local candidates = {}

    -- espaço interno: x = 1..2, z = 1..3
    for dx = 1, 2 do
        for dz = 1, 3 do
            table.insert(candidates, {dx = dx, dz = dz})
        end
    end

    if #candidates == 0 then return end

    -- escolha aleatória
    local c = candidates[math.random(#candidates)]

    local chest_pos = {
        x = base_pos.x + c.dx,
        y = base_pos.y,
        z = base_pos.z + c.dz
    }

    local vi = area:index(chest_pos.x, chest_pos.y, chest_pos.z)
    data[vi] = c_oakchest

    -- garantir inicialização correta
    minetest.after(0, function()
        local node = minetest.get_node(chest_pos)
        local def = minetest.registered_nodes[node.name]
        if def and def.on_construct then
            def.on_construct(chest_pos)
        end
    end)
end

-----------------------------
-- GERAÇÃO DO MUNDO
-----------------------------
minetest.register_on_generated(function(minp, maxp)
    -- Otimização: ignora chunks muito altos ou muito baixos
    if maxp.y < -50 or minp.y > 80 then return end

    local vm = minetest.get_voxel_manip()
    local emin, emax = vm:read_from_map(minp, maxp)
    local area = VoxelArea:new {MinEdge = emin, MaxEdge = emax}
    local data = vm:get_data()

    -- Configurações
    local SEA_LEVEL = 10
    local CENTER_X = (MIN_XZ + MAX_XZ) / 2
    local CENTER_Z = (MIN_XZ + MAX_XZ) / 2
    local MAX_RADIUS = (SIZE / 2) * 0.85

    -- Lista para armazenar posições de árvores, pebbles e coqueiros
    local tree_positions = {}
    local pebble_positions = {}
    local palm_positions = {}
    local palm_leaf_rotations = {}  -- Lista para armazenar rotações das folhas

	-- ============================================
	-- EPICENTROS DE NEVE (NOVO SISTEMA)
	-- ============================================
	local SNOW_RADIUS = 350

	local EPICENTER_NE = {
	    x = MAX_XZ * 0.5,
	    z = MAX_XZ * 0.5
	}

	local EPICENTER_SW = {
	    x = MIN_XZ * 0.5,
	    z = MIN_XZ * 0.5
	}

	local function inside_snow_area(x, z)
	    -- Distância ao epicentro NE
	    local dx1 = x - EPICENTER_NE.x
	    local dz1 = z - EPICENTER_NE.z
	    local d1 = dx1*dx1 + dz1*dz1

	    -- Distância ao epicentro SW
	    local dx2 = x - EPICENTER_SW.x
	    local dz2 = z - EPICENTER_SW.z
	    local d2 = dx2*dx2 + dz2*dz2

	    return (d1 <= SNOW_RADIUS*SNOW_RADIUS) or
		   (d2 <= SNOW_RADIUS*SNOW_RADIUS)
	end


        for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- Coordenadas toroidais
            local wx = ((x - MIN_XZ) % SIZE) + MIN_XZ
            local wz = ((z - MIN_XZ) % SIZE) + MIN_XZ

            -- Calcula altura do terreno
            local height, biome_factor = calculate_height(wx, wz, SEA_LEVEL, CENTER_X, CENTER_Z, MAX_RADIUS)

            -- Geração das camadas
            for y = math.max(minp.y, -50), math.min(maxp.y, 75) do
                local vi = area:index(x, y, z)
                
                if y <= -50 then
                    data[vi] = c_redrock
                elseif y <= -48 then
                    data[vi] = c_peridotite
                elseif y <= -46 then
                    data[vi] = c_bedrock
                elseif y <= -43 then
                    data[vi] = c_peridotite
                elseif y <= -40 then
                    data[vi] = c_lava
                elseif y <= -35 then
                    data[vi] = c_basalt
-----------------------------
-- MODIFICAÇÃO NA GERAÇÃO DO MUNDO
-----------------------------

elseif y <= height - 7 then
    -- Verifica se deve ser caverna
    if is_cave(x, y, z) then
        data[vi] = c_air
        
        -- Adiciona água/lava em cavernas profundas
        if y < -30 then
            -- 10% de chance de ter lava
            if math.random() < 0.1 then
                data[vi] = c_lava
            end
        elseif y < -25 then
            -- 30% de chance de ter água
            if math.random() < 0.3 then
                data[vi] = c_water
            end
        end
    else
        data[vi] = c_gneiss
    end
        -- CAMADA VARIÁVEL: Saprolite (0 a 3 blocos)
elseif y <= height - 4 then
    -- Calcula espessura do saprolite usando ruído
    local saprolite_noise = minetest.get_perlin({
        offset = 0,
        scale = 1,
        spread = {x = 40, y = 40, z = 40},
        seed = 9876,
        octaves = 2,
        persist = 0.5,
        lacunarity = 2.0
    }):get_3d({x = wx, y = y, z = wz})
    
    -- Mapeia o ruído (-1 a 1) para espessura (0 a 2)
    local saprolite_thickness = math.floor((saprolite_noise + 1) * 1.5 + 0.5)
    
    -- Verifica se está dentro da espessura do saprolite
    if y > height - 4 - saprolite_thickness then
        data[vi] = c_saprolite
    else
        data[vi] = c_gneiss
    end
                elseif y <= height - 1 then
                    if height <= SEA_LEVEL + 5 then
                        data[vi] = c_sand
                    else
                        data[vi] = c_dirt
                    end
                elseif y == height then
                    local is_mountain = (height > SEA_LEVEL + 8)

		    if is_mountain and inside_snow_area(x, z) then
			data[vi] = c_snow
			goto continue_top
	            end


                    if height <= SEA_LEVEL then
                        data[vi] = c_wetsand
                        -- -----------------------------------------
			-- Propagar areia molhada para baixo (coluna)
			-- -----------------------------------------
			local by = y - 1
			while by >= minp.y do
			    local bvi = area:index(x, by, z)
			    local node_below = data[bvi]

			    -- Se for areia comum, virar areia molhada
			    if node_below == c_sand then
				data[bvi] = c_wetsand
				by = by - 1
			    else
				break -- Parar quando encontrar outro material
			    end
			end
		    elseif height <= SEA_LEVEL + 5 then
                        data[vi] = c_sand
                    elseif height <= SEA_LEVEL + 6 then
                        data[vi] = c_dirt
                        
                     -- -------------------------------
	             -- Adicionar PEBBLES (SEIXOS) raros
	             -- ---------------------------------

			        -- Marca posição para adicionar pebble depois
			    if math.random() < 0.005 then  -- 0.5% de chance
				table.insert(pebble_positions, {x=x, y=height+1, z=z})
			    end
                    elseif height <= SEA_LEVEL + 7 then
                        data[vi] = c_topgrass
                    else
                        data[vi] = c_topgrass
                    end

                    ::continue_top::
                elseif y <= SEA_LEVEL and data[vi] == c_air then
                    data[vi] = c_water
                else
                    data[vi] = c_air
                end
            end 

            -- Árvores (apenas em terreno sólido acima do mar)
            if height > SEA_LEVEL + 6 and height >= minp.y and height <= maxp.y then
                local tree_density = 0.70

                if biome_factor < 0.5 then
                    tree_density = 0.68
                elseif biome_factor > 0.7 then
                    tree_density = 0.72
                end

                local noise_val = minetest.get_perlin(noise_trees):get_2d({x = wx, y = wz})
                if noise_val > tree_density then
                    table.insert(tree_positions, {x=x, y=height+1, z=z, wx=wx, wz=wz, type="tree"})
                end
            end

            -- Arbustos
            if height > SEA_LEVEL + 6 and height >= minp.y and height <= maxp.y then
                local bush_density = 0.75

                if biome_factor < 0.5 then
                    bush_density = 0.72
                elseif biome_factor > 0.7 then
                    bush_density = 0.80
                end

                local noise_bushes = {
                    offset = 0,
                    scale = 0.6,
                    spread = {x = 8, y = 8, z = 8},
                    seed = 98765,
                    octaves = 2,
                    persist = 0.4,
                }

                local bush_noise = minetest.get_perlin(noise_bushes):get_2d({x = wx, y = wz})
                if bush_noise > bush_density then
                    table.insert(tree_positions, {x=x, y=height+1, z=z, wx=wx, wz=wz, type="bush"})
                end
            end

            -- Coqueiros (apenas em areia perto do nível do mar)
            if height >= SEA_LEVEL - 2 and height <= SEA_LEVEL + 3 and height >= minp.y and height <= maxp.y then
                local palm_density = 0.6

                local noise_palms = {
                    offset = 0,
                    scale = 0.6,
                    spread = {x = 15, y = 15, z = 15},
                    seed = 33333,
                    octaves = 2,
                    persist = 0.4,
                }

                local palm_noise = minetest.get_perlin(noise_palms):get_2d({x = wx, y = wz})
                if palm_noise > palm_density then
                    table.insert(palm_positions, {x=x, y=height+1, z=z, wx=wx, wz=wz})
                end
            end

        end -- fim do for x
    end -- fim do for z

    -- SEGUNDA PASSAGEM: Gera as árvores, arbustos e coqueiros após todo o terreno estar pronto
    for _, spawn_data in ipairs(tree_positions) do
        if spawn_data.type == "tree" then
            spawn_tree(area, data, spawn_data, spawn_data.wx, spawn_data.wz)
        elseif spawn_data.type == "bush" then
            spawn_bush(area, data, spawn_data, spawn_data.wx, spawn_data.wz)
        end
    end
    
    -- Gera coqueiros
    for _, palm_data in ipairs(palm_positions) do
        local leaf_nodes = spawn_palm_tree(area, data, palm_data, palm_data.wx, palm_data.wz)
        -- Armazena folhas para rotacionar depois
        if leaf_nodes then
            for _, leaf_info in ipairs(leaf_nodes) do
                table.insert(palm_leaf_rotations, leaf_info)
            end
        end
    end
    
	
	-- TERCEIRA PASSAGEM: Adiciona pebbles no topo E baús embaixo
	for _, pebble_pos in ipairs(pebble_positions) do
	    if area:contains(pebble_pos.x, pebble_pos.y, pebble_pos.z) then
		local vi = area:index(pebble_pos.x, pebble_pos.y, pebble_pos.z)
		-- Só coloca se for ar (evita sobrescrever árvores/arbustos)
		if data[vi] == c_air then
		    data[vi] = c_pebble
		    
		    -- Adiciona baú 2 blocos abaixo (substitui o que estiver lá)
		    local chest_y = pebble_pos.y - 2
		    if area:contains(pebble_pos.x, chest_y, pebble_pos.z) then
		        local chest_vi = area:index(pebble_pos.x, chest_y, pebble_pos.z)
		        data[chest_vi] = c_oakchest  
		    end
		end
	    end
	end

    -- =============================
    -- TORRES DE OBSIDIANA EM 2x2
    -- =============================
    local c_obsidian = minetest.get_content_id("nodes:obsidian")

    -- Altura da torre
    local TOWER_MIN_Y = -50
    local TOWER_MAX_Y = 80

    -- Lista das 4 posições base (cantos do quadrado)
    local tower_bases = {
        {x = MIN_XZ,         z = MIN_XZ},
        {x = MAX_XZ - 1,     z = MIN_XZ},
        {x = MIN_XZ,         z = MAX_XZ - 1},
        {x = MAX_XZ - 1,     z = MAX_XZ - 1},
    }

    -- Gera quatro torres
    for _, base in ipairs(tower_bases) do
        for y = TOWER_MIN_Y, TOWER_MAX_Y do
            for dx = 0, 4 do
                for dz = 0, 4 do
                    local tx = base.x + dx
                    local tz = base.z + dz

                    if tx >= minp.x and tx <= maxp.x and
                       tz >= minp.z and tz <= maxp.z and
                       y  >= minp.y and y  <= maxp.y then

                        local vi = area:index(tx, y, tz)
                        data[vi] = c_obsidian
                    end
                end
            end
        end
    end

if not tent_generated then
    -- limite de busca: perto da origem
    if math.abs(minp.x) > TENT_SEARCH_RADIUS or
       math.abs(minp.z) > TENT_SEARCH_RADIUS then
        return
    end

    -- varrer posições deste chunk
    for z = minp.z, maxp.z do
        for x = minp.x, maxp.x do
            -- prioridade: mais perto da origem
            if (x * x + z * z) <= (TENT_SEARCH_RADIUS * TENT_SEARCH_RADIUS) then
                for y = SEA_LEVEL + 1, SEA_LEVEL + 6 do
                    local base_pos = {x = x, y = y, z = z}

                    if area:contains(x, y, z) then
                        if can_spawn_tent(area, data, base_pos) then
			    spawn_tent(area, data, base_pos)
			    place_random_chest(area, data, base_pos)
			    tent_generated = true
                            break
                        end
                    end
                end
            end
            if tent_generated then break end
        end
        if tent_generated then break end
    end
end

    -- Grava dados no voxelmanip
    vm:set_data(data)
    vm:write_to_map()
    vm:update_map()

	-- Rotaciona folhas de palmeira e inicializa baús
	minetest.after(0, function()
	    -- Rotação das folhas de palmeira
	    for _, leaf_info in ipairs(palm_leaf_rotations) do
		local node = minetest.get_node(leaf_info.pos)
		if node.name == "nodes:palm_leaf" then
		    minetest.set_node(leaf_info.pos, {
		        name = "nodes:palm_leaf",
		        param2 = leaf_info.rotation
		    })
		end
	    end
	    
	    -- Inicializa inventários dos baús
	    for _, pebble_pos in ipairs(pebble_positions) do
		local chest_pos = {x = pebble_pos.x, y = pebble_pos.y - 2, z = pebble_pos.z}
		local node = minetest.get_node(chest_pos)
		
		if node.name == "nodes:oak_chest" then
		    -- Força re-construção do baú para criar o inventário
		    local node_def = minetest.registered_nodes["nodes:oak_chest"]
		    if node_def and node_def.on_construct then
		        node_def.on_construct(chest_pos)
		    end
		end
	    end
	end)
end) -- FIM do register_on_generated


if not minetest.registered_nodes["nodes:grass"] then
    minetest.log("warning", "[terrain] nodes:top_grass não está registrado.")
end

minetest.register_lbm({
    name = "terrain:grass_conversion",
    nodenames = {"nodes:top_grass"},
    run_at_every_load = true,
    action = function(pos)
        local x, y, z = pos.x, pos.y - 1, pos.z
        local n

        n = minetest.get_node({x = x + 1, y = y, z = z}).name
        if n == "nodes:top_grass" or n == "nodes:grass" then
            minetest.set_node(pos, {name = "nodes:grass"})
            return
        end

        n = minetest.get_node({x = x - 1, y = y, z = z}).name
        if n == "nodes:top_grass" or n == "nodes:grass" then
            minetest.set_node(pos, {name = "nodes:grass"})
            return
        end

        n = minetest.get_node({x = x, y = y, z = z + 1}).name
        if n == "nodes:top_grass" or n == "nodes:grass" then
            minetest.set_node(pos, {name = "nodes:grass"})
            return
        end

        n = minetest.get_node({x = x, y = y, z = z - 1}).name
        if n == "nodes:top_grass" or n == "nodes:grass" then
            minetest.set_node(pos, {name = "nodes:grass"})
            return
        end
    end
})


minetest.after(1, function()
    print("[terrain] Pré-gerando área de spawn...")
    minetest.emerge_area(
        {x = -48, y = -16, z = -48},
        {x = 48, y = 80, z = 48},
        function(blockpos, action, calls_remaining)
            if calls_remaining == 0 then
                print("[terrain] Área de spawn pré-gerada com sucesso!")
            end
    end)
end)

print("[terrain] Geração continental com biomas, árvores e coqueiros carregada")
