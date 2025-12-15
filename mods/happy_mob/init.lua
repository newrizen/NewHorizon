--[[
  Mod: Happy Mob
  Versão com múltiplos mobs: Ouriço, Coelho, Galinha, galo, tubarão...
--]]

-------------------------------
-- CONFIGURAÇÕES GLOBAIS
-------------------------------

local DEBUG = true

local function log(msg)
    if DEBUG then
        minetest.log("action", "[Happy Mob] "..msg)
    end
end

-------------------------------
-- MOB 1: OURIÇO (Defensivo)
-------------------------------

mobs:register_mob("happy_mob:ourico", {
    type = "animal",
    passive = true,          -- Pode se defender quando atacado
    damage = 2,
    reach = 1,
    
    hp_min = 10,
    hp_max = 15,
    armor = 100,
    
    collisionbox = {-0.3, 0, -0.25, 0.25, 0.4, 0.25},
    physical = true,
    stepheight = 1.1,
    fall_speed = -8,
    fall_damage = 2,
    
    visual = "mesh",
    mesh = "ourico.obj",
    textures = {"ouricoskin.png", "ouricoshadow.png"},
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    walk_velocity = 1.5,
    run_velocity = 4.5,
    
    view_range = 10,
    water_damage = 1,
    lava_damage = 5,
    light_damage = 0,
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
        run_start = 41,
        run_end = 60,
        jump_start = 61,
        jump_end = 80
    },

    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            minetest.chat_send_player(clicker:get_player_name(), "O ouriço é amigável, mas cuidado ao atacá-lo!")
        end
    end,
})

-- Spawn do Ouriço (grama)
mobs:spawn({
    name = "happy_mob:ourico",
    nodes = {"air"},
    neighbors = {"nodes:grass"},
    max_light = 15,
    interval = 30,
    chance = 3000,
    active_object_count = 5,
    min_height = -10,
    max_height = 25
})

mobs:register_egg("happy_mob:ourico", "Orbe com Ouriço", "orbspawner.png", 0)

-------------------------------
-- MOB 2: COELHO (Passivo/Tímido)
-------------------------------

mobs:register_mob("happy_mob:coelho", {
    type = "animal",
    passive = true,           -- Totalmente passivo
    damage = 0,               -- Não causa dano
    
    hp_min = 5,
    hp_max = 8,
    armor = 80,
    
    collisionbox = {-0.2, 0, -0.3, 0.2, 0.4, 0.3},
    physical = true,
    stepheight = 1.1,
    fall_speed = -8,
    fall_damage = 2,
    
    visual = "mesh",
    mesh = "rabbit.obj",      -- Você precisa criar este modelo
    textures = {"rabbit.png"}, -- Você precisa criar esta textura
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    walk_velocity = 2,
    run_velocity = 6,         -- Coelhos são rápidos quando assustados
    
    view_range = 8,
    water_damage = 1,
    lava_damage = 5,
    light_damage = 0,
    
    -- Coelhos fogem de jogadores
    runaway = true,
    runaway_from = {"player"},
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
        run_start = 41,
        run_end = 60,
    },
    
    -- Coelhos pulam ocasionalmente
    jump = true,
    jump_height = 4,

    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            minetest.chat_send_player(clicker:get_player_name(), "O coelho fugiu assustado!")
            -- Faz o coelho pular e fugir
            self.object:set_velocity({x = 0, y = 6, z = 0})
        end
    end,
    
    -- Sons (se você tiver arquivos de som)
    sounds = {
        random = "coelho_sound",
        damage = "coelho_hurt",
    },
})

-- Spawn do Coelho (neve)
mobs:spawn({
    name = "happy_mob:coelho",
    nodes = {"air"},
    neighbors = {"nodes:snow"},
    max_light = 15,
    interval = 30,
    chance = 2500,            -- Spawn mais frequente
    active_object_count = 8,  -- Mais coelhos podem spawnar
    min_height = 0,
    max_height = 100
})

mobs:register_egg("happy_mob:coelho", "Orbe com Coelho", "orbspawner.png", 0)

-------------------------------
-- MOB 3: GALO (Agressivo)
-------------------------------

