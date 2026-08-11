/*
 * Large Coastal Boulder
 * https://polyfork.dev/asset/large-coastal-boulder-a2cab1
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './large-coastal-boulder-a2cab1.mjs';
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
 *   colorway  choice  'coastal-grey' 'coastal-grey' | 'sun-bleached' | 'wet-basalt' | 'kelp-green'
 *   stone     color   '#9AA3A0'      any hex or THREE.Color
 *   damp      color   '#5A6462'      any hex or THREE.Color
 *   tallness  range   1              0.72 to 1.34
 *   lobeSize  range   1              0.5 to 1.25
 *   facets    choice  'standard'     'chunky' | 'standard' | 'fine'
 *   dampLine  range   0.26           0.12 to 0.5
 *
 * Every option is described in full at https://polyfork.dev/cdn/large-coastal-boulder-a2cab1-params.json
 *
 * SPECS  190 triangles, 1 material, 2.4 x 1.54 x 1.73 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'coastal-grey': { stone: '#9AA3A0', damp: '#5A6462' },
  'sun-bleached': { stone: '#A79680', damp: '#8A8071' },
  'wet-basalt':   { stone: '#6E757A', damp: '#3E4348' },
  'kelp-green':   { stone: '#7C8683', damp: '#3B6B2C' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'coastal-grey', label: 'Colorway',
    options: ['coastal-grey', 'sun-bleached', 'wet-basalt', 'kelp-green'],
    describe: 'Curated Pirate Cove stone schemes. coastal-grey is weathered grey-green ' +
      'rock over a dark damp skirt; sun-bleached is warm dry sandstone above the tide ' +
      'line; wet-basalt is cold near-black volcanic rock; kelp-green keeps the stone ' +
      'grey and turns the wet base kelp-dark-green. Sets stone and damp unless those ' +
      'are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#9AA3A0', label: 'Stone',
    describe: 'Albedo of the dry weathered rock — every facet above the damp line, ' +
      'about two thirds of the visible surface. The dominant colour of the asset.',
  },
  damp: {
    type: 'color', default: '#5A6462', label: 'Damp base',
    describe: 'Albedo of the sea-damp skirt around the bottom of both lumps. Should ' +
      'stay clearly DARKER than Stone; if it matches Stone the two-tone tide line ' +
      'disappears and the boulder reads as one flat mass.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.72, max: 1.34, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Height of both lumps. 0.72 is a squat 1.13 m tide-flat slab that reads ' +
      'as a low sea rock; 1.34 is a 2.05 m upright crag taller than a person. The ' +
      '2.40 m footprint is unchanged, so the silhouette goes from wide-and-flat to ' +
      'steep-and-pointed. This REBUILDS, it does not stretch: the facet cell is this ' +
      'rock\'s repeating unit and holds a constant size, so a taller crag is carved ' +
      'by MORE cutting planes rather than by taller cells (145 tris at 0.72, 224 at ' +
      '1.34). Nothing about a cell\'s size or the Facet grade changes with it.',
  },
  lobeSize: {
    type: 'range', default: 1.0, min: 0.5, max: 1.25, step: 0.01, label: 'Shoulder lobe',
    affects: 'geometry',
    describe: 'Size of the smaller fused lump on the -X flank, and how far out it sits. ' +
      'At 0.5 it is a knuckle barely breaking the main mass\'s outline, so the rock ' +
      'reads as one boulder 2.06 m wide; at 1.25 it is a broad shoulder two thirds the ' +
      'main mass\'s height with a deep notch between them, 2.56 m wide. It always stays ' +
      'fused to the main mass and is never removed. Like Tallness this REBUILDS the ' +
      'lobe rather than scaling it — the facet cells stay the size they are on the main ' +
      'mass, so a bigger shoulder is carved by more of them (154 tris at 0.5, 215 at ' +
      '1.25) and the two masses always read as the same stone.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facet grade',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'The SIZE of a facet cell — the pitch the cutting planes are laid out at. ' +
      'chunky = few huge planes, an angular hand-hewn crystal (122 tris at default ' +
      'size); standard = the approved boulder (190); fine = many smaller cells, a more ' +
      'eroded weathered rock (275). Changes the silhouette\'s number of corners, not ' +
      'its proportions. Cell size is held constant across Tallness and Shoulder lobe, ' +
      'so this grade reads the same on a squat slab and on a tall crag.',
  },
  dampLine: {
    type: 'range', default: 0.26, min: 0.12, max: 0.50, step: 0.01, label: 'Damp line',
    describe: 'Height of the damp skirt as a fraction of total height, measured at its ' +
      'average — the actual edge wanders +/-30% of that around the rock and snaps to ' +
      'facet boundaries. It is a real world height, so the smaller lobe sits deeper in ' +
      'it than the main mass. 0.12 is a barely-wet foot, 0.50 a half-submerged tide rock.',
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
  const RINGS = 22, SEGS = 30;
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
        cfg.cz + Math.sin(a) * r + cfg.shearZ * t * t,
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
  const centre = [cfg.cx, cfg.H * 0.42, cfg.cz];
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
  const S = 8;
  const corners = [
    [-S, -S, -S], [S, -S, -S], [S, -S, S], [-S, -S, S],
    [-S, S, -S], [S, S, -S], [S, S, S], [-S, S, S],
  ];
  const c = corners;
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
  chunky:   { main: 20, lobe: 14 },
  standard: { main: 30, lobe: 20 },
  fine:     { main: 44, lobe: 30 },
};

// The size knobs REBUILD the rock, they do not stretch it. A facet cell is this
// asset's repeating unit and holds a constant size at every setting, so a taller or
// broader lump is carved by MORE cutting planes of the same pitch. Cell size is set
// by the `facets` grade alone. `skin` is the lump's surface up to a constant factor.
const skin = (R, H) => R * (R + H);

const MAIN_R0 = 0.82, MAIN_H0 = 1.58;
const LOBE_R0 = 0.56, LOBE_H0 = 1.05;

// Floor of 12 planes: the smallest lobe would otherwise be carved by five, and five
// planes is a shard rather than a rock.
const cellCount = (base, R, H, R0, H0) =>
  Math.max(12, Math.round(base * (skin(R, H) / skin(R0, H0))));

const FIT = 0.9722;

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['coastal-grey'];
  const C = {
    stone: userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default),
    damp:  userParams.damp  ?? (userParams.colorway ? way.damp  : params.damp.default),
  };

  const tall = P.tallness;
  const lob = P.lobeSize;
  const pc = PLANE_COUNTS[P.facets] || PLANE_COUNTS.standard;

  const mainH = MAIN_H0 * tall;
  const lobeR = LOBE_R0 * lob;
  const lobeH = LOBE_H0 * tall * (0.78 + 0.22 * lob);

  const main = buildLump({
    H: mainH, R: MAIN_R0, cx: 0.28, cz: 0.0,
    prof: [[0, 0.90], [0.15, 1.00], [0.30, 0.98], [0.45, 0.88], [0.60, 0.75],
           [0.75, 0.58], [0.88, 0.38], [1.00, 0.13]],
    m3: 0.11, p3: 0.7, m5: 0.06, p5: 2.4,
    shearX: -0.10, shearZ: 0.09,
    planes: cellCount(pc.main, MAIN_R0, mainH, MAIN_R0, MAIN_H0),
    phase: 0.31, seed: 20260729, bite: 0.115,
  });

  const lobe = buildLump({

    H: lobeH, R: lobeR,
    cx: 0.28 - 1.02 * (0.72 + 0.28 * lob), cz: 0.26,
    prof: [[0, 0.92], [0.20, 1.00], [0.40, 0.96], [0.60, 0.84], [0.80, 0.62], [1.00, 0.16]],
    m3: 0.13, p3: 2.1, m5: 0.07, p5: 0.4,
    shearX: -0.07, shearZ: 0.05,
    planes: cellCount(pc.lobe, lobeR, lobeH, LOBE_R0, LOBE_H0),
    phase: 1.97, seed: 777001, bite: 0.13,
  });

  const lumps = [
    { faces: main.faces.filter((f) => !f.every((p) => insideOf(p, lobe.planes, 0.004))) },
    { faces: lobe.faces.filter((f) => !f.every((p) => insideOf(p, main.planes, 0.004))) },
  ];

  let mnx = Infinity, mxx = -Infinity, mnz = Infinity, mxz = -Infinity, mxy = -Infinity;
  for (const l of lumps) for (const f of l.faces) for (const p of f) {
    if (p[0] < mnx) mnx = p[0]; if (p[0] > mxx) mxx = p[0];
    if (p[2] < mnz) mnz = p[2]; if (p[2] > mxz) mxz = p[2];
    if (p[1] > mxy) mxy = p[1];
  }
  const ox = (mnx + mxx) / 2, oz = (mnz + mxz) / 2;
  const H = mxy * FIT;

  const pos = [];
  const col = [];
  const tmp = new THREE.Color();
  const push3 = (p) => pos.push((p[0] - ox) * FIT, p[1] * FIT, (p[2] - oz) * FIT);

  const paint = (hex) => {
    tmp.set(hex);
    for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b);
  };

  for (let li = 0; li < lumps.length; li++) {
    const faces = lumps[li].faces;
    const info = faces.map((f) => {
      const c = [0, 0, 0];
      for (const p of f) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
      c[0] /= f.length; c[1] /= f.length; c[2] /= f.length;
      const n = norm(cross(sub(f[1], f[0]), sub(f[2], f[0])));
      const wx = (c[0] - ox) * FIT, wy = c[1] * FIT, wz = (c[2] - oz) * FIT;
      return { f, n, wx, wy, wz, az: Math.atan2(wz, wx), area: faceArea(f) };
    });
    const lumpArea = info.reduce((s, t) => s + t.area, 0);

    const base = P.dampLine * H;
    const isDamp = (t) => t.wy < base * (1 + 0.30 * Math.sin(2.3 * t.az + 1.1)
                                           + 0.18 * Math.sin(3.7 * t.az + 0.3));

    for (const t of info) {
      const hex = isDamp(t) ? C.damp : C.stone;
      for (let i = 1; i + 1 < t.f.length; i++) {
        push3(t.f[0]); push3(t.f[i]); push3(t.f[i + 1]);
        paint(hex);
      }
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
  g.name = 'large-coastal-boulder';
  g.add(mesh);
  return g;
}

export default createAsset;
