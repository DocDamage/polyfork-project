/*
 * Potted Cactus
 * https://polyfork.dev/asset/potted-cactus-855c1d
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './potted-cactus-855c1d.mjs';
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
 * SPECS  181 triangles, 1 material, 0.13 x 0.18 x 0.13 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

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

const CLAY   = '#c85a2e';
const SOIL   = '#3d2a18';
const CACTUS = '#3f9b45';
const FLOWER = '#e8402f';

const SOIL_Y = 0.072;
const potPts = [
  [0.000, 0.000],
  [0.042, 0.000],
  [0.048, 0.010],
  [0.058, 0.060],
  [0.066, 0.070],
  [0.064, 0.084],
  [0.054, 0.084],
  [0.052, SOIL_Y],
].map(([r, y]) => new THREE.Vector2(r, y));
add(new THREE.LatheGeometry(potPts, 7), CLAY);

add(new THREE.CircleGeometry(0.054, 7).rotateX(-Math.PI / 2).translate(0, SOIL_Y + 0.001, 0), SOIL);

const R = 0.066;
const ball = new THREE.SphereGeometry(R, 7, 5);

{
  const pos = ball.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const r = Math.hypot(x, z);
    if (r > 1e-4) {
      const a = Math.atan2(z, x);
      const k = 1 + 0.13 * Math.cos(a * 7);
      pos.setX(i, x * k); pos.setZ(i, z * k);
    }
  }
  pos.needsUpdate = true;
}
ball.scale(1, 0.88, 1);

ball.translate(0, SOIL_Y + R * 0.88 - 0.014, 0);
add(ball, CACTUS);

const crownTop = SOIL_Y + R * 0.88 - 0.014 + R * 0.88;
const flower = new THREE.IcosahedronGeometry(0.026, 0);
flower.scale(1, 0.45, 1);
flower.translate(0, crownTop - 0.009, 0);
add(flower, FLOWER);

export function createAsset() {
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}
export const rig = {};
export const detach = [];

export const night = {};
