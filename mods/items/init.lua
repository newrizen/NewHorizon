-- Arquivo: items/init.lua
-----------------------------
-- ITEMS
-----------------------------
print("[items] init.lua carregado")

-- Criar tabela namespace para o mod (no início do arquivo init.lua)
items = {}


minetest.register_craftitem("items:stick", {
    description = "Graveto",
    inventory_image = "graveto.png",
    wield_image = "graveto.png",
    wield_scale = {x = 0.7, y = 0.7, z = 0.7},

    range = 5, -- AUMENTA O ALCANCE

    tool_capabilities = {
        full_punch_interval = 1.0,
        max_drop_level = 0,
        groupcaps = {
            crumbly = {times = {[3] = 1.00}, uses = 0},
            cracky  = {times = {[3] = 2.00}, uses = 0},
            snappy  = {times = {[3] = 0.80}, uses = 0},
            choppy  = {times = {[3] = 1.50}, uses = 0},
        },
        damage_groups = {fleshy = 1},
    },
})

-- Itens necessários para escrever
minetest.register_craftitem("items:feather", {
    description = "Pena",
    inventory_image = "feather.png",
    wield_image = "feather.png",
    wield_scale = {x = 0.2, y = 0.2, z = 0.01},
})

minetest.register_craftitem("items:bottle", {
    description = "Frasco",
    inventory_image = "bottle.png",
    wield_image = "bottle.png",
    wield_scale = {x = 0.3, y = 0.3, z = 0.5},
})

minetest.register_craftitem("items:inkbottle", {
    description = "Frasco com tinta",
    inventory_image = "inkbottle.png",
    wield_image = "inkbottle.png",
    wield_scale = {x = 0.3, y = 0.3, z = 0.5},
})


-- Função auxiliar para verificar se o jogador tem os itens necessários
local function player_has_writing_tools(player)
    local inv = player:get_inventory()
    local has_feather = false
    local has_ink = false
    
    -- Verificar hotbar (slots 1-8)
    for i = 1, 8 do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == "items:feather" then
            has_feather = true
        end
    end
    
    -- Verificar inventário inteiro para frasco de tinta
    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == "items:inkbottle" then
            has_ink = true
        end
    end
    
    return has_feather, has_ink
end

-- Função para consumir a tinta após escrever
local function consume_ink(player)
    local inv = player:get_inventory()
    
    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if stack:get_name() == "items:inkbottle" then
            stack:take_item(1)
            inv:set_stack("main", i, stack)
            -- Adicionar frasco vazio de volta
            inv:add_item("main", ItemStack("items:bottle"))
            return true
        end
    end
    return false
end

-- Registro do item Página (em branco)
minetest.register_craftitem("items:page", {
    description = "Página",
    inventory_image = "page.png",
    wield_image = "page.png",
    wield_scale = {x = 0.5, y = 0.5, z = 0.01},
    
    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then
            return
        end
        
        local player_name = user:get_player_name()
        local has_feather, has_ink = player_has_writing_tools(user)
        
        if not has_feather or not has_ink then
            local msg = "Você precisa de "
            if not has_feather and not has_ink then
                msg = msg .. "uma pena na hotbar e um frasco de tinta no inventário para escrever."
            elseif not has_feather then
                msg = msg .. "uma pena na hotbar para escrever."
            else
                msg = msg .. "um frasco de tinta no inventário para escrever."
            end
            minetest.chat_send_player(player_name, msg)
            return itemstack
        end
        
        -- Mostrar formspec para escrever
        minetest.show_formspec(player_name, "items:page_writer",
            "size[8,6]" ..
            "label[0.3,0;Escrever na Página:]" ..
            "textarea[0.3,0.5;8,4.5;page_text;;]" ..
            "button[2,5;2,1;save;Salvar]" ..
            "button[4,5;2,1;cancel;Cancelar]"
        )
        
        return itemstack
    end,
})

-- Registro do item Página escrita
minetest.register_craftitem("items:writedpage", {
    description = "Página escrita",
    inventory_image = "writedpage.png",
    wield_image = "writedpage.png",
    wield_scale = {x = 0.5, y = 0.5, z = 0.01},
    stack_max = 1,
    
    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then
            return
        end
        
        local player_name = user:get_player_name()
        local meta = itemstack:get_meta()
        local text = meta:get_string("text")
        
        if text == "" then
            text = "Página em branco"
        end
        
        minetest.show_formspec(player_name, "items:page_reader",
            "size[8,6]" ..
            "textarea[0.3,0.3;8,5;page_text;;" .. minetest.formspec_escape(text) .. "]" ..
            "button_exit[3,5.3;2,1;close;Fechar]"
        )
        
        return itemstack
    end,
})

