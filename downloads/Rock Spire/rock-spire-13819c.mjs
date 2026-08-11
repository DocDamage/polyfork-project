/*
 * Rock Spire
 * https://polyfork.dev/asset/rock-spire-13819c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './rock-spire-13819c.mjs';
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
 *   colorway  choice  'pale-granite' 'pale-granite' | 'dark-slate' | 'blue-slate' | 'dry-sandstone'
 *   stone     color   '#87847c'      any hex or THREE.Color
 *   tallness  range   1              0.62 to 1.35
 *   taper     range   1              0.55 to 1.25
 *   facets    range   9              7 to 11
 *   shards    range   3              2 to 4
 *   lean      range   1              0 to 1.8
 *
 * Every option is described in full at https://polyfork.dev/cdn/rock-spire-13819c-params.json
 *
 * SPECS  378 triangles, 1 material, 1.29 x 3.5 x 1.46 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'pale-granite':  { stone: '#87847c' },
  'dark-slate':    { stone: '#57544e' },
  'blue-slate':    { stone: '#3f4d55' },
  'dry-sandstone': { stone: '#a5855e' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'pale-granite', label: 'Colorway',
    options: ['pale-granite', 'dark-slate', 'blue-slate', 'dry-sandstone'],
    describe: 'Which STONE this outcrop is cut from, straight off the kit menu. The rock ' +
      'is one material and carries one flat albedo, so a colorway here swaps the material ' +
      'rather than a paint scheme, and all four read as the same rock in different ' +
      'country: pale-granite is the light warm grey of the approved spire and sits on ' +
      'open hillside and scree; dark-slate is a much darker grey for shaded forest floor ' +
      'and wet ravines; blue-slate is cold blue-grey for high or alpine ground; ' +
      'dry-sandstone is warm tan for arid and desert edges of the kit. Sets Stone unless ' +
      'that is passed explicitly.',
  },
  stone: {
    type: 'color', default: '#87847c', label: 'Stone',
    describe: 'The single albedo of the entire rock — the chamfered foot, every planar ' +
      'column, the break plane and all the summit shards, 100% of the surface. This is ' +
      'deliberate and it is the whole palette: a rock is ONE material, so it gets ONE ' +
      'flat tone, and every light and dark difference you see on it is the scene lights ' +
      'raking planes that lean at different angles, which flat shading gives for free. ' +
      'Do not expect a second zone to appear at any knob setting; the form carries the ' +
      'asset. Pick any stone hex from the kit menu.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.62, max: 1.35, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Height of the spire, and the widest knob on the asset: 0.62 is a 2.2 m ' +
      'boulder-sized crag you can stand a character beside, 1.00 the approved 3.50 m ' +
      'spire, 1.35 a 4.7 m landmark tower. REBUILT, NOT SCALED: the foot girth and the ' +
      'summit shards are fixed sections that stay the same size at every value while the ' +
      'shaft between them grows, so a short one is a stubby chunk of rock and a tall one ' +
      'is a thin fang, rather than the same object at two zoom levels. The footprint never ' +
      'changes, so every value still drops onto the same terrain blob.',
  },
  taper: {
    type: 'range', default: 1.0, min: 0.55, max: 1.25, step: 0.01, label: 'Taper',
    affects: 'geometry',
    describe: 'How hard the shaft narrows over its height, scaling how far every column ' +
      'travels from its foot girth to its break girth. Girth at the ground never changes, ' +
      'so only the upper silhouette moves: 0.55 is a near parallel-sided basalt pillar ' +
      'with a broad blunt summit, 1.00 the approved spire, 1.25 a slender needle whose ' +
      'shards are almost as wide as the rock below them. Stops short of pinching the ' +
      'summit away entirely, because the cleft top is the identity and has to survive ' +
      'every value.',
  },
  facets: {
    type: 'range', default: 9, min: 7, max: 11, step: 1, label: 'Facets',
    affects: 'geometry',
    describe: 'Number of planar columns running foot to summit. Each count has its own ' +
      'hand-authored set: its own belly plan, its own break plan and its own ladder of ' +
      'kink heights, three of the columns running dead straight the whole way. 7 is a ' +
      'crude hand-hewn crystal with long straight silhouette runs, 9 the approved spire, ' +
      '11 a more eroded rock that reads rounder. Changes the corner count of the outline ' +
      'and the triangle count; the belly girth is solved for at every count, so the ' +
      'footprint and the 3.50 m height hold to within a few percent whatever it is set to.',
  },
  shards: {
    type: 'range', default: 3, min: 2, max: 4, step: 1, label: 'Summit shards',
    affects: 'geometry',
    describe: 'How many broken points the summit splits into, and how broad each one is: ' +
      'the shards divide the whole break plane between them, so 2 is a deeply split tooth ' +
      'of two BROAD wedges, 3 the approved crown with a tall point, a medium and a stub, ' +
      '4 a shattered crown of narrower spikes with a notch on every side. The tallest ' +
      'shard is always present and always sets the total height. A whole facet of the top ' +
      'ring is left bare between neighbours and capped flat, so every notch shows the ' +
      'break plane at its floor — never a spike stood on a plate, never two cones merging ' +
      'at a seam. The notch facets are the narrowest ones available, which keeps the ' +
      'shards themselves chunky.',
  },

  lean: {
    type: 'range', default: 1.0, min: 0, max: 1.8, step: 0.05, label: 'Lean',
    affects: 'geometry',
    describe: 'How far the spire leans off plumb. The bottom third is always dead ' +
      'vertical and the whole angle lives in the terminal run above it, which is what ' +
      'makes a lean read as a lean instead of as a bend. 0 is a plumb pillar, 1.0 the ' +
      'approved 0.30 m of summit offset (about 10 degrees in the top run), 1.8 a strongly ' +
      'canted crag. The lean runs along +X so it reads in the front elevation, and it ' +
      'works with the columns rather than against them: the -X columns carry most of the ' +
      'taper while the +X ones stay near vertical, so the mass reads as a leaning tooth.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

const BELLY_W   = 1.16;

const PLAN_Z    = 1.18;

const SHAFT_H   = 2.999;
const CREST     = 0.465;

const BELLY     = 0.045;
const FOOT      = 0.845;

const COLUMNS = {
  7: [
    { k: [], g: [0.652, 0.484] },
    { k: [0.322, 0.674], g: [0.975, 0.975, 0.777, 0.428] },
    { k: [], g: [0.627, 0.472] },
    { k: [0.54, 0.601], g: [1.000, 1.000, 0.952, 0.273] },
    { k: [], g: [0.602, 0.451] },
    { k: [0.243, 0.828], g: [0.919, 0.919, 0.565, 0.400] },
    { k: [0.279, 0.37, 0.642], g: [0.578, 0.578, 0.546, 0.450, 0.323] },
  ],
  8: [
    { k: [], g: [0.652, 0.426] },
    { k: [0.245, 0.674], g: [0.975, 0.975, 0.750, 0.434] },
    { k: [], g: [0.656, 0.434] },
    { k: [0.506, 0.601], g: [1.000, 1.000, 0.922, 0.276] },
    { k: [0.548, 0.638, 0.715], g: [0.637, 0.637, 0.538, 0.470, 0.248] },
    { k: [], g: [0.919, 0.574] },
    { k: [0.423, 0.461, 0.746], g: [0.619, 0.619, 0.599, 0.453, 0.322] },
    { k: [0.201, 0.782], g: [0.944, 0.944, 0.595, 0.419] },
  ],
  9: [
    { k: [0.115, 0.188, 0.586], g: [0.652, 0.652, 0.612, 0.476, 0.360] },
    { k: [0.278, 0.674], g: [0.975, 0.975, 0.772, 0.460] },
    { k: [], g: [0.711, 0.524] },
    { k: [0.516, 0.627], g: [1.000, 1.000, 0.904, 0.302] },
    { k: [0.548, 0.715, 0.742], g: [0.690, 0.690, 0.521, 0.498, 0.296] },
    { k: [], g: [0.919, 0.645] },
    { k: [0.451, 0.489, 0.772], g: [0.671, 0.671, 0.651, 0.500, 0.379] },
    { k: [0.234, 0.808], g: [0.944, 0.944, 0.599, 0.445] },
    { k: [], g: [0.556, 0.404] },
  ],
  10: [
    { k: [], g: [0.739, 0.480] },
    { k: [0.228, 0.674], g: [0.975, 0.975, 0.751, 0.450] },
    { k: [0.277, 0.185, 0.787], g: [0.751, 0.751, 0.751, 0.496, 0.400] },
    { k: [], g: [1.000, 0.632] },
    { k: [0.491, 0.581, 0.715], g: [0.729, 0.729, 0.628, 0.509, 0.287] },
    { k: [0.517, 0.828], g: [0.919, 0.919, 0.580, 0.269] },
    { k: [], g: [0.709, 0.462] },
    { k: [0.363, 0.756], g: [0.944, 0.944, 0.601, 0.307] },
    { k: [0.409, 0.621, 0.863], g: [0.727, 0.727, 0.554, 0.389, 0.301] },
    { k: [0.324, 0.891], g: [0.969, 0.969, 0.561, 0.445] },
  ],
  11: [
    { k: [0.111, 0.214, 0.612], g: [0.652, 0.652, 0.593, 0.443, 0.322] },
    { k: [0.253, 0.674], g: [0.975, 0.975, 0.745, 0.416] },
    { k: [0.304, 0.186, 0.787], g: [0.781, 0.781, 0.781, 0.502, 0.391] },
    { k: [], g: [1.000, 0.609] },
    { k: [0.496, 0.638, 0.715], g: [0.758, 0.758, 0.607, 0.540, 0.315] },
    { k: [0.543, 0.828], g: [0.919, 0.919, 0.609, 0.296] },
    { k: [], g: [0.737, 0.461] },
    { k: [0.38, 0.756], g: [0.944, 0.944, 0.596, 0.284] },
    { k: [0.41, 0.855, 0.89], g: [0.756, 0.756, 0.389, 0.363, 0.285] },
    { k: [0.349, 0.917], g: [0.969, 0.969, 0.512, 0.414] },
    { k: [], g: [0.633, 0.399] },
  ],
};
const PHASE = { 7: 0.42, 8: 0.19, 9: 0.66, 10: 0.31, 11: 0.52 };

const SNAP = [0.00, -0.055, 0.040, -0.075, 0.015, -0.035, 0.060, -0.020, 0.032, -0.062, 0.022];

const CROWN = [
  { rise: CREST, splay: 0.16 },
  { rise: 0.21,  splay: 0.30 },
  { rise: 0.35,  splay: 0.22 },
  { rise: 0.16,  splay: 0.26 },
];
const CROWN_F = [0, 0.52, 1];
const TIP_SH  = 0.46;

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);

  const way = COLORWAYS[P.colorway] || COLORWAYS['pale-granite'];

  const STONE = userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default);

  const TALL  = Math.max(0.62, Math.min(1.35, P.tallness));
  const TAPER = Math.max(0.55, Math.min(1.25, P.taper));
  const N     = Math.max(7, Math.min(11, Math.round(P.facets)));
  const LEAN  = Math.max(0, Math.min(1.8, P.lean));

  const NSH   = Math.max(2, Math.min(4, Math.min(Math.floor(N / 2), Math.round(P.shards))));

  const cols = COLUMNS[N];
  const phase = PHASE[N];
  const shaftH = SHAFT_H * TALL;

  let px0 = Infinity, px1 = -Infinity;
  for (let i = 0; i < N; i++) {
    const v = Math.cos(phase + (i / N) * Math.PI * 2) * cols[i].g[0];
    if (v < px0) px0 = v;
    if (v > px1) px1 = v;
  }
  const R0 = BELLY_W / (px1 - px0);

  const XS = cols.map((c) => [BELLY, ...c.k, 1]);
  const rad = (i, t) => {
    const xs = XS[i], ys = cols[i].g;
    let r = ys[ys.length - 1];
    if (t <= xs[0]) {
      return ys[0] * (FOOT + (1 - FOOT) * (t / BELLY));
    }
    for (let j = 1; j < xs.length; j++) {
      if (t <= xs[j]) { r = ys[j - 1] + (ys[j] - ys[j - 1]) * ((t - xs[j - 1]) / (xs[j] - xs[j - 1])); break; }
    }
    return ys[0] - (ys[0] - r) * TAPER;
  };

  const ts = [...new Set([0, BELLY, 1, ...cols.flatMap((c) => c.k)])].sort((a, b) => a - b);

  const leanAt = (t) => Math.pow(Math.max(0, (t - 0.28) / 0.72), 1.25) * LEAN * 0.30;

  const ring = (t, snap) => {
    const cx = leanAt(t), cz = cx * 0.46;
    const y = t * shaftH;
    const out = [];
    for (let i = 0; i < N; i++) {
      const a = phase + (i / N) * Math.PI * 2;
      const r = R0 * rad(i, t);
      out.push([
        cx + Math.cos(a) * r,
        snap ? y + SNAP[i % SNAP.length] : y,
        cz + Math.sin(a) * r,
      ]);
    }
    return out;
  };

  const rings = ts.map((t, k) => ring(t, k === ts.length - 1));

  const POS = [], COL = [];
  const tmp = new THREE.Color();
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) COL.push(tmp.r, tmp.g, tmp.b); };
  const tri = (a, b, c, hex) => {
    POS.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    paint(hex);
  };
  const d2 = (a, b) => (a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2;

  const quad = (a, b, c, d, hex) => {
    if (d2(a, c) <= d2(b, d)) { tri(a, b, c, hex); tri(a, c, d, hex); }
    else { tri(a, b, d, hex); tri(b, c, d, hex); }
  };
  const centroid = (loop) => {
    const c = [0, 0, 0];
    for (const p of loop) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
    return [c[0] / loop.length, c[1] / loop.length, c[2] / loop.length];
  };
  const capUp = (loop, lift, hex) => {
    const c = centroid(loop);
    c[1] = Math.max(...loop.map((p) => p[1])) + lift;
    for (let i = 0; i < loop.length; i++) tri(c, loop[(i + 1) % loop.length], loop[i], hex);
  };
  const capDown = (loop, hex) => {
    const c = centroid(loop);
    for (let i = 0; i < loop.length; i++) tri(c, loop[i], loop[(i + 1) % loop.length], hex);
  };
  const fanUp = (c, arc, hex) => {
    for (let i = 0; i + 1 < arc.length; i++) tri(c, arc[i + 1], arc[i], hex);
  };

  for (let k = 0; k + 1 < rings.length; k++) {
    const A = rings[k], B = rings[k + 1];
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;
      quad(A[i], B[i], B[j], A[j], STONE);
    }
  }
  capDown(rings[0], STONE);

  const top = rings[rings.length - 1];
  const Cs = [leanAt(1), shaftH, leanAt(1) * 0.46];

  const chord = (f) => Math.hypot(top[(f + 1) % N][0] - top[f][0], top[(f + 1) % N][2] - top[f][2]);
  const sep = (a, b) => Math.min(((a - b) % N + N) % N, ((b - a) % N + N) % N);
  let zF = 0, zD = 9;
  for (let f = 0; f < N; f++) {
    const a = phase + ((f + 0.5) / N) * Math.PI * 2;
    const d = Math.abs(Math.atan2(Math.sin(a - Math.PI / 2), Math.cos(a - Math.PI / 2)));
    if (d < zD) { zD = d; zF = f; }
  }
  const notch = [zF];
  while (notch.length < NSH) {
    let best = -1, bestScore = Infinity;
    for (let f = 0; f < N; f++) {
      if (notch.some((c) => sep(f, c) < 2)) continue;
      const score = chord(f) - 0.02 * Math.min(...notch.map((c) => sep(f, c)));
      if (score < bestScore) { bestScore = score; best = f; }
    }
    if (best < 0) break;
    notch.push(best);
  }
  notch.sort((a, b) => a - b);
  const zAt = notch.indexOf(zF);

  for (let g = 0; g < notch.length; g++) {

    const n0 = notch[(zAt + g) % notch.length];
    const n1 = notch[(zAt + g + 1) % notch.length];
    const s = (n0 + 1) % N;
    const cnt = (((n1 - n0 - 1) % N) + N) % N;

    const base = [Cs];
    for (let k = 0; k <= cnt; k++) base.push(top[(s + k) % N]);

    let mx = 0, mz = 0, rr = 0;
    for (let k = 1; k < base.length; k++) {
      mx += base[k][0] - Cs[0]; mz += base[k][2] - Cs[2];
      rr += Math.hypot(base[k][0] - Cs[0], base[k][2] - Cs[2]);
    }
    const ml = Math.hypot(mx, mz) || 1;
    rr /= base.length - 1;
    const D = CROWN[g % CROWN.length];
    const off = [
      (mx / ml) * D.splay * rr + 0.05 * LEAN,
      D.rise,
      (mz / ml) * D.splay * rr + 0.023 * LEAN,
    ];

    const Ct = centroid(base);
    const loops = CROWN_F.map((f) => {
      const sh = 1 - (1 - TIP_SH) * f;
      const d = Math.pow(f, 1.1);
      return base.map((p) => [
        Ct[0] + off[0] * d + (p[0] - Ct[0]) * sh,
        Cs[1] + off[1] * f + (p[1] - Cs[1]) * sh,
        Ct[2] + off[2] * d + (p[2] - Ct[2]) * sh,
      ]);
    });
    for (let k = 0; k + 1 < loops.length; k++) {
      const A = loops[k], B = loops[k + 1];
      for (let i = 0; i < A.length; i++) {
        const j = (i + 1) % A.length;
        quad(A[i], B[i], B[j], A[j], STONE);
      }
    }
    capUp(loops[loops.length - 1], 0.018, STONE);

    fanUp(Cs, [top[n0], top[(n0 + 1) % N]], STONE);
  }

  for (let i = 0; i < POS.length; i += 3) POS[i + 2] *= PLAN_Z;

  let bx0 = Infinity, bx1 = -Infinity, bz0 = Infinity, bz1 = -Infinity, by0 = Infinity;
  for (let i = 0; i < POS.length; i += 3) {
    if (POS[i] < bx0) bx0 = POS[i];
    if (POS[i] > bx1) bx1 = POS[i];
    if (POS[i + 1] < by0) by0 = POS[i + 1];
    if (POS[i + 2] < bz0) bz0 = POS[i + 2];
    if (POS[i + 2] > bz1) bz1 = POS[i + 2];
  }
  const ox = (bx0 + bx1) / 2, oz = (bz0 + bz1) / 2;
  for (let i = 0; i < POS.length; i += 3) {
    POS[i] -= ox; POS[i + 1] -= by0; POS[i + 2] -= oz;
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(POS, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(COL, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'spire';

  const g = new THREE.Group();
  g.name = 'rock-spire';
  g.add(mesh);

  return g;
}

export default createAsset;
