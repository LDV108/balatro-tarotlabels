local function wrap_words(name)
    local words = {}
    for w in name:gmatch('%S+') do words[#words + 1] = w end
    if #words <= 1 then return { name } end

    local best_i, best_diff = 1, math.huge
    for i = 1, #words - 1 do
        local left, right = 0, 0
        for j = 1, i do left = left + #words[j] + (j > 1 and 1 or 0) end
        for j = i + 1, #words do right = right + #words[j] + (j > i + 1 and 1 or 0) end
        local diff = math.abs(left - right)
        if diff <= best_diff then best_diff = diff; best_i = i end
    end

    local left_parts, right_parts = {}, {}
    for j = 1, best_i do left_parts[#left_parts + 1] = words[j] end
    for j = best_i + 1, #words do right_parts[#right_parts + 1] = words[j] end
    return { table.concat(left_parts, ' '), table.concat(right_parts, ' ') }
end

local function build_label(card, lines, anchor, y_offset)
    local row_nodes = {}
    for _, line in ipairs(lines) do
        row_nodes[#row_nodes + 1] = {
            n = G.UIT.R,
            config = { align = 'cm' },
            nodes = { { n = G.UIT.T, config = { text = line, scale = 0.3, colour = G.C.WHITE } } },
        }
    end
    return UIBox {
        definition = {
            n = G.UIT.ROOT,
            config = { align = 'cm', r = 0.08, colour = { 0, 0, 0, 0.75 }, padding = 0.04 },
            nodes = row_nodes,
        },
        config = { align = anchor, offset = { x = 0, y = y_offset }, parent = card },
    }
end

local function is_stat_area(card)
    return card.area and card.area.config and card.area.config.type == 'title'
end

local function desired_placement(card)
    if is_stat_area(card) then
        return 'tm', -0.18
    elseif card.area == G.pack_cards then
        if card.highlighted then return 'bm', 0.55 end
        return 'tm', -0.12
    elseif card.area == G.shop_jokers and card.highlighted then
        return 'bm', 0.55
    end
    return 'bm', 0.12
end

local function desired_lines(card)
    if not card.tarot_label_name then return nil end
    if is_stat_area(card) then
        return wrap_words(card.tarot_label_name)
    end
    return { card.tarot_label_name }
end

local function place_label(card)
    if not card.tarot_label_name then return end
    local anchor, y_offset = desired_placement(card)
    local lines = desired_lines(card)
    local key = anchor .. ':' .. tostring(y_offset) .. ':' .. table.concat(lines, '|')
    if card.tarot_label_state == key and card.children.tarot_label then return end
    if card.children.tarot_label then card.children.tarot_label:remove() end
    card.children.tarot_label = build_label(card, lines, anchor, y_offset)
    card.tarot_label_state = key
end

local Card_set_sprites = Card.set_sprites
function Card:set_sprites(_center, _front)
    Card_set_sprites(self, _center, _front)

    if _center and _center.set == 'Tarot' then
        local name = localize { type = 'name_text', set = _center.set, key = self.config.center_key }
        if not name or name == 'ERROR' then name = _center.name end
        self.tarot_label_name = name
        self.tarot_label_state = nil
        place_label(self)
    else
        if self.children.tarot_label then
            self.children.tarot_label:remove()
            self.children.tarot_label = nil
        end
        self.tarot_label_name = nil
        self.tarot_label_state = nil
    end
end

local Card_set_card_area = Card.set_card_area
function Card:set_card_area(area)
    Card_set_card_area(self, area)
    place_label(self)
end

local Card_highlight = Card.highlight
function Card:highlight(is_highlighted)
    Card_highlight(self, is_highlighted)
    place_label(self)
end
