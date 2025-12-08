--[[
  Mod: Happy Mob
  Versão comentada e aprimorada
  Descrição completa do funcionamento interno
--]]

-------------------------------
-- CONFIGURAÇÕES INICIAIS
-------------------------------

-- Lista de nós válidos para spawn (deve ter pelo menos 1 nó)
local spawn_nodes = {
  "nodes:grass" -- Nós de pedra como base para spawn
}

-- Probabilidade de spawn (1 em 30000 chances por intervalo)
local spawn_chance = 3000 --30000

-- Texturas disponíveis para o mob (arquivos devem existir na pasta textures)
local mob_textures = {
  "ouricoskin.png", -- Textura principal obrigatória
  "happy_mob_texture_alt.png" -- Textura alternativa opcional
}

-- Sistema de debug (true para ver logs detalhados)
local DEBUG = true

-- Função de log personalizada
local function log(msg)
    if DEBUG then
        minetest.log("action", "[Happy Mob] "..msg)
    end
end

-------------------------------
-- REGISTRO PRINCIPAL DO MOB
-------------------------------

mobs:register_mob("happy_mob:ourico", {
    -- PROPRIEDADES BÁSICAS --
    type = "animal",          -- Tipo de entidade (animal/monster/npc)
    passive = true,           -- Não ataca jogadores
    damage = 0,               -- Dano causado em contato
    reach = 2,                -- Alcance de interação
    attack_type = "dogfight", -- Tipo de IA de combate (não usado em mobs passivos)
    
    -- CONFIGURAÇÕES DE SAÚDE --
    hp_min = 10,              -- Vida mínima inicial
    hp_max = 15,              -- Vida máxima inicial
    armor = 100,              -- Resistência a danos (0-100)
    
    -- FÍSICA E COLISÃO --
    collisionbox = {-0.35, 0, -0.35, 0.35, 0.4, 0.35}, -- Caixa de colisão (X1,Y1,Z1,X2,Y2,Z2)
    physical = true,          -- Respeita as leis da física
    stepheight = 1.1,         -- Altura máxima que pode subir (em blocos)
    fall_speed = -8,          -- Força da gravidade (valores negativos)
    fall_damage = 0,          -- Dano por queda desativado
    
    -- PARÂMETROS VISUAIS --
    visual = "mesh",          -- Tipo de renderização (mesh/sprite)
    mesh = "ourico.obj",   -- Arquivo do modelo 3D
    textures = mob_textures,  -- Lista de texturas aplicáveis
    rotate = 180,             -- Correção de rotação do modelo (graus)
    visual_size = {x = 15, y = 15}, -- Ajuste ou alteração de tamanho
    
    
    -- VELOCIDADES --
    walk_velocity = 1.5,      -- Velocidade normal de caminhada
    run_velocity = 4.5,       -- Velocidade máxima de corrida
    
    -- CONFIGURAÇÕES DE COMPORTAMENTO --
    view_range = 10,          -- Alcance de detecção de jogadores (em blocos)
    water_damage = 1,         -- Dano por segundo na água
    lava_damage = 5,          -- Dano por segundo na lava
    light_damage = 0,         -- Dano por exposição à luz
    
    -- SISTEMA DE ESTADOS INTERNOS --
    states = {
        idle = 0,     -- Estado parado/ocioso
        walking = 1,  -- Estado de movimento normal
        jumping = 2,  -- Estado durante pulo
        fleeing = 3   -- Estado de fuga de jogadores
    },
    
    -- ANIMAÇÕES DISPONÍVEIS --
    animation = {
        speed_normal = 15,    -- Velocidade base das animações
        stand_start = 0,      -- Quadro inicial de idle
        stand_end = 20,       -- Quadro final de idle
        walk_start = 21,      -- Quadro inicial de caminhada
        walk_end = 40,        -- Quadro final de caminhada
        run_start = 41,       -- Quadro inicial de corrida
        run_end = 60,         -- Quadro final de corrida
        jump_start = 61,      -- Quadro inicial de pulo
        jump_end = 80         -- Quadro final de pulo
    },

    --[[ 
      CALLBACK: on_activate
      Executado quando o mob é criado/spawnado
      Parâmetros:
        self - Referência da entidade
    --]]
    on_activate = function(self)
        self.state = self.states.idle  -- Define estado inicial
        self:set_animation("stand")    -- Inicia animação de idle
        log("Mob ativado em " .. minetest.pos_to_string(self.object:get_pos()))
    end,

    --[[ 
      CALLBACK: on_step
      Executado a cada frame para atualizar lógica
      Parâmetros:
        self - Referência da entidade
        dtime - Delta time desde o último frame
    --]]
    on_step = function(self, dtime)
        local pos = self.object:get_pos()
        if not pos then return end

        -- Atualização de temporizadores --
        self.jump_cooldown = (self.jump_cooldown or 0) - dtime
        self.fear_time = (self.fear_time or 0) - dtime

        -- Verificação de superfície --
        local pos_down = {x = pos.x, y = pos.y - 0.5, z = pos.z}
        local node_down = minetest.get_node(pos_down)
        local on_ground = minetest.registered_nodes[node_down.name] and
                         minetest.registered_nodes[node_down.name].walkable

        -- Máquina de estados principal --
        if self.state == self.states.idle then
            self.idle_timer = (self.idle_timer or 0) + dtime
            
            -- Transição para movimento após 3-8 segundos
            if self.idle_timer > math.random(3, 8) then
                self.state = self.states.walking
                self:set_animation("walk")
                self.walk_direction = math.random() * 2 * math.pi  -- Direção aleatória
                self.walk_duration = math.random(2, 5)            -- Duração do movimento
                self.idle_timer = nil
                log("Iniciando movimento")
            end

        elseif self.state == self.states.walking then
            self.walk_duration = self.walk_duration - dtime
            
            -- Detecção de obstáculos --
            local yaw = self.walk_direction
            local dir = {x = math.cos(yaw), z = math.sin(yaw)}
            local pos_front = {
                x = pos.x + dir.x * 0.5,
                y = pos.y + 0.5,
                z = pos.z + dir.z * 0.5
            }

            -- Lógica de pulo sobre obstáculos --
            if minetest.registered_nodes[minetest.get_node(pos_front).name].walkable then
                self.object:set_velocity({
                    x = dir.x * 2,
                    y = 6,  -- Força vertical do pulo
                    z = dir.z * 2
                })
                self:set_animation("jump")
                self.state = self.states.jumping
                log("Pulando obstáculo")
            else
                -- Movimentação normal --
                local x = math.cos(yaw) * self.walk_velocity
                local z = math.sin(yaw) * self.walk_velocity
                self.object:set_velocity({x = x, y = self.object:get_velocity().y, z = z})
            end
            
            -- Atualização de rotação --
            self.object:set_yaw(yaw - math.pi/2)  -- Ajuste de orientação do modelo

            -- Finalização do movimento --
            if self.walk_duration <= 0 or not on_ground then
                self.state = self.states.idle
                self:set_animation("stand")
                self.object:set_velocity({x = 0, y = self.object:get_velocity().y, z = 0})
                log("Voltando para estado ocioso")
            end

        elseif self.state == self.states.jumping then
            -- Verificação de aterrissagem --
            if on_ground then
                self.state = self.states.idle
                self:set_animation("stand")
                log("Pulo concluído")
            end

        elseif self.state == self.states.fleeing then
            -- Lógica de fuga persistente --
            if self.fear_time <= 0 then
                self.state = self.states.idle
                self:set_animation("stand")
                log("Fim do estado de fuga")
            else
                local flee_dir = {
                    x = -self.flee_from.x,
                    z = -self.flee_from.z
                }
                local yaw = math.atan2(flee_dir.z, flee_dir.x) - math.pi/2
                self.object:set_yaw(yaw)
                self.object:set_velocity({
                    x = flee_dir.x * self.run_velocity,
                    y = self.object:get_velocity().y,
                    z = flee_dir.z * self.run_velocity
                })
            end
        end

        -- Detecção de jogadores próximos --
        local players = minetest.get_objects_inside_radius(pos, self.view_range)
        for _, player in ipairs(players) do
            if player:is_player() then
                local player_pos = player:get_pos()
                local dist = vector.distance(pos, player_pos)
                
                -- Pulo social com cooldown --
                if dist < 3 and self.jump_cooldown <= 0 and on_ground then
                    self.jump_cooldown = 30  -- Cooldown de 30 segundos
                    self:set_animation("jump")
                    self.object:set_velocity({x = 0, y = 7, z = 0})
                    minetest.chat_send_player(player:get_player_name(), "O ouriço pulou de alegria!")
                    log("Pulo social executado")
                end
            end
        end
    end,

    --[[ 
      CALLBACK: on_punch
      Executado quando o mob é atingido
      Parâmetros:
        self - Referência da entidade
        puncher - Jogador que atacou
        time_from_last_punch - Tempo desde o último ataque
        tool_capabilities - Capacidades da ferramenta usada
        dir - Vetor de direção do ataque
    --]]
    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
        if not dir then return end
        
        -- Ativa modo de fuga --
        self.state = self.states.fleeing
        self.fear_time = 10  -- Duração de 10 segundos
        self.flee_from = vector.normalize(dir)
        self:set_animation("run")
        
        -- Aplica força de fuga --
        self.object:set_velocity({
            x = -self.flee_from.x * self.run_velocity,
            y = 6,  -- Pequeno impulso vertical
            z = -self.flee_from.z * self.run_velocity
        })
        log("Mob em fuga após ataque")
    end,

    --[[ 
      CALLBACK: on_rightclick
      Executado no clique direito do jogador
      Parâmetros:
        self - Referência da entidade
        clicker - Jogador que interagiu
    --]]
    on_rightclick = function(self, clicker)
        local pos = self.object:get_pos()
        local pos_down = {x = pos.x, y = pos.y - 0.5, z = pos.z}
        local node_down = minetest.get_node(pos_down)
        local on_ground = minetest.registered_nodes[node_down.name] and
                         minetest.registered_nodes[node_down.name].walkable

        if on_ground then
            local player_name = clicker:get_player_name()
            minetest.chat_send_player(player_name, "Você fez o ouriço pular!")
            self.object:set_velocity({x = 0, y = 7, z = 0})
            self:set_animation("jump")
            log("Pulo induzido por jogador")
        end
    end
})

-------------------------------
-- CONFIGURAÇÃO DE SPAWN
-------------------------------

mobs:spawn({
    name = "happy_mob:ourico",
    nodes = {"air"},          -- Spawna no ar acima dos nós especificados
    neighbors = spawn_nodes,  -- Exige proximidade com esses nós
    max_light = 15,           -- Nível máximo de luminosidade
    interval = 30,            -- Intervalo de tentativas de spawn (segundos)
    chance = spawn_chance,     -- Probabilidade de spawn
    active_object_count = 10,   -- Quantidade máxima na área
    min_height = -10,         -- Altura mínima no mapa
    max_height = 25           -- Altura máxima no mapa
})

-------------------------------
-- OVO CRIATIVO
-------------------------------

mobs:register_egg("happy_mob:ourico", "Ovo para Ouriço", "mobs_chicken_egg.png", 0)

-------------------------------
-- LOGS FINAIS
-------------------------------

minetest.register_on_mods_loaded(function()
    log("Mod inicializado com sucesso!")
    log("Configuração de spawn:")
    log("Chance: 1 em " .. spawn_chance)
    log("Nós de spawn: " .. table.concat(spawn_nodes, ", "))
end)
