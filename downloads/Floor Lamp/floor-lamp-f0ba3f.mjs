/*
 * Floor Lamp
 * https://polyfork.dev/asset/floor-lamp-f0ba3f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './floor-lamp-f0ba3f.mjs';
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
 * SPECS  80 triangles, 1 material, 0.35 x 1.74 x 0.34 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SHADE = 0xe8a72c;
const METAL = 0x34383f;

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

export function createAsset() {
  const BASE_H = 0.045, BASE_R = 0.16;
  const STEM_R = 0.013, STEM_TOP = 1.44;
  const SHADE_H = 0.30, SHADE_BOT = 0.18, SHADE_TOP = 0.11;

  add(new THREE.CylinderGeometry(BASE_R, BASE_R, BASE_H, 7)
    .translate(0, BASE_H / 2, 0), METAL);

  add(new THREE.CylinderGeometry(STEM_R, STEM_R, STEM_TOP - BASE_H, 6)
    .translate(0, BASE_H + (STEM_TOP - BASE_H) / 2, 0), METAL);

  add(new THREE.CylinderGeometry(SHADE_TOP, SHADE_BOT, SHADE_H, 7)
    .translate(0, STEM_TOP + SHADE_H / 2, 0), SHADE);

  const group = new THREE.Group();
  group.name = 'floor-lamp';
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
