/*
 * Broccoli
 * https://polyfork.dev/asset/broccoli-69c8b6
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './broccoli-69c8b6.mjs';
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
 * SPECS  140 triangles, 1 material, 0.18 x 0.16 x 0.16 m (real-world scale).
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

const STALK = '#d8e5a8';
const DARK  = '#2b6127';
const MID   = '#4f9a35';

function floret(r, x, y, z, rot, squash = 0.74) {
  const g = new THREE.IcosahedronGeometry(r, 0);
  g.scale(1, squash, 1);
  g.rotateY(rot);
  g.rotateX(rot * 0.37);
  return g.translate(x, y, z);
}

export function createAsset() {
  const group = new THREE.Group();

  add(new THREE.CylinderGeometry(0.040, 0.048, 0.062, 5).translate(0, 0.031, 0), STALK);

  const R = 0.048, rSide = 0.046;
  const sideRot = [0.7, 1.9, 3.1, 4.4, 5.6];
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * Math.PI * 2 + 0.3;
    add(floret(rSide, Math.cos(a) * R, 0.088, Math.sin(a) * R, sideRot[i]), DARK);
  }
  add(floret(0.061, 0, 0.121, 0, 0.0), MID);

  const mesh = finish(parts);
  parts.length = 0;
  mesh.castShadow = mesh.receiveShadow = true;
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
