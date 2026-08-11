/*
 * Treasure Chest
 * https://polyfork.dev/asset/treasure-chest-58da92
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './treasure-chest-58da92.mjs';
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
 * SPECS  120 triangles, 1 material, 0.83 x 0.61 x 0.55 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const WOOD = '#6b3f18';
const GOLD = '#e3a72c';
const DARK = '#231a12';

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
    vertexColors: true, flatShading: true, roughness: 0.8, metalness: 0,
  }));
}
const box = (w, h, d, x, y, z) => new THREE.BoxGeometry(w, h, d).translate(x, y, z);

const W = 0.80;
const D = 0.50;
const BH = 0.35;
const R = D / 2;

add(box(W, BH, D, 0, BH / 2, 0), WOOD);

const dome = new THREE.CylinderGeometry(R, R, W, 6, 1, false, 0, Math.PI);
dome.rotateZ(Math.PI / 2);
dome.translate(0, BH, 0);
add(dome, WOOD);

add(box(W + 0.03, 0.06, D + 0.03, 0, BH, 0), GOLD);

const STRAP_X = 0.24;
const STRAP_W = 0.07;
for (const sx of [-STRAP_X, STRAP_X]) {

  add(box(STRAP_W, BH, 0.03, sx, BH / 2, D / 2 + 0.005), GOLD);

  const arc = new THREE.CylinderGeometry(R + 0.012, R + 0.012, STRAP_W, 6, 1, true, 0, Math.PI);
  arc.rotateZ(Math.PI / 2);
  arc.translate(sx, BH, 0);
  add(arc, GOLD);
}

add(box(0.14, 0.16, 0.03, 0, BH + 0.01, D / 2 + 0.01), GOLD);

add(box(0.035, 0.06, 0.02, 0, BH - 0.02, D / 2 + 0.03), DARK);

export function createAsset() {
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}
export const rig = {};
export const detach = [];

export const night = {};
