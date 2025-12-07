minetest.register_craftitem("items:stick", {
    description = "Graveto",
    inventory_image = "graveto.png",
    wield_image = "graveto.png",
    wield_scale = {x = 1, y = 1, z = 1},

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

--minetest.register_tool("items:stick", {
    --description = "Graveto",
    --inventory_image = "graveto.png",
    --wield_image = "graveto.png",
    --wield_scale = {x = 1, y = 1, z = 1},

    --range = 5, -- AUMENTA O ALCANCE

    --tool_capabilities = {
       -- full_punch_interval = 1.0,
        --max_drop_level = 0,
        --groupcaps = {
            --crumbly = {times = {[3] = 1.00}, uses = 0},
            --cracky  = {times = {[3] = 2.00}, uses = 0},
            --snappy  = {times = {[3] = 0.80}, uses = 0},
            --choppy  = {times = {[3] = 1.50}, uses = 0},
        --},
        --damage_groups = {fleshy = 1},
    --},
--})

minetest.register_craftitem("items:nut", {
    description = "Noz",
    inventory_image = "noz.png",
    wield_image = "noz.png",
    wield_scale = {x = 1, y = 1, z = 1},

    -- Comida: recupera 1 ponto de vida
    on_use = minetest.item_eat(1),
})



