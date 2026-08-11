/*
 * Large Path Stone
 * https://polyfork.dev/asset/large-path-stone-1b0844
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './large-path-stone-1b0844.mjs';
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
 *   across      range   1.1            0.8 to 1.4
 *   elongation  range   1              0.6 to 1.65
 *   thickness   range   1              0.45 to 1.02
 *   sides       choice  'standard'     'chunky' | 'standard' | 'worn'
 *   chip        range   1              0 to 1.6
 *
 * Every option is described in full at https://polyfork.dev/cdn/large-path-stone-1b0844-params.json
 *
 * SPECS  80 triangles, 1 material, 1.1 x 0.06 x 1.03 m (real-world scale).
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
      'coastal-grey is the kit\'s weathered grey-green cove rock; sun-bleached is warm ' +
      'dry sandstone above the tide line; wet-basalt is cold dark volcanic rock; ' +
      'kelp-shadow is a darker damp grey-green for stones lying in shade. Sets `stone` ' +
      'unless `stone` is passed explicitly.',
  },
  stone: {
    type: 'color', default: '#9AA3A0', label: 'Stone',
    describe: 'Albedo of the entire slab — tread, both chamfer steps, rim wall, splayed ' +
      'foot and underside. The only colour in the asset. Keep it clearly lighter than ' +
      'the terrain you scatter it on or the stones vanish into the path.',
  },
  across: {
    type: 'range', default: 1.10, min: 0.80, max: 1.40, step: 0.01, label: 'Size across',
    affects: 'geometry',
    describe: 'Overall plan size in metres — both axes scale together. 0.80 is a ' +
      'single-stride stepping stone, 1.10 is the approved large slab, 1.40 is a broad ' +
      'landing stone nearly two paces across. Height is NOT scaled by this, so bigger ' +
      'values read flatter and more flush with the ground.',
  },
  elongation: {
    type: 'range', default: 1.0, min: 0.60, max: 1.65, step: 0.01, label: 'Elongation',
    affects: 'geometry',
    describe: 'Plan aspect: stretches the slab along X and squeezes it along Z by the ' +
      'same factor, so the footprint AREA and the overall size stay put. 0.60 is a ' +
      '0.85 x 1.34 m stone laid across the path; 1.0 is the approved near-square ' +
      '1.10 x 1.03 m slab; 1.65 is a 1.41 x 0.81 m long flag laid along it. Scatter a ' +
      'run with mixed values (and random yaw) and no two stones read as the same rock.',
  },
  thickness: {
    type: 'range', default: 1.0, min: 0.45, max: 1.02, step: 0.01, label: 'Thickness',
    affects: 'geometry',
    describe: 'Vertical scale of the whole section. 0.45 is a 0.026 m thin flake barely ' +
      'proud of the ground, almost a paving flag; 1.0 is the approved 0.058 m slab; ' +
      '1.02 is the 0.059 m maximum the kit\'s 0.06 m path-stone cap allows. Footprint ' +
      'is unchanged, so this moves the lit edge band between a hairline and a chunky ' +
      'visible step with a real shadow under it.',
  },
  sides: {
    type: 'choice', default: 'standard', label: 'Outline',
    options: ['chunky', 'standard', 'worn'], affects: 'geometry',
    describe: 'How many corners the irregular outline has. chunky = 6 big blunt facets, ' +
      'an angular split-rock shard (~59 tris); standard = the approved 8-sided stone ' +
      '(~80 tris); worn = 10 smaller facets, a rounder river-tumbled slab (~100 tris). ' +
      'Changes the number of corners in the silhouette, not the footprint.',
  },
  chip: {
    type: 'range', default: 1.0, min: 0.0, max: 1.6, step: 0.05, label: 'Broken corner',
    affects: 'geometry',
    describe: 'Size of the two spalls where flakes have broken away — the deep one on ' +
      'the +X flank, a shallower one on +Z. 0 leaves the outline unbroken and the stone ' +
      'reads as an intact paver; 1.0 is the approved chip, a notch ~13% of the radius ' +
      'deep that cuts through the rim wall and slopes into the tread; 1.6 takes a big ' +
      'bite visibly out of the silhouette, a cracked and heavily used stone.',
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

const SIDE_COUNTS = { chunky: 6, standard: 8, worn: 10 };

const F_MID = 0.30;
const F_UP  = 0.72;
const F_SH  = 0.88;
const R_BOT = 0.90;
const R_UP  = 1.00;

function drawTables(N, seed) {
  const rand = prng(seed);
  const t = { gap: [], rad: [], bulge: [], inset: [], topY: [] };
  for (let i = 0; i < N; i++) {
    t.gap.push(0.45 + rand() * 1.35);
    t.rad.push(0.74 + rand() * 0.26);
    t.bulge.push(1.000 + rand() * 0.018);
    t.inset.push(0.030 + rand() * 0.042);

    t.topY.push((rand() - 0.5) * 0.010);
  }
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
  if (Math.min(...ang) < 108 || Math.max(...ang) > 166) return null;
  if (Math.max(...edge) / Math.min(...edge) < 2.0) return null;
  const rad = ring.map(p => Math.hypot(p.x, p.z));
  if (Math.max(...rad) / Math.min(...rad) < 1.30) return null;
  const half = Math.floor(N / 2);
  for (let i = 0; i < half; i++) {
    const a = rad[i], b = rad[(i + half) % N];
    if (Math.abs(a - b) / Math.max(a, b) < 0.08) return null;
  }
  return Math.max(...edge) / Math.min(...edge);
}

function outlineTables(N) {
  for (let s = 0; s < 600; s++) {
    const t = drawTables(N, 1084400 + N * 7919 + s * 104729);
    if (ringScore(ringFrom(t, N), N) !== null) return t;
  }
  return drawTables(N, 1084400 + N * 7919);
}

function chipWeights(N, chip) {
  const w = new Array(N).fill(0);
  if (chip <= 0) return w;
  const deep = 0;
  const shallow = Math.round(N * 0.75) % N;
  w[deep] = chip;
  w[(deep + 1) % N] = chip * 0.34;
  w[(deep + N - 1) % N] = chip * 0.30;
  w[shallow] = Math.max(w[shallow], chip * 0.55);
  w[(shallow + 1) % N] = Math.max(w[(shallow + 1) % N], chip * 0.18);
  return w;
}

function buildSlab(P) {
  const N = SIDE_COUNTS[P.sides] || SIDE_COUNTS.standard;
  const T = outlineTables(N);
  const chipW = chipWeights(N, P.chip);

  const e = Math.sqrt(P.elongation);
  const WIDE = P.across * e;
  const DEEP = P.across * 0.94 / e;

  const TOTAL = 0.058 * P.thickness;
  const CROWN = TOTAL * 0.21;
  const H = TOTAL - CROWN;
  const yMid = F_MID * H, yUp = F_UP * H, ySh = F_SH * H;

  const wob = Math.min(0.004 * P.thickness, CROWN * 0.5);

  const ring = ringFrom(T, N);

  const fMid = ring.map((_, i) => T.bulge[i] * (1 - 0.105 * chipW[i]));
  const fUp  = ring.map((_, i) => R_UP * (1 - 0.175 * chipW[i]));

  const wx = ring.map((p, i) => p.x * fMid[i]), wz = ring.map((p, i) => p.z * fMid[i]);
  const sx = WIDE / (Math.max(...wx) - Math.min(...wx));
  const sz = DEEP / (Math.max(...wz) - Math.min(...wz));
  ring.forEach(p => { p.x *= sx; p.z *= sz; });

  const rMean = ring.reduce((s, p) => s + Math.hypot(p.x, p.z), 0) / N;

  const mid = ring.map((p, i) => [p.x * fMid[i], yMid, p.z * fMid[i]]);
  const bot = ring.map(p => [p.x * R_BOT, 0, p.z * R_BOT]);
  const up  = ring.map((p, i) => [p.x * fUp[i], yUp, p.z * fUp[i]]);

  const insetRing = (frac, y, drop) => mid.map((p, i) => {
    const len = Math.hypot(p[0], p[2]) || 1;
    const cut = (T.inset[i] + chipW[i] * 0.22 * rMean) * frac;
    const k = Math.max(0.12, (len - cut) / len);
    return [p[0] * k, y - drop * chipW[i], p[2] * k];
  });
  const sh  = insetRing(0.38, ySh, H * 0.14);
  const top = mid.map((p, i) => {
    const len = Math.hypot(p[0], p[2]) || 1;
    const cut = T.inset[i] + chipW[i] * 0.22 * rMean;
    const k = Math.max(0.10, (len - cut) / len);
    return [p[0] * k, H + T.topY[i] * (wob / 0.005) - H * 0.32 * chipW[i], p[2] * k];
  });

  const hiA = [ 0.17 * WIDE, H + CROWN,        -0.13 * DEEP];
  const hiB = [-0.19 * WIDE, H + CROWN * 0.76,  0.11 * DEEP];
  const d2 = (p, h) => (p[0] - h[0]) ** 2 + (p[2] - h[2]) ** 2;
  const owner = top.map(p => (d2(p, hiA) <= d2(p, hiB) ? hiA : hiB));

  const pos = [];
  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    quad(pos, bot[i], bot[j], mid[j], mid[i]);
    quad(pos, mid[i], mid[j], up[j],  up[i]);
    quad(pos, up[i],  up[j],  sh[j],  sh[i]);
    quad(pos, sh[i],  sh[j],  top[j], top[i]);
    if (owner[i] === owner[j]) tri(pos, owner[i], top[i], top[j]);
    else quad(pos, owner[i], top[i], top[j], owner[j]);
  }

  for (let k = 1; k <= N - 2; k++) tri(pos, bot[0], bot[k + 1], bot[k]);
  return posGeo(pos);
}

export function createAsset(userParams = {}) {
  const P = {};
  for (const k of Object.keys(params)) P[k] = params[k].default;
  Object.assign(P, userParams);
  const way = COLORWAYS[P.colorway] || COLORWAYS['coastal-grey'];
  const stone = userParams.stone ?? (userParams.colorway ? way.stone : params.stone.default);

  const g = new THREE.Group();
  g.name = 'large-path-stone';
  const mesh = finish([{ g: buildSlab(P), c: stone }]);
  mesh.name = 'stone';

  mesh.geometry.computeBoundingBox();
  const b = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2);
  g.add(mesh);
  return g;
}

export default createAsset;
