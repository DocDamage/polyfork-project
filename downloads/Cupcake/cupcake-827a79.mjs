/*
 * Cupcake
 * https://polyfork.dev/asset/cupcake-827a79
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cupcake-827a79.mjs';
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
 * SPECS  154 triangles, 1 material, 0.07 x 0.11 x 0.07 m (real-world scale).
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

const C = {
  paper: 0xd9506a,
  cream: 0xfff1d6,
  cherry: 0xc1272d,
  stem: 0x6b4226,
};

function wrapper() {
  const g = new THREE.CylinderGeometry(0.034, 0.024, 0.032, 16, 1, false);
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), z = pos.getZ(i);
    const r = Math.hypot(x, z);
    if (r < 1e-6) continue;
    const seg = Math.round(Math.atan2(z, x) / (Math.PI * 2) * 16);
    const s = (seg % 2 === 0) ? 1.0 : 0.9;
    pos.setX(i, x * s); pos.setZ(i, z * s);
  }
  g.translate(0, 0.016, 0);
  return g;
}

function frosting() {
  const blobs = [
    { r: 0.037, sy: 0.55, p: [0.000, 0.040, 0.000] },
    { r: 0.028, sy: 0.60, p: [0.006, 0.058, -0.003] },
    { r: 0.018, sy: 0.65, p: [-0.003, 0.073, 0.004] },
  ];
  for (const b of blobs) {
    const g = new THREE.IcosahedronGeometry(b.r, 0);
    g.scale(1, b.sy, 1);
    g.translate(...b.p);
    add(g, C.cream);
  }
}

function cherry() {
  const g = new THREE.IcosahedronGeometry(0.012, 0);
  g.translate(0.001, 0.088, 0.001);
  add(g, C.cherry);
  const s = new THREE.CylinderGeometry(0.0018, 0.0018, 0.014, 5, 1, true);
  s.rotateZ(0.3);
  s.translate(0.003, 0.103, 0.001);
  add(s, C.stem);
}

export function createAsset() {
  add(wrapper(), C.paper);
  frosting();
  cherry();
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];
