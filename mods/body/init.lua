-- Arquivo: body/init.lua
print("[body] Mod carregado")

------------------------------------------------------------
-- TABELAS GLOBAIS
------------------------------------------------------------
local body_objects = {}
local hand3d_objects = {}
local shadow_objects = {}

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
    },
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
        self.object:set_rotation({x = math.pi/2, y = 0, z = 0})
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
-- FUNÇÃO PARA ROTACIONAR CABEÇA E CORPO
------------------------------------------------------------
local function rotate_head_to_look(self, player)
    if not player then return end
    
    local look_pitch = player:get_look_vertical()
    local look_yaw = player:get_look_horizontal()
    local ctrl = player:get_player_control()
    
    -- Detecta se está pressionando teclas de movimento
    local is_moving_keys = ctrl.up or ctrl.down or ctrl.left or ctrl.right
    
    -- Inicializa body_yaw se não existir
    --if not self.body_yaw then
    --    self.body_yaw = look_yaw
    --end
    
    -- Atualiza body_yaw baseado no estado de movimento
    if is_moving_keys then
        -- Em movimento: body_yaw segue a direção da câmera
        -- (centraliza a cabeça, pois o corpo sempre aponta para onde olha)
        self.body_yaw = look_yaw
    else
        -- Parado: body_yaw MANTÉM o último valor
        -- (isso permite que a cabeça gire independentemente)
        -- self.body_yaw permanece inalterado
    end
    
    -- Calcula diferença entre olhar e corpo
    local yaw_diff = look_yaw - self.body_yaw
    
    -- Normaliza o ângulo para ficar entre -π e π
    while yaw_diff > math.pi do
        yaw_diff = yaw_diff - 2 * math.pi
    end
    while yaw_diff < -math.pi do
        yaw_diff = yaw_diff + 2 * math.pi
    end
    
    -- Converte para graus
    local head_pitch = math.deg(-look_pitch)
    local head_yaw_raw = math.deg(-yaw_diff)
    
    -- Limite da cabeça
    local head_limit = 60
    
    -- Aplica a rotação da cabeça
    local head_yaw
    if is_moving_keys then
        -- Em movimento: cabeça centralizada (0° relativo ao corpo)
        head_yaw = 0
    else
        -- Parado: cabeça pode girar livremente
        head_yaw = math.max(-head_limit, math.min(head_limit, head_yaw_raw))
    end
    
    -- Limita a rotação vertical
    head_pitch = math.max(-60, math.min(60, head_pitch))
    
    -- Calcula rotação do corpo em graus (baseado no body_yaw armazenado)
    local body_rotation = math.deg(-self.body_yaw)
    
    -- Rotaciona a cabeça
    self.object:set_bone_position(
        "bone_All_Head",
        {x = 0.5, y = 5, z = 0},
        {x = 0, y = head_yaw * 0.5, z = head_pitch}
    )
    
    -- Rotaciona o torso e braços
    self.object:set_bone_position(
        "bone_TorsoArms",
        {x = 0, y = 0, z = 0},
        {x = 0, y = 0, z = 0}
    )
    
    -- Rotaciona as pernas
    self.object:set_bone_position(
        "bone_Legs",
        {x = 0, y = 0, z = 0},
        {x = 0, y = 0, z = 0}
    )
end

