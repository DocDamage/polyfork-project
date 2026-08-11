/*
 * Hot Air Balloon
 * https://polyfork.dev/asset/hot-air-balloon-a2a511
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './hot-air-balloon-a2a511.mjs';
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
 * SPECS  138 triangles, 1 material, 1.56 x 2.61 x 1.56 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CREAM = 0xf2e6cf;
const RED   = 0xd83f2c;
const WOOD  = 0x8a5a30;
const DARK  = 0x2f2419;

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const NECK_Y = 0.87;
  const GORES = 8;

  const profile = [
    new THREE.Vector2(0.15, 0.00),
    new THREE.Vector2(0.50, 0.25),
    new THREE.Vector2(0.78, 0.62),
    new THREE.Vector2(0.76, 1.02),
    new THREE.Vector2(0.58, 1.38),
    new THREE.Vector2(0.32, 1.62),
    new THREE.Vector2(0.00, 1.74),
  ];
  for (let i = 0; i < GORES; i++) {
    const g = new THREE.LatheGeometry(profile, 1, i * (2 * Math.PI / GORES), 2 * Math.PI / GORES);
    g.translate(0, NECK_Y, 0);
    add(g, i % 2 ? RED : CREAM);
  }

  const cap = new THREE.CircleGeometry(0.16, 6).rotateX(Math.PI / 2).translate(0, NECK_Y, 0);
  add(cap, DARK);

  const BW = 0.40, BH = 0.34;
  add(new THREE.BoxGeometry(BW, BH, BW).translate(0, BH / 2, 0), WOOD);

  const cordTop = NECK_Y, cordBot = BH;
  const cordH = cordTop - cordBot, cordR = 0.19;
  for (let i = 0; i < 4; i++) {
    const a = Math.PI / 4 + i * Math.PI / 2;
    add(new THREE.CylinderGeometry(0.02, 0.02, cordH, 3, 1, true)
      .translate(Math.cos(a) * cordR, cordBot + cordH / 2, Math.sin(a) * cordR), DARK);
  }

  return finish(parts);
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
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
