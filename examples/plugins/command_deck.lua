-- ==============================================================
-- command_deck.lua  (v1.0.0)
--
-- A single tabbed HUD that hosts several tools in ONE window, so you
-- are not juggling a separate floating window per feature. Switch
-- tabs with the button row at the top.
--
--   [ Boss ]   self-learning boss cast coach. Watches the current
--              target's cast bar and, by correlating each cast with
--              your health, teaches ITSELF which of a boss's skills
--              actually hurt -- then screams at you to dodge only the
--              dangerous ones. The learned threat profile is keyed by
--              boss + skill and persisted, so it is smarter on your
--              tenth pull than your first.
--
--   [ Vitals ] live resource + buff sentinel. Shows only the resources
--              your class actually uses, learns each one's max by
--              observation, warns when a resource is CAPPED (wasting
--              regen), and lists your active buffs/debuffs with
--              countdown bars.
--
-- Future tabs (Drops / Crafting) will plug into this same shell.
--
-- Uses only the documented API: farever.target.*, farever.player.*,
-- farever.now/store/sound/toast/log, the imgui draw surface, and the
-- cast_start / cast_end / target_changed events.
-- ==============================================================

local PLUGIN_VERSION = "1.0.0"

-- ── layout ────────────────────────────────────────────────────────
local PANEL_W   = 270
local RING_BOX  = 150     -- cast-coach ring panel height
local DB_KEY    = "boss_threat_db"
local SAVE_EVERY = 4.0    -- seconds between throttled store writes

-- danger thresholds, as fraction of max HP lost during a cast
local DANGER_HI = 0.12
local DANGER_MD = 0.04

-- ── tab state ─────────────────────────────────────────────────────
local TABS = { "Boss", "Vitals" }
local tab  = 1

-- ── boss-coach runtime ────────────────────────────────────────────
-- threat_db[boss .. "|" .. skill] = { seen = n, dmg = sum_of_hp_fraction_lost }
local threat_db   = {}
local active_cast = nil   -- { boss, skill, hp0, warned } between cast_start/end
local last_save   = -1e9
local db_dirty    = false

-- ── vitals runtime ────────────────────────────────────────────────
-- observed_max[name] = highest value we have ever read for that resource
local observed_max = {}

-- ── safe readers (any field may be missing on older mod builds) ────
local function pget(name)
    local f = farever.player and farever.player[name]
    if f then local ok, v = pcall(f); if ok and type(v) == "number" then return v end end
    return 0
end
local function tget(name)
    local f = farever.target and farever.target[name]
    if f then local ok, v = pcall(f); if ok then return v end end
    return nil
end

