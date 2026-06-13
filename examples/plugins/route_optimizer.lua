-- ==============================================================
-- route_optimizer.lua  (v2.0.0)
--
-- A simple "what's around me" finder for the Farever minimap.
--
-- v2 is a ground-up UI rewrite. The default view is now a RADAR:
-- a circle centred on you (ahead = up) with a coloured dot for every
-- chest / orb / ore / plant within your radius -- through walls --
-- plus a big readout of the nearest one and which way to turn. The
-- old multi-stop route planner still exists, but it is tucked behind
-- an off-by-default "Advanced" toggle so it never gets in the way.
--
-- Note on "see through walls": the radar shows everything around you
-- regardless of line of sight, because it is a top-down map of world
-- positions. A plugin cannot pin a marker exactly over an object in
-- the 3D view -- the mod does not expose the game camera to plugins,
-- only your position and facing -- so the radar is the reliable way
-- to do this.
--
-- Uses only documented API: farever.pois(), farever.player.*,
-- farever.now(), farever.store.*, farever.waypoints.* (optional),
-- farever.toast/sound, imgui.* draw surface + font_scale.
-- ==============================================================

local PLUGIN_VERSION = "2.0.0"

-- ── tunables ──────────────────────────────────────────────────────
local PANEL_W     = 250    -- forces window content width via dummy()
local RADAR       = 210    -- radar diameter, pixels
local ARROW_H     = 120    -- advanced nav-arrow panel height
local POI_CACHE_S = 1.5    -- seconds between farever.pois() snapshots
local MAX_STOPS   = 25     -- advanced route cap
local ARRIVE_XY   = 4.0    -- metres: reached a stop / pinged
local ARRIVE_Z    = 6.0
local PING_NEAR   = 12.0   -- metres: announce an item this close
local PING_FAR    = 20.0   -- metres: hysteresis before it can re-announce
local WP_LABEL    = "Finder: target"

-- ── colours per object kind ───────────────────────────────────────
local KIND_RGB = {
    chest   = { 1.00, 0.84, 0.25 },   -- gold
    red_orb = { 1.00, 0.35, 0.35 },   -- red
    ore     = { 0.45, 0.80, 1.00 },   -- blue
    plant   = { 0.45, 1.00, 0.55 },   -- green
}
local KIND_LABEL = {
    chest = "Chest", red_orb = "Red Orb", ore = "Ore", plant = "Plant",
}

-- ── persisted settings ────────────────────────────────────────────
local radius        = 150
local want_chest    = true
local want_red_orb  = false
local want_ore      = false
local want_plant    = false
local ping          = true
local advanced      = false
local auto_advance  = true
local use_waypoints = false

-- ── runtime state (not persisted) ─────────────────────────────────
local pois_cache   = nil
local pois_cache_t = -1e9
local announced    = {}     -- id -> true while within PING_NEAR
local route        = {}     -- advanced: ordered stops
local visited      = {}     -- advanced: id -> true (skipped / collected this run)
local need_build   = false
local last_total   = 0.0
local wp_pinned    = false

-- ── helpers ───────────────────────────────────────────────────────

local function kind_rgb(kind)
    local c = KIND_RGB[kind]
    if c then return c[1], c[2], c[3] end
    return 0.8, 0.8, 0.8
end

local function kind_selected(kind)
    if kind == "chest"   then return want_chest   end
    if kind == "red_orb" then return want_red_orb end
    if kind == "ore"     then return want_ore     end
    if kind == "plant"   then return want_plant   end
    return false
end

local function row_label(e)
    if e.subkind and #e.subkind > 0 and #e.subkind <= 18 then return e.subkind end
    if e.name and #e.name > 0 and #e.name <= 22 then return e.name end
    return KIND_LABEL[e.kind] or e.kind
end

