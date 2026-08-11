/*
 * Baguette
 * https://polyfork.dev/asset/baguette-4eb3a2
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './baguette-4eb3a2.mjs';
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
 * SPECS  120 triangles, 1 material, 0.63 x 0.1 x 0.1 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CRUST = 0xc98a46;
const TIP   = 0xa1631f;
const SLASH = 0xf9e9c0;

const L = 0.60;
const R = 0.051;
const SIDES = 8;

const STATIONS = [0, 0.09, 0.19, 0.81, 0.91, 1];
const RSCALE   = [0.42, 0.86, 1.00, 1.00, 0.86, 0.42];
const TIP_EXT = 0.013;

const parts = [];
const add = (g, c) => parts.push({ g, c });

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

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const COS8 = Math.cos(Math.PI / SIDES);
function radiusAt(t) {
  let k = 0;
  while (k < STATIONS.length - 2 && STATIONS[k + 1] < t) k++;
  const f = (t - STATIONS[k]) / (STATIONS[k + 1] - STATIONS[k]);
  return R * (RSCALE[k] + (RSCALE[k + 1] - RSCALE[k]) * f);
}

function bottomAt(t) { return (R - radiusAt(t)) * COS8 * 0.25; }
function centerYAt(t) { return bottomAt(t) + radiusAt(t) * COS8; }
const xAt = (t) => -L / 2 + t * L;
const tAt = (x) => (x + L / 2) / L;

function ringPt(t, j, off = 0) {
  const a = (j + 0.5) * 2 * Math.PI / SIDES;
  const r = radiusAt(t) + off;
  return [xAt(t), centerYAt(t) + r * Math.sin(a), r * Math.cos(a)];
}

const body = [], ends = [];
for (let k = 0; k < STATIONS.length - 1; k++) {
  const t0 = STATIONS[k], t1 = STATIONS[k + 1];
  const out = (k === 0 || k === STATIONS.length - 2) ? ends : body;
  for (let j = 0; j < SIDES; j++) {
    const A = ringPt(t0, j), B = ringPt(t0, j + 1);
    const C = ringPt(t1, j + 1), D = ringPt(t1, j);
    quad(out, A, D, C, B);
  }
}

const apexHi = [xAt(1) + TIP_EXT, centerYAt(1), 0];
const apexLo = [xAt(0) - TIP_EXT, centerYAt(0), 0];
for (let j = 0; j < SIDES; j++) {
  tri(ends, apexHi, ringPt(1, j + 1), ringPt(1, j));
  tri(ends, apexLo, ringPt(0, j), ringPt(0, j + 1));
}
add(posGeo(body), CRUST);
add(posGeo(ends), TIP);

const SHEAR = 0.050, THICK = 0.028, LIFT = 0.0018;
const slashes = [];
for (const c of [-0.14, -0.047, 0.047, 0.14]) {
  const rail = [];
  for (let j = 0; j <= 3; j++) {
    const x = c + SHEAR * (j - 1.5) / 3;

    rail.push([
      ringPt(tAt(x - THICK / 2), j, LIFT / COS8),
      ringPt(tAt(x + THICK / 2), j, LIFT / COS8),
    ]);
    rail[j][0][0] = x - THICK / 2;
    rail[j][1][0] = x + THICK / 2;
  }
  for (let j = 0; j < 3; j++)
    quad(slashes, rail[j][0], rail[j][1], rail[j + 1][1], rail[j + 1][0]);
}
add(posGeo(slashes), SLASH);

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'baguette';
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