mobs:register_mob("happy_mob:galo", {
    type = "animal",
    passive = false,
    reach = 1,
    damage = 1,
    attack_type = "dogfight",
    -- drop com a sintaxe correta
    drops = {
        {name = "items:feather", chance = 1, min = 1, max = 5},  -- 1-5 penas
        {name = "nodes:raw_chicken", chance = 1, min = 1, max = 1},  -- 1 galinha crua (sempre)
    },
    
    hp_min = 4,
    hp_max = 8,
    armor = 100,
    
    collisionbox = {-0.25, 0, -0.2, 0.3, 0.4, 0.2}, -- X (frente), y (em baixo), z (lateral) / x (traz), y (cima), z (lateral)
    selectionbox = {-0.5, 0, -0.2, 0.5, 0.4, 0.2}, -- X (frente), y (em baixo), z (lateral) / x (traz), y (cima), z (lateral)
    physical = true,
    stepheight = 1.1,
    fall_speed = -4,          -- Galinhas caem devagar (batem asas)
    fall_damage = 0,
    floats = 2,               -- Não nadam bem
    
    visual = "mesh",
    mesh = "rooster.obj",     -- Você precisa criar este modelo
    textures = {"rooster.png"}, -- Você precisa criar esta textura
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    walk_velocity = 1,
    run_velocity = 4,
    
    view_range = 8,
    water_damage = 0,
    lava_damage = 5,
    light_damage = 0,
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
    },
    
    -- Galinhas podem ser alimentadas e seguir o jogador com sementes
    follow = {"farming:seed_wheat", "default:grass_1"},


    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            local item = clicker:get_wielded_item()
            local name = item:get_name()
            
            -- Se o jogador está segurando sementes, a galinha segue
            if name == "farming:seed_wheat" or name == "default:grass_1" then
                minetest.chat_send_player(clicker:get_player_name(), "O galo está interessada na comida!")
            else
                minetest.chat_send_player(clicker:get_player_name(), "Cocoricó! 🐔")
            end
        end
    end,
    
    -- Sons da galinha
    sounds = {
        random = "galinha_cacarejo",
        damage = "galinha_hurt",
    },
})

-- Spawn da Galinha (terra/dirt)
mobs:spawn({
    name = "happy_mob:galo",
    nodes = {"air"},
    neighbors = {"nodes:dirt", "nodes:grass"},  -- Spawna em dirt e grama
    max_light = 15,
    interval = 30,
    chance = 2000,            -- Spawn frequente
    active_object_count = 2, -- Muitas galinhas
    min_height = -10,
    max_height = 50
})

mobs:register_egg("happy_mob:galo", "Orbe com Galo", "orbspawner.png", 0)

-------------------------------
-- MOB 3: GALINHA (Passiva/Põe Ovos)
-------------------------------

mobs:register_mob("happy_mob:galinha", {
    type = "animal",
    passive = true,
    damage = 0,
    -- drop com a sintaxe correta
    drops = {
        {name = "items:feather", chance = 1, min = 1, max = 5},  -- 1-5 penas
        {name = "nodes:raw_chicken", chance = 1, min = 1, max = 1},  -- 1 galinha crua (sempre)
    },
    
    hp_min = 4,
    hp_max = 8,
    armor = 100,
    
    collisionbox = {-0.25, 0, -0.2, 0.3, 0.4, 0.2}, -- X (frente), y (em baixo), z (lateral) / x (traz), y (cima), z (lateral)
    selectionbox = {-0.5, 0, -0.2, 0.5, 0.4, 0.2}, -- X (frente), y (em baixo), z (lateral) / x (traz), y (cima), z (lateral)
    physical = true,
    stepheight = 1.1,
    fall_speed = -4,          -- Galinhas caem devagar (batem asas)
    fall_damage = 0,
    floats = 2,               -- Não nadam bem
    
    visual = "mesh",
    mesh = "chicken.obj",     -- Você precisa criar este modelo
    textures = {"chicken.png"}, -- Você precisa criar esta textura
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    walk_velocity = 1,
    run_velocity = 3,
    
    view_range = 8,
    water_damage = 0,
    lava_damage = 5,
    light_damage = 0,
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
    },
    
    -- Galinhas podem ser alimentadas e seguir o jogador com sementes
    follow = {"farming:seed_wheat", "default:grass_1"},
    
    -- Sistema de ovos
    on_step = function(self, dtime)
        -- Timer para botar ovos
        self.egg_timer = (self.egg_timer or 0) + dtime
        
        -- Bota um ovo a cada 60-120 segundos
        if self.egg_timer > math.random(60, 120) then
            local pos = self.object:get_pos()
            minetest.add_item(pos, "happy_mob:chicken_egg")  -- Você precisa criar este item nodes:egg
            self.egg_timer = 0
            log("Galinha botou um ovo em " .. minetest.pos_to_string(pos))
        end
    end,

    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            local item = clicker:get_wielded_item()
            local name = item:get_name()
            
            -- Se o jogador está segurando sementes, a galinha segue
            if name == "farming:seed_wheat" or name == "default:grass_1" then
                minetest.chat_send_player(clicker:get_player_name(), "A galinha está interessada na comida!")
            else
                minetest.chat_send_player(clicker:get_player_name(), "Cocoricó! 🐔")
            end
        end
    end,
    
    -- Sons da galinha
    sounds = {
        random = "galinha_cacarejo",
        damage = "galinha_hurt",
    },
})

