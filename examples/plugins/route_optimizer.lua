-- ==============================================================
-- route_optimizer.lua  (v1.0.0)
--
-- A gathering route optimizer for the Farever minimap.
--
-- Where every other navigation plugin points you at the *single*
-- nearest node, this one plans an *ordered multi-stop route* across
-- all the collectibles you care about and walks you through them one
-- by one:
--
--   1. Pull the full POI table (farever.pois()).
--   2. Filter by category (ore / plant / chest / red orb), optional
--      resource sub-type, search radius, and a persistent "done" set.
--   3. Take the N nearest of what is left (cap = max stops).
--   4. Order them: greedy nearest-neighbour from your position, then
--      a bounded 2-opt pass to shorten the total path.
--   5. Draw the whole route as a connected line on a schematic map,
--      a live nav arrow to the current stop, and an ordered list.
--   6. Auto-advance: when you reach a stop it is marked, a toast +
--      ping fire, and the arrow snaps to the next stop. Chests / red
--      orbs (which do not respawn) can be marked permanently done.
--
-- Read-only and advisory, like every Farever plugin: it never moves
-- your character, it just tells you the best order to walk.
--
-- Uses only documented API: farever.pois(), farever.player.*,
-- farever.now(), farever.store.*, farever.waypoints.* (optional),
-- farever.toast/sound, and the imgui draw surface.
-- ==============================================================

local PLUGIN_VERSION = "1.0.0"

-- ── tunables ──────────────────────────────────────────────────────
local PANEL_W      = 380     -- forces window content width via dummy()
local MAP_H        = 200     -- schematic route map height
local ARROW_H      = 132     -- nav-arrow panel height
local LIST_ROWS    = 14      -- max route rows shown
local ARRIVE_XY    = 4.0     -- metres: within this XY of a stop = arrived
local ARRIVE_Z     = 6.0     -- metres: and within this height delta
local POI_CACHE_S  = 2.0     -- seconds between farever.pois() snapshots
local WP_LABEL     = "Route: next stop"

-- ── persisted settings ────────────────────────────────────────────
local radius        = 250
local max_stops     = 20
local want_ore      = true
local want_plant    = true
local want_chest    = true
local want_red_orb  = true
local sub_filter    = ""      -- "" = any sub-type
local auto_advance  = true
local use_waypoints = false
local show_map      = true
local show_arrow    = true

-- ── runtime state (not persisted) ─────────────────────────────────
local route        = {}     -- ordered { id, x, y, z, name, kind, subkind }
local visited      = {}     -- set: id -> true, this run (skip + auto-advance)
local done_set     = {}     -- set: id -> true, persisted (permanent "collected")
local need_build   = true   -- rebuild route on next locked frame
local pois_cache   = nil
local pois_cache_t = -1e9
local last_total   = 0.0    -- last computed route length, metres
local wp_pinned    = false

-- sub-type combo state, rebuilt each frame
local sub_labels   = { "(any)" }
local sub_idx      = 1

-- ── small helpers ─────────────────────────────────────────────────