local function dist3(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function get_pois()
    local now = farever.now()
    if not pois_cache or (now - pois_cache_t) > POI_CACHE_S then
        pois_cache   = (farever.pois and farever.pois()) or {}
        pois_cache_t = now
    end
    return pois_cache
end

local function save_settings()
    farever.store.set("radius", radius)
    farever.store.set("want_chest", want_chest)
    farever.store.set("want_red_orb", want_red_orb)
    farever.store.set("want_ore", want_ore)
    farever.store.set("want_plant", want_plant)
    farever.store.set("ping", ping)
    farever.store.set("advanced", advanced)
    farever.store.set("auto_advance", auto_advance)
    farever.store.set("use_waypoints", use_waypoints)
end

-- ── nearby scan ───────────────────────────────────────────────────
-- Returns a distance-sorted list of selected objects within radius,
-- plus the nearest one.

local function scan_nearby(px, py, pz)
    local r2 = radius * radius
    local list, nearest, nd = {}, nil, nil
    for _, p in ipairs(get_pois()) do
        if kind_selected(p.kind) then
            local dx, dy = px - p.x, py - p.y
            local d2 = dx * dx + dy * dy
            if d2 <= r2 then
                local dz = p.z - pz
                local e = {
                    id = tostring(p.id), x = p.x, y = p.y, z = p.z,
                    kind = p.kind, subkind = p.subkind, name = p.name,
                    dxy = math.sqrt(d2), dz = dz, d3 = math.sqrt(d2 + dz * dz),
                }
                list[#list + 1] = e
                if not nd or e.d3 < nd then nd, nearest = e.d3, e end
            end
        end
    end
    table.sort(list, function(a, b) return a.d3 < b.d3 end)
    return list, nearest
end

-- ── proximity ping (once per object while it stays near) ───────────

local function update_ping(list)
    if not ping then announced = {}; return end
    for _, e in ipairs(list) do
        if e.d3 <= PING_NEAR and not announced[e.id] then
            announced[e.id] = true
            farever.sound("info")
            farever.toast("Near: " .. row_label(e), 1.5)
        end
    end
    -- forget anything that drifted back out (hysteresis)
    local keep = {}
    for _, e in ipairs(list) do
        if announced[e.id] and e.d3 <= PING_FAR then keep[e.id] = true end
    end
    announced = keep
end

-- ── bearing / direction text ──────────────────────────────────────

local function local_frame(e, px, py)
    local dx, dy = e.x - px, e.y - py
    local h = farever.player.rot_z()
    local cosh, sinh = math.cos(h), math.sin(h)
    local fwd =  dx * cosh + dy * sinh
    local rgt = -dx * sinh + dy * cosh
    return fwd, rgt
end

local function turn_hint(fwd, rgt)
    local d = math.deg(math.atan(rgt, fwd))
    if     math.abs(d) < 18  then return "straight ahead"
    elseif math.abs(d) > 160 then return "behind you"
    elseif d > 0             then return string.format("turn right %.0f deg", d)
    else                          return string.format("turn left %.0f deg", -d) end
end

-- ── big nearest readout ───────────────────────────────────────────

local function draw_readout(e, px, py, pz)
    if not e then
        imgui.text_colored(0.6, 0.6, 0.6, 1.0, "Nothing in range.")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0, "Move, widen the radius, or tick more types.")
        return
    end
    local r, g, b = kind_rgb(e.kind)
    imgui.font_scale(1.5)
    imgui.text_colored(r, g, b, 1.0, row_label(e))
    imgui.font_scale(1.0)

    local dxy = math.sqrt((px - e.x) ^ 2 + (py - e.y) ^ 2)
    local dz  = e.z - pz
    local vert
    if     math.abs(dz) < 3 then vert = "same level"
    elseif dz > 0           then vert = string.format("%.0fm UP", dz)
    else                         vert = string.format("%.0fm DOWN", -dz) end
    imgui.text(string.format("%.0f m away  -  %s", dxy, vert))

    local fwd, rgt = local_frame(e, px, py)
    imgui.text_colored(0.85, 0.9, 1.0, 1.0, turn_hint(fwd, rgt))
end

-- ── radar ─────────────────────────────────────────────────────────

local function draw_radar(list, px, py, highlight_id)
    local ox, oy = imgui.cursor_pos()
    local cx, cy = ox + RADAR * 0.5, oy + RADAR * 0.5
    local R = RADAR * 0.5 - 8
    local h = farever.player.rot_z()
    local cosh, sinh = math.cos(h), math.sin(h)

    -- backdrop + rings
    imgui.draw_circle_filled(cx, cy, R, 0.05, 0.07, 0.10, 0.88, 48)
    imgui.draw_circle(cx, cy, R,        0.30, 0.34, 0.45, 0.85, 1.5, 48)
    imgui.draw_circle(cx, cy, R * 0.5,  0.24, 0.27, 0.37, 0.5, 1.0, 32)
    imgui.draw_line(cx - R, cy, cx + R, cy, 0.2, 0.22, 0.30, 0.35, 1.0)
    imgui.draw_line(cx, cy - R, cx, cy + R, 0.2, 0.22, 0.30, 0.35, 1.0)
    imgui.draw_text(cx - 16, oy - 1, 0.6, 0.65, 0.8, 0.9, "AHEAD")
    imgui.draw_text(cx + 3, cy - R + 2, 0.5, 0.55, 0.7, 0.8,
        string.format("%.0fm", radius))

    local scale = R / radius
    for _, e in ipairs(list) do
        local dx, dy = e.x - px, e.y - py
        local fwd =  dx * cosh + dy * sinh
        local rgt = -dx * sinh + dy * cosh
        local sx, sy = cx + rgt * scale, cy - fwd * scale   -- ahead = up
        -- clamp to rim just in case of float slop
        local ddx, ddy = sx - cx, sy - cy
        local dd = math.sqrt(ddx * ddx + ddy * ddy)
        if dd > R then sx, sy = cx + ddx / dd * R, cy + ddy / dd * R end

        local r, g, b = kind_rgb(e.kind)
        local close = 1.0 - math.min(e.d3 / radius, 1.0)
        local rad = 2.5 + close * 3.0
        if e.id == highlight_id then
            local pulse = (math.sin(farever.now() * 5) + 1) * 0.5
            imgui.draw_line(cx, cy, sx, sy, r, g, b, 0.55, 1.5)
            imgui.draw_circle(sx, sy, rad + 3 + pulse * 3, r, g, b, 0.5 + pulse * 0.4, 1.5, 20)
        end
        imgui.draw_circle_filled(sx, sy, rad, r, g, b, 1.0, 16)
    end

    -- player: green triangle pointing up (you always face "ahead" here)
    imgui.draw_triangle_filled(cx, cy - 7, cx - 5, cy + 5, cx + 5, cy + 5,
        0.2, 1.0, 0.4, 1.0)
    imgui.dummy(RADAR, RADAR)
end

-- ── advanced: multi-stop route (greedy NN + bounded 2-opt) ─────────

local function gather_candidates(px, py, pz)
    local r2 = radius * radius
    local cands = {}
    for _, p in ipairs(get_pois()) do
        local id = tostring(p.id)
        if kind_selected(p.kind) and not visited[id] then
            local dx, dy = px - p.x, py - p.y
            local d2 = dx * dx + dy * dy
            if d2 <= r2 then
                cands[#cands + 1] = {
                    id = id, x = p.x, y = p.y, z = p.z,
                    kind = p.kind, subkind = p.subkind, name = p.name,
                    d0 = math.sqrt(d2 + (pz - p.z) ^ 2),
                }
            end
        end
    end
    table.sort(cands, function(a, b) return a.d0 < b.d0 end)
    while #cands > MAX_STOPS do table.remove(cands) end
    return cands
end

local function path_len(r, px, py, pz)
    local total, cx, cy, cz = 0.0, px, py, pz
    for _, n in ipairs(r) do
        total = total + dist3(cx, cy, cz, n.x, n.y, n.z)
        cx, cy, cz = n.x, n.y, n.z
    end
    return total
end

local function two_opt(r, px, py, pz)
    local n = #r
    if n < 4 then return end
    local guard, improved = 0, true
    while improved and guard < 60 do
        improved = false; guard = guard + 1
        for i = 1, n - 1 do
            for k = i + 1, n do
                local ax, ay, az
                if i == 1 then ax, ay, az = px, py, pz
                else ax, ay, az = r[i - 1].x, r[i - 1].y, r[i - 1].z end
                local bx, by, bz = r[i].x, r[i].y, r[i].z
                local cxx, cyy, czz = r[k].x, r[k].y, r[k].z
                local before, after
                if k < n then
                    local dx, dy, dz = r[k + 1].x, r[k + 1].y, r[k + 1].z
                    before = dist3(ax, ay, az, bx, by, bz) + dist3(cxx, cyy, czz, dx, dy, dz)
                    after  = dist3(ax, ay, az, cxx, cyy, czz) + dist3(bx, by, bz, dx, dy, dz)
                else
                    before = dist3(ax, ay, az, bx, by, bz)
                    after  = dist3(ax, ay, az, cxx, cyy, czz)
                end
                if after + 1e-6 < before then
                    local lo, hi = i, k
                    while lo < hi do r[lo], r[hi] = r[hi], r[lo]; lo, hi = lo + 1, hi - 1 end
                    improved = true
                end
            end
        end
    end
end

local function wp_available()
    return farever.waypoints
        and type(farever.waypoints.add) == "function"
        and type(farever.waypoints.remove) == "function"
end

local function wp_clear()
    if wp_pinned and wp_available() then pcall(farever.waypoints.remove, WP_LABEL) end
    wp_pinned = false
end

local function wp_pin_current()
    if not (use_waypoints and wp_available()) then return end
    wp_clear()
    local cur = route[1]
    if cur then pcall(farever.waypoints.add, cur.x, cur.y, cur.z, WP_LABEL); wp_pinned = true end
end

local function build_route()
    local px, py, pz = farever.player.x(), farever.player.y(), farever.player.z()
    local remaining = gather_candidates(px, py, pz)
    local r, cx, cy, cz = {}, px, py, pz
    while #remaining > 0 do
        local bi, bd
        for i, nd in ipairs(remaining) do
            local d = dist3(cx, cy, cz, nd.x, nd.y, nd.z)
            if not bd or d < bd then bd, bi = d, i end
        end
        local nd = table.remove(remaining, bi)
        r[#r + 1] = nd; cx, cy, cz = nd.x, nd.y, nd.z
    end
    two_opt(r, px, py, pz)
    route, last_total = r, path_len(r, px, py, pz)
    wp_pin_current()
end

local function draw_arrow_panel(cur, px, py, pz)
    local ax, ay = imgui.cursor_pos()
    local cx, cy = ax + PANEL_W * 0.5, ay + ARROW_H * 0.5
    imgui.draw_rect_filled(ax, ay, ax + PANEL_W, ay + ARROW_H, 0.08, 0.10, 0.13, 0.78)
    imgui.draw_rect(ax, ay, ax + PANEL_W, ay + ARROW_H, 0.28, 0.30, 0.42, 0.85, 1.5)
    if not cur then
        imgui.draw_text(ax + 12, cy - 7, 0.5, 0.5, 0.5, 1.0, "No stops")
        imgui.dummy(PANEL_W, ARROW_H); return
    end
    local fwd, rgt = local_frame(cur, px, py)
    local dz = cur.z - pz
    local d_h = math.sqrt(fwd * fwd + rgt * rgt)
    local th, tv = math.atan(rgt, fwd), math.atan(dz, math.max(math.sqrt(fwd*fwd+rgt*rgt), 1.0))
    local dir_x, dir_y = math.sin(th), -math.cos(th)
    local perp_x, perp_y = -dir_y, dir_x
    local r, g, b = kind_rgb(cur.kind)
    local ps = 0.95 + 0.05 * math.sin(farever.now() * 3)
    local L, hl_n, hw_n = 46 * ps, 20 * ps, 12 * ps
    local tilt = math.sin(tv) * 15
    local tail_x, tail_y = cx - dir_x * L * 0.35, cy - dir_y * L * 0.35
    local tip_x, tip_y   = cx + dir_x * L, cy + dir_y * L - tilt
    local back_x, back_y = tip_x - dir_x * hl_n, tip_y - dir_y * hl_n
    imgui.draw_line(tail_x, tail_y, back_x, back_y, r, g, b, 1.0, 5.0)
    imgui.draw_triangle_filled(tip_x, tip_y,
        back_x + perp_x * hw_n, back_y + perp_y * hw_n,
        back_x - perp_x * hw_n, back_y - perp_y * hw_n, r, g, b, 1.0)
    imgui.draw_text(ax + 6, ay + 5, 0.88, 0.88, 0.88, 0.95, "Next: " .. row_label(cur):sub(1, 22))
    imgui.draw_text(ax + 6, ay + ARROW_H - 18, r, g, b, 1.0,
        string.format("%.0f m   %+.1f m   (%d left)", d_h, dz, #route))
    imgui.dummy(PANEL_W, ARROW_H)
end

-- ── lifecycle ─────────────────────────────────────────────────────

function on_init()
    -- One-time migration to the v2 simple defaults (chests only).
    if farever.store.get("ui_version", 0) < 2 then
        radius, want_chest = 150, true
        want_red_orb, want_ore, want_plant = false, false, false
        ping, advanced, auto_advance, use_waypoints = true, false, true, false
        save_settings()
        farever.store.set("ui_version", 2)
    else
        radius        = farever.store.get("radius", 150)
        want_chest    = farever.store.get("want_chest", true)
        want_red_orb  = farever.store.get("want_red_orb", false)
        want_ore      = farever.store.get("want_ore", false)
        want_plant    = farever.store.get("want_plant", false)
        ping          = farever.store.get("ping", true)
        advanced      = farever.store.get("advanced", false)
        auto_advance  = farever.store.get("auto_advance", true)
        use_waypoints = farever.store.get("use_waypoints", false)
    end
    route, visited, announced = {}, {}, {}
    need_build, wp_pinned = false, false
    farever.log.info("route_optimizer v" .. PLUGIN_VERSION .. " loaded (radar UI)")
end

function on_event(name, _)
    if name == "hero_locked" then
        wp_clear()
        route, visited, announced = {}, {}, {}
        need_build = false
    end
end

-- ── main render ───────────────────────────────────────────────────

function on_render()
    imgui.dummy(PANEL_W, 0)

    if not farever.player.locked() then
        imgui.text_colored(1.0, 0.6, 0.2, 1.0, "Waiting for player lock...")
        return
    end

    local px, py, pz = farever.player.x(), farever.player.y(), farever.player.z()
    local list, nearest = scan_nearby(px, py, pz)
    update_ping(list)

    -- In advanced route mode the highlight follows the current stop.
    local highlight = nearest
    if advanced and #route > 0 then
        local cur = route[1]
        if auto_advance then
            local dxy = math.sqrt((px - cur.x) ^ 2 + (py - cur.y) ^ 2)
            if dxy <= ARRIVE_XY and math.abs(pz - cur.z) <= ARRIVE_Z then
                visited[cur.id] = true
                table.remove(route, 1)
                farever.toast("Collected: " .. row_label(cur), 1.5)
                farever.sound("info")
                if #route == 0 then wp_clear(); farever.toast("Route done!", 2.0); farever.sound("alert")
                else wp_pin_current() end
            end
        end
        highlight = route[1]
    end
    local highlight_id = highlight and highlight.id or nil

    -- ── readout + radar (the whole point) ──────────────────────────
    draw_readout(highlight, px, py, pz)
    imgui.separator()
    draw_radar(list, px, py, highlight_id)

    -- ── minimal controls ───────────────────────────────────────────
    local v, c
    v, c = imgui.slider_float("Radius (m)", radius, 30, 500)
    if c then radius = v; save_settings(); if advanced then need_build = true end end

    local nv
    nv, c = imgui.checkbox("Chests", want_chest)
    if c then want_chest = nv; save_settings(); need_build = advanced end
    imgui.same_line()
    nv, c = imgui.checkbox("Orbs", want_red_orb)
    if c then want_red_orb = nv; save_settings(); need_build = advanced end
    nv, c = imgui.checkbox("Ore", want_ore)
    if c then want_ore = nv; save_settings(); need_build = advanced end
    imgui.same_line()
    nv, c = imgui.checkbox("Plants", want_plant)
    if c then want_plant = nv; save_settings(); need_build = advanced end

    nv, c = imgui.checkbox("Ping when near", ping)
    if c then ping = nv; save_settings() end

    -- top few as text, so you have names + exact distances too
    if #list > 0 then
        imgui.separator()
        local shown = math.min(#list, 3)
        for i = 1, shown do
            local e = list[i]
            local r, g, b = kind_rgb(e.kind)
            imgui.text_colored(r, g, b, 1.0, string.format(
                "%d. %-16s %4.0fm", i, row_label(e):sub(1, 16), e.dxy))
        end
    end

    -- ── advanced route mode (off by default) ───────────────────────
    imgui.separator()
    nv, c = imgui.checkbox("Advanced: plan a route", advanced)
    if c then
        advanced = nv; save_settings()
        if advanced then need_build = true else wp_clear(); route = {} end
    end

    if advanced then
        if imgui.button("Build route") then need_build = true end
        imgui.same_line()
        if imgui.button("Reset") then visited = {}; need_build = true end
        nv, c = imgui.checkbox("Auto-advance", auto_advance)
        if c then auto_advance = nv; save_settings() end
        if wp_available() then
            imgui.same_line()
            nv, c = imgui.checkbox("Pin waypoint", use_waypoints)
            if c then use_waypoints = nv; if use_waypoints then wp_pin_current() else wp_clear() end; save_settings() end
        end

        if need_build then build_route(); need_build = false end

        if #route == 0 then
            imgui.text_colored(0.6, 0.6, 0.6, 1.0, "No stops match in range.")
        else
            draw_arrow_panel(route[1], px, py, pz)
            imgui.text(string.format("Route: %d stops, %.0f m", #route, last_total))
            for i = 1, math.min(#route, 6) do
                local n = route[i]
                local dxy = math.sqrt((px - n.x) ^ 2 + (py - n.y) ^ 2)
                local r, g, b = kind_rgb(n.kind)
                imgui.text_colored(r, g, b, (i == 1) and 1.0 or 0.85, string.format(
                    "%s %-16s %4.0fm", (i == 1) and ">" or (i .. "."), row_label(n):sub(1, 16), dxy))
                imgui.same_line()
                if imgui.button("skip##" .. i) then
                    visited[n.id] = true
                    if i == 1 then wp_clear() end
                    table.remove(route, i)
                    last_total = path_len(route, px, py, pz)
                    if route[1] then wp_pin_current() end
                    break
                end
            end
        end
    end
end