-- Spawn da Galinha (terra/dirt)
mobs:spawn({
    name = "happy_mob:galinha",
    nodes = {"air"},
    neighbors = {"nodes:dirt", "nodes:grass"},  -- Spawna em dirt e grama
    max_light = 15,
    interval = 30,
    chance = 2000,            -- Spawn frequente
    active_object_count = 10, -- Muitas galinhas
    min_height = -10,
    max_height = 50
})

mobs:register_egg("happy_mob:galinha", "Orbe com Galinha", "orbspawner.png", 0)

-------------------------------
-- MOB 4: TUBARÃO (Agressivo)
-------------------------------
mobs:register_mob("happy_mob:shark", {
    type = "animal",
    passive = false,
    reach = 1,
    damage = 5,
    attack_type = "dogfight",
    
    hp_min = 20,
    hp_max = 30,
    armor = 100,
    
    collisionbox = {-1.25, 0, -0.2, 1.3, 0.4, 0.2},
    selectionbox = {-1.5, 0, -0.2, 1.5, 0.4, 0.2},
    physical = true,
    stepheight = 0,           -- NÃO consegue subir degraus (importante!)
    fall_speed = -6,
    fall_damage = 0,
    floats = 1,
    
    visual = "mesh",
    mesh = "shark.obj",
    textures = {"shark.png"},
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    -- IMPORTANTE: Propriedades para manter na água
    fly = true,               -- Permite "voar" na água
    fly_in = "nodes:water",   -- Só "voa" dentro de nodes:water
    
    walk_velocity = 1,
    run_velocity = 4,
    
    view_range = 16,
    water_damage = 0,
    lava_damage = 5,
    light_damage = 0,
    air_damage = 2,           -- CRÍTICO: Recebe dano fora da água!
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
    },
    
    follow = {"nodes:raw_chicken"},
    
    -- ADICIONE: Função para forçar o tubarão a voltar para água
    do_custom = function(self, dtime)
        local pos = self.object:get_pos()
        local node = minetest.get_node(pos)
        
        -- Se não está na água, tenta voltar
        if node.name ~= "nodes:water" then
            -- Procura por água próxima
            local water_pos = minetest.find_node_near(pos, 5, {"nodes:water"})
            
            if water_pos then
                -- Move em direção à água
                local dir = vector.direction(pos, water_pos)
                self.object:set_velocity(vector.multiply(dir, 2))
            end
        end
    end,
    
    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            local item = clicker:get_wielded_item()
            local name = item:get_name()
            
            if name == "nodes:raw_chicken" then
                minetest.chat_send_player(clicker:get_player_name(), "O tubarão está com fome!")
            else
                minetest.chat_send_player(clicker:get_player_name(), "Glub, glub...")
            end
        end
    end,
    
    sounds = {
        random = "tubarao_som",
        damage = "tubarao_hurt",
    },
})

