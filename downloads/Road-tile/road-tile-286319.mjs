/*
 * Road-tile
 * https://polyfork.dev/asset/road-tile-286319
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './road-tile-286319.mjs';
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
 *   colorway     choice  'fresh-asphalt' 'fresh-asphalt' | 'sun-bleached' | 'oiled-tarmac' | 'concrete-slab'
 *   asphalt      color   '#3d3f46'      any hex or THREE.Color
 *   repairPatch  color   '#4c4f57'      any hex or THREE.Color
 *   underside    color   '#1a1f26'      any hex or THREE.Color
 *   wear         range   0              0 to 0.04
 *   facets       range   10             6 to 16
 *   patchLayout  choice  'none'         'none' | 'scattered' | 'shift-a' | 'shift-b' | 'shift-c'
 *
 * createAsset() with no arguments gives the CLEAN tile: flat top, one tone per
 * zone, no patches. That is the useful default for paving an area, since any
 * mark baked into the tile repeats in a grid across every copy. Dial `wear` up
 * and pick a `patchLayout` per instance to age a road.
 *
 * Every option is described in full at https://polyfork.dev/cdn/road-tile-286319-params.json
 *
 * SPECS  210 triangles (258 with patch repairs on), 1 material,
 *        4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;
const HALF = SIZE / 2;
const THICK = 0.05;
const TOP_Y = 0.0;
const BOT_Y = TOP_Y - THICK;

const BAND = 0.42;

const SINK = [0, 0.005];

const WEAR_MAX = 0.040;

const COLORWAYS = {
  'fresh-asphalt': { asphalt: 0x3d3f46, repairPatch: 0x4c4f57, underside: 0x1a1f26 },
  'sun-bleached':  { asphalt: 0x676b72, repairPatch: 0x898c95, underside: 0x3d3f46 },
  'oiled-tarmac':  { asphalt: 0x2a2d35, repairPatch: 0x3d3f46, underside: 0x0c0e14 },
  'concrete-slab': { asphalt: 0x999ca3, repairPatch: 0xafb5bb, underside: 0x676b72 },
};
const DEF = {
  colorway: 'fresh-asphalt',

  wear: 0,

  facets: 10,
  patchLayout: 'none',
};

const PATCH_LAYOUTS = { 'none': -1, 'scattered': 0, 'shift-a': 1, 'shift-b': 2, 'shift-c': 3 };

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

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

function edgeFall(u) {
  const t = Math.min(1, Math.max(0, (HALF - Math.abs(u)) / BAND));
  return t * t * (3 - 2 * t);
}

function wearField(x, z, amp) {
  if (amp <= 0) return TOP_Y;

  const dimple = Math.sin(7.4 * x + 0.9) * Math.sin(6.9 * z + 2.6);

  const vary = 0.85 + 0.15 * Math.sin(1.3 * x + 0.4) * Math.sin(1.1 * z - 0.7);
  const s = 0.95 * dimple * vary
          + 0.12 * Math.sin(1.9 * x + 0.7) * Math.sin(1.5 * z - 0.4);
  const f = 0.5 + 0.5 * Math.min(1, Math.max(-1, s));
  return TOP_Y - amp * f * edgeFall(x) * edgeFall(z);
}

const SQUARES = [
  { x:  1.30, z: -1.15, w: 1, d: 1 },
  { x: -1.35, z:  0.62, w: 2, d: 1 },
  { x:  0.10, z:  1.28, w: 1, d: 1 },
  { x: -0.75, z: -1.30, w: 1, d: 1 },
  { x:  1.05, z:  0.95, w: 1, d: 2 },
];

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function patchCells(N, seed) {
  const set = new Set();
  const rnd = prng(seed * 7919 + 13);
  const cell = SIZE / N;

  const big = N >= 8;
  for (const sq of SQUARES) {
    const w = big ? sq.w : 1, d = big ? sq.d : 1;
    let i0 = Math.floor((sq.x + HALF) / cell);
    let j0 = Math.floor((sq.z + HALF) / cell);
    if (seed > 0) {
      i0 += Math.round((rnd() * 2 - 1) * 2);
      j0 += Math.round((rnd() * 2 - 1) * 2);
    }

    i0 = Math.max(1, Math.min(N - 1 - w, i0));
    j0 = Math.max(1, Math.min(N - 1 - d, j0));
    for (let i = i0; i < i0 + w; i++) {
      for (let j = j0; j < j0 + d; j++) set.add(j * N + i);
    }
  }
  return set;
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = [
    p.asphalt !== undefined ? p.asphalt : cw.asphalt,
    p.repairPatch !== undefined ? p.repairPatch : cw.repairPatch,
  ];
  const under = p.underside !== undefined ? p.underside : cw.underside;
  const amp = Math.max(0, Math.min(WEAR_MAX, p.wear !== undefined ? p.wear : DEF.wear));
  const N = Math.max(6, Math.min(16, Math.round(p.facets !== undefined ? p.facets : DEF.facets)));
  let layout = p.patchLayout !== undefined ? p.patchLayout : DEF.patchLayout;
  if (p.repairs === false) layout = 'none';          // legacy alias
  const seed = PATCH_LAYOUTS[layout] !== undefined ? PATCH_LAYOUTS[layout] : PATCH_LAYOUTS[DEF.patchLayout];
  const repairs = seed >= 0;

  const cell = SIZE / N;
  const gx = (i) => -HALF + i * cell;
  const h = (x, z) => wearField(x, z, amp);

  const pid = new Int8Array(N * N);
  if (repairs) for (const k of patchCells(N, seed)) pid[k] = 1;
  const idAt = (i, j) => (i < 0 || j < 0 || i >= N || j >= N) ? 0 : pid[j * N + i];

  const top = [[], []];
  const side = [];

  for (let j = 0; j < N; j++) {
    for (let i = 0; i < N; i++) {
      const id = idAt(i, j), drop = SINK[id];
      const x0 = gx(i), x1 = gx(i + 1), z0 = gx(j), z1 = gx(j + 1);
      const y = (x, z) => h(x, z) - drop;

      quad(top[id],
        [x0, y(x0, z1), z1], [x1, y(x1, z1), z1], [x1, y(x1, z0), z0], [x0, y(x0, z0), z0]);

      const nb = [idAt(i + 1, j), idAt(i - 1, j), idAt(i, j + 1), idAt(i, j - 1)];
      for (let e = 0; e < 4; e++) {
        const up = SINK[nb[e]];
        if (drop <= up) continue;
        const lo = (x, z) => h(x, z) - drop, hi = (x, z) => h(x, z) - up;
        const w = top[id];
        if (e === 0) quad(w, [x1, lo(x1, z0), z0], [x1, lo(x1, z1), z1], [x1, hi(x1, z1), z1], [x1, hi(x1, z0), z0]);
        if (e === 1) quad(w, [x0, lo(x0, z1), z1], [x0, lo(x0, z0), z0], [x0, hi(x0, z0), z0], [x0, hi(x0, z1), z1]);
        if (e === 2) quad(w, [x1, lo(x1, z1), z1], [x0, lo(x0, z1), z1], [x0, hi(x0, z1), z1], [x1, hi(x1, z1), z1]);
        if (e === 3) quad(w, [x0, lo(x0, z0), z0], [x1, lo(x1, z0), z0], [x1, hi(x1, z0), z0], [x0, hi(x0, z0), z0]);
      }
    }
  }

  const P = HALF, M = -HALF;
  quad(side, [P, BOT_Y, P], [P, BOT_Y, M], [P, TOP_Y, M], [P, TOP_Y, P]);
  quad(side, [M, BOT_Y, M], [M, BOT_Y, P], [M, TOP_Y, P], [M, TOP_Y, M]);
  quad(side, [M, BOT_Y, P], [P, BOT_Y, P], [P, TOP_Y, P], [M, TOP_Y, P]);
  quad(side, [P, BOT_Y, M], [M, BOT_Y, M], [M, TOP_Y, M], [P, TOP_Y, M]);

  quad(side, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF]);

  const parts = [{ g: posGeo(side), c: under }];
  for (let k = 0; k < 2; k++) if (top[k].length) parts.push({ g: posGeo(top[k]), c: C[k] });

  const g = new THREE.Group();
  g.name = 'road-tile';
  const mesh = finish(parts);
  mesh.name = 'road-surface';
  g.add(mesh);
  return g;
}

export const params = {
  colorway:    { type: 'choice', default: 'fresh-asphalt', label: 'Colorway',
                 options: ['fresh-asphalt', 'sun-bleached', 'oiled-tarmac', 'concrete-slab'],
                 describe: 'curated road-surface scheme: fresh-asphalt is the kit default dark blue-grey tarmac, sun-bleached a pale weathered highway, oiled-tarmac a near-black freshly sealed road, concrete-slab a light grey concrete pavement' },
  asphalt:     { type: 'color', default: '#3d3f46', label: 'Asphalt',
                 describe: 'albedo of the main road wearing course — about 80% of the visible surface' },
  repairPatch: { type: 'color', default: '#4c4f57', label: 'Repair patch',
                 describe: 'albedo of the weathered resurfacing patch sunk into the road, normally a shade LIGHTER than the asphalt; visible once patchLayout is set to anything but none' },

  underside:   { type: 'color', default: '#1a1f26', label: 'Substrate',
                 describe: 'albedo of the slab cut edge and underside (the base course); keeps the tile border a crisp dark line' },

  wear:        { type: 'range', default: 0, min: 0, max: 0.040, label: 'Wear depth',
                 affects: 'geometry',
                 describe: 'depth in metres of the sunken worn dishes in the road surface. 0 is the DEFAULT and the clean tile: a dead flat, brand new slab with one uniform tone, which is what you want when paving an area with dozens of copies. Dial it up per instance to age a road — 0.024 is where flat shading first separates the worn planes, 0.040 is a heavily worn old road. All relief is sunk, so the tiling edges stay flush at every value' },
  facets:      { type: 'range', default: 10, min: 6, max: 16, step: 1, label: 'Facet count',
                 affects: 'geometry',
                 describe: 'how finely the 4 m top surface is subdivided, which is the grid the wear dishes and the patch repairs are cut from: 6 gives big 0.67 m chunky planes and blocky patch outlines, the default 10 gives 0.40 m planes, 16 gives fine 0.25 m planes and smoother patch edges. Triangle count scales with the square of this value. On the clean default tile (wear 0, no patches) the top is flat at every value, so this knob only changes the look once wear or patchLayout is dialled up' },

  patchLayout: { type: 'choice', default: 'none', label: 'Patch layout',
                 options: ['none', 'scattered', 'shift-a', 'shift-b', 'shift-c'],
                 affects: 'geometry',
                 describe: 'whether the road carries sunken square patch repairs, and where they sit. none is the DEFAULT and leaves one clean unbroken tarmac surface — the right choice for paving an area, since a baked mark repeats in a grid across every copy. scattered adds five small square repairs (1-2 facet cells each, about 7% of the surface) as real recesses with their own albedo; shift-a/b/c move every square to a different cell, so neighbouring tiles across a run never line up and the tiling stops being readable. Patch count, size, depth and the flush edges are identical at every value but none' },
};
export const presets = COLORWAYS;
export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
