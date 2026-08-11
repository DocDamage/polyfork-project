/*
 * Lane-marking-decal
 * https://polyfork.dev/asset/lane-marking-decal-d1a212
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './lane-marking-decal-d1a212.mjs';
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
 *   colorway  choice  'yellow-white' 'yellow-white' | 'road-white' | 'warm-yellow'
 *   paint     color   '#ecf1cb'      any hex or THREE.Color
 *
 * Every option is described in full at https://polyfork.dev/cdn/lane-marking-decal-d1a212-params.json
 *
 * SPECS  298 triangles, 1 material, 4 x 0.02 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const PAL = {
  asphalt: 0x3d3f46,
  paint:   0xecf1cb,
};

const COLORWAYS = {
  'yellow-white': { paint: 0xecf1cb },
  'road-white':   { paint: 0xf1f2ef },
  'warm-yellow':  { paint: 0xe8cc42 },
};

const MODULE   = 4.0;
const HALF     = MODULE / 2;
const SHEET_H  = 0.006;
const PAINT_TOP  = 0.019;
const PAINT_BASE = 0.003;
const DASH_L   = 0.30;
const DASH_HW  = 0.075;
const COUNT    = 9;
const PITCH    = (MODULE - DASH_L) / (COUNT - 1);
const BEVEL    = 0.02;
const SEG      = 13;

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function dash(x0, x1, keep) {
  const xa = x0 + (keep === 'xmin' ? 0 : BEVEL), xb = x1 - (keep === 'xmax' ? 0 : BEVEL);
  const za = -DASH_HW + BEVEL, zb = DASH_HW - BEVEL;
  const base = [[x1, DASH_HW], [x1, -DASH_HW], [x0, -DASH_HW], [x0, DASH_HW]];
  const top  = [[xb, zb], [xb, za], [xa, za], [xa, zb]];
  const b = base.map(p => [p[0], PAINT_BASE, p[1]]);
  const t = top.map(p  => [p[0], PAINT_TOP,  p[1]]);
  const pos = [];
  for (let i = 0; i < 4; i++) quad(pos, b[i], b[(i+1)%4], t[(i+1)%4], t[i]);
  quad(pos, t[0], t[1], t[2], t[3]);
  return posGeo(pos);
}

function sheet() {
  const h = HALF, d = MODULE / SEG;
  const pos = [];
  const per = [];
  for (let k = 0; k < SEG; k++) per.push([ h,        h - k * d]);
  for (let k = 0; k < SEG; k++) per.push([ h - k*d, -h        ]);
  for (let k = 0; k < SEG; k++) per.push([-h,       -h + k * d]);
  for (let k = 0; k < SEG; k++) per.push([-h + k*d,  h        ]);
  const n = per.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const t0 = [per[i][0], SHEET_H, per[i][1]], t1 = [per[j][0], SHEET_H, per[j][1]];
    const b0 = [per[i][0], 0, per[i][1]],       b1 = [per[j][0], 0, per[j][1]];
    tri(pos, [0, SHEET_H, 0], t0, t1);
    tri(pos, [0, 0, 0], b1, b0);
    quad(pos, b0, b1, t1, t0);
  }
  return posGeo(pos);
}

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
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

export function createAsset(params = {}) {
  const cw = COLORWAYS[params.colorway] || COLORWAYS['yellow-white'];
  const paintHex = params.paint !== undefined ? params.paint : cw.paint;

  const g = new THREE.Group();
  g.name = 'lane-marking-decal';

  const parts = [{ g: sheet(), c: PAL.asphalt }];
  for (let i = 0; i < COUNT; i++) {
    const x0 = -HALF + i * PITCH, x1 = x0 + DASH_L;
    const keep = i === 0 ? 'xmin' : (i === COUNT - 1 ? 'xmax' : null);
    parts.push({ g: dash(x0, x1, keep), c: paintHex });
  }

  const mesh = finish(parts);
  mesh.name = 'lane-marking-surface';
  g.add(mesh);
  return g;
}

export const params = {
  colorway: { type: 'choice', default: 'yellow-white', label: 'Marking colour',
              options: ['yellow-white', 'road-white', 'warm-yellow'],
              describe: 'curated road-marking paint colour; geometry unchanged' },
  paint:    { type: 'color', default: '#ecf1cb', label: 'Paint',
              describe: 'albedo of the dashed centre-line marking' },
};
export const presets = COLORWAYS;
export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
