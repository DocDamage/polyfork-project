/*
 * Layer Cake
 * https://polyfork.dev/asset/layer-cake-45d142
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './layer-cake-45d142.mjs';
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
 * SPECS  181 triangles, 1 material, 0.29 x 0.25 x 0.31 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SPONGE = 0xd9a05b;
const CREAM  = 0xf2a7b8;
const CHERRY = 0xd0342c;
const PLATE  = 0xe6e2da;

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

add(new THREE.CylinderGeometry(0.155, 0.155, 0.012, 10).translate(0, 0.006, 0), PLATE);

add(new THREE.CylinderGeometry(0.115, 0.115, 0.175, 8).translate(0, 0.0995, 0), SPONGE);

for (const y of [0.068, 0.130]) {
  add(new THREE.CylinderGeometry(0.119, 0.119, 0.02, 8, 1, true).translate(0, y, 0), CREAM);
}

add(new THREE.CylinderGeometry(0.123, 0.123, 0.034, 8).translate(0, 0.199, 0), CREAM);

const DRIPS = [[0.35, 0.042], [1.55, 0.030], [2.75, 0.038], [4.05, 0.026], [5.35, 0.034]];
for (const [phi, len] of DRIPS) {
  const g = new THREE.ConeGeometry(0.014, len, 5, 1, true);
  g.rotateX(Math.PI);
  g.translate(Math.cos(phi) * 0.108, 0.184 - len / 2, Math.sin(phi) * 0.108);
  add(g, CREAM);
}

add(new THREE.IcosahedronGeometry(0.021, 0).translate(0, 0.237, 0), CHERRY);

export function createAsset() {
  const group = new THREE.Group();
  group.name = 'layer-cake';
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
