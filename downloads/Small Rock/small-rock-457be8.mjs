/*
 * Small Rock
 * https://polyfork.dev/asset/small-rock-457be8
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './small-rock-457be8.mjs';
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
 *   colorway  choice  'shore-grey'   'shore-grey' | 'sun-bleached' | 'wet-basalt' | 'tide-dark'
 *   stone     color   '#9AA3A0'      any hex or THREE.Color
 *   tallness  range   1              0.62 to 1.55
 *   spurSize  range   1              0.35 to 1.35
 *   facets    choice  'standard'     'chunky' | 'standard' | 'fine'
 *   craggy    range   1              0.25 to 1.75
 *
 * Every option is described in full at https://polyfork.dev/cdn/small-rock-457be8-params.json
 *
 * SPECS  188 triangles, 1 material, 0.69 x 0.48 x 0.69 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'shore-grey':   { stone: '#9AA3A0' },
  'sun-bleached': { stone: '#A79680' },
  'wet-basalt':   { stone: '#6E757A' },
  'tide-dark':    { stone: '#5A6462' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'shore-grey', label: 'Colorway',
    options: ['shore-grey', 'sun-bleached', 'wet-basalt', 'tide-dark'],
    describe: 'Curated Pirate Cove stone schemes, all from the kit menu. shore-grey is ' +
      'the weathered grey-green beach rock that matches the kit concept\'s other stones; ' +
      'sun-bleached is warm dry sandstone above the tide line; wet-basalt is cold grey ' +
      'volcanic rock; tide-dark is a near-black wet tide rock. The asset has a single ' +
      'colour zone, so a colorway sets Stone unless Stone is passed explicitly.',
  },
  stone: {
    type: 'color', default: '#9AA3A0', label: 'Stone',
    describe: 'Albedo of the whole rock — every facet, 100% of the visible surface. ' +
      'This asset is one material and therefore one colour; there is no second zone to ' +
      'set. Keep it a desaturated mineral grey, brown-grey or slate, never a saturated hue.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.62, max: 1.55, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Height of the rock, rebuilt (not scaled) about the ground plane: the ' +
      'profile is re-sampled and the cutting planes land on new cells, so the facet ' +
      'layout and the triangle count both change. 0.62 is a 0.30 m flat tide slab that ' +
      'reads as a stepping stone; 1.00 is the approved 0.485 m shore rock; 1.55 is a ' +
      '0.75 m steep-shouldered boulder about knee-and-a-half high. Footprint stays 0.70 m ' +
      'across, so the silhouette runs from a wide flat wedge to a chunky pyramid.',
  },
  spurSize: {
    type: 'range', default: 1.0, min: 0.35, max: 1.35, step: 0.01, label: 'Spur',
    affects: 'geometry',
    describe: 'Size and stand-off of the small fused knuckle low on the +X flank — the ' +
      'ref\'s proud wedge. At 0.35 it is absorbed into the main mass and the rock reads ' +
      'as one clean convex dome with no bump at all; at 1.00 it is the approved knuckle, ' +
      'about a fifth of the width and 40% of the height; at 1.35 it is a broad ledge ' +
      'roughly 45% of the height with a deep notch above it, so the rock reads as a ' +
      'two-step stone. It is always FUSED into the main mass and never detaches.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facet grade',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'How many cutting planes carve the stone, i.e. how many flat cells the ' +
      'silhouette has. chunky = 30 huge planes, a hand-hewn crystal (112 tris); ' +
      'standard = the approved rock, 52 planes and ~12 outline corners (188 tris); ' +
      'fine = 73 planes, a more eroded weathered stone (251 tris). Going ' +
      'finer than this walks a faceted rock toward a smooth blob, which is why the ' +
      'default is nowhere near the triangle ceiling. Changes cell size, not proportions.',
  },
  craggy: {
    type: 'range', default: 1.0, min: 0.25, max: 1.75, step: 0.01, label: 'Cragginess',
    affects: 'geometry',
    describe: 'How irregular the plan outline and how deep the plane bites are. 0.25 is ' +
      'a smooth water-tumbled cobble — near-circular in plan, gentle shallow facets; ' +
      '1.75 is a freshly split angular chunk with deep bites, pinched flanks and a ' +
      'jagged outline. Does not change the overall 0.70 x 0.485 m envelope, only how ' +
      'much the outline wanders inside it.',
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
        cfg.cx + Math.cos(a) * r + cfg.shearX * t * t,
        y,
        cfg.cz + Math.sin(a) * r * (cfg.sz || 1) + cfg.shearZ * t * t,
      ]);
    }
  }
  return pts;
}

function cutDirections(count, phase) {
  const dirs = [];
  const ga = Math.PI * (3 - Math.sqrt(5));
  const N = Math.round(count * 1.45);
  for (let i = 0; i < N; i++) {
    const ny = 1 - (2 * i + 1) / N;
    if (ny < -0.42) continue;
    const rad = Math.sqrt(Math.max(0, 1 - ny * ny));
    const a = i * ga + phase;
    dirs.push([Math.cos(a) * rad, ny, Math.sin(a) * rad]);
  }
  return dirs;
}

function buildLump(cfg) {
  const pts = surfacePoints(cfg);
  const centre = [cfg.cx, cfg.H * 0.40, cfg.cz];
  const rand = prng(cfg.seed);

  const planes = [{ n: [0, -1, 0], d: 0 }];
  for (const n of cutDirections(cfg.planes, cfg.phase)) {
    let s = -Infinity;
    for (const p of pts) { const v = dot(n, p); if (v > s) s = v; }
    const c = dot(n, centre);

    const bite = cfg.bite * rand() * (1 - 0.55 * Math.max(0, n[1]));
    planes.push({ n, d: c + (s - c) * (1 - bite) });
  }

  let faces = [];
  const S = 4;
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

  return { faces: faces.filter((f) => faceArea(f) > 1e-5), planes };
}

const insideOf = (p, planes, slack) => planes.every((pl) => dot(pl.n, p) - pl.d < -slack);

const PLANE_COUNTS = {
  chunky:   { main: 22, spur: 8 },
  standard: { main: 38, spur: 14 },
  fine:     { main: 54, spur: 19 },
};

const MAIN_W = 0.6078;

const SPUR_AZ = 20 * Math.PI / 180;

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['shore-grey'];
  const C = {
    stone: userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default),
  };

  const tall = P.tallness;
  const sp = P.spurSize;
  const cg = P.craggy;
  const pc = PLANE_COUNTS[P.facets] || PLANE_COUNTS.standard;

  const main = buildLump({

    H: 0.541 * tall, R: 0.345, sz: 1.136, cx: 0, cz: 0,
    prof: [[0, 0.80], [0.12, 0.97], [0.25, 1.00], [0.40, 0.96], [0.55, 0.90],
           [0.70, 0.78], [0.82, 0.58], [0.92, 0.38], [1.00, 0.12]],
    m3: 0.115 * cg, p3: 0.9, m5: 0.065 * cg, p5: 2.2,

    shearX: -0.055, shearZ: -0.045,
    planes: pc.main, phase: 0.41, seed: 20260731, bite: 0.075 + 0.055 * cg,
  });

  const spurD = 0.245 * (0.80 + 0.20 * sp);
  const spur = buildLump({
    H: 0.215 * tall * (0.72 + 0.28 * sp), R: 0.180 * sp, sz: 1.08,
    cx: Math.cos(SPUR_AZ) * spurD, cz: Math.sin(SPUR_AZ) * spurD,
    prof: [[0, 0.90], [0.22, 1.00], [0.45, 0.96], [0.68, 0.82], [0.85, 0.58], [1.00, 0.18]],
    m3: 0.10 * cg, p3: 2.4, m5: 0.06 * cg, p5: 0.6,
    shearX: 0.035, shearZ: 0.02,
    planes: pc.spur, phase: 2.13, seed: 4471, bite: 0.09 + 0.06 * cg,
  });

  const lumps = [
    { faces: main.faces.filter((f) => !f.every((p) => insideOf(p, spur.planes, 0.002))) },
    { faces: spur.faces.filter((f) => !f.every((p) => insideOf(p, main.planes, 0.002))) },
  ];

  let mnx = Infinity, mxx = -Infinity, mnz = Infinity, mxz = -Infinity;
  for (const f of main.faces) for (const p of f) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
  }
  const FIT = MAIN_W / (mxx - mnx);
  for (const l of lumps) for (const f of l.faces) for (const p of f) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
  }
  const ox = (mnx + mxx) / 2, oz = (mnz + mxz) / 2;

  const pos = [];
  const col = [];
  const tmp = new THREE.Color(C.stone);
  const push3 = (p) => pos.push((p[0] - ox) * FIT, p[1] * FIT, (p[2] - oz) * FIT);

  for (const l of lumps) for (const f of l.faces) {
    for (let i = 1; i + 1 < f.length; i++) {
      push3(f[0]); push3(f[i]); push3(f[i + 1]);
      for (let k = 0; k < 3; k++) col.push(tmp.r, tmp.g, tmp.b);
    }
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
  g.name = 'small-shore-rock';
  g.add(mesh);
  return g;
}

export default createAsset;