-- Callback do formspec para escrever na página
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "items:page_writer" then
        return
    end
    
    local player_name = player:get_player_name()
    
    if fields.cancel or fields.quit then
        return
    end
    
    if fields.save and fields.page_text then
        local text = fields.page_text
        
        if text == "" then
            minetest.chat_send_player(player_name, "Você não escreveu nada!")
            return
        end
        
        -- Verificar novamente se tem os itens (para evitar exploits)
        local has_feather, has_ink = player_has_writing_tools(player)
        if not has_feather or not has_ink then
            minetest.chat_send_player(player_name, "Você não tem mais os itens necessários!")
            return
        end
        
        local inv = player:get_inventory()
        
        -- Procurar e remover uma página em branco do inventário
        for i = 1, inv:get_size("main") do
            local stack = inv:get_stack("main", i)
            if stack:get_name() == "items:page" then
                -- Remover a página em branco
                stack:take_item(1)
                inv:set_stack("main", i, stack)
                
                -- Consumir tinta
                consume_ink(player)
                
                -- Criar página escrita
                local written_page = items.create_page_with_text(text)
                inv:add_item("main", written_page)
                
                minetest.chat_send_player(player_name, "Página escrita com sucesso!")
                return
            end
        end
        
        minetest.chat_send_player(player_name, "Você não tem uma página em branco!")
    end
end)

-- Função auxiliar para criar páginas com texto pré-definido
function items.create_page_with_text(text)
    local itemstack = ItemStack("items:writedpage")
    local meta = itemstack:get_meta()
    meta:set_string("text", text)
    meta:set_string("description", "Página: " .. text:sub(1, 30) .. "...")
    return itemstack
end

-- Exemplo de diferentes tipos de páginas que podem ser geradas
local page_texts = {
    diary = {
        "Querido diário, hoje foi um dia interessante nas minas...",
        "Encontrei uma caverna profunda hoje. Não sei se devo explorar...",
        "Os cristais brilham de forma estranha à noite.",
    },
    recipe = {
        "Receita secreta: Misture 3 nozes com mel selvagem.",
        "Para criar uma poção forte, combine ervas da montanha com água pura.",
        "O segredo está na temperatura: nunca deixe ferver!",
    },
    message = {
        "Se você está lendo isso, significa que eu não consegui voltar.",
        "Cuidado com as profundezas. Há algo lá embaixo.",
        "O tesouro está escondido onde o sol nunca alcança.",
    },
}

-- Registro do item Página
minetest.register_craftitem("items:writedpage", {
    description = "Página escrita",
    inventory_image = "writedpage.png",
    wield_image = "writedpage.png",
    wield_scale = {x = 0.5, y = 0.5, z = 0.01},
    stack_max = 1, -- Páginas não empilham pois podem ter textos diferentes
    
    -- Ao usar o item com botão direito
    on_use = function(itemstack, user, pointed_thing)
        if not user or not user:is_player() then
            return
        end
        
        local player_name = user:get_player_name()
        local meta = itemstack:get_meta()
        local text = meta:get_string("text")
        
        -- Se a página estiver vazia
        if text == "" then
            text = "Página escrita"
        end
        
        -- Mostra o texto da página para o jogador
        minetest.show_formspec(player_name, "items:page_reader",
            "size[8,6]" ..
            "textarea[0.3,0.3;8,5;page_text;;" .. minetest.formspec_escape(text) .. "]" ..
            "button_exit[3,5.3;2,1;close;Fechar]"
        )
        
        return itemstack
    end,
})

-- Função auxiliar para criar páginas com texto pré-definido
function items.create_page_with_text(text)
    local itemstack = ItemStack("items:writedpage")
    local meta = itemstack:get_meta()
    meta:set_string("text", text)
    meta:set_string("description", "Página: " .. text:sub(1, 30) .. "...")
    return itemstack
end

-- Exemplo de diferentes tipos de páginas que podem ser geradas
local page_texts = {
    diary = {
        "Querido diário, hoje foi um dia interessante nas minas...",
        "Encontrei uma caverna profunda hoje. Não sei se devo explorar...",
        "Os cristais brilham de forma estranha à noite.",
    },
    recipe = {
        "Receita secreta: Misture 3 nozes com mel selvagem.",
        "Para criar uma poção forte, combine ervas da montanha com água pura.",
        "O segredo está na temperatura: nunca deixe ferver!",
    },
    message = {
        "Se você está lendo isso, significa que eu não consegui voltar.",
        "Cuidado com as profundezas. Há algo lá embaixo.",
        "O tesouro está escondido onde o sol nunca alcança.",
    },
}
