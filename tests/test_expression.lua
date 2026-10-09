-- tests/test_expression.lua — NS.Expression (docs/superpowers/plans/2026-10-09-m-plus-v0.1.md, Task 4).

local T = _G.PGFE_TEST
local test, assertEqual, assertNil, assertTrue =
    T.test, T.assertEqual, T.assertNil, T.assertTrue

local function E() return T.newAddon().Expression end

test("expression: clauses in fixed order", function()
    local c = E().BuildClauses{ regions = { "oce", "chi" }, noSameSpec = true, noSameClassRole = true,
        experiencedLeader = true, keyLevel = 14, maxAge = 15 }
    assertEqual(table.concat(c, " | "),
        "( oce or chi ) | pgfe_samespec == 0 | pgfe_sameclassrole == 0 | ( mpmapintime and mpmapmaxkey >= 14 ) | age <= 15")
end)

test("expression: empty user text → bare block", function()
    local X = E()
    local out = X.Merge("", { "age <= 15" })
    assertEqual(out, X.MARK_BEGIN .. "\n( age <= 15 )\n" .. X.MARK_END)
    assertEqual(X.Normalize(out), "( age <= 15 )")
end)

test("expression: user text is parenthesized so its OR cannot leak", function()
    local X = E()
    local out = X.Merge("voice or myrealm", { "age <= 15" })
    assertEqual(X.Normalize(out), "( age <= 15 ) and ( voice or myrealm )")
end)

test("expression: re-apply is idempotent and replaces the block", function()
    local X = E()
    local once = X.Merge("voice", { "age <= 15" })
    local twice = X.Merge(once, { "age <= 10" })
    assertEqual(X.Normalize(twice), "( age <= 10 ) and ( voice )")
    assertEqual(X.Merge(twice, { "age <= 10" }), twice)
end)

test("expression: strip restores the user text exactly", function()
    local X = E()
    local user = "voice\n-- my note\nor myrealm"
    local stripped, ok = X.Strip(X.Merge(user, { "age <= 15" }))
    assertTrue(ok); assertEqual(stripped, user)
end)

test("expression: no clauses → user text only (block removed)", function()
    local X = E()
    assertEqual(X.Merge(X.Merge("voice", { "age <= 15" }), {}), "voice")
end)

test("expression: comment-only user text treated as empty (no `and ( )`)", function()
    local X = E()
    local out = X.Merge("-- just a note", { "age <= 15" })
    assertEqual(X.Normalize(out), "( age <= 15 )")
    local stripped = X.Strip(out)
    assertEqual(stripped, "-- just a note")
end)

test("expression: damaged block (begin without end) → error, text untouched", function()
    local X = E()
    local bad = X.MARK_BEGIN .. "\n( age <= 15 ) and (\nvoice"
    local out, err = X.Merge(bad, { "age <= 10" })
    assertNil(out); assertEqual(err, "damaged")
end)

test("expression: over 2000 chars → toolong", function()
    local X = E()
    local out, err = X.Merge(string.rep("x", 1990), { "age <= 15" })
    assertNil(out); assertEqual(err, "toolong")
end)