local function dist3(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function kind_selected(kind)
    if kind == "ore"     then return want_ore     end
    if kind == "plant"   then return want_plant   end
    if kind == "chest"   then return want_chest   end
    if kind == "red_orb" then return want_red_orb end
    return false
end

-- Chests / red orbs do not respawn, so a permanent "done" makes sense.
-- Ore / plant respawn, so we only ever skip them for the current run.
local function can_be_done(kind)
    return kind == "chest" or kind == "red_orb"
end

local KIND_LABEL = {
    ore = "Ore", plant = "Plant", chest = "Chest", red_orb = "Red Orb",
}

local function row_label(p)
    if p.subkind and #p.subkind > 0 and #p.subkind <= 18 then
        return p.subkind
    end
    if p.name and #p.name > 0 and #p.name <= 22 then
        return p.name
    end
    return KIND_LABEL[p.kind] or p.kind
end

-- ── persistence (store holds string / number / bool only) ─────────

local function load_done()
    local s = farever.store.get("done_ids", "")
    local t = {}
    for id in s:gmatch("[^,]+") do t[id] = true end
    return t
end

local function save_done()
    local ids = {}
    for id in pairs(done_set) do ids[#ids + 1] = id end
    farever.store.set("done_ids", table.concat(ids, ","))
end

local function save_settings()
    farever.store.set("radius", radius)
    farever.store.set("max_stops", max_stops)
    farever.store.set("want_ore", want_ore)
    farever.store.set("want_plant", want_plant)
    farever.store.set("want_chest", want_chest)
    farever.store.set("want_red_orb", want_red_orb)
    farever.store.set("sub_filter", sub_filter)
    farever.store.set("auto_advance", auto_advance)
    farever.store.set("use_waypoints", use_waypoints)
    farever.store.set("show_map", show_map)
    farever.store.set("show_arrow", show_arrow)
end

-- ── waypoint integration (optional native backend) ────────────────

local function wp_available()
    return farever.waypoints
        and type(farever.waypoints.add) == "function"
        and type(farever.waypoints.remove) == "function"
end

local function wp_clear()
    if wp_pinned and wp_available() then
        pcall(farever.waypoints.remove, WP_LABEL)
    end
    wp_pinned = false
end

local function wp_pin_current()
    if not (use_waypoints and wp_available()) then return end
    wp_clear()
    local cur = route[1]
    if cur then
        pcall(farever.waypoints.add, cur.x, cur.y, cur.z, WP_LABEL)
        wp_pinned = true
    end
end

-- ── POI access (cached) ───────────────────────────────────────────

local function get_pois()
    local now = farever.now()
    if not pois_cache or (now - pois_cache_t) > POI_CACHE_S then
        pois_cache   = (farever.pois and farever.pois()) or {}
        pois_cache_t = now
    end
    return pois_cache
end

-- Distinct sub-types among the selected categories within radius, so
-- the combo only ever offers resources you can actually route to.
local function refresh_sub_labels(px, py)
    local seen, list = {}, {}
    local r2 = radius * radius
    for _, p in ipairs(get_pois()) do
        if kind_selected(p.kind) and p.subkind and #p.subkind > 0 then
            local dx, dy = px - p.x, py - p.y
            if (dx * dx + dy * dy) <= r2 and not seen[p.subkind] then
                seen[p.subkind] = true
                list[#list + 1] = p.subkind
            end
        end
    end
    table.sort(list)
    sub_labels = { "(any)" }
    for _, s in ipairs(list) do sub_labels[#sub_labels + 1] = s end

    -- keep sub_idx in sync with the stored sub_filter string
    sub_idx = 1
    for i, lbl in ipairs(sub_labels) do
        if (sub_filter == "" and lbl == "(any)") or lbl == sub_filter then
            sub_idx = i
            break
        end
    end
end

-- ── candidate selection + routing ─────────────────────────────────

local function gather_candidates(px, py, pz)
    local r2 = radius * radius
    local cands = {}
    for _, p in ipairs(get_pois()) do
        local id = tostring(p.id)
        if kind_selected(p.kind)
           and not done_set[id] and not visited[id]
           and (sub_filter == "" or p.subkind == sub_filter) then
            local dx, dy = px - p.x, py - p.y
            local d2 = dx * dx + dy * dy
            if d2 <= r2 then
                cands[#cands + 1] = {
                    id = id, x = p.x, y = p.y, z = p.z,
                    name = p.name, kind = p.kind, subkind = p.subkind,
                    d0 = math.sqrt(d2 + (pz - p.z) ^ 2),
                }
            end
        end
    end
    -- Keep only the max_stops nearest so routing stays cheap and the
    -- plan stays walkable.
    table.sort(cands, function(a, b) return a.d0 < b.d0 end)
    while #cands > max_stops do table.remove(cands) end
    return cands
end

-- Total open-path length: player -> stop1 -> stop2 -> ...
local function path_len(r, px, py, pz)
    local total, cx, cy, cz = 0.0, px, py, pz
    for _, n in ipairs(r) do
        total = total + dist3(cx, cy, cz, n.x, n.y, n.z)
        cx, cy, cz = n.x, n.y, n.z
    end
    return total
end

-- Position of a path node; index 0 is the (fixed) player start.
local function node_xyz(r, idx, px, py, pz)
    if idx == 0 then return px, py, pz end
    local n = r[idx]
    return n.x, n.y, n.z
end

-- Bounded 2-opt over an open path with a fixed virtual start (player).
local function two_opt(r, px, py, pz)
    local n = #r
    if n < 4 then return end
    local guard = 0
    local improved = true
    while improved and guard < 60 do
        improved = false
        guard = guard + 1
        for i = 1, n - 1 do
            for k = i + 1, n do
                local ax, ay, az = node_xyz(r, i - 1, px, py, pz) -- before seg
                local bx, by, bz = r[i].x, r[i].y, r[i].z         -- seg start
                local cx, cy, cz = r[k].x, r[k].y, r[k].z         -- seg end
                local before, after
                if k < n then
                    local dx, dy, dz = r[k + 1].x, r[k + 1].y, r[k + 1].z
                    before = dist3(ax, ay, az, bx, by, bz)
                           + dist3(cx, cy, cz, dx, dy, dz)
                    after  = dist3(ax, ay, az, cx, cy, cz)
                           + dist3(bx, by, bz, dx, dy, dz)
                else
                    before = dist3(ax, ay, az, bx, by, bz)
                    after  = dist3(ax, ay, az, cx, cy, cz)
                end
                if after + 1e-6 < before then
                    -- reverse r[i..k] in place
                    local lo, hi = i, k
                    while lo < hi do
                        r[lo], r[hi] = r[hi], r[lo]
                        lo, hi = lo + 1, hi - 1
                    end
                    improved = true
                end
            end
        end
    end
end

local function build_route()
    local px, py, pz = farever.player.x(), farever.player.y(), farever.player.z()
    local remaining  = gather_candidates(px, py, pz)
    local r          = {}
    local cx, cy, cz = px, py, pz

    -- greedy nearest-neighbour seed
    while #remaining > 0 do
        local bi, bd
        for i, nd in ipairs(remaining) do
            local d = dist3(cx, cy, cz, nd.x, nd.y, nd.z)
            if not bd or d < bd then bd, bi = d, i end
        end
        local nd = table.remove(remaining, bi)
        r[#r + 1] = nd
        cx, cy, cz = nd.x, nd.y, nd.z
    end

    two_opt(r, px, py, pz)
    route      = r
    last_total = path_len(r, px, py, pz)
    wp_pin_current()
end

-- ── nav arrow to the current stop ─────────────────────────────────

local function dz_rgb(dz)
    local a = math.abs(dz)
    if     a <  5 then return 0.4, 1.0, 0.4
    elseif a < 20 then return 1.0, 0.9, 0.2
    else               return 1.0, 0.4, 0.3 end
end

local function draw_arrow_panel(cur, px, py, pz)
    local ax, ay = imgui.cursor_pos()
    local cx, cy = ax + PANEL_W * 0.5, ay + ARROW_H * 0.5
    imgui.draw_rect_filled(ax, ay, ax + PANEL_W, ay + ARROW_H, 0.08, 0.10, 0.13, 0.78)
    imgui.draw_rect(ax, ay, ax + PANEL_W, ay + ARROW_H, 0.28, 0.30, 0.42, 0.85, 1.5)

    if not cur then
        imgui.draw_text(ax + 14, cy - 7, 0.5, 0.5, 0.5, 1.0, "No stops in range")
        imgui.dummy(PANEL_W, ARROW_H)
        return
    end

    local dx, dy, dz = cur.x - px, cur.y - py, cur.z - pz
    local h = farever.player.rot_z()
    local cosh, sinh = math.cos(h), math.sin(h)
    local fwd =  dx * cosh + dy * sinh
    local rgt = -dx * sinh + dy * cosh
    local d_h = math.sqrt(fwd * fwd + rgt * rgt)
    local th  = math.atan(rgt, fwd)
    local tv  = math.atan(dz, math.max(d_h, 1.0))

    local dir_x, dir_y =  math.sin(th), -math.cos(th)
    local perp_x, perp_y = -dir_y, dir_x
    local r, g, b = dz_rgb(dz)

    if d_h < 30 then
        local pulse = (math.sin(farever.now() * (d_h < 10 and 8.0 or 4.0)) + 1) * 0.5
        local pr = 26 + pulse * 14
        imgui.draw_circle_filled(cx, cy, pr, r, g, b, 0.07 + pulse * 0.11, 32)
        imgui.draw_circle(cx, cy, pr, r, g, b, 0.35 + pulse * 0.30, 1.0 + pulse, 32)
    end

    local ps   = 0.95 + 0.05 * math.sin(farever.now() * 3)
    local L     = 48 * ps
    local hl_n  = 20 * ps
    local hw_n  = 12 * ps
    local tilt  = math.sin(tv) * 15
    local tail_x, tail_y = cx - dir_x * L * 0.35, cy - dir_y * L * 0.35
    local tip_x,  tip_y  = cx + dir_x * L, cy + dir_y * L - tilt
    local back_x, back_y = tip_x - dir_x * hl_n, tip_y - dir_y * hl_n
    imgui.draw_line(tail_x, tail_y, back_x, back_y, r, g, b, 1.0, 5.0)
    imgui.draw_triangle_filled(tip_x, tip_y,
        back_x + perp_x * hw_n, back_y + perp_y * hw_n,
        back_x - perp_x * hw_n, back_y - perp_y * hw_n, r, g, b, 1.0)
    imgui.draw_triangle(tip_x, tip_y,
        back_x + perp_x * hw_n, back_y + perp_y * hw_n,
        back_x - perp_x * hw_n, back_y - perp_y * hw_n, 0, 0, 0, 0.6, 1.5)

    imgui.draw_text(ax + 6, ay + 5, 0.88, 0.88, 0.88, 0.95,
        "Next: " .. row_label(cur):sub(1, 26))
    imgui.draw_text(ax + 6, ay + ARROW_H - 19, r, g, b, 1.0,
        string.format("%.0f m   %+.1f m   (%d left)", d_h, dz, #route))
    imgui.dummy(PANEL_W, ARROW_H)
end

-- ── schematic route map ───────────────────────────────────────────
-- Projection: screen-right = world +Y (east), screen-up = world +X
-- (north), matching the in-game minimap / compass convention.

local function draw_route_map(px, py)
    local ox, oy = imgui.cursor_pos()
    imgui.draw_rect_filled(ox, oy, ox + PANEL_W, oy + MAP_H, 0.05, 0.06, 0.10, 0.92)
    imgui.draw_rect(ox, oy, ox + PANEL_W, oy + MAP_H, 0.22, 0.24, 0.36, 0.8, 1.0)

    if #route == 0 then
        imgui.draw_text(ox + 12, oy + MAP_H * 0.5 - 7, 0.5, 0.5, 0.5, 1.0,
            "No route — press Build")
        imgui.dummy(PANEL_W, MAP_H)
        return
    end

    -- bounding box in projected (u = y, v = -x) space
    local umin, umax = px, px   -- placeholder, replaced below
    umin, umax = py, py
    local vmin, vmax = -px, -px
    local function expand(wx, wy)
        local u, v = wy, -wx
        if u < umin then umin = u end
        if u > umax then umax = u end
        if v < vmin then vmin = v end
        if v > vmax then vmax = v end
    end
    expand(px, py)
    for _, n in ipairs(route) do expand(n.x, n.y) end

    local pad = 16
    local iw, ih = PANEL_W - 2 * pad, MAP_H - 2 * pad
    local s = math.min(iw / math.max(umax - umin, 1.0),
                       ih / math.max(vmax - vmin, 1.0))
    local cu, cv = (umin + umax) * 0.5, (vmin + vmax) * 0.5
    local function project(wx, wy)
        local u, v = wy, -wx
        return ox + PANEL_W * 0.5 + (u - cu) * s,
               oy + MAP_H   * 0.5 + (v - cv) * s
    end

    -- route edges: player -> stop1 -> stop2 -> ...
    local lx, ly = project(px, py)
    for i, n in ipairs(route) do
        local sx, sy = project(n.x, n.y)
        local edge_a = (i == 1) and 0.95 or 0.45     -- highlight the active leg
        imgui.draw_line(lx, ly, sx, sy, 0.45, 0.75, 1.0, edge_a, i == 1 and 2.5 or 1.4)
        lx, ly = sx, sy
    end

    -- nodes
    for i, n in ipairs(route) do
        local sx, sy = project(n.x, n.y)
        if i == 1 then
            local pulse = (math.sin(farever.now() * 3) + 1) * 0.5
            imgui.draw_circle_filled(sx, sy, 5.0, 1.0, 0.85, 0.2, 1.0)
            imgui.draw_circle(sx, sy, 6 + pulse * 4, 1.0, 0.85, 0.2, pulse * 0.8, 1.5)
        else
            imgui.draw_circle_filled(sx, sy, 3.2, 0.55, 0.75, 1.0, 0.85)
        end
        if i <= 9 then
            imgui.draw_text(sx + 5, sy - 6, 0.85, 0.9, 1.0, 0.9, tostring(i))
        end
    end

    -- player dot + heading
    local spx, spy = project(px, py)
    imgui.draw_circle_filled(spx, spy, 4.5, 0.2, 1.0, 0.4, 1.0)
    local h = farever.player.rot_z()
    imgui.draw_line(spx, spy, spx + math.sin(h) * 12, spy - math.cos(h) * 12,
        0.2, 1.0, 0.4, 0.9, 2.0)

    imgui.draw_text(ox + 6, oy + 4, 0.5, 0.55, 0.7, 0.9,
        string.format("%d stops  -  %.0f m total", #route, last_total))
    imgui.dummy(PANEL_W, MAP_H)
end

-- ── lifecycle ─────────────────────────────────────────────────────

function on_init()
    radius        = farever.store.get("radius", 250)
    max_stops     = farever.store.get("max_stops", 20)
    want_ore      = farever.store.get("want_ore", true)
    want_plant    = farever.store.get("want_plant", true)
    want_chest    = farever.store.get("want_chest", true)
    want_red_orb  = farever.store.get("want_red_orb", true)
    sub_filter    = farever.store.get("sub_filter", "")
    auto_advance  = farever.store.get("auto_advance", true)
    use_waypoints = farever.store.get("use_waypoints", false)
    show_map      = farever.store.get("show_map", true)
    show_arrow    = farever.store.get("show_arrow", true)
    done_set      = load_done()

    route      = {}
    visited    = {}
    need_build = true
    wp_pinned  = false
    farever.log.info("route_optimizer v" .. PLUGIN_VERSION .. " loaded")
end

function on_event(name, _)
    if name == "hero_locked" then
        -- new zone / session: routes and the run's skip-set no longer apply
        wp_clear()
        route      = {}
        visited    = {}
        need_build = true
    end
end

-- ── main render ───────────────────────────────────────────────────

function on_render()
    imgui.dummy(PANEL_W, 0)   -- pin content width
    imgui.text("Gathering Route Optimizer v" .. PLUGIN_VERSION)

    if not farever.player.locked() then
        imgui.text_colored(1.0, 0.6, 0.2, 1.0, "Waiting for player lock...")
        return
    end

    local px = farever.player.x()
    local py = farever.player.y()
    local pz = farever.player.z()

    -- ── auto-advance: pop the current stop once you reach it ───────
    if auto_advance and #route > 0 then
        local cur = route[1]
        local dxy = math.sqrt((px - cur.x) ^ 2 + (py - cur.y) ^ 2)
        if dxy <= ARRIVE_XY and math.abs(pz - cur.z) <= ARRIVE_Z then
            visited[cur.id] = true
            table.remove(route, 1)
            farever.toast("Collected: " .. row_label(cur), 1.5)
            farever.sound("info")
            if #route == 0 then
                wp_clear()
                farever.toast("Route complete!", 2.5)
                farever.sound("alert")
            else
                wp_pin_current()
            end
        end
    end

    -- ── filters ────────────────────────────────────────────────────
    local v, c
    v, c = imgui.drag_float("Radius (m)", radius, 2.0, 30, 1000)
    if c then radius = v; need_build = true; save_settings() end
    v, c = imgui.drag_float("Max stops", max_stops, 0.25, 3, 40)
    if c then max_stops = math.floor(v + 0.5); need_build = true; save_settings() end

    local nv
    nv, c = imgui.checkbox("Ore", want_ore)
    if c then want_ore = nv; need_build = true; save_settings() end
    imgui.same_line()
    nv, c = imgui.checkbox("Plant", want_plant)
    if c then want_plant = nv; need_build = true; save_settings() end
    imgui.same_line()
    nv, c = imgui.checkbox("Chest", want_chest)
    if c then want_chest = nv; need_build = true; save_settings() end
    imgui.same_line()
    nv, c = imgui.checkbox("Red Orb", want_red_orb)
    if c then want_red_orb = nv; need_build = true; save_settings() end

    -- sub-type combo (rebuilt from what's actually in range)
    refresh_sub_labels(px, py)
    local ni, ch = imgui.combo("Resource", sub_idx, sub_labels)
    if ch then
        sub_idx = ni
        sub_filter = (sub_labels[ni] == "(any)") and "" or sub_labels[ni]
        need_build = true
        save_settings()
    end

    nv, c = imgui.checkbox("Auto-advance", auto_advance)
    if c then auto_advance = nv; save_settings() end
    imgui.same_line()
    nv, c = imgui.checkbox("Map", show_map)
    if c then show_map = nv; save_settings() end
    imgui.same_line()
    nv, c = imgui.checkbox("Arrow", show_arrow)
    if c then show_arrow = nv; save_settings() end

    if wp_available() then
        imgui.same_line()
        nv, c = imgui.checkbox("Pin WP", use_waypoints)
        if c then
            use_waypoints = nv
            if use_waypoints then wp_pin_current() else wp_clear() end
            save_settings()
        end
    end

    imgui.separator()

    -- ── build controls ─────────────────────────────────────────────
    if imgui.button("Build route") then need_build = true end
    imgui.same_line()
    if imgui.button("Reset run") then
        visited = {}; need_build = true
    end
    imgui.same_line()
    if imgui.button("Clear done") then
        done_set = {}; save_done(); need_build = true
        farever.toast("Cleared permanent collected set", 1.5)
    end

    if need_build then
        build_route()
        need_build = false
    end

    -- ── visuals ─────────────────────────────────────────────────────
    if show_arrow then draw_arrow_panel(route[1], px, py, pz) end
    if show_map   then draw_route_map(px, py) end

    imgui.separator()

    if #route == 0 then
        local total = 0
        for _ in pairs(done_set) do total = total + 1 end
        imgui.text_colored(0.6, 0.6, 0.6, 1.0, "No stops match your filters in range.")
        imgui.text_colored(0.5, 0.5, 0.5, 1.0,
            string.format("(%d POIs loaded, %d marked done)", #get_pois(), total))
        return
    end

    imgui.text(string.format("Route  -  %d stops  -  %.0f m", #route, last_total))
    imgui.separator()

    for i, n in ipairs(route) do
        if i > LIST_ROWS then
            imgui.text_colored(0.55, 0.55, 0.55, 1.0,
                string.format("  ... %d more", #route - LIST_ROWS))
            break
        end
        local dxy = math.sqrt((px - n.x) ^ 2 + (py - n.y) ^ 2)
        local dz  = n.z - pz
        local r, g, b = dz_rgb(dz)
        local a = (i == 1) and 1.0 or 0.9
        local marker = (i == 1) and ">" or string.format("%d.", i)
        imgui.text_colored(r, g, b, a, string.format(
            "%-3s %-20s %5.0fm %+6.1fm", marker, row_label(n):sub(1, 20), dxy, dz))

        -- skip just this stop (any kind), or mark chests/orbs done forever
        imgui.same_line()
        if imgui.button("skip##" .. i) then
            visited[n.id] = true
            if i == 1 then wp_clear() end
            table.remove(route, i)
            last_total = path_len(route, px, py, pz)
            if route[1] then wp_pin_current() end
            break
        end
        if can_be_done(n.kind) then
            imgui.same_line()
            if imgui.button("done##" .. i) then
                done_set[n.id] = true; save_done()
                visited[n.id] = true
                if i == 1 then wp_clear() end
                table.remove(route, i)
                last_total = path_len(route, px, py, pz)
                if route[1] then wp_pin_current() end
                break
            end
        end
    end

    imgui.separator()
    imgui.text_colored(0.5, 0.5, 0.5, 1.0,
        string.format("Z: %.1f   radius %.0fm   cap %d", pz, radius, max_stops))
end
