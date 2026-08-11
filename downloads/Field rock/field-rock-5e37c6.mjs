/*
 * Field rock
 * https://polyfork.dev/asset/field-rock-5e37c6
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './field-rock-5e37c6.mjs';
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
 *   colorway  choice  'field-granite' 'field-granite' | 'sun-bleached' | 'dark-basalt' | 'pale-flint'
 *   stone     color   '#8A9498'      any hex or THREE.Color
 *   bedding   color   '#D9C9A3'      any hex or THREE.Color
 *   moss      color   '#5EA83A'      any hex or THREE.Color
 *   mossDeep  color   '#3B7A2E'      any hex or THREE.Color
 *   size      range   1.05           0.35 to 2
 *   flatness  range   1              0.65 to 1.35
 *   chips     range   3              0 to 5
 *   wear      choice  'weathered'    'kept' | 'weathered' | 'derelict'
 *
 * Every option is described in full at https://polyfork.dev/cdn/field-rock-5e37c6-params.json
 *
 * SPECS  144 triangles, 1 material, 1.05 x 0.77 x 1.03 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'field-granite': { stone: '#8A9498', bedding: '#D9C9A3', moss: '#5EA83A', mossDeep: '#3B7A2E' },
  'sun-bleached':  { stone: '#B08A55', bedding: '#F2E6C8', moss: '#8FCB4A', mossDeep: '#5EA83A' },
  'dark-basalt':   { stone: '#5A6468', bedding: '#8A9498', moss: '#3B7A2E', mossDeep: '#24552A' },
  'pale-flint':    { stone: '#B6BFC2', bedding: '#B08A55', moss: '#5EA83A', mossDeep: '#24552A' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'field-granite', label: 'Colorway',
    options: ['field-granite', 'sun-bleached', 'dark-basalt', 'pale-flint'],
    describe: 'Curated Salvage Commons stone schemes. field-granite is the shipped ' +
      'galvanised grey rock with warm tan fracture faces and bright moss; sun-bleached ' +
      'is a dry sandstone-brown stone with cream breaks and fresh spring moss; ' +
      'dark-basalt is a cold near-charcoal stone with pale grey breaks and deep shade ' +
      'moss; pale-flint is a bleached light grey stone with dark tan breaks. Sets ' +
      'stone, bedding, moss and mossDeep unless those are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#8A9498', label: 'Stone',
    describe: 'Albedo of the rock itself — every un-chipped facet, about 70% of the ' +
      'visible surface and the dominant colour of the asset. Keep it a committed ' +
      'mid-value: too light and the tan fracture faces stop reading as breaks.',
  },
  bedding: {
    type: 'color', default: '#D9C9A3', label: 'Bedding / fracture',
    describe: 'Albedo of the deep chip scars only — the flat break faces where a flake ' +
      'has spalled off, exposing paler interior stone. Should stay clearly BRIGHTER ' +
      'and warmer than Stone; matched to Stone the chips vanish and the boulder reads ' +
      'as one flat grey lump.',
  },
  moss: {
    type: 'color', default: '#5EA83A', label: 'Moss',
    describe: 'Albedo of the main body of the moss cap on the crown. The brighter of ' +
      'the two greens; it is the one colour block that reads at the kit\'s high ' +
      'strategy camera, so keep it saturated.',
  },
  mossDeep: {
    type: 'color', default: '#3B7A2E', label: 'Moss shadow patches',
    describe: 'Albedo of the darker irregular patches inside the moss cap, roughly a ' +
      'third of it. Sits one clear value step below Moss; matched to Moss the cap ' +
      'flattens into a single green sticker.',
  },
  size: {
    type: 'range', default: 1.05, min: 0.35, max: 2.0, step: 0.05, label: 'Size',
    affects: 'geometry',
    describe: 'Width of the boulder across X in METRES, and a genuine rebuild rather ' +
      'than a scale: the cutting-plane count grows with it (20 planes at 0.35 m, 26 at ' +
      'the 1.05 m default, 35 at 2.0 m) so each facet stays a readable hand-sized ' +
      'plane instead of the whole rock getting coarser or finer, and the moss pad ' +
      'keeps its real 0.03 m thickness at every size. 0.35 m is a two-handed field ' +
      'stone a villager could lift; 2.0 m is a waist-high glacial block you walk ' +
      'around. Triangle count moves with it.',
  },
  flatness: {
    type: 'range', default: 1.0, min: 0.65, max: 1.35, step: 0.01, label: 'Chunkiness',
    affects: 'geometry',
    describe: 'Height of the boulder as a proportion of its width, and a rebuild: the ' +
      'tangent planes are re-solved against the new profile so the facet layout, the ' +
      'corner count and the triangle count all change. 0.65 is a flat 0.49 m slab that ' +
      'reads as an outcrop breaking the turf; 1.0 is the shipped squat field stone at ' +
      '0.76 m; 1.35 is a chunky 1.02 m near-cubic block. Footprint is unchanged, so ' +
      'the change is entirely in the elevation silhouette.',
  },
  chips: {
    type: 'range', default: 3, min: 0, max: 5, step: 1, label: 'Chip scars',
    affects: 'geometry',
    describe: 'How many deep fracture faces are struck off the boulder, each a whole ' +
      'flat cell stepped in about 18% toward the centre and painted the Bedding tan. ' +
      '0 is an unbroken weather-rounded stone in one colour; 3 is the shipped stone ' +
      'with a break on the front, the +X flank and the upper -X shoulder; 5 adds a ' +
      'break on the back and a big spall off the crown. Each one visibly flattens a ' +
      'facet of the silhouette.',
  },
  wear: {
    type: 'choice', default: 'weathered', affects: 'geometry',
    options: ['kept', 'weathered', 'derelict'],
    label: 'Wear',
    describe: 'How long the stone has sat undisturbed. kept is a stone recently turned ' +
      'out of a worked field: cells crisp and tightly cut, and only a small patch of ' +
      'moss left in the lee of the crown. weathered is the shipped default: the moss ' +
      'caps the crown and spills down the front shoulder with a ragged overhanging ' +
      'lip. derelict is a stone the meadow has taken back: deeper eroded cells, a ' +
      'thicker moss pad over most of the upper half and a spall broken off the top. ' +
      'Geometry, not paint — the moss shell and facet count differ at all three. ' +
      'The footprint is identical at every value.',
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

function surfacePoints(cfg) {
  const pts = [];
  const RINGS = 20, SEGS = 28;
  for (let i = 0; i <= RINGS; i++) {
    const t = i / RINGS;
    const rf = profAt(cfg.prof, t);
    const y = t * cfg.H;
    for (let j = 0; j < SEGS; j++) {
      const a = (j / SEGS) * Math.PI * 2;
      const m = 1
        + cfg.m3 * Math.sin(3 * a + cfg.p3)
        + cfg.m5 * Math.sin(5 * a + cfg.p5);
      const r = cfg.R * rf * m;
      pts.push([
        Math.cos(a) * r + cfg.shearX * t * t,
        y,
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
  [0.30, 0.16, 0.94],
  [0.92, 0.22, -0.32],
  [-0.58, 0.26, -0.74],
  [-0.70, 0.42, 0.52],
  [0.10, 0.86, 0.50],
];
const CHIP_BITE = [0.112, 0.102, 0.096, 0.090, 0.140];

const WEARS = {

  kept:      { bite: 0.72, mossThr: 2.14, mossT: 0.030, spall: false, dPlanes: 5 },
  weathered: { bite: 1.00, mossThr: 1.90, mossT: 0.042, spall: false, dPlanes: 0 },
  derelict:  { bite: 1.24, mossThr: 1.44, mossT: 0.052, spall: true,  dPlanes: -7 },
};

const R0 = 0.50;

const PROFILE = [
  [0.00, 0.82], [0.12, 0.95], [0.30, 1.00], [0.60, 0.98],
  [0.80, 0.90], [0.92, 0.76], [1.00, 0.52],
];

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);

  const way = COLORWAYS[P.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['stone', 'bedding', 'moss', 'mossDeep']) {
    C[k] = userParams[k] ?? way[k] ?? params[k].default;
  }

  const SIZE = clamp(Number(P.size) || params.size.default, 0.35, 2.0);
  const FLAT = clamp(Number(P.flatness) || params.flatness.default, 0.65, 1.35);
  const W = WEARS[P.wear] || WEARS.weathered;
  const nChips = clamp(Math.round(Number(P.chips)), 0, 5);

  const H = 0.645 * FLAT;

  const nPlanes = Math.round((24 + 20 * (SIZE - 0.35) / 1.65) * (0.72 + 0.28 * FLAT))
    + W.dPlanes;

  const pts = surfacePoints({
    H, R: R0, prof: PROFILE,
    m3: 0.09, p3: 0.9, m5: 0.05, p5: 2.7,
    shearX: -0.055, shearZ: 0.045,
    zSquash: 0.90,
  });
  const centre = [0, H * 0.40, 0];
  const rand = prng(50372641);

  const planes = [{ n: [0, -1, 0], d: 0, chip: false }];
  const tangent = (n, bite) => {
    let s = -Infinity;
    for (const p of pts) { const v = dot(n, p); if (v > s) s = v; }
    const c = dot(n, centre);
    return c + (s - c) * (1 - bite);
  };

  for (const n of cutDirections(nPlanes, 0.37)) {

    const bite = 0.115 * W.bite * rand() * (1 - 0.35 * Math.max(0, n[1]));
    planes.push({ n, d: tangent(n, bite), chip: false });
  }

  const chipList = W.spall && nChips < 5 ? [...CHIP_DIRS.slice(0, nChips), CHIP_DIRS[4]]
                                         : CHIP_DIRS.slice(0, nChips);
  for (let i = 0; i < chipList.length; i++) {
    const n = norm(chipList[i]);
    const b = CHIP_BITE[CHIP_DIRS.indexOf(chipList[i])] * (1 - 0.42 * Math.max(0, n[1]));
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
  faces = faces.filter((f) => faceArea(f.loop) > 2e-5);

  const wl = welder();
  const idx = faces.map((f) => f.loop.map(wl.find));
  const V = wl.pts;

  const info = faces.map((f, i) => {
    const loop = f.loop;
    const c = [0, 0, 0];
    for (const p of loop) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
    c[0] /= loop.length; c[1] /= loop.length; c[2] /= loop.length;
    return { i, c, n: norm(cross(sub(loop[1], loop[0]), sub(loop[2], loop[0]))), chip: f.chip };
  });

  const AZ0 = 2.05;
  const mossy = new Array(faces.length).fill(false);
  for (const t of info) {
    if (t.c[1] < 0.40 * H) continue;
    const az = Math.atan2(t.c[2], t.c[0]);

    const score = 0.62 * Math.max(0, t.n[1])
      + 0.95 * (t.c[1] / H)
      + 0.80 * Math.cos(az - AZ0)
      + 0.18 * Math.sin(2.6 * az + 1.7)
      + 0.12 * Math.sin(4.1 * az + 0.4);
    mossy[t.i] = score > W.mossThr;
  }

  let mnx = Infinity, mxx = -Infinity, mnz = Infinity, mxz = -Infinity;
  for (const p of V) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
  }
  const FIT0 = SIZE / (mxx - mnx);

  const T = W.mossT * Math.min(1.30, 0.35 + 0.65 * SIZE / 1.05) / FIT0;

  const dirEdge = new Set();
  for (const t of info) {
    if (!mossy[t.i]) continue;
    const L = idx[t.i];
    for (let k = 0; k < L.length; k++) dirEdge.add(`${L[k]},${L[(k + 1) % L.length]}`);
  }
  const rim = new Set();
  for (const e of dirEdge) {
    const [a, b] = e.split(',');
    if (!dirEdge.has(`${b},${a}`)) { rim.add(+a); rim.add(+b); }
  }

  const vn = V.map(() => [0, 0, 0]);
  for (const t of info) {
    if (!mossy[t.i]) continue;
    for (const vi of idx[t.i]) { vn[vi][0] += t.n[0]; vn[vi][1] += t.n[1]; vn[vi][2] += t.n[2]; }
  }
  const off = V.map((p, i) => {
    const n = norm(vn[i]);

    const k = T * (rim.has(i) ? 0.32 : 1.30);
    return [p[0] + n[0] * k, p[1] + n[1] * k, p[2] + n[2] * k];
  });

  let bx0 = Infinity, bx1 = -Infinity, bz0 = Infinity, bz1 = -Infinity;
  const acc = (p) => {
    if (p[0] < bx0) bx0 = p[0]; if (p[0] > bx1) bx1 = p[0];
    if (p[2] < bz0) bz0 = p[2]; if (p[2] > bz1) bz1 = p[2];
  };
  for (const p of V) acc(p);
  for (const t of info) if (mossy[t.i]) for (const vi of idx[t.i]) acc(off[vi]);

  const FIT = SIZE / (bx1 - bx0);
  const ox = (bx0 + bx1) / 2, oz = (bz0 + bz1) / 2;

  const pos = [];
  const col = [];
  const tmp = new THREE.Color();
  const push3 = (p) => pos.push((p[0] - ox) * FIT, p[1] * FIT, (p[2] - oz) * FIT);
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b); };
  const tri = (a, b, c, hex) => { push3(a); push3(b); push3(c); paint(hex); };

  for (const t of info) {
    if (mossy[t.i]) continue;
    const loop = faces[t.i].loop;
    const hex = t.chip ? C.bedding : C.stone;
    for (let k = 1; k + 1 < loop.length; k++) tri(loop[0], loop[k], loop[k + 1], hex);
  }

  for (const t of info) {
    if (!mossy[t.i]) continue;

    const nz = Math.sin(5.3 * t.c[0] / H + 1.1) + Math.sin(4.7 * t.c[2] / H + 2.3)
             + 0.6 * Math.sin(9.1 * t.c[0] / H - 0.7);
    const hex = nz < -0.45 ? C.mossDeep : C.moss;
    const L = idx[t.i];
    for (let k = 1; k + 1 < L.length; k++) tri(off[L[0]], off[L[k]], off[L[k + 1]], hex);
    for (let k = 0; k < L.length; k++) {
      const a = L[k], b = L[(k + 1) % L.length];
      if (dirEdge.has(`${b},${a}`)) continue;
      tri(V[a], V[b], off[b], hex);
      tri(V[a], off[b], off[a], hex);
    }
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'boulder';

  const g = new THREE.Group();
  g.name = 'field-rock';
  g.add(mesh);
  return g;
}

export default createAsset;
