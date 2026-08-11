/*
 * Scooter
 * https://polyfork.dev/asset/scooter-b4b718
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './scooter-b4b718.mjs';
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
 * SPECS  136 triangles, 1 material, 0.58 x 0.87 x 0.36 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const FRAME = '#ec5b3a';
const RUBBER = '#23262b';

const parts = [];
const add = (g, c) => parts.push({ g, c });

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

function wheel(x, r, t) {
  return new THREE.CylinderGeometry(r, r, t, 8).rotateX(Math.PI / 2).translate(x, r, 0);
}

export function createAsset() {
  const R = 0.06;
  const T = 0.028;
  const REAR_X = -0.22;
  const FRONT_X = 0.20;

  add(wheel(REAR_X, R, T), RUBBER);
  add(wheel(FRONT_X, R, T), RUBBER);

  add(new THREE.BoxGeometry(0.36, 0.026, 0.08).translate(-0.02, 0.088, 0), FRAME);

  add(new THREE.BoxGeometry(0.05, 0.026, 0.08).rotateZ(0.5).translate(REAR_X + 0.06, 0.07, 0), FRAME);

  const stem = new THREE.CylinderGeometry(0.023, 0.023, 0.80, 6);
  stem.translate(0, 0.40, 0);
  stem.rotateZ(-0.10);
  stem.translate(FRONT_X, R, 0);
  add(stem, FRAME);

  const barY = 0.85, barX = FRONT_X + 0.083;
  add(new THREE.CylinderGeometry(0.02, 0.02, 0.36, 6).rotateX(Math.PI / 2).translate(barX, barY, 0), FRAME);

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, 0, -(bb.min.z + bb.max.z) / 2);

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
