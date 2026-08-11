/*
 * Pineapple
 * https://polyfork.dev/asset/pineapple-bb287a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pineapple-bb287a.mjs';
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
 * SPECS  140 triangles, 1 material, 0.24 x 0.52 x 0.25 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const GOLD = 0xE7A22E;
const GOLD_D = 0xC77E1C;
const GREEN = 0x4E9C3A;
const GREEN_D = 0x3C7A2C;

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
  const group = new THREE.Group();
  group.name = 'pineapple';

  const H = 0.30;
  const prof = [
    [0.000, 0.000],
    [0.078, 0.035],
    [0.096, 0.130],
    [0.082, 0.235],
    [0.050, 0.300],
    [0.000, 0.300],

  ];

  const pv = prof.map(([r, y]) => new THREE.Vector2(r, y));
  for (let i = 0; i < pv.length - 1; i++) {
    const seg = new THREE.LatheGeometry([pv[i], pv[i + 1]], 8);
    add(seg, i % 2 === 0 ? GOLD : GOLD_D);
  }

  function leaf(len, rad, tiltDeg, azDeg) {
    const g = new THREE.ConeGeometry(rad, len, 3);
    g.translate(0, len / 2, 0);
    g.scale(1, 1, 0.45);
    g.rotateZ(THREE.MathUtils.degToRad(tiltDeg));
    g.rotateY(THREE.MathUtils.degToRad(azDeg));
    g.translate(0, 0.295, 0);
    return g;
  }

  for (let i = 0; i < 6; i++) {
    add(leaf(0.19, 0.026, 42, (i / 6) * 360 + 20, GREEN), GREEN);
  }

  for (let i = 0; i < 3; i++) {
    add(leaf(0.24, 0.024, 18, (i / 3) * 360 + 40, GREEN_D), GREEN_D);
  }

  add(leaf(0.20, 0.022, 0, 0, GREEN), GREEN);

  const mesh = finish(parts);
  mesh.name = 'pineapple';
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