-- Spawn do tubarão (somente na água)
mobs:spawn({
    name = "happy_mob:shark",
    nodes = {"nodes:water"},           -- Spawna DENTRO da água
    neighbors = {"nodes:wet_sand"},
    max_light = 15,
    interval = 30,
    chance = 2000,
    active_object_count = 2,
    min_height = -20,
    max_height = 5                     -- Não spawna acima do nível do mar
})

mobs:register_egg("happy_mob:shark", "Orbe com Tubarão", "orbspawner.png", 0)

-------------------------------
-- MOB 4: RATAZANA (Agressivo)
-------------------------------
mobs:register_mob("happy_mob:rat", {
    type = "animal",
    passive = false,
    reach = 1,
    damage = 2,
    attack_type = "dogfight",
    
    hp_min = 8,
    hp_max = 10,
    armor = 100,
    
    collisionbox = {-0.25, 0, -0.2, 0.3, 0.4, 0.2},
    selectionbox = {-0.5, 0, -0.2, 0.5, 0.4, 0.2},
    physical = true,
    stepheight = 3,
    fall_speed = -8,
    fall_damage = 0,
    floats = 1,
    
    visual = "mesh",
    mesh = "rat.obj",
    textures = {"rat.png"},
    rotate = 180,
    visual_size = {x = 15, y = 15},
    
    -- PERMITIRIA "VOAR" DENTRO DAS FOLHAS se não retirasse a capacidade de andar...
    --fly = true,
    --fly_in = {"nodes:leaves"},  -- Pode ser uma lista!
    
    walk_velocity = 3,
    run_velocity = 6,
    
    view_range = 8,
    water_damage = 0,
    lava_damage = 5,
    light_damage = 0,
    
    animation = {
        speed_normal = 15,
        stand_start = 0,
        stand_end = 20,
        walk_start = 21,
        walk_end = 40,
    },
    
    follow = {"nodes:blueberry"},

    on_rightclick = function(self, clicker)
        if clicker:is_player() then
            local item = clicker:get_wielded_item()
            local name = item:get_name()
            
            if name == "nodes:blueberry" then
                minetest.chat_send_player(clicker:get_player_name(), "A ratazana quer comida!")
            else
                minetest.chat_send_player(clicker:get_player_name(), "Quick, quick...")
            end
        end
    end,
    
    sounds = {
        random = "rat_quick",
        damage = "rat_hurt",
    },
})

-- Spawn da ratazana (grama perto de árvores)
mobs:spawn({
    name = "happy_mob:rat",
    nodes = {"air"},
    neighbors = {"nodes:grass", "nodes:wood", "default:tree"},
    max_light = 15,
    interval = 30,
    chance = 2000,
    active_object_count = 3,
    min_height = -20,
    max_height = 30                  
})

mobs:register_egg("happy_mob:rat", "Orbe com Ratazana", "orbspawner.png", 0)

-------------------------------
-- ITEM: OVO (Exemplo)
-------------------------------
-- Você pode criar um item de ovo que as galinhas dropam
minetest.register_craftitem("happy_mob:chicken_egg", { -- Você precisa criar este item nodes:egg
    description = "Ovo de galinha",
    inventory_image = "mobs_chicken_egg.png",  -- Crie esta textura
    on_use = minetest.item_eat(2), -- Come o ovo cru (restaura 2 de fome)
})

-------------------------------
-- LOGS FINAIS
-------------------------------

minetest.register_on_mods_loaded(function()
    log("===========================================")
    log("Mod Happy Mob inicializado com sucesso!")
    log("===========================================")
    log("")
    log("OURIÇO:")
    log("  - Spawn: nodes:grass")
    log("  - Comportamento: Passivo, mas se defende quando atacado")
    log("  - Dano: 2 HP")
    log("")
    log("COELHO:")
    log("  - Spawn: nodes:snow")
    log("  - Comportamento: Totalmente passivo e tímido")
    log("  - Foge de jogadores")
    log("")
    log("GALINHA:")
    log("  - Spawn: nodes:dirt e nodes:grass")
    log("  - Comportamento: Passiva, segue jogadores com sementes")
    log("  - Bota ovos periodicamente")
    log("")
    log("===========================================")
end)
