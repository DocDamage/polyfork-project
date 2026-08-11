/*
 * Train Engine
 * https://polyfork.dev/asset/train-engine-180979
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './train-engine-180979.mjs';
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
 * SPECS  147 triangles, 1 material, 4 x 3.2 x 2.13 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const GREEN = 0x2f8f57;
const DARK = 0x232a2e;
const RED = 0xd23b2e;

const SCALE = 5;

const BOILER_R = 0.185, BOILER_BACK = -0.22, BOILER_NOSE = 0.38, BOILER_Y = 0.30;
const WHEEL_R = 0.145, WHEEL_W = 0.055, WHEEL_Z = 0.185;

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
  merged.scale(SCALE, SCALE, SCALE);

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

export function createAsset() {
  const group = new THREE.Group();

  const bl = BOILER_NOSE - BOILER_BACK;
  add(new THREE.CylinderGeometry(BOILER_R, BOILER_R, bl, 8, 1, true)
    .rotateZ(Math.PI / 2).translate((BOILER_NOSE + BOILER_BACK) / 2, BOILER_Y, 0), GREEN);

  add(new THREE.CircleGeometry(BOILER_R, 8)
    .rotateY(Math.PI / 2).translate(BOILER_NOSE, BOILER_Y, 0), RED);

  add(new THREE.BoxGeometry(0.24, 0.43, 0.34).translate(-0.30, 0.335, 0), GREEN);

  add(new THREE.CylinderGeometry(0.065, 0.045, 0.22, 5, 1, true).translate(0.26, 0.53, 0), DARK);
  add(new THREE.CircleGeometry(0.065, 5, -Math.PI / 2).rotateX(-Math.PI / 2).translate(0.26, 0.64, 0), DARK);

  for (const x of [0.24, -0.26]) {
    for (const z of [WHEEL_Z, -WHEEL_Z]) {
      add(new THREE.CylinderGeometry(WHEEL_R, WHEEL_R, WHEEL_W, 6)
        .rotateX(Math.PI / 2).translate(x, WHEEL_R, z), DARK);
    }
  }

  group.add(finish(parts));
  parts.length = 0;
  return group;
}

export const rig = {};
export const detach = [];