------------------------------------------------------------
-- ENTIDADE DE CORPO
------------------------------------------------------------
minetest.register_entity("body:body_entity", {
    initial_properties = {
        visual = "mesh",
        mesh = "skin2.gltf",
        textures = {"skin2.png"},
        visual_size = {x = 2, y = 2, z = 2},
        physical = false,
        collide_with_objects = false,
        pointable = false,
        static_save = false,
        backface_culling = false,
        glow = 0,
        shaded = true,
        makes_footstep_sound = false,
    },
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
        self.object:set_nametag_attributes({
            color = {a = 0, r = 255, g = 255, b = 255},
            text = "",
        })
        self.body_yaw = 0
    end,

    on_step = function(self, dtime)
        local parent = self.object:get_attach()
        if not parent then
            self.object:remove()
            return
        end
        
        if not parent:is_player() then
            return
        end
        
        -- Rotação estilo Minecraft
        rotate_head_to_look(self, parent)
        
        local ctrl = parent:get_player_control()
        local vel = parent:get_velocity()
        
        if ctrl.jump and vel.y >= 0 then
            self:set_animation("jump")
            return
        end
        
        if ctrl.sneak and vel.x < 0.1 and vel.z < 0.1 then
            self:set_animation("sneak")
            return
        end
        
        local is_moving_back = ctrl.down
        local is_moving = ctrl.up or ctrl.left or ctrl.right
        local horizontal = {x = vel.x, y = 0, z = vel.z}
        local speed = vector.length(horizontal)
     
        if is_moving_back then
            if ctrl.sneak and speed >= 0.1 then
                self:set_animation("sneak_walk_back")
                return
            end
            if ctrl.aux1 or speed >= 4 then
                self:set_animation("run_back")
                return
            elseif speed < 4 and speed > 0 then
                self:set_animation("walk_back")
                return
            end
        end  

        if is_moving then
            if ctrl.sneak and speed >= 0.1 then
                self:set_animation("sneak_walk")
                return
            end
            if ctrl.aux1 or speed >= 4 then
                self:set_animation("run")
                return
            elseif speed < 4 and speed > 0 then
                self:set_animation("walk")
                return
            end
        else
            self:set_animation("idle")
            return
        end
    end,

    set_animation = function(self, anim)
        if self.current_anim == anim then return end
        self.current_anim = anim
        
        if anim == "idle" then
            self.object:set_animation({x = 0, y = 1}, 0.25, 0, true)
        elseif anim == "jump" then
            self.object:set_animation({x = 2.08, y = 2.63}, 4, 0, false)
        elseif anim == "climb" then
            self.object:set_animation({x = 2.08, y = 2.63}, 1, 0, true)
        elseif anim == "walk" then
            self.object:set_animation({x = 1, y = 2}, 2, 0, true)
        elseif anim == "walk_back" then
            self.object:set_animation({x = 2, y = 1}, 2, 0, true)
        elseif anim == "run" then
            self.object:set_animation({x = 1, y = 2}, 6, 0, true)
        elseif anim == "run_back" then
            self.object:set_animation({x = 2, y = 1}, 6, 0, true)
        elseif anim == "sneak" then
            self.object:set_animation({x = 2.63, y = 2.88}, 2, 0, false)
        elseif anim == "sneak_walk" then
            self.object:set_animation({x = 2.91, y = 4.91}, 0.8, 0, true)
        elseif anim == "sneak_walk_back" then
            self.object:set_animation({x = 4.91, y = 2.91}, 0.8, 0, true)
        end
    end,
})

------------------------------------------------------------
-- FUNÇÃO PARA TORNAR O MODELO PADRÃO INVISÍVEL (demais configurações permanecem validas) 
------------------------------------------------------------
local function make_player_invisible(player)
    if not player then return end
    
    player:set_properties({
        visual = "mesh",
        mesh = "mcl_meshhand.b3d",
        textures = {"blank.png^[opacity:0"},
        visual_size = {x = 0, y = 0, z = 0},
        collisionbox = {-0.3, 0.0, -0.3, 0.3, 2.7, 0.3},
        stepheight = 0.6,
        eye_height = 2.4,
        makes_footstep_sound = true,
        alpha = 160,
    })
    
    print("[body] Modelo padrão ocultado para " .. player:get_player_name())
end

------------------------------------------------------------
-- FUNÇÃO PARA CRIAR O CORPO
------------------------------------------------------------
local function create_body(player)
    if not player then return end
    
    local player_name = player:get_player_name()
    
    if body_objects[player_name] then
        body_objects[player_name]:remove()
        body_objects[player_name] = nil
    end
    
    local body = minetest.add_entity(player:get_pos(), "body:body_entity")
    if body then
        body:set_attach(
            player,
            "",
            {x = 0, y = 11.1, z = 0},
            {x = 0, y = -90, z = 0}
        )
        body_objects[player_name] = body
        print("[body] Corpo criado para " .. player_name)
    else
        print("[body] ERRO: Não foi possível criar corpo para " .. player_name)
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
-- EVENTOS DE JOGADOR
------------------------------------------------------------

minetest.register_on_joinplayer(function(player)
    minetest.after(0.3, function()
        if player and player:is_player() then
            make_player_invisible(player)
            create_body(player)
            create_shadow(player)
        end
    end)
end)

minetest.register_on_leaveplayer(function(player)
    local player_name = player:get_player_name()
    if body_objects[player_name] then
        body_objects[player_name]:remove()
        body_objects[player_name] = nil
        print("[body] Corpo removido para " .. player_name)
    end
    if shadow_objects[player_name] then
        shadow_objects[player_name]:remove()
        shadow_objects[player_name] = nil
    end
end)

minetest.register_on_dieplayer(function(player)
    local player_name = player:get_player_name()
    if body_objects[player_name] then
        body_objects[player_name]:remove()
        body_objects[player_name] = nil
    end
    if shadow_objects[player_name] then
        shadow_objects[player_name]:remove()
        shadow_objects[player_name] = nil
    end
end)

minetest.register_on_respawnplayer(function(player)
    minetest.after(0.5, function()
        if player and player:is_player() then
            make_player_invisible(player)
            create_body(player)
            create_shadow(player)
        end
    end)
end)
