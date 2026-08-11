/*
 * Large Boulder
 * https://polyfork.dev/asset/large-boulder-a29b99
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './large-boulder-a29b99.mjs';
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
 *   colorway     choice  'granite-grey' 'granite-grey' | 'mossy-shade' | 'sandstone' | 'dark-slate'
 *   stone        color   '#a3a099'      any hex or THREE.Color
 *   lichen       color   '#3d6b34'      any hex or THREE.Color
 *   moss         color   '#5f9a4b'      any hex or THREE.Color
 *   tallness     range   1              0.66 to 1.2
 *   facets       choice  'standard'     'chunky' | 'standard' | 'fine'
 *   buried       range   0.2            0.08 to 0.42
 *   mossPatches  range   5              0 to 7
 *
 * Every option is described in full at https://polyfork.dev/cdn/large-boulder-a29b99-params.json
 *
 * SPECS  295 triangles, 1 material, 2.2 x 1.34 x 1.98 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'granite-grey': { stone: '#a3a099', lichen: '#3d6b34', moss: '#5f9a4b' },
  'mossy-shade':  { stone: '#87847c', lichen: '#2f4f2e', moss: '#4c8140' },
  'sandstone':    { stone: '#c2a479', lichen: '#6f8f3c', moss: '#8fa84a' },
  'dark-slate':   { stone: '#6e6b63', lichen: '#25402c', moss: '#3d6b34' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'granite-grey', label: 'Colorway',
    options: ['granite-grey', 'mossy-shade', 'sandstone', 'dark-slate'],
    describe: 'Curated Nature & Forest stone schemes. granite-grey is pale warm grey rock ' +
      'with bright moss; mossy-shade is a darker damp-forest grey under deep green moss; ' +
      'sandstone is warm tan rock with dry yellow-green lichen; dark-slate is near-charcoal ' +
      'rock with very dark moss for shaded ravines. Sets stone, lichen and moss unless ' +
      'those are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#a3a099', label: 'Stone',
    describe: 'Albedo of the whole rock body — every facet of the boulder, roughly 85% of ' +
      'the visible surface and the dominant colour of the asset. A rock is one material, so ' +
      'this is its single flat tone; all shading on it comes from the facets and the lights.',
  },
  lichen: {
    type: 'color', default: '#3d6b34', label: 'Lichen edge',
    describe: 'Albedo of the darker green crust ring around the edge of every moss patch — ' +
      'the sloped shoulder of the raised moss pad. Keep it clearly DARKER than Moss or the ' +
      'patches lose their edge and read as one flat green blot.',
  },
  moss: {
    type: 'color', default: '#5f9a4b', label: 'Moss',
    describe: 'Albedo of the bright green top face of each moss patch, the highest and ' +
      'flattest part of the crust. This is the colour that has to be visible against the ' +
      'grey from 10 m, so keep a real value step between it and Stone.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.66, max: 1.20, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Height of the rock form before it is cut by the ground plane. The footprint ' +
      'stays 2.2 m wide, so 0.66 is a squat 0.89 m slab that reads as a low sitting rock, ' +
      '1.00 the approved 1.34 m boulder and 1.20 a 1.60 m waist-high crag. NOT a scale: the ' +
      'cutting planes are recomputed ' +
      'against the new form, so the facet layout and the triangle count both change. (A ' +
      'boulder has no repeating structure to multiply, so this dimension rebuilds its ' +
      'cell pattern rather than gaining bays.)',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facet grade',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'How many planes carve the rock. chunky = 20 huge cells, a hand-hewn crystal ' +
      'with long straight silhouette runs (~150 tris); standard = the approved boulder, ~36 ' +
      'cells about 0.55 m across; fine = 48 smaller cells, a more eroded weathered rock ' +
      '(~330 tris). Changes the number of corners in the outline, never the proportions.',
  },
  buried: {
    type: 'range', default: 0.20, min: 0.08, max: 0.42, step: 0.01, label: 'Buried depth',
    affects: 'geometry',
    describe: 'How far up its own form the ground plane cuts the boulder, as a fraction of ' +
      'the full form height. 0.08 leaves a narrow foot about half the rock\'s girth so it ' +
      'perches like a glacial erratic and stands tallest; 0.42 cuts almost at the widest ' +
      'girth so the rock sits half-sunken with near-vertical sides and is much lower. The ' +
      'bottom is always a flat cap at y=0.',
  },
  mossPatches: {
    type: 'range', default: 5, min: 0, max: 7, step: 1, label: 'Moss patches',
    affects: 'geometry',
    describe: 'Number of raised moss crusts on the crown and shoulder facets, spread one per ' +
      'azimuth sector so at least one is visible from any side. 0 is a completely bare, clean ' +
      'grey rock with no green geometry and no green triangles at all; 6 wraps moss most of ' +
      'the way round the top edge. Each patch is real relief cut out of its host facet.',
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
  for (const f of faces) {
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
    if (loop.length >= 3) kept.push(loop);
  }
  if (cut.length >= 3) {
    const cap = capPolygon(cut, pl.n);
    if (cap.length >= 3) kept.push(cap);
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

const centroidOf = (f) => {
  const c = [0, 0, 0];
  for (const p of f) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
  return [c[0] / f.length, c[1] / f.length, c[2] / f.length];
};

const PROFILE = [
  [0.00, 0.18], [0.10, 0.48], [0.24, 0.76], [0.40, 0.94], [0.52, 1.00],
  [0.62, 1.00], [0.74, 0.96], [0.86, 0.86], [1.00, 0.64],
];

const PLAN_SQUASH = 0.885;

function surfacePoints(cfg) {
  const pts = [];
  const RINGS = 24, SEGS = 32;
  for (let i = 0; i <= RINGS; i++) {
    const u = i / RINGS;
    const rf = profAt(PROFILE, u);
    const y = (u - cfg.buried) * cfg.H;
    for (let j = 0; j < SEGS; j++) {
      const a = (j / SEGS) * Math.PI * 2;
      const m = 1 + 0.10 * Math.sin(3 * a + 0.9) + 0.055 * Math.sin(5 * a + 2.6);
      const r = cfg.R * rf * m;
      pts.push([
        Math.cos(a) * r + cfg.shearX * u * u,
        y,
        Math.sin(a) * r * PLAN_SQUASH + cfg.shearZ * u * u,
      ]);
    }
  }
  return pts;
}

function cutDirections(count, phase) {
  const dirs = [];
  const ga = Math.PI * (3 - Math.sqrt(5));
  const N = Math.round(count * 1.42);
  for (let i = 0; i < N; i++) {
    const ny = 1 - (2 * i + 1) / N;
    if (ny < -0.40) continue;
    const rad = Math.sqrt(Math.max(0, 1 - ny * ny));
    const a = i * ga + phase;
    dirs.push([Math.cos(a) * rad, ny, Math.sin(a) * rad]);
  }
  return dirs;
}

function buildRock(cfg) {
  const pts = surfacePoints(cfg);
  const centre = [0, (0.45 - cfg.buried) * cfg.H, 0];
  const rand = prng(cfg.seed);

  let topY = -Infinity;
  for (const p of pts) if (p[1] > topY) topY = p[1];

  const planes = [{ n: [0, -1, 0], d: 0 }];
  const CROWN = [[0.55, 0.100, 0.976], [2.70, 0.130, 0.970], [4.45, 0.085, 0.980]];
  for (const [az, tilt, lift] of CROWN) {
    const n = norm([Math.cos(az) * tilt, 1, Math.sin(az) * tilt]);
    planes.push({ n, d: n[1] * topY * lift });
  }

  const foot = 0.60 + 0.90 * cfg.buried;
  for (let i = 0; i < 7; i++) {
    const a = (i / 7) * Math.PI * 2 + 0.37 + 0.15 * Math.sin(i * 2.1);
    const hx = Math.cos(a), hz = Math.sin(a);
    let rEq = 0;
    for (const p of pts) { const v = p[0] * hx + p[2] * hz; if (v > rEq) rEq = v; }
    const r = rEq * foot * (0.94 + 0.11 * Math.sin(i * 3.3 + 1.2));
    const n = norm([hx * 0.80, -0.60, hz * 0.80]);
    planes.push({ n, d: n[0] * hx * r + n[2] * hz * r });
  }

  for (const n of cutDirections(cfg.planes, cfg.phase)) {
    let s = -Infinity;
    for (const p of pts) { const v = dot(n, p); if (v > s) s = v; }
    const c = dot(n, centre);

    const bite = cfg.bite * rand() * (1 - 0.60 * Math.max(0, n[1]));
    planes.push({ n, d: c + (s - c) * (1 - bite) });
  }

  let faces = [];
  const S = 8;
  const c = [
    [-S, -S, -S], [S, -S, -S], [S, -S, S], [-S, -S, S],
    [-S, S, -S], [S, S, -S], [S, S, S], [-S, S, S],
  ];
  faces.push([c[3], c[2], c[1], c[0]]);
  faces.push([c[4], c[5], c[6], c[7]]);
  faces.push([c[0], c[1], c[5], c[4]]);
  faces.push([c[2], c[3], c[7], c[6]]);
  faces.push([c[1], c[2], c[6], c[5]]);
  faces.push([c[3], c[0], c[4], c[7]]);
  for (const pl of planes) faces = clipByPlane(faces, pl);

  return faces.filter((f) => faceArea(f) > 2e-4);
}

function pickMossFaces(faces, count) {
  if (count <= 0) return [];
  const best = new Array(count).fill(null);
  for (const f of faces) {
    const n = norm(cross(sub(f[1], f[0]), sub(f[2], f[0])));
    if (n[1] < 0.14) continue;
    const c = centroidOf(f);
    const az = Math.atan2(c[2], c[0]);
    const k = Math.floor(((az + Math.PI * 2) % (Math.PI * 2)) / (Math.PI * 2 / count)) % count;

    const t = (n[1] - 0.60) / 0.24;
    const score = faceArea(f) * Math.exp(-t * t);
    if (!best[k] || score > best[k].score) best[k] = { f, n, score };
  }
  return best.filter(Boolean);
}

const PATCH_R = 0.42;

function mossPatch(host, n, seed, hex, out) {
  const { f } = host;
  const rand = prng(seed);
  const c = centroidOf(f);
  const k = Math.floor(rand() * f.length);
  const P = [
    c[0] + (f[k][0] - c[0]) * 0.30,
    c[1] + (f[k][1] - c[1]) * 0.30,
    c[2] + (f[k][2] - c[2]) * 0.30,
  ];
  let faceR = 0;
  for (const p of f) faceR = Math.max(faceR, Math.hypot(p[0] - P[0], p[1] - P[1], p[2] - P[2]));
  const base = Math.min(0.88, PATCH_R / faceR);

  const inset = (loop, lo, hi, lift) => loop.map((p) => {
    const t = lo + (hi - lo) * rand();
    return [
      P[0] + (p[0] - P[0]) * t + n[0] * lift,
      P[1] + (p[1] - P[1]) * t + n[1] * lift,
      P[2] + (p[2] - P[2]) * t + n[2] * lift,
    ];
  });
  const S = inset(f, base * 0.62, base * 1.05, 0);
  const A = inset(S, 0.80, 0.90, 0.022);

  const ring = (lo, hi, col) => {
    for (let i = 0; i < lo.length; i++) {
      const j = (i + 1) % lo.length;
      out.quad(lo[i], lo[j], hi[j], hi[i], col);
    }
  };
  ring(f, S, out.C.stone);
  ring(S, A, hex);
  out.fan(A, hex);
}

const PLANE_COUNTS = { chunky: 18, standard: 30, fine: 44 };

const TARGET_W = 2.20;

const FORM_H = 1.53;

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['granite-grey'];
  const pick = (k) => userParams[k] ?? (userParams.colorway ? way[k] : params[k].default);
  const C = { stone: pick('stone'), lichen: pick('lichen'), moss: pick('moss') };

  const buried = Math.min(0.42, Math.max(0.08, P.buried));
  const faces = buildRock({
    H: FORM_H * P.tallness, R: 1.0, buried,
    shearX: -0.085, shearZ: 0.07,
    planes: PLANE_COUNTS[P.facets] || PLANE_COUNTS.standard,
    phase: 0.44, seed: 20260805, bite: 0.125,
  });

  let mnx = Infinity, mxx = -Infinity, mnz = Infinity, mxz = -Infinity;
  for (const f of faces) for (const p of f) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
  }
  const FIT = TARGET_W / (mxx - mnx);
  const ox = (mnx + mxx) / 2, oz = (mnz + mxz) / 2;
  const fitP = (p) => [(p[0] - ox) * FIT, p[1] * FIT, (p[2] - oz) * FIT];
  const fitted = faces.map((f) => f.map(fitP));

  const pos = [], col = [];
  const tmp = new THREE.Color();
  const paint = (hex) => { tmp.set(hex); for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b); };
  const tri = (a, b, c, hex) => {
    pos.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    paint(hex);
  };
  const out = {
    C,
    quad: (a, b, c, d, hex) => { tri(a, b, c, hex); tri(a, c, d, hex); },
    fan: (loop, hex) => { for (let i = 1; i + 1 < loop.length; i++) tri(loop[0], loop[i], loop[i + 1], hex); },
  };

  const mossed = pickMossFaces(fitted, Math.round(P.mossPatches));
  const mossedSet = new Set(mossed.map((m) => m.f));
  for (let i = 0; i < mossed.length; i++) {
    mossPatch(mossed[i], mossed[i].n, 4001 + i * 977, i % 2 ? C.lichen : C.moss, out);
  }
  for (const f of fitted) if (!mossedSet.has(f)) out.fan(f, C.stone);

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'boulder';

  const g = new THREE.Group();
  g.name = 'large-boulder';
  g.add(mesh);
  return g;
}

export default createAsset;
