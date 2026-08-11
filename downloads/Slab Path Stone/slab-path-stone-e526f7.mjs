/*
 * Slab Path Stone
 * https://polyfork.dev/asset/slab-path-stone-e526f7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './slab-path-stone-e526f7.mjs';
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
 *   colorway  choice  'river-grey'   'river-grey' | 'granite' | 'basalt' | 'pale-flagstone' | 'warm-sand'
 *   stone     color   '#a3a099'      any hex or THREE.Color
 *   facets    range   7              5 to 7
 *   chipping  range   0.8            0 to 1
 *   crown     range   0.3            0 to 1
 *   seed      range   5              1 to 8
 *
 * Every option is described in full at https://polyfork.dev/cdn/slab-path-stone-e526f7-params.json
 *
 * SPECS  76 triangles, 1 material, 1.1 x 0.06 x 0.7 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DEG = Math.PI / 180;

const LENGTH = 1.10;
const WIDTH  = 0.70;

const H = 0.058;

const Y_BELLY = H * 0.36;
const T_FOOT  = 0.034;
const T_SHLDR = 0.006;

const COLORWAYS = {
  'river-grey':     { stone: '#a3a099' },
  'granite':        { stone: '#87847c' },
  'basalt':         { stone: '#57544e' },
  'pale-flagstone': { stone: '#e0d2b4' },
  'warm-sand':      { stone: '#c2a479' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'river-grey', label: 'Colorway',
    options: ['river-grey', 'granite', 'basalt', 'pale-flagstone', 'warm-sand'],
    describe: 'Curated stone types from the kit palette. river-grey is the shipped mid ' +
      'grey and matches the kit round path stone this slab sits beside; granite is one ' +
      'value step darker; basalt is near-black forest-floor rock; pale-flagstone is a ' +
      'warm cream flag; warm-sand is a tan sandstone for dirt trails. A rock is ONE ' +
      'material, so the colorway repaints the whole slab and nothing else.',
  },
  stone: {
    type: 'color', default: '#a3a099', label: 'Stone',
    describe: 'Albedo of the entire slab — top plate, crown chamfer, rim wall, fracture ' +
      'notch, foot and underside. This asset has exactly one colour zone by design ' +
      '(BUILD 8bc: a path stone is one uniform stone albedo), so this is the only ' +
      'colour knob. Every tone difference in a render is the scene lights on flat ' +
      'shaded facets, never paint.',
  },
  facets: {
    type: 'range', default: 7, min: 5, max: 7, step: 1,
    label: 'Facets', affects: 'geometry',
    describe: 'Number of straight planes clipping the outline. Four are always the ' +
      'slab\'s main edges; the rest sit on the diagonals and shear a corner off. 5 is a ' +
      'blunt rectangle with one sheared corner and the fracture; 7 is a hewn flag with ' +
      'three corners gone. Triangle count runs 8*facets+20 — 60 tris at 5, 68 at 6, 76 ' +
      'at the default 7. It stops at 7 rather than 8 because the fracture notch owns ' +
      'three outline vertices of its own and 8bc holds a path stone under ~80 tris.',
  },
  chipping: {
    type: 'range', default: 0.80, min: 0, max: 1, step: 0.05,
    label: 'Chipping', affects: 'geometry',
    describe: 'How split-out rather than quarried the outline is. 0 is a cut paver: ' +
      'dead-square parallel edges, even 45-degree corner cuts and only a shallow 0.075 m ' +
      'bite in the front edge. 1 swings every edge line up to 14 degrees off square, ' +
      'cuts each corner to a different depth and drives the fracture 0.125 m into the ' +
      'plan, so no two edges are alike and no pair is parallel. The 1.10 x 0.70 m ' +
      'footprint is held exactly at every value.',
  },
  crown: {
    type: 'range', default: 0.30, min: 0, max: 1, step: 0.05,
    label: 'Crown', affects: 'geometry',
    describe: 'How domed the stone is. 0 is a flat flagstone: a broad top plate over a ' +
      'tall rim and a narrow 33-degree chamfer. 1 is a worn river cobble: a small top ' +
      'plate over a crown chamfer four times as wide, starting low on the section. The ' +
      'dome eats into the rim rather than adding to it, so total height never leaves ' +
      '0.058 m.',
  },
  seed: {
    type: 'range', default: 5, min: 1, max: 8, step: 1,
    label: 'Seed', affects: 'geometry',
    describe: 'Which stone this is. Each whole value picks different corners to shear, ' +
      'different edge angles, a different run-in and apex for the fracture notch and a ' +
      'different flank for the wider half of the crown chamfer — all at the same ' +
      'footprint and the same section, so a consumer can pave a run out of eight ' +
      'distinct slabs instead of eight copies of one. The notch always sits on the front ' +
      '(+Z) edge, so it faces the camera whichever stone is picked. There is deliberately ' +
      'NO size knob: a plain slab has nothing that repeats along its length to rebuild, ' +
      'and 8bc hands the scale range (0.6-1.6x per clone) to the consumer scattering ' +
      'the run.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) {
  let s = (seed | 0) % 2147483647;
  if (s <= 0) s += 2147483646;
  const r = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 8; i++) r();
  return r;
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function resolve(p) {
  const out = {};
  for (const k in params) out[k] = params[k].default;
  const cw = (p.colorway !== undefined && COLORWAYS[p.colorway]) ? p.colorway : out.colorway;
  out.colorway = cw;
  Object.assign(out, COLORWAYS[cw]);
  for (const k in p) if (p[k] !== undefined && p[k] !== null) out[k] = p[k];

  out.facets   = clamp(Math.round(+out.facets), 5, 8);
  out.chipping = clamp(+out.chipping, 0, 1);
  out.crown    = clamp(+out.crown, 0, 1);
  out.seed     = clamp(Math.round(+out.seed), 1, 64);
  return out;
}

function clipHalf(poly, ux, uz, d) {
  const out = [];
  for (let i = 0; i < poly.length; i++) {
    const A = poly[i], B = poly[(i + 1) % poly.length];
    const da = ux * A[0] + uz * A[1] - d;
    const db = ux * B[0] + uz * B[1] - d;
    if (da <= 0) out.push(A);
    if ((da < 0 && db > 0) || (da > 0 && db < 0)) {
      const t = da / (da - db);
      out.push([A[0] + (B[0] - A[0]) * t, A[1] + (B[1] - A[1]) * t]);
    }
  }
  return out;
}

function area2(poly) {
  let a = 0;
  for (let i = 0; i < poly.length; i++) {
    const p = poly[i], q = poly[(i + 1) % poly.length];
    a += p[0] * q[1] - q[0] * p[1];
  }
  return a;
}

function edgeNormals(poly) {
  const N = [];
  for (let i = 0; i < poly.length; i++) {
    const A = poly[i], B = poly[(i + 1) % poly.length];
    const ex = B[0] - A[0], ez = B[1] - A[1];
    const L = Math.hypot(ex, ez) || 1;
    N.push([ez / L, -ex / L]);
  }
  return N;
}

function planOutline(P, rand) {
  const A = LENGTH / 2, B = WIDTH / 2;

  const support = (ux, uz) => A * Math.abs(ux) + B * Math.abs(uz);

  const lines = [];
  const push = (angDeg, cut) => {
    const a = angDeg * DEG, ux = Math.cos(a), uz = Math.sin(a);
    lines.push([ux, uz, support(ux, uz) * cut]);
  };

  for (let k = 0; k < 4; k++) {
    push(k * 90 + (rand() - 0.5) * 28 * P.chipping, 1 - 0.14 * P.chipping * rand());
  }

  const corners = [45, 135, 225, 315];
  for (let i = corners.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [corners[i], corners[j]] = [corners[j], corners[i]];
  }
  for (let k = 0; k < P.facets - 4; k++) {
    push(corners[k] + (rand() - 0.5) * 20 * P.chipping, 0.86 - 0.10 * P.chipping * rand());
  }

  const R = (A + B) * 1.5;
  let poly = [[-R, R], [R, R], [R, -R], [-R, -R]];
  for (const [ux, uz, d] of lines) poly = clipHalf(poly, ux, uz, d);

  let x0 = Infinity, x1 = -Infinity, z0 = Infinity, z1 = -Infinity;
  for (const [x, z] of poly) {
    if (x < x0) x0 = x; if (x > x1) x1 = x;
    if (z < z0) z0 = z; if (z > z1) z1 = z;
  }
  const cx = (x0 + x1) / 2, cz = (z0 + z1) / 2;
  const kx = LENGTH / (x1 - x0), kz = WIDTH / (z1 - z0);
  poly = poly.map(([x, z]) => [(x - cx) * kx, (z - cz) * kz]);

  if (area2(poly) > 0) poly.reverse();
  return poly;
}

function biteNotch(poly, rand, depth) {
  const n = poly.length;
  const N = edgeNormals(poly);

  let best = 0, bestScore = -Infinity;
  for (let i = 0; i < n; i++) {
    const A0 = poly[i], B0 = poly[(i + 1) % n];
    const len = Math.hypot(B0[0] - A0[0], B0[1] - A0[1]);
    const facing = -N[i][1];
    const score = len * Math.max(0, facing);
    if (score > bestScore) { bestScore = score; best = i; }
  }

  const A = poly[best], B = poly[(best + 1) % n];
  const ex = B[0] - A[0], ez = B[1] - A[1];
  const [nx, nz] = N[best];

  const w  = 0.26 + rand() * 0.06;
  const a1 = 0.24 + rand() * 0.16;
  const a2 = a1 + w * 0.40;
  const a3 = a1 + w;

  const at = (t, d) => [A[0] + ex * t + nx * d, A[1] + ez * t + nz * d];

  const out = poly.slice(0, best + 1);
  out.push(at(a1, 0), at(a2, depth), at(a3, 0));
  out.push(...poly.slice(best + 1));
  return { poly: out, apexIndex: best + 2, depth };
}

function offsetRing(poly, N, tPerEdge, apexIndex, apexCap) {
  const n = poly.length;
  const out = [];
  for (let k = 0; k < n; k++) {
    const i = (k - 1 + n) % n;
    const j = k;
    const [ax, az] = N[i], [bx, bz] = N[j];
    const ca = ax * poly[k][0] + az * poly[k][1] + tPerEdge[i];
    const cb = bx * poly[k][0] + bz * poly[k][1] + tPerEdge[j];
    const det = ax * bz - bx * az;
    let px, pz;
    if (Math.abs(det) < 1e-6) {
      px = poly[k][0] + bx * tPerEdge[j];
      pz = poly[k][1] + bz * tPerEdge[j];
    } else {
      px = (ca * bz - cb * az) / det;
      pz = (ax * cb - bx * ca) / det;
    }

    const dx = px - poly[k][0], dz = pz - poly[k][1];
    const d = Math.hypot(dx, dz);
    const cap = (k === apexIndex) ? apexCap : 2.2 * Math.max(tPerEdge[i], tPerEdge[j]);
    if (d > cap && d > 1e-9) {
      px = poly[k][0] + (dx / d) * cap;
      pz = poly[k][1] + (dz / d) * cap;
    }
    out.push([px, pz]);
  }
  return out;
}

function slab(P, rand) {
  const base = planOutline(P, rand);
  const notchDepth = 0.075 + 0.050 * P.chipping;
  const bitten = biteNotch(base, rand, notchDepth);
  const plan = bitten.poly;
  const n = plan.length;
  const c = P.crown;
  const N = edgeNormals(plan);

  const tCrown = 0.006 + 0.030 + 0.052 * c;
  const yShoulder = H * (0.66 - 0.26 * c);

  const ka = rand() * Math.PI * 2;
  const ux = Math.cos(ka), uz = Math.sin(ka);
  const bias = (arr, amp) =>
    arr.map((_, i) => clamp(1 + amp * (N[i][0] * ux + N[i][1] * uz), 0.75, 1 + amp));

  const kTop = bias(N, 0.45);
  const kShl = bias(N, 0.30);

  const tFoot  = N.map(() => T_FOOT);
  const tZero  = N.map(() => 0);
  const tShldr = N.map((_, i) => T_SHLDR * kShl[i]);
  const tTop   = N.map((_, i) => tCrown * kTop[i]);

  const apexCap = 0.60 * notchDepth;
  const AI = bitten.apexIndex;

  const rings = [
    { y: 0,         t: tFoot },
    { y: Y_BELLY,   t: tZero },
    { y: yShoulder, t: tShldr },
    { y: H,         t: tTop },
  ];

  const V = rings.map((r) => {
    const ring = offsetRing(plan, N, r.t, AI, apexCap);
    return ring.map(([x, z]) => [x, r.y, z]);
  });

  const contour = plan.map(([x, z]) => new THREE.Vector2(x, z));
  const faces = THREE.ShapeUtils.triangulateShape(contour, []);

  const pos = [];

  for (const f of faces) {
    let [a, b, cc] = f;

    const s = (plan[a][0] * plan[b][1] - plan[b][0] * plan[a][1])
            + (plan[b][0] * plan[cc][1] - plan[cc][0] * plan[b][1])
            + (plan[cc][0] * plan[a][1] - plan[a][0] * plan[cc][1]);
    if (s > 0) { const tmp = b; b = cc; cc = tmp; }
    tri(pos, V[3][a], V[3][b], V[3][cc]);
    tri(pos, V[0][a], V[0][cc], V[0][b]);
  }

  for (let b = 0; b < 3; b++) {
    const L = V[b], U = V[b + 1];
    for (let k = 0; k < n; k++) {
      const j = (k + 1) % n;
      quad(pos, L[k], L[j], U[j], U[k]);
    }
  }

  return posGeo(pos);
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const rand = prng(P.seed * 7919 + 13);

  const g = new THREE.Group();
  g.name = 'slab-path-stone';

  const mesh = finish([{ g: slab(P, rand), c: P.stone }]);
  mesh.name = 'stone';
  g.add(mesh);

  return g;
}

export default createAsset;