-- ── threat DB (de)serialization (store holds scalars, so flatten) ──
local function db_encode(db)
    local parts = {}
    for k, v in pairs(db) do
        parts[#parts + 1] = string.format("%s\t%d\t%.5f", k, v.seen, v.dmg)
    end
    return table.concat(parts, "\n")
end
local function db_decode(s)
    local db = {}
    if type(s) ~= "string" then return db end
    for line in s:gmatch("[^\n]+") do
        local k, seen, dmg = line:match("^(.-)\t(%d+)\t([%d%.]+)$")
        if k then db[k] = { seen = tonumber(seen), dmg = tonumber(dmg) } end
    end
    return db
end
local function db_save(force)
    if not db_dirty then return end
    local now = farever.now()
    if not force and (now - last_save) < SAVE_EVERY then return end
    farever.store.set(DB_KEY, db_encode(threat_db))
    last_save, db_dirty = now, false
end

-- avg fraction of HP a (boss, skill) has cost us, plus sample count
local function threat_of(boss, skill)
    local e = threat_db[(boss or "") .. "|" .. (skill or "")]
    if not e or e.seen == 0 then return 0, 0 end
    return e.dmg / e.seen, e.seen
end

local function danger_rgb(avg, seen)
    if seen == 0 then return 0.55, 0.6, 0.7 end          -- unknown: grey-blue
    if avg >= DANGER_HI then return 1.0, 0.30, 0.30 end   -- red
    if avg >= DANGER_MD then return 1.0, 0.80, 0.30 end   -- amber
    return 0.45, 0.85, 0.55                                -- green: harmless
end

-- prettify an internal id ("Boar_Skill1" -> "Boar Skill1")
local function nice(id)
    if not id or id == "" then return "?" end
    return (id:gsub("_", " "))
end

-- ── arc helper for the cast ring ──────────────────────────────────
local function draw_arc(cx, cy, rad, frac, r, g, b, a, thick)
    frac = math.max(0, math.min(frac, 1))
    if frac <= 0 then return end
    local segs = math.max(2, math.floor(56 * frac))
    local a0 = -math.pi / 2
    local prev_x, prev_y = cx + math.cos(a0) * rad, cy + math.sin(a0) * rad
    for i = 1, segs do
        local t = a0 + (2 * math.pi * frac) * (i / segs)
        local x, y = cx + math.cos(t) * rad, cy + math.sin(t) * rad
        imgui.draw_line(prev_x, prev_y, x, y, r, g, b, a, thick)
        prev_x, prev_y = x, y
    end
end

-- ══════════════════════════════════════════════════════════════════
--  EVENTS  (drive the learning)
-- ══════════════════════════════════════════════════════════════════

function on_event(name, data)
    if name == "cast_start" then
        local boss = tget("name") or ""
        active_cast = {
            boss  = boss,
            skill = (data and data.skill) or tget("cast_skill") or "",
            hp0   = pget("health_pct"),
            warned = false,
        }
        -- pre-emptive warning if we already know this one is nasty
        local avg, seen = threat_of(active_cast.boss, active_cast.skill)
        if seen > 0 and avg >= DANGER_HI then
            farever.sound("alert")
            farever.toast("DODGE: " .. nice(active_cast.skill), 1.5)
            active_cast.warned = true
        end

    elseif name == "cast_end" then
        if active_cast then
            local skill = (data and data.skill) or active_cast.skill
            if skill == active_cast.skill then
                local drop = active_cast.hp0 - pget("health_pct")  -- fraction of max HP
                local key  = active_cast.boss .. "|" .. active_cast.skill
                local e    = threat_db[key] or { seen = 0, dmg = 0 }
                e.seen = e.seen + 1
                if drop > 0 then e.dmg = e.dmg + drop end
                threat_db[key] = e
                db_dirty = true
                db_save(false)
            end
            active_cast = nil
        end

    elseif name == "target_changed" then
        active_cast = nil

    elseif name == "hero_locked" then
        active_cast = nil
        db_save(true)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  BOSS TAB
-- ══════════════════════════════════════════════════════════════════

local function render_boss()
    local exists = tget("exists")
    if not exists then
        imgui.text_colored(0.6, 0.6, 0.6, 1.0, "No target.")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0,
            "Target a boss; the coach learns its")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0,
            "dangerous casts as you fight.")
        return
    end

    local boss = tget("name") or ""
    imgui.text_colored(0.85, 0.9, 1.0, 1.0, nice(boss))
    local hp_pct = tget("hp_pct") or 0
    imgui.progress(hp_pct, string.format("HP %.0f%%", hp_pct * 100))

    -- ── live cast ring ────────────────────────────────────────────
    local casting = tget("is_casting")
    local ox, oy = imgui.cursor_pos()
    local cx, cy = ox + PANEL_W * 0.5, oy + RING_BOX * 0.5
    local R = RING_BOX * 0.5 - 18

    if casting then
        local skill = tget("cast_skill") or ""
        local prog  = tget("cast_progress") or 0
        local rem   = tget("cast_remaining_sec") or 0
        local total = tget("cast_total_sec") or 0
        local avg, seen = threat_of(boss, skill)
        local r, g, b = danger_rgb(avg, seen)

        -- live warning even for a skill we have not classified yet,
        -- the first time it crosses into "known dangerous"
        if seen > 0 and avg >= DANGER_HI and active_cast and not active_cast.warned then
            farever.sound("alert"); active_cast.warned = true
        end

        imgui.draw_circle(cx, cy, R, 0.25, 0.27, 0.35, 0.8, 2.0, 48)
        if total > 0 then
            draw_arc(cx, cy, R, prog, r, g, b, 1.0, 4.0)
        else
            -- duration unknown (first sighting): spin an indeterminate arc
            local t = (farever.now() * 0.6) % 1.0
            draw_arc(cx, cy, R, 0.18, r, g, b, 1.0, 4.0)  -- short fixed wedge
            imgui.draw_circle(cx, cy, R - 6,
                r, g, b, 0.25 + 0.2 * math.sin(farever.now() * 6), 2.0, 32)
            local _ = t
        end

        -- centre label: remaining time, big
        local pulse = (avg >= DANGER_HI) and (0.7 + 0.3 * math.sin(farever.now() * 10)) or 1.0
        imgui.draw_text(cx - 26, cy - 10, r, g, b, pulse,
            (total > 0) and string.format("%.1fs", rem) or "??")
        imgui.dummy(PANEL_W, RING_BOX)

        imgui.font_scale(1.3)
        imgui.text_colored(r, g, b, 1.0, nice(skill))
        imgui.font_scale(1.0)
        if seen == 0 then
            imgui.text_colored(0.6, 0.6, 0.7, 1.0, "new skill - learning...")
        elseif avg >= DANGER_HI then
            imgui.text_colored(r, g, b, 1.0, string.format(
                "DANGER  avg -%.0f%% HP  (x%d)", avg * 100, seen))
        elseif avg >= DANGER_MD then
            imgui.text_colored(r, g, b, 1.0, string.format(
                "caution  avg -%.0f%% HP  (x%d)", avg * 100, seen))
        else
            imgui.text_colored(r, g, b, 1.0, string.format(
                "harmless  (x%d)", seen))
        end
    else
        imgui.draw_circle(cx, cy, R, 0.2, 0.22, 0.3, 0.5, 1.5, 48)
        imgui.draw_text(cx - 34, cy - 7, 0.5, 0.55, 0.65, 0.9, "no cast")
        imgui.dummy(PANEL_W, RING_BOX)
    end

    -- ── learned threat profile for this boss ──────────────────────
    imgui.separator()
    imgui.text_colored(0.7, 0.75, 0.85, 1.0, "Known skills:")
    local rows = {}
    local prefix = boss .. "|"
    for k, v in pairs(threat_db) do
        if k:sub(1, #prefix) == prefix and v.seen > 0 then
            rows[#rows + 1] = { skill = k:sub(#prefix + 1), avg = v.dmg / v.seen, seen = v.seen }
        end
    end
    table.sort(rows, function(a, b) return a.avg > b.avg end)
    if #rows == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (nothing learned yet)")
    else
        for i = 1, math.min(#rows, 6) do
            local row = rows[i]
            local r, g, b = danger_rgb(row.avg, row.seen)
            imgui.text_colored(r, g, b, 1.0, string.format(
                "  %-16s -%2.0f%%  x%d", nice(row.skill):sub(1, 16), row.avg * 100, row.seen))
        end
    end

    if imgui.button("Forget this boss") then
        for k in pairs(threat_db) do
            if k:sub(1, #prefix) == prefix then threat_db[k] = nil end
        end
        db_dirty = true; db_save(true)
        farever.toast("Cleared threat data for " .. nice(boss), 1.5)
    end
end

-- ══════════════════════════════════════════════════════════════════
--  VITALS TAB
-- ══════════════════════════════════════════════════════════════════

-- name, getter field, regen field (or nil), bar colour
local RESOURCES = {
    { "Energy", "energy", "energy_regen", 0.40, 0.80, 1.00 },
    { "Rage",   "rage",   "rage_regen",   1.00, 0.45, 0.40 },
    { "Spark",  "spark",  "spark_regen",  1.00, 0.85, 0.35 },
    { "Focus",  "focus",  nil,            0.65, 0.55, 1.00 },
    { "Combo",  "combo_point", nil,       1.00, 0.60, 0.85 },
    { "Poise",  "poise",  "poise_regen",  0.60, 0.80, 0.70 },
    { "Oxygen", "oxygen", nil,            0.45, 0.90, 0.95 },
    { "Shield", "shield", nil,            0.80, 0.80, 0.90 },
    { "Fervor", "fervor", nil,            1.00, 0.70, 0.45 },
    { "Faith",  "faith",  nil,            0.95, 0.95, 0.70 },
}

local function render_vitals()
    if not farever.player.locked() then
        imgui.text_colored(1.0, 0.6, 0.2, 1.0, "Waiting for player lock...")
        return
    end

    -- health, the one resource with a real max
    local hp, hpmax = pget("health"), pget("max_health")
    local hp_pct = (hpmax > 0) and (hp / hpmax) or pget("health_pct")
    imgui.font_scale(1.2)
    imgui.text_colored(0.6, 1.0, 0.55, 1.0, "Health")
    imgui.font_scale(1.0)
    imgui.progress(hp_pct, string.format("%.0f / %.0f", hp, hpmax))
    local hregen = pget("health_regen")
    if hregen ~= 0 then imgui.same_line(); imgui.text(string.format("  +%.0f/s", hregen)) end

    imgui.separator()

    local shown = 0
    for _, res in ipairs(RESOURCES) do
        local name, field, regen_field = res[1], res[2], res[3]
        local cur = pget(field)
        local regen = regen_field and pget(regen_field) or 0
        -- learn the max by observation
        local mx = observed_max[field] or 0
        if cur > mx then mx = cur; observed_max[field] = mx end
        -- only surface resources this class actually uses
        if mx > 0 or regen ~= 0 then
            shown = shown + 1
            local r, g, b = res[4], res[5], res[6]
            local frac = (mx > 0) and (cur / mx) or 0
            local capped = (mx > 0 and cur >= mx - 1e-6 and regen ~= 0)
            if capped then
                local p = 0.6 + 0.4 * math.sin(farever.now() * 8)
                imgui.text_colored(1.0, 0.5, 0.3, p, string.format("%s  CAPPED", name))
            else
                imgui.text_colored(r, g, b, 1.0, name)
            end
            imgui.progress(frac, string.format("%.0f / %.0f%s",
                cur, mx, (regen ~= 0) and string.format("  (+%.1f/s)", regen) or ""))
        end
    end
    if shown == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "No class resources detected.")
    end

    -- buffs / debuffs
    imgui.separator()
    imgui.text_colored(0.7, 0.75, 0.85, 1.0, "Active statuses:")
    local statuses = farever.player.statuses and farever.player.statuses() or nil
    if not statuses or #statuses == 0 then
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "  (none)")
    else
        for i = 1, math.min(#statuses, 8) do
            local s = statuses[i]
            local dur = tonumber(s.duration) or 0
            local stacks = tonumber(s.stacks) or 0
            local label = nice(s.kind or "?"):sub(1, 18)
            if stacks > 1 then label = label .. " x" .. stacks end
            -- colour shifts to red as the buff runs low
            local low = dur > 0 and dur < 4
            local r, g, b = low and 1.0 or 0.7, low and 0.5 or 0.85, low and 0.3 or 0.6
            imgui.text_colored(r, g, b, 1.0, string.format(
                "  %-20s %s", label, (dur > 0) and string.format("%.0fs", dur) or ""))
        end
    end
end

-- ══════════════════════════════════════════════════════════════════
--  SHELL
-- ══════════════════════════════════════════════════════════════════

function on_init()
    threat_db    = db_decode(farever.store.get(DB_KEY, ""))
    tab          = farever.store.get("deck_tab", 1)
    if tab < 1 or tab > #TABS then tab = 1 end
    observed_max = {}
    active_cast  = nil
    db_dirty     = false
    last_save    = farever.now()
    farever.log.info("command_deck v" .. PLUGIN_VERSION .. " loaded")
end

function on_render()
    imgui.dummy(PANEL_W, 0)

    -- tab bar
    for i, label in ipairs(TABS) do
        if i > 1 then imgui.same_line() end
        local mark = (i == tab) and ("[" .. label .. "]") or (" " .. label .. " ")
        if imgui.button(mark .. "##tab" .. i) then
            tab = i; farever.store.set("deck_tab", tab)
        end
    end
    imgui.separator()

    if tab == 1 then render_boss()
    elseif tab == 2 then render_vitals() end

    -- flush any pending learning to disk on a throttle
    db_save(false)
end
