/*
 * Garden Rock
 * https://polyfork.dev/asset/garden-rock-2d3b51
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './garden-rock-2d3b51.mjs';
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
 *   colorway   choice  'mossy-granite' 'mossy-granite' | 'dark-basalt' | 'pale-granite' | 'sakura-drift'
 *   stone      color   '#8A9197'      any hex or THREE.Color
 *   moss       color   '#9CC46B'      any hex or THREE.Color
 *   tallness   range   1              0.66 to 1.45
 *   lumps      range   4              2 to 5
 *   facets     choice  'standard'     'chunky' | 'standard' | 'fine'
 *   mossCover  range   0.55           0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/garden-rock-2d3b51-params.json
 *
 * SPECS  340 triangles, 1 material, 0.9 x 0.52 x 0.82 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'mossy-granite': { stone: '#8A9197', moss: '#9CC46B' },
  'dark-basalt':   { stone: '#4E5459', moss: '#3F8A5E' },
  'pale-granite':  { stone: '#C7CBCC', moss: '#6FA860' },
  'sakura-drift':  { stone: '#A9AFB4', moss: '#F2A8BE' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'mossy-granite', label: 'Colorway',
    options: ['mossy-granite', 'dark-basalt', 'pale-granite', 'sakura-drift'],
    describe: 'Curated kit-coherent schemes. mossy-granite is the approved asset: mid ' +
      'grey granite under bright yellow-green moss. dark-basalt is a near-black wet ' +
      'volcanic stone with dark forest moss, for shaded alley corners. pale-granite is ' +
      'a bleached near-white stone with deeper green moss, high contrast in sunlight. ' +
      'sakura-drift keeps a light grey stone and turns the top caps blossom PINK, so ' +
      'the rock reads as drifted cherry petals instead of moss. Sets stone and moss ' +
      'unless those are passed explicitly.',
  },
  stone: {
    type: 'color', default: '#8A9197', label: 'Stone',
    describe: 'Albedo of the rock itself — every facet that is not capped by moss, ' +
      'about three quarters of the surface and the dominant colour of the asset. ' +
      'Keep it a desaturated grey; a saturated stone reads as painted concrete.',
  },
  moss: {
    type: 'color', default: '#9CC46B', label: 'Moss',
    describe: 'Albedo of the moss caps on the upward-facing facets. Should stay ' +
      'clearly LIGHTER in value than Stone — at equal value the green stops reading ' +
      'at thumbnail size and the rock looks uniformly grey. Set it pink for fallen ' +
      'blossom, or match it to Stone to kill the moss entirely.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.66, max: 1.45, step: 0.01, label: 'Tallness',
    affects: 'geometry',
    describe: 'Height of every lump about the ground plane, footprint unchanged at ' +
      '0.90 m across. 0.66 is a 0.35 m flat slab of a rock half-buried in a garden ' +
      'bed; 1.00 is the approved 0.52 m boulder; 1.45 is a 0.74 m upright knee-high ' +
      'crag. A boulder has no repeating structure to multiply, so this reshapes the ' +
      'profile rather than adding features: the cutting planes are recomputed against ' +
      'the new surface, so the facet layout and the triangle count both change ' +
      '(321 tris at 0.66, 351 at 1.45). The count knob below is the one that adds mass.',
  },
  lumps: {
    type: 'range', default: 4, min: 2, max: 5, step: 1, label: 'Lump count',
    affects: 'geometry',
    describe: 'How many fused masses compose the boulder, added outward from the ' +
      'dome: 2 is the dome plus the front shelf alone, a compact 0.67 x 0.81 m ' +
      'twin-lump stone (222 tris; the moss thins to ~21% because the mossiest flanks ' +
      'leave with the dropped lumps); 3 adds the right lump at 0.76 m wide (278); 4 is ' +
      'the approved 0.90 x 0.82 m garden rock with the left knuckle (340); 5 adds a ' +
      'low knuckle behind the dome for a 0.90 x 0.94 m sprawling cluster (384). Each ' +
      'lump is genuinely rebuilt and re-fused against its neighbours, so both the ' +
      'triangle count and the overall footprint grow with the count.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facet grade',
    options: ['chunky', 'standard', 'fine'], affects: 'geometry',
    describe: 'How many cutting planes carve each lump. chunky = few huge cells, an ' +
      'angular hand-hewn crystal of a rock (213 tris); standard = the approved garden ' +
      'rock (340 tris); fine = many smaller cells, a more eroded weathered stone (479 ' +
      'tris). Changes how many corners the silhouette has, not its proportions — the ' +
      'footprint drifts a few cm either way (0.88 m fine, 0.95 m chunky) because the ' +
      'tangent planes land differently, but the squat wide stance is unchanged.',
  },
  mossCover: {
    type: 'range', default: 0.55, min: 0, max: 1, step: 0.01, label: 'Moss cover',
    describe: 'How much of the rock the moss claims. 0 is a completely bare stone with ' +
      'zero green facets — no speckle, no faint tint; 0.55 is the approved patchy cap ' +
      'on the crown, the right lump and the front terrace (27% of triangles); 1.0 ' +
      'buries every upward and upper-shoulder facet in moss (44%) for a damp shaded ' +
      'corner. The boundary always snaps to facet creases, and moss never reaches a ' +
      'downward face, a steep flank or the ground line at any value.',
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

  return { faces: faces.filter((f) => faceArea(f) > 1e-5), planes, H: cfg.H };
}

const insideOf = (p, planes, slack) => planes.every((pl) => dot(pl.n, p) - pl.d < -slack);

const PLANE_COUNTS = {
  chunky:   [22, 16, 16, 13, 11],
  standard: [36, 26, 26, 20, 16],
  fine:     [52, 38, 38, 29, 23],
};

const LUMPS = [
  {
    H: 0.55, R: 0.300, cx: -0.06, cz: -0.06,
    prof: [[0, 0.86], [0.18, 1.00], [0.38, 0.97], [0.58, 0.86], [0.78, 0.70],
           [0.90, 0.55], [1.00, 0.34]],
    m3: 0.12, p3: 0.7, m5: 0.06, p5: 2.4, shearX: -0.05, shearZ: 0.06,
    phase: 0.31, seed: 20260802, bite: 0.115,
  },
  {
    H: 0.25, R: 0.245, cx: 0.10, cz: 0.23,

    prof: [[0, 0.90], [0.28, 1.00], [0.74, 0.99], [0.90, 0.95], [1.00, 0.72]],
    m3: 0.10, p3: 2.6, m5: 0.07, p5: 0.9, shearX: 0.03, shearZ: 0.04,
    phase: 1.97, seed: 510443, bite: 0.10,
  },
  {
    H: 0.33, R: 0.235, cx: 0.24, cz: 0.06,
    prof: [[0, 0.90], [0.20, 1.00], [0.44, 0.96], [0.66, 0.85], [0.85, 0.64], [1.00, 0.24]],
    m3: 0.13, p3: 4.1, m5: 0.06, p5: 1.7, shearX: 0.04, shearZ: -0.03,
    phase: 3.44, seed: 88117, bite: 0.125,
  },
  {
    H: 0.27, R: 0.200, cx: -0.32, cz: 0.10,
    prof: [[0, 0.92], [0.22, 1.00], [0.48, 0.95], [0.72, 0.82], [1.00, 0.28]],
    m3: 0.14, p3: 1.3, m5: 0.07, p5: 3.1, shearX: -0.04, shearZ: 0.03,
    phase: 5.02, seed: 640231, bite: 0.13,
  },
  {
    H: 0.24, R: 0.170, cx: 0.06, cz: -0.34,
    prof: [[0, 0.92], [0.24, 1.00], [0.50, 0.94], [0.75, 0.80], [1.00, 0.26]],
    m3: 0.15, p3: 3.6, m5: 0.08, p5: 5.4, shearX: 0.03, shearZ: -0.04,
    phase: 2.55, seed: 991307, bite: 0.13,
  },
];

const FIT = 0.9102;

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['mossy-granite'];
  const C = {
    stone: userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default),
    moss:  userParams.moss  ?? (userParams.colorway ? way.moss  : params.moss.default),
  };

  const tall = P.tallness;
  const n = Math.max(2, Math.min(5, Math.round(P.lumps)));
  const pc = PLANE_COUNTS[P.facets] || PLANE_COUNTS.standard;

  const lumpDefs = LUMPS.slice(0, n);
  const built = lumpDefs.map((d, i) => buildLump({ ...d, H: d.H * tall, planes: pc[i] }));

  const lumps = built.map((l, i) => ({
    H: l.H,
    faces: l.faces.filter((f) => !built.some((o, j) =>
      j !== i && f.every((p) => insideOf(p, o.planes, -0.006)))),
  }));

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

  const cut = P.mossCover <= 0 ? Infinity : 2.15 - 1.55 * P.mossCover;

  for (let li = 0; li < lumps.length; li++) {
    const l = lumps[li];
    const lumpTop = l.H * FIT;
    const ph = li * 1.9;
    for (const f of l.faces) {
      const c = [0, 0, 0];
      for (const p of f) { c[0] += p[0]; c[1] += p[1]; c[2] += p[2]; }
      c[0] /= f.length; c[1] /= f.length; c[2] /= f.length;
      const nrm = norm(cross(sub(f[1], f[0]), sub(f[2], f[0])));
      const wx = (c[0] - ox) * FIT, wy = c[1] * FIT, wz = (c[2] - oz) * FIT;
      const az = Math.atan2(wz, wx);
      const rel = lumpTop > 1e-6 ? wy / lumpTop : 0;

      const score = 1.45 * nrm[1] + 0.55 * rel
        + 0.30 * Math.sin(3.1 * az + 1.4 + ph) + 0.22 * Math.sin(5.3 * az + 0.6 + ph)
        + 0.17 * Math.sin(7.7 * az + 3.9 + ph)

        + 0.26 * Math.sin(9.1 * wx + 4.2 * wz + 1.1 + ph)
        + 0.20 * Math.sin(7.3 * wz - 5.5 * wx + 2.7 + ph);

      const mossy = score > cut && nrm[1] > 0.26 && rel > 0.38 && wy > 0.34 * H;

      const hex = mossy ? C.moss : C.stone;
      for (let i = 1; i + 1 < f.length; i++) {
        push3(f[0]); push3(f[i]); push3(f[i + 1]);
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
  mesh.name = 'rock';

  const g = new THREE.Group();
  g.name = 'garden-rock';
  g.add(mesh);
  return g;
}

export default createAsset;
