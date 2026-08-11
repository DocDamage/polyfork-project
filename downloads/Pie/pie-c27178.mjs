/*
 * Pie
 * https://polyfork.dev/asset/pie-c27178
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pie-c27178.mjs';
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
 * SPECS  256 triangles, 1 material, 0.26 x 0.08 x 0.25 m (real-world scale).
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

const CRUST = 0xd9a24a;
const CHERRY = 0x8e2323;
const TIN = 0xb4b9c0;

const R_TOP = 0.112;

const R_BOT = 0.088;
const H_TIN = 0.05;
const R_FILL = 0.098;

function createAsset() {

  add(new THREE.CylinderGeometry(R_TOP, R_BOT, H_TIN, 8, 1, false)
    .translate(0, H_TIN / 2, 0), TIN);

  add(new THREE.CylinderGeometry(R_FILL, R_FILL, 0.022, 8, 1, false)
    .translate(0, 0.063, 0), CHERRY);

  add(new THREE.TorusGeometry(0.112, 0.019, 6, 10)
    .rotateX(Math.PI / 2).translate(0, 0.0645, 0), CRUST);

  const LEN = 0.200, W = 0.019, T = 0.007;
  const Y = [0.0725, 0.0745];
  for (const dir of [0, 1]) {
    for (const off of [-0.052, 0, 0.052]) {
      const g = new THREE.BoxGeometry(LEN, T, W);
      if (dir === 1) g.rotateY(Math.PI / 2);
      g.translate(dir === 0 ? 0 : off, Y[dir], dir === 0 ? off : 0);
      add(g, CRUST);
    }
  }

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export default createAsset;
export const rig = {};
export const detach = [];
