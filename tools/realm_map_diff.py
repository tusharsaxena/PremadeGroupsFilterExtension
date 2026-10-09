#!/usr/bin/env python3
"""Diff this addon's realm map against PremadeRegions' realm lists.

Usage (from the repo root):
    python3 tools/realm_map_diff.py <path/to/PremadeRegions/Regions.lua> [path/to/defaults/Realms.lua]

Reads both Lua files as text (nothing is executed), pulls out every bucket per portal, normalizes
each realm name the way NS.Regions.Normalize does (ASCII lowercase, whitespace and ASCII
punctuation dropped, every other byte kept), and prints one line per difference:

    ADDED   <portal> <key> <realm>   the reference lists a realm this addon's map lacks
    REMOVED <portal> <key> <realm>   this addon's map lists a realm the reference lacks
    MOVED   <portal> <key> <realm>   both list it, in different buckets (key = the reference's;
                                     this addon's bucket follows in brackets)

Exit status: 0 when the maps agree, 1 when any difference exists, 2 on a usage or parse error.
Dev-only: tools/ is kept out of the packaged zip by .pkgmeta. See docs/realm-map-maintenance.md.
"""

import re
import string
import sys

PORTALS = ("US", "EU")
# Ours: `US = {`; PremadeRegions: `PR.US_REGION_REALMS = {`.
PORTAL_RE = re.compile(r"\b(US|EU)(?:_REGION_REALMS)?\s*=\s*\{")
# Ours: `oce = { ... }`; PremadeRegions: `["oce"] = { ... }`. Buckets hold no nested braces.
BUCKET_RE = re.compile(r'(?:\["(\w+)"\]|\b(\w+))\s*=\s*\{([^{}]*)\}')
STRING_RE = re.compile(r'"((?:[^"\\]|\\.)*)"')
COMMENT_RE = re.compile(r"--[^\n]*")
DROP = set(string.whitespace + string.punctuation)


def normalize(realm):
    """Byte-for-byte twin of NS.Regions.Normalize under Lua 5.1's C locale."""
    raw = realm.encode("utf-8").lower()  # bytes.lower() touches ASCII only, like string.lower
    return bytes(b for b in raw if chr(b) not in DROP or b > 127).decode("utf-8", "replace")


def parse(path):
    """Return {portal: {normalized: (key, display)}}."""
    with open(path, encoding="utf-8") as handle:
        text = COMMENT_RE.sub("", handle.read())
    marks = [(m.group(1), m.end()) for m in PORTAL_RE.finditer(text)]
    if sorted(p for p, _ in marks) != sorted(PORTALS):
        raise ValueError("%s: expected one US and one EU block, found %s" % (path, [p for p, _ in marks]))
    marks.sort(key=lambda item: item[1])
    result = {}
    for index, (portal, start) in enumerate(marks):
        end = marks[index + 1][1] if index + 1 < len(marks) else len(text)
        realms = {}
        for quoted, bare, body in BUCKET_RE.findall(text[start:end]):
            key = quoted or bare
            for name in STRING_RE.findall(body):
                realms[normalize(name)] = (key, name)
        if not realms:
            raise ValueError("%s: the %s block holds no realms" % (path, portal))
        result[portal] = realms
    return result


def diff(reference, ours):
    lines = []
    for portal in PORTALS:
        ref, own = reference[portal], ours[portal]
        for norm in sorted(ref):
            key, name = ref[norm]
            if norm not in own:
                lines.append("ADDED   %s %s %s" % (portal, key, name))
            elif own[norm][0] != key:
                lines.append("MOVED   %s %s %s [ours: %s]" % (portal, key, name, own[norm][0]))
        for norm in sorted(own):
            if norm not in ref:
                key, name = own[norm]
                lines.append("REMOVED %s %s %s" % (portal, key, name))
    return lines


def main(argv):
    if len(argv) not in (2, 3):
        sys.stderr.write(__doc__)
        return 2
    try:
        reference = parse(argv[1])
        ours = parse(argv[2] if len(argv) == 3 else "defaults/Realms.lua")
    except (OSError, ValueError) as err:
        sys.stderr.write("realm_map_diff: %s\n" % err)
        return 2
    lines = diff(reference, ours)
    for line in lines:
        print(line)
    counts = ", ".join("%s %d" % (p, len(ours[p])) for p in PORTALS)
    print("%d difference(s); this addon's map: %s realms" % (len(lines), counts))
    return 1 if lines else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
