/*
 * Medium Rock
 * https://polyfork.dev/asset/medium-rock-e08405
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './medium-rock-e08405.mjs';
 *   scene.add(createAsset());
 *
 * The bare "three" specifiers below resolve through any bundler, or through
 * an importmap in your page:
 *
 *   { "imports": { "three": "https://unpkg.com/three@0.180.0/build/three.module.js",
 *                  "three/addons/": "https://unpkg.com/three@0.180.0/examples/jsm/" } }
 *
 * Browsers refuse to load ES modules from file:// URLs, so a page of your own
 * that imports this file has to be served over http:  python3 -m http.server
 *
 * The index.html in this asset's .zip download sidesteps that and opens with
 * a double-click. The store page above has the same snippet for Unity, Godot,
 * Blender and GLB.
 *
 * OPTIONS  createAsset({ ... })
 *
 *   colorway   choice  'granite-grey' 'granite-grey' | 'mossy-shade' | 'sandstone' | 'dark-slate'
 *   stone      color   '#87847c'      any hex or THREE.Color
 *   fracture   color   '#bcb9b1'      any hex or THREE.Color
 *   moss       color   '#5f9a4b'      any hex or THREE.Color
 *   mossDeep   color   '#3d6b34'      any hex or THREE.Color
 *   size       range   1              0.55 to 1.6
 *   rake       range   0.6            0.1 to 1
 *   chips      range   3              0 to 4
 *   mossCover  range   0.3            0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/medium-rock-e08405-params.json
 *
 * SPECS  173 triangles, 1 material, 1 x 0.63 x 0.79 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'granite-grey': { stone: '#87847c', fracture: '#bcb9b1', moss: '#5f9a4b', mossDeep: '#3d6b34' },
  'mossy-shade':  { stone: '#6e6b63', fracture: '#a3a099', moss: '#4c8140', mossDeep: '#2f4f2e' },
  'sandstone':    { stone: '#8c6a47', fracture: '#c2a479', moss: '#8fa84a', mossDeep: '#6f8f3c' },
  'dark-slate':   { stone: '#57544e', fracture: '#87847c', moss: '#3d6b34', mossDeep: '#25402c' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'granite-grey', label: 'Colorway',
    options: ['granite-grey', 'mossy-shade', 'sandstone', 'dark-slate'],
    describe: 'Curated Nature & Forest stone schemes, all from the kit palette. ' +
      'granite-grey is the shipped mid warm-grey rock with pale break faces and bright ' +
      'spring moss; mossy-shade is a darker damp-forest grey under deep shade green, for ' +
      'the floor of a closed canopy; sandstone is a warm tan stone with dry yellow-green ' +
      'lichen, for sunlit clearings and riverbanks; dark-slate is a cold near-charcoal ' +
      'stone with very dark moss, for ravines and wet gullies. Sets stone, ' +
      'fracture, moss and mossDeep unless those are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#87847c', label: 'Stone',
    describe: 'Albedo of the weathered rock body — every un-chipped facet, about 75% of ' +
      'the visible surface and the dominant colour of the asset. A mid rung of the kit\'s ' +
      'neutral grey ramp, so it sits in the same stone family as the kit\'s large boulder ' +
      'while leaving two clear rungs of headroom above it for the Fracture faces. A stone ' +
      'is one material: all the shading you see on it comes from the facets and the scene ' +
      'lights, never from this value.',
  },
  fracture: {
    type: 'color', default: '#bcb9b1', label: 'Fracture face',
    describe: 'Albedo of the chip scars only — the whole flat cells where a flake has ' +
      'broken off, exposing paler unweathered interior stone. Keep it TWO rungs of the ' +
      'kit grey ramp lighter than Stone, not one: a single rung is about 12% of value, ' +
      'which the hero\'s shading hides and the flat front elevation shows as one merged ' +
      'grey. Unused when Chip scars is 0.',
  },
  moss: {
    type: 'color', default: '#5f9a4b', label: 'Moss',
    describe: 'Albedo of the main body of the moss crust on the crest and upper ramp. ' +
      'The brighter of the two greens and the one colour block that has to read against ' +
      'the grey from 10 m, so keep it saturated. Unused when Moss cover is 0.',
  },
  mossDeep: {
    type: 'color', default: '#3d6b34', label: 'Moss shadow patches',
    describe: 'Albedo of the darker irregular patches inside the moss crust, roughly a ' +
      'third of it. Sits one clear value step below Moss; matched to Moss the crust ' +
      'flattens into a single green sticker.',
  },
  size: {
    type: 'range', default: 1.00, min: 0.55, max: 1.60, step: 0.05, label: 'Size',
    affects: 'geometry',
    describe: 'Width of the rock across X in METRES. A genuine REBUILD, not a scale: the ' +
      'facet cell is a rock\'s repeat unit, so the cutting-plane count follows the ' +
      'surface (2 big cells per flank tier at 0.55 m, 3 at the 1.00 m default, 4 at ' +
      '1.60 m, plus an undercut ring that grows from 4 planes to 7, giving 164 / 172 / ' +
      '199 triangles) and each cell stays a constant size in world units instead ' +
      'of the whole stone getting coarser or finer. The moss crust keeps its real ' +
      '0.022 m thickness at every ' +
      'size. 0.55 m is a stone you could roll aside; 1.60 m is a knee-to-waist-high ' +
      'wedge you walk around. The triangle count moves with it.',
  },
  rake: {
    type: 'range', default: 0.60, min: 0.10, max: 1.00, step: 0.05, label: 'Wedge rake',
    affects: 'geometry',
    describe: 'How hard the wedge is raked — the knob that owns this rock\'s identity. ' +
      'It re-solves the two ramp planes and the mass\'s lean together, so the whole ' +
      'solid is re-cut and the triangle count changes. 0.10 is a blunt near-symmetric ' +
      'block barely taller at one end, about 0.55 m high, close to a small boulder; ' +
      '0.60 is the shipped wedge, a 0.63 m crest with a ~19 degree upper ramp breaking ' +
      'into a ~50 degree lower one; 1.00 is a dramatic 0.68 m fin whose long ' +
      'side is one bold straight run down to the tail. The footprint stays 1.00 m wide, ' +
      'so the whole change is in the FRONT elevation silhouette.',
  },
  chips: {
    type: 'range', default: 3, min: 0, max: 4, step: 1, label: 'Chip scars',
    affects: 'geometry',
    describe: 'How many fresh fracture faces are struck off the rock. Each one is a whole ' +
      'flat cell cut 6-9% deeper toward the centre and painted the pale Fracture ' +
      'grey, so it visibly flattens one corner of the silhouette as well as changing ' +
      'colour. 0 is an unbroken weather-rounded stone in a single tone; 3 is the shipped ' +
      'rock, with breaks on the front flank, the scarp\'s front corner and the back ' +
      'shoulder so no elevation is bare; 4 adds a spall just under the crest.',
  },
  mossCover: {
    type: 'range', default: 0.30, min: 0, max: 1, step: 0.05, label: 'Moss cover',
    affects: 'geometry',
    describe: 'How far the moss crust spreads over the up-facing cells, as real welded ' +
      'crusts cut out of the rock\'s own cells, each with a bare stone margin around it ' +
      'and a real raised lip — never paint. EXACTLY 0 is a completely bare clean stone ' +
      'with no green geometry and no green triangles at all, for dry or rocky ground; ' +
      '0.30 is the shipped rock, two crusts on the ramp that leave its slope break and ' +
      'the crest ridge bare; 1.00 spreads up to five larger crusts onto the shoulders as ' +
      'well, like a stone that has sat in deep shade for years. Never on a flank, never ' +
      'on the scarp, never over the crest and never underneath, at any value.',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const cross = (a, b) => [
  a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0],
];
function norm(a) {
  const l = Math.hypot(a[0], a[1], a[2]) || 1;
  return [a[0] / l, a[1] / l, a[2] / l];
}
const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function profAt(table, t) {
  if (t <= table[0][0]) return table[0][1];
  for (let i = 1; i < table.length; i++) {
    if (t <= table[i][0]) {
      const [t0, r0] = table[i - 1], [t1, r1] = table[i];
      return r0 + (r1 - r0) * ((t - t0) / (t1 - t0));
    }
  }
  return table[table.length - 1][1];
}

const EPS = 1e-6;

function capPolygon(pts, n) {
  const c = [0, 0, 0];
  for (const p of pts) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
  c[0] /= pts.length; c[1] /= pts.length; c[2] /= pts.length;
  const a = Math.abs(n[1]) < 0.9 ? [0, 1, 0] : [1, 0, 0];
  const u = norm(cross(a, n));
  const v = cross(n, u);
  const keyed = pts.map((p) => {
    const d = sub(p, c);
    return { p, ang: Math.atan2(dot(d, v), dot(d, u)) };
  });
  keyed.sort((x, y) => x.ang - y.ang);
  return dedupeLoop(keyed.map((k) => k.p));
}

function dedupeLoop(loop, tol = 2e-5) {
  const out = [];
  for (const p of loop) {
    const q = out[out.length - 1];
    if (q && Math.abs(p[0] - q[0]) < tol && Math.abs(p[1] - q[1]) < tol && Math.abs(p[2] - q[2]) < tol) continue;
    out.push(p);
  }
  const f = out[0], l = out[out.length - 1];
  if (out.length > 1 && Math.abs(f[0] - l[0]) < tol && Math.abs(f[1] - l[1]) < tol && Math.abs(f[2] - l[2]) < tol) out.pop();
  return out;
}

function clipByPlane(faces, pl) {
  const kept = [];
  const cut = [];
  for (const face of faces) {
    const f = face.loop;
    const dist = f.map((p) => dot(pl.n, p) - pl.d);
    const nf = [];
    for (let i = 0; i < f.length; i++) {
      const j = (i + 1) % f.length;
      const di = dist[i], dj = dist[j];
      if (di <= EPS) nf.push(f[i]);
      if (Math.abs(di) <= EPS) cut.push(f[i]);
      else if ((di < 0 && dj > EPS) || (di > EPS && dj < 0)) {
        const s = di / (di - dj);
        const p = [
          f[i][0] + (f[j][0] - f[i][0]) * s,
          f[i][1] + (f[j][1] - f[i][1]) * s,
          f[i][2] + (f[j][2] - f[i][2]) * s,
        ];
        nf.push(p); cut.push(p);
      }
    }
    const loop = dedupeLoop(nf);
    if (loop.length >= 3) kept.push({ loop, chip: face.chip });
  }
  if (cut.length >= 3) {
    const cap = capPolygon(cut, pl.n);
    if (cap.length >= 3) kept.push({ loop: cap, chip: !!pl.chip });
  }
  return kept;
}

function faceArea(f) {
  let a = [0, 0, 0];
  for (let i = 1; i + 1 < f.length; i++) {
    const c = cross(sub(f[i], f[0]), sub(f[i + 1], f[0]));
    a = [a[0] + c[0], a[1] + c[1], a[2] + c[2]];
  }
  return Math.hypot(a[0], a[1], a[2]) / 2;
}

function resampleLoop(loop, n) {
  const out = loop.slice();
  while (out.length < n) {
    let bi = 0, bl = -1;
    for (let i = 0; i < out.length; i++) {
      const a = out[i], b = out[(i + 1) % out.length];
      const L = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
      if (L > bl) { bl = L; bi = i; }
    }
    if (bl <= 0) break;
    const a = out[bi], b = out[(bi + 1) % out.length];
    out.splice(bi + 1, 0, [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2]);
  }
  return out;
}

function surfacePoints(cfg) {
  const pts = [];
  const RINGS = 20, SEGS = 28;

  const wedge = (x) => {
    const s = clamp((x - cfg.xTail) / (cfg.xCrest - cfg.xTail), 0, 1);
    return cfg.wLow + (1 - cfg.wLow) * s * s * (3 - 2 * s);
  };
  for (let i = 0; i <= RINGS; i++) {
    const t = i / RINGS;
    const rf = profAt(cfg.prof, t);
    for (let j = 0; j < SEGS; j++) {
      const a = (j / SEGS) * Math.PI * 2;
      const m = 1
        + cfg.m3 * Math.sin(3 * a + cfg.p3)
        + cfg.m5 * Math.sin(5 * a + cfg.p5);
      const r = cfg.R * rf * m;
      const x = Math.cos(a) * r + cfg.lean * t * t;
      pts.push([
        x,
        t * cfg.H * wedge(Math.cos(a) * cfg.R * profAt(cfg.prof, 0.32) * m),
        (Math.sin(a) * r + cfg.shearZ * t * t) * cfg.zSquash,
      ]);
    }
  }
  return pts;
}

function cutDirections(count, phase) {
  const dirs = [];
  const ga = Math.PI * (3 - Math.sqrt(5));
  const N = Math.round(count * 1.30);
  for (let i = 0; i < N; i++) {
    const ny = 1 - (2 * i + 1) / N;
    if (ny < -0.45) continue;
    const rad = Math.sqrt(Math.max(0, 1 - ny * ny));
    const a = i * ga + phase;
    dirs.push([Math.cos(a) * rad, ny, Math.sin(a) * rad]);
  }
  return dirs;
}

function welder(tol = 5e-4) {
  const map = new Map();
  const pts = [];
  const find = (p) => {
    const gx = Math.round(p[0] / tol), gy = Math.round(p[1] / tol), gz = Math.round(p[2] / tol);
    for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) for (let dz = -1; dz <= 1; dz++) {
      const i = map.get(`${gx + dx},${gy + dy},${gz + dz}`);
      if (i !== undefined) return i;
    }
    const i = pts.length;
    pts.push([p[0], p[1], p[2]]);
    map.set(`${gx},${gy},${gz}`, i);
    return i;
  };
  return { find, pts };
}

const CHIP_DIRS = [
  [0.34, 0.10, 0.93],
  [0.86, 0.28, 0.43],
  [-0.26, 0.34, -0.90],
  [-0.08, 0.60, 0.80],
];

const CHIP_BITE = [0.058, 0.062, 0.090, 0.066];

const R0 = 0.50;

const PROFILE = [
  [0.00, 0.86], [0.14, 0.97], [0.32, 1.00], [0.58, 0.96],
  [0.78, 0.84], [0.92, 0.66], [1.00, 0.42],
];

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);

  const way = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['stone', 'fracture', 'moss', 'mossDeep']) {
    C[k] = userParams[k] ?? way[k] ?? params[k].default;
  }

  const SIZE = clamp(Number(P.size) || params.size.default, 0.55, 1.60);
  const RAKE = clamp(Number(P.rake ?? params.rake.default), 0.10, 1.00);
  const nChips = clamp(Math.round(Number(P.chips)), 0, 4);
  const COVER = clamp(Number(P.mossCover ?? params.mossCover.default), 0, 1);

  const H = 0.4725 + 0.138 * RAKE;

  const nFlank = Math.round(2 + 2.1 * (SIZE - 0.55) / 1.05);
  const nFoot  = Math.round(4 + 3.0 * (SIZE - 0.55) / 1.05);

  const pts = surfacePoints({
    H, R: R0, prof: PROFILE,
    m3: 0.085, p3: 1.35, m5: 0.052, p5: 2.10,
    lean: 0.05 + 0.09 * RAKE,
    shearZ: 0.035,
    zSquash: 0.767,

    xTail: -0.50, xCrest: 0.24,
    wLow: 0.36 - 0.26 * RAKE,
  });
  const centre = [0.06, H * 0.34, 0];
  const rand = prng(70418293);

  const tangent = (n, bite) => {
    let s = -Infinity;
    for (const p of pts) { const v = dot(n, p); if (v > s) s = v; }
    const c = dot(n, centre);
    return c + (s - c) * (1 - bite);
  };

  const planes = [{ n: [0, -1, 0], d: 0, chip: false }];

  const a1 = (8 + 18 * RAKE) * Math.PI / 180;
  const a2 = (30 + 34 * RAKE) * Math.PI / 180;
  const wedgePlanes = [
    { n: norm([-Math.sin(a1), Math.cos(a1), 0.05]), bite: 0.045 },
    { n: norm([-Math.sin(a2), Math.cos(a2), -0.04]), bite: 0.115 },

    { n: norm([0.985, 0.40 + 0.09 * RAKE, 0.04]), bite: 0.155 },

    { n: norm([-0.95, 0.26, 0.08]), bite: 0.120 },
  ];
  for (const w of wedgePlanes) planes.push({ n: w.n, d: tangent(w.n, w.bite), chip: false });

  for (const side of [1, -1]) {
    for (const tier of [0, 1]) {
      const ny = tier ? 0.34 : -0.20;
      const n0 = tier ? nFlank : nFlank + 1;
      for (let k = 0; k < n0; k++) {
        const t = n0 === 1 ? 0.5 : k / (n0 - 1);

        const az = (tier ? 64 + 84 * t : 35 + 110 * t) * Math.PI / 180;
        const ch = Math.sqrt(Math.max(0.05, 1 - ny * ny));
        const n = norm([Math.cos(az) * ch, ny + 0.07 * rand(), Math.sin(az) * ch * side]);
        planes.push({ n, d: tangent(n, 0.030 + 0.065 * rand()), chip: false });
      }
    }
  }

  for (const side of [1, -1]) {
    const n = norm([-0.42, 0.62, 0.66 * side]);
    planes.push({ n, d: tangent(n, 0.030 + 0.025 * rand()), chip: false });
  }

  const FOOT = 0.62;
  for (let i = 0; i < nFoot; i++) {
    const a = (i / nFoot) * Math.PI * 2 + 0.34 + 0.20 * Math.sin(i * 2.4);
    const hx = Math.cos(a), hz = Math.sin(a);
    let rEq = -Infinity;
    for (const p of pts) { const v = p[0] * hx + p[2] * hz; if (v > rEq) rEq = v; }
    const r = rEq * FOOT * (0.92 + 0.14 * Math.sin(i * 3.1 + 0.8));
    const n = norm([hx * 0.72, -0.69, hz * 0.72]);
    planes.push({ n, d: n[0] * hx * r + n[2] * hz * r, chip: false });
  }

  for (let i = 0; i < nChips; i++) {
    const n = norm(CHIP_DIRS[i]);
    const b = CHIP_BITE[i] * (1 - 0.40 * Math.max(0, n[1]));
    planes.push({ n, d: tangent(n, b), chip: true });
  }

  const S = 6;
  const c8 = [
    [-S, -S, -S], [S, -S, -S], [S, -S, S], [-S, -S, S],
    [-S, S, -S], [S, S, -S], [S, S, S], [-S, S, S],
  ];
  let faces = [
    { loop: [c8[3], c8[2], c8[1], c8[0]], chip: false },
    { loop: [c8[4], c8[5], c8[6], c8[7]], chip: false },
    { loop: [c8[0], c8[1], c8[5], c8[4]], chip: false },
    { loop: [c8[2], c8[3], c8[7], c8[6]], chip: false },
    { loop: [c8[1], c8[2], c8[6], c8[5]], chip: false },
    { loop: [c8[3], c8[0], c8[4], c8[7]], chip: false },
  ];
  for (const pl of planes) faces = clipByPlane(faces, pl);

  faces = faces.filter((f) => faceArea(f.loop) > 2.6e-4);

  const info = faces.map((f, i) => {
    const loop = f.loop;
    const c = [0, 0, 0];
    for (const p of loop) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
    c[0] /= loop.length; c[1] /= loop.length; c[2] /= loop.length;
    return {
      i, c, n: norm(cross(sub(loop[1], loop[0]), sub(loop[2], loop[0]))),
      chip: f.chip, area: faceArea(loop),
    };
  });

  let topY = -Infinity;
  for (const f of faces) for (const p of f.loop) if (p[1] > topY) topY = p[1];

  const hosts = [];
  if (COVER > 0) {
    const scored = [];
    for (const t of info) {

      if (t.n[1] < 0.60 - 0.16 * COVER || t.chip) continue;
      if (t.n[2] < -0.15 - 0.30 * COVER) continue;
      if (t.c[1] < (0.32 - 0.16 * COVER) * H) continue;

      if (t.c[1] > topY - (0.24 - 0.10 * COVER) * H) continue;

      if (t.c[0] < -0.34) continue;
      const score = 0.45 * t.n[1]
        + 1.45 * Math.max(0, t.n[2])
        + 0.45 * (t.c[1] / H)
        + 0.95 * clamp((t.c[0] + 0.20) / 0.40, 0, 1)

        + 0.30 * clamp(Math.sqrt(t.area) / 0.34, 0, 1);
      scored.push({ t, score });
    }
    scored.sort((a, b) => b.score - a.score);
    const nPatch = clamp(Math.round(1 + 4 * COVER), 1, 5);
    for (const s of scored.slice(0, nPatch)) hosts.push(s.t);

    hosts.sort((a, b) => b.area - a.area);
  }

  let bx0 = Infinity, bx1 = -Infinity, bz0 = Infinity, bz1 = -Infinity;
  for (const f of faces) for (const p of f.loop) {
    if (p[0] < bx0) bx0 = p[0]; if (p[0] > bx1) bx1 = p[0];
    if (p[2] < bz0) bz0 = p[2]; if (p[2] > bz1) bz1 = p[2];
  }
  const FIT = SIZE / (bx1 - bx0);
  const ox = (bx0 + bx1) / 2, oz = (bz0 + bz1) / 2;

  const T = 0.022 * Math.min(1.30, 0.45 + 0.55 * SIZE) / FIT;
  const PATCH_R = (0.13 + 0.15 * COVER) / FIT;

  const pos = [];
  const col = [];
  const tmp = new THREE.Color();
  const push3 = (p) => pos.push((p[0] - ox) * FIT, p[1] * FIT, (p[2] - oz) * FIT);
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b); };

  const tri = (a, b, c, hex) => {
    const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
    const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
    const A = Math.hypot(uy * vz - uz * vy, uz * vx - ux * vz, ux * vy - uy * vx) * 0.5;
    if (A * FIT * FIT < 5e-7) return;
    push3(a); push3(b); push3(c); paint(hex);
  };

  const hostSet = new Set(hosts.map((t) => t.i));
  const fan = (loop, hex) => {
    for (let k = 1; k + 1 < loop.length; k++) tri(loop[0], loop[k], loop[k + 1], hex);
  };

  for (const t of info) {
    if (hostSet.has(t.i)) continue;
    fan(faces[t.i].loop, t.chip ? C.fracture : C.stone);
  }

  for (let h = 0; h < hosts.length; h++) {
    const t = hosts[h];
    const loop = faces[t.i].loop;
    const n = t.n;
    const rand2 = prng(9001 + h * 733);

    let best = loop[0];
    for (const p of loop) if (p[2] > best[2]) best = p;
    let ax = best[0] - t.c[0], ay = best[1] - t.c[1], az2 = best[2] - t.c[2];
    const aL = Math.hypot(ax, ay, az2) || 1;
    const aK = Math.min(aL * 0.34, 0.085 / FIT) / aL;
    const P = [t.c[0] + ax * aK, t.c[1] + ay * aK, t.c[2] + az2 * aK];

    let faceR0 = 0;
    for (const p of loop) faceR0 = Math.max(faceR0, Math.hypot(p[0] - P[0], p[1] - P[1], p[2] - P[2]));
    const wantPts = clamp(Math.round(7 + 6 * Math.min(PATCH_R, faceR0) * FIT / 0.26), 7, 14);
    const L2 = resampleLoop(loop, wantPts);

    let faceR = 0;
    for (const p of L2) faceR = Math.max(faceR, Math.hypot(p[0] - P[0], p[1] - P[1], p[2] - P[2]));

    const base = Math.min(0.34 + 0.30 * COVER, PATCH_R / faceR);

    const rTarget = base * faceR;
    const S1 = L2.map((p) => {
      const dx = p[0] - P[0], dy = p[1] - P[1], dz = p[2] - P[2];
      const len = Math.hypot(dx, dy, dz) || 1;

      const g = clamp((topY - p[1]) / (0.16 * H), 0.45, 1);

      const r = Math.min(rTarget * (0.92 + 0.16 * rand2()) * g, len * 0.88);
      return [P[0] + dx / len * r, P[1] + dy / len * r, P[2] + dz / len * r];
    });
    const A1 = S1.map((p) => [
      P[0] + (p[0] - P[0]) * 0.86 + n[0] * T,
      P[1] + (p[1] - P[1]) * 0.86 + n[1] * T,
      P[2] + (p[2] - P[2]) * 0.86 + n[2] * T,
    ]);
    const hex = h % 2 ? C.mossDeep : C.moss;

    const ring = (lo, hi, col) => {
      for (let i = 0; i < lo.length; i++) {
        const j = (i + 1) % lo.length;
        tri(lo[i], lo[j], hi[j], col); tri(lo[i], hi[j], hi[i], col);
      }
    };
    ring(L2, S1, t.chip ? C.fracture : C.stone);
    ring(S1, A1, hex);
    fan(A1, hex);
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'rock';

  const g = new THREE.Group();
  g.name = 'medium-rock';
  g.add(mesh);
  return g;
}

export default createAsset;
