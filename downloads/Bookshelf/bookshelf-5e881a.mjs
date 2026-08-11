/*
 * Bookshelf
 * https://polyfork.dev/asset/bookshelf-5e881a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './bookshelf-5e881a.mjs';
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
 * SPECS  120 triangles, 1 material, 0.44 x 0.4 x 0.2 m (real-world scale).
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

const box = (w, h, d, x, y, z) => new THREE.BoxGeometry(w, h, d).translate(x, y, z);

const WOOD  = 0x9a5f34;
const RED   = 0xd23b2c;
const TEAL  = 0x239b8b;
const GOLD  = 0xe8b23a;

export function createAsset() {

  const W = 0.44, H = 0.40, D = 0.20, t = 0.025;
  const half = W / 2 - t / 2;
  const innerW = W - 2 * t;

  add(box(t, H, D, -half, H / 2, 0), WOOD);
  add(box(t, H, D,  half, H / 2, 0), WOOD);
  add(box(innerW, t, D, 0, t / 2, 0), WOOD);
  add(box(innerW, t, D, 0, H - t / 2, 0), WOOD);
  add(box(innerW, H - 2 * t, 0.02, 0, H / 2, -D / 2 + 0.01), WOOD);

  const floorY = t;
  const book = (cx, w, h, d, cz, leanDeg, color) => {
    const g = new THREE.BoxGeometry(w, h, d)
      .translate(0, h / 2, 0)
      .rotateZ(leanDeg * Math.PI / 180)
      .translate(cx, floorY, cz);
    add(g, color);
  };

  book(-0.150, 0.052, 0.30, 0.150,  0.005,   0, RED);
  book(-0.098, 0.056, 0.28, 0.140, -0.010,  -6, TEAL);
  book(-0.042, 0.050, 0.31, 0.155,  0.008, -13, GOLD);
  book( 0.022, 0.052, 0.29, 0.145, -0.006, -19, RED);
  book( 0.072, 0.056, 0.28, 0.150,  0.006, -22, TEAL);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
