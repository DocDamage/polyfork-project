/*
 * Armchair
 * https://polyfork.dev/asset/armchair-980c7c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './armchair-980c7c.mjs';
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
 * SPECS  72 triangles, 1 material, 0.9 x 0.64 x 0.82 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const UPHOLSTERY = '#c46a4c';
const CUSHION    = '#ecd7ac';
const BASE       = '#3a2b22';

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  const box = (w, h, d, x, y, z) => new THREE.BoxGeometry(w, h, d).translate(x, y, z);

  add(box(0.90, 0.12, 0.82, 0, 0.06, 0), BASE);

  const armW = 0.16, armH = 0.36, armD = 0.82, armY = 0.12 + armH / 2;
  add(box(armW, armH, armD, -0.37, armY, 0), UPHOLSTERY);
  add(box(armW, armH, armD,  0.37, armY, 0), UPHOLSTERY);

  add(box(0.90, 0.52, 0.16, 0, 0.12 + 0.26, -0.33), UPHOLSTERY);

  add(box(0.60, 0.17, 0.62, 0, 0.12 + 0.085, 0.04), CUSHION);

  add(box(0.60, 0.34, 0.14, 0, 0.12 + 0.19, -0.24), CUSHION);

  const g = new THREE.Group();
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

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
