/*
 * Small Path Stone
 * https://polyfork.dev/asset/small-path-stone-1679ff
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './small-path-stone-1679ff.mjs';
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
 *   colorway    choice  'coastal-grey' 'coastal-grey' | 'sun-bleached' | 'wet-basalt' | 'kelp-shadow'
 *   stone       color   '#9AA3A0'      any hex or THREE.Color
 *   across      range   0.6            0.38 to 0.88
 *   elongation  range   1              0.62 to 1.6
 *   thickness   range   1              0.45 to 1.05
 *   sides       choice  'standard'     'chunky' | 'standard' | 'pebbled'
 *   wear        range   1              0.2 to 1.6
 *
 * Every option is described in full at https://polyfork.dev/cdn/small-path-stone-1679ff-params.json
 *
 * SPECS  76 triangles, 1 material, 0.6 x 0.06 x 0.57 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'coastal-grey': { stone: '#9AA3A0' },
  'sun-bleached': { stone: '#A79680' },
  'wet-basalt':   { stone: '#6E757A' },
  'kelp-shadow':  { stone: '#7C8683' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'coastal-grey', label: 'Colorway',
    options: ['coastal-grey', 'sun-bleached', 'wet-basalt', 'kelp-shadow'],
    describe: 'Curated Pirate Cove stone schemes. The slab has exactly ONE colour zone ' +
      '(a rock is one material), so a colorway simply re-tints the whole stone. ' +
      'coastal-grey is the kit\'s weathered grey-green cove rock, the same hue as ' +
      'large-path-stone and large-coastal-boulder, so mixed scatter runs read as one ' +
      'path; sun-bleached is warm dry sandstone above the tide line; wet-basalt is cold ' +
      'dark volcanic rock; kelp-shadow is a damp grey-green for stones lying in shade. ' +
      'Sets `stone` unless `stone` is passed explicitly.',
  },
  stone: {
    type: 'color', default: '#9AA3A0', label: 'Stone',
    describe: 'Albedo of the entire slab — tread, reveal ring, rim crests, chamfer, rim ' +
      'wall, splayed foot and underside. The only colour in the asset. Keep it clearly ' +
      'lighter than the terrain you scatter it on or the stones vanish into the path.',
  },
  across: {
    type: 'range', default: 0.60, min: 0.38, max: 0.88, step: 0.01, label: 'Size across',
    affects: 'geometry',
    describe: 'Overall plan size in metres — both axes together. 0.38 is a cobble you ' +
      'need three of per stride, 0.60 is the approved stone, 0.88 is a broad flag ' +
      'approaching the large path stone. Section height is NOT scaled with it, so big ' +
      'values read flatter and more flush, small ones chunkier. Nothing repeats along ' +
      'this dimension in a single rock, so this one range honestly rescales the plan ' +
      'rather than rebuilding — `sides` is the knob that rebuilds (its triangle count ' +
      'moves), and the rim band, reveal and chamfer are all re-derived at the new size ' +
      'rather than multiplied through.',
  },
  elongation: {
    type: 'range', default: 1.0, min: 0.62, max: 1.60, step: 0.01, label: 'Elongation',
    affects: 'geometry',
    describe: 'Plan aspect: stretches the slab along X and squeezes it along Z by the ' +
      'same factor, so the footprint AREA and the overall size stay put. 0.62 is a ' +
      '0.47 x 0.72 m stone laid across the path; 1.0 is the approved near-round ' +
      '0.60 x 0.57 m pebble; 1.60 is a 0.76 x 0.45 m long flag laid along it. Scatter a ' +
      'run with mixed values and random yaw and no two stones read as the same rock.',
  },
  thickness: {
    type: 'range', default: 1.0, min: 0.45, max: 1.05, step: 0.01, label: 'Thickness',
    affects: 'geometry',
    describe: 'Vertical scale of the whole section, footprint unchanged. 0.45 is a ' +
      '0.025 m flake barely proud of the ground, almost a paving flag with no visible ' +
      'edge band; 1.0 is the approved 0.056 m stone; 1.05 is the 0.059 m maximum the ' +
      'kit\'s 0.06 m path-stone cap allows. Moves the lit rim band between a hairline ' +
      'and a chunky step with a real shadow under it.',
  },
  sides: {
    type: 'choice', default: 'standard', label: 'Outline',
    options: ['chunky', 'standard', 'pebbled'], affects: 'geometry',
    describe: 'How many corners the irregular outline has, and so how many rim blocks ' +
      'the ring is built from. chunky = 6 big blunt facets, an angular split-rock shard ' +
      '(60 tris); standard = the approved 8-sided pebble (76 tris); pebbled = 10 smaller ' +
      'facets, a rounder river-tumbled stone (96 tris). Changes the corner count in the ' +
      'silhouette and the triangle count, not the footprint.',
  },
  wear: {
    type: 'range', default: 1.0, min: 0.20, max: 1.60, step: 0.05, label: 'Wear',
    affects: 'geometry',
    describe: 'How long the stone has been walked on — one knob driving the three things ' +
      'that age together. 0.20 is freshly split: a 6 mm dip in the tread, a hairline ' +
      '17-28 mm chamfer and rim crests almost level, so it reads as a cut flag. 1.0 is ' +
      'the approved stone: a 17 mm hollow, a 30-50 mm chamfer band and crests wobbling ' +
      '16 mm block to block. 1.60 is a heavily used stone: a 24 mm basin ringed by a ' +
      '40-66 mm chamfer and a plainly scalloped rim. The hollow is always cut DOWNWARD ' +
      'out of the section, so total height stays under the kit\'s 0.06 m cap throughout.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function prep(geo, hex) {
  geo = geo.toNonIndexed();
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
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function capRing(out, ring, up) {
  const contour = ring.map(p => new THREE.Vector2(p[0], p[2]));
  for (const [a, b, c] of THREE.ShapeUtils.triangulateShape(contour, [])) {
    const p = ring[a], q = ring[b], r = ring[c];

    const ny = (q[2] - p[2]) * (r[0] - p[0]) - (q[0] - p[0]) * (r[2] - p[2]);
    if ((ny > 0) === up) tri(out, p, q, r); else tri(out, p, r, q);
  }
}

const SIDE_COUNTS = { chunky: 6, standard: 8, pebbled: 10 };

const F_MID  = 0.22;
const F_UP   = 0.52;

const R_BOT  = 0.88;
const NOMINAL = 0.60;

function drawTables(N, seed) {
  const rand = prng(seed);
  const t = { gap: [], rad: [], bulge: [], inset: [], drop: [] };
  for (let i = 0; i < N; i++) {
    t.gap.push(0.45 + rand() * 1.30);
    t.rad.push(0.70 + rand() * 0.30);
    t.bulge.push(1.000 + rand() * 0.016);
    t.inset.push(0.030 + rand() * 0.020);

    t.drop.push(rand());

  }

  const lo = Math.min(...t.drop), hi = Math.max(...t.drop);
  t.drop = t.drop.map(d => (d - lo) / ((hi - lo) || 1));
  return t;
}

function ringFrom(t, N) {
  const ring = [];
  const total = t.gap.reduce((s, w) => s + w, 0);
  let a = 0;
  for (let i = 0; i < N; i++) {
    const r = 0.5 * t.rad[i];

    ring.push({ x: Math.cos(a) * r, z: Math.sin(a) * r });
    a -= (t.gap[i] / total) * Math.PI * 2;
  }
  return ring;
}

function ringScore(ring, N) {
  const turn = (i) => {
    const p = ring[(i + N - 1) % N], q = ring[i], s = ring[(i + 1) % N];
    return (q.x - p.x) * (s.z - q.z) - (q.z - p.z) * (s.x - q.x);
  };
  let sum = 0;
  for (let i = 0; i < N; i++) sum += turn(i);
  const sign = sum >= 0 ? 1 : -1;
  for (let i = 0; i < N; i++) if (turn(i) * sign <= 0) return null;

  const edge = [], ang = [];
  for (let i = 0; i < N; i++) {
    const p = ring[(i + N - 1) % N], q = ring[i], s = ring[(i + 1) % N];
    edge.push(Math.hypot(s.x - q.x, s.z - q.z));
    const ax = p.x - q.x, az = p.z - q.z, bx = s.x - q.x, bz = s.z - q.z;
    ang.push(Math.acos((ax * bx + az * bz) /
      ((Math.hypot(ax, az) * Math.hypot(bx, bz)) || 1)) * 180 / Math.PI);
  }
  if (Math.min(...ang) < 104 || Math.max(...ang) > 166) return null;
  if (Math.max(...edge) / Math.min(...edge) < 2.10) return null;
  const rad = ring.map(p => Math.hypot(p.x, p.z));
  if (Math.max(...rad) / Math.min(...rad) < 1.38) return null;
  const half = Math.floor(N / 2);
  for (let i = 0; i < half; i++) {
    const a = rad[i], b = rad[(i + half) % N];
    if (Math.abs(a - b) / Math.max(a, b) < 0.08) return null;
  }
  return Math.max(...edge) / Math.min(...edge);
}

function outlineTables(N) {
  for (let s = 0; s < 4000; s++) {
    const t = drawTables(N, 990017 + N * 7919 + s * 104729);
    if (ringScore(ringFrom(t, N), N) !== null) return t;
  }
  return drawTables(N, 990017 + N * 7919);
}

function cornerToward(ring, dx, dz) {
  let best = 0, bestDot = -Infinity;
  for (let i = 0; i < ring.length; i++) {
    const len = Math.hypot(ring[i].x, ring[i].z) || 1;
    const d = (ring[i].x * dx + ring[i].z * dz) / len;
    if (d > bestDot) { bestDot = d; best = i; }
  }
  return best;
}

function chipWeights(ring, N) {
  const w = new Array(N).fill(0);
  const deep = cornerToward(ring, 0, 1);
  const shallow = cornerToward(ring, -1, 0);
  w[deep] = 1.0;
  w[(deep + 1) % N] = 0.38;
  w[(deep + N - 1) % N] = 0.34;
  w[shallow] = Math.max(w[shallow], 0.60);
  w[(shallow + 1) % N] = Math.max(w[(shallow + 1) % N], 0.22);
  return w;
}

function buildSlab(P) {
  const N = SIDE_COUNTS[P.sides] || SIDE_COUNTS.standard;
  const T = outlineTables(N);
  const ring = ringFrom(T, N);
  const chipW = chipWeights(ring, N);

  const e = Math.sqrt(P.elongation);
  const WIDE = P.across * e;
  const DEEP = P.across * 0.95 / e;

  const TOTAL = 0.056 * P.thickness;
  const yMid = F_MID * TOTAL, yUp = F_UP * TOTAL;
  const DISH = TOTAL * (0.08 + 0.22 * P.wear);
  const WIDEN = 0.45 + 0.55 * P.wear;
  const FLOOR = TOTAL * 0.935 - DISH;

  const bite = ring.map((_, i) => 1 - 0.16 * chipW[i]);
  const fMid = ring.map((_, i) => T.bulge[i] * bite[i]);
  const fUp  = ring.map((_, i) => bite[i] - 0.10 * chipW[i]);
  const fBot = ring.map((_, i) => R_BOT * bite[i]);

  const wx = ring.map((p, i) => p.x * fMid[i]), wz = ring.map((p, i) => p.z * fMid[i]);
  const sx = WIDE / (Math.max(...wx) - Math.min(...wx));
  const sz = DEEP / (Math.max(...wz) - Math.min(...wz));
  ring.forEach(p => { p.x *= sx; p.z *= sz; });

  const rMean = ring.reduce((s, p) => s + Math.hypot(p.x, p.z), 0) / N;
  const scale = P.across / NOMINAL;

  const bot = ring.map((p, i) => [p.x * fBot[i], 0, p.z * fBot[i]]);
  const mid = ring.map((p, i) => [p.x * fMid[i], yMid, p.z * fMid[i]]);
  const up  = ring.map((p, i) => [p.x * fUp[i],  yUp,  p.z * fUp[i]]);

  const crestY = ring.map((_, i) => Math.max(
    FLOOR + TOTAL * 0.02,
    TOTAL - T.drop[i] * DISH * 0.95 - TOTAL * 0.34 * chipW[i]));

  const pullIn = (from, cut, y) => from.map((p, i) => {
    const len = Math.hypot(p[0], p[2]) || 1;
    const c = cut(i);
    const k = Math.max(0.12, (len - c) / len);
    return [p[0] * k, y(i), p[2] * k];
  });

  const crest = pullIn(mid, i => (T.inset[i] * scale * WIDEN) + chipW[i] * 0.22 * rMean,
                       i => crestY[i]);

  const inner = pullIn(crest, () => 0.018 * scale * (0.6 + 0.4 * P.wear), () => FLOOR);

  const pos = [];
  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    quad(pos, bot[i], bot[j], mid[j], mid[i]);
    quad(pos, mid[i], mid[j], up[j], up[i]);
    quad(pos, up[i], up[j], crest[j], crest[i]);
    quad(pos, crest[i], crest[j], inner[j], inner[i]);
  }

  capRing(pos, inner, true);
  capRing(pos, bot, false);
  return posGeo(pos);
}

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['coastal-grey'];
  const stone = userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default);

  const g = new THREE.Group();
  g.name = 'small-path-stone';
  const mesh = finish([{ g: buildSlab(P), c: stone }]);
  mesh.name = 'stone';

  mesh.geometry.computeBoundingBox();
  const b = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2);
  g.add(mesh);
  return g;
}

export default createAsset;
