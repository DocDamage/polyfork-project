/*
 * Headphones
 * https://polyfork.dev/asset/headphones-d3e940
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './headphones-d3e940.mjs';
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
 * SPECS  146 triangles, 1 material, 0.23 x 0.15 x 0.09 m (real-world scale).
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

const DARK = '#23262b';
const PAD  = '#c8ccd2';

export function createAsset() {
  const HALF = 0.088;
  const CUP_R = 0.046;
  const CUP_L = 0.028;
  const CUP_Y = -0.008;

  const band = new THREE.TorusGeometry(HALF, 0.013, 3, 7, Math.PI);
  add(band, DARK);

  for (const s of [1, -1]) {
    const x = s * HALF;

    const shell = new THREE.CylinderGeometry(CUP_R, CUP_R, CUP_L, 7)
      .rotateZ(Math.PI / 2).translate(x, CUP_Y, 0);
    add(shell, DARK);

    const outer = x + s * (CUP_L / 2 + 0.006);
    const pad = new THREE.CylinderGeometry(0.031, 0.031, 0.012, 6)
      .rotateZ(Math.PI / 2).translate(outer, CUP_Y, 0);
    add(pad, PAD);
  }

  const mesh = finish(parts);

  const g = new THREE.Group();
  g.add(mesh);
  const box = new THREE.Box3().setFromObject(g);
  const c = box.getCenter(new THREE.Vector3());
  mesh.position.set(-c.x, -box.min.y, -c.z);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
