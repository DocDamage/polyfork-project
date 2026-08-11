/*
 * Hammer
 * https://polyfork.dev/asset/hammer-fa3e51
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './hammer-fa3e51.mjs';
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
 * SPECS  112 triangles, 1 material, 0.19 x 0.32 x 0.04 m (real-world scale).
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

const WOOD  = '#9a6533';
const STEEL = '#8b929c';
const DARK  = '#5f656e';

export function createAsset() {
  const HEAD_Y = 0.30;

  const handle = new THREE.CylinderGeometry(0.0135, 0.017, 0.31, 8)
    .translate(0, 0.31 / 2, 0);
  add(handle, WOOD);

  add(new THREE.BoxGeometry(0.055, 0.036, 0.034).translate(0, HEAD_Y, 0), DARK);

  const face = new THREE.CylinderGeometry(0.019, 0.016, 0.05, 8)
    .rotateZ(-Math.PI / 2)
    .translate(0.026 + 0.05 / 2, HEAD_Y, 0);
  add(face, STEEL);

  const P = [
    [-0.020,  0.018],
    [-0.060,  0.014],
    [-0.094, -0.008],
    [-0.110, -0.052],
    [-0.086, -0.026],
    [-0.078, -0.014],
    [-0.064, -0.030],
    [-0.056, -0.050],
    [-0.040, -0.022],
    [-0.024, -0.012],
  ];
  const shape = new THREE.Shape();
  shape.moveTo(P[0][0], P[0][1]);
  for (let i = 1; i < P.length; i++) shape.lineTo(P[i][0], P[i][1]);
  shape.closePath();
  const claw = new THREE.ExtrudeGeometry(shape, {
    depth: 0.024, bevelEnabled: false,
  }).translate(0, HEAD_Y, -0.012);
  add(claw, STEEL);

  const g = new THREE.Group();
  g.name = 'claw-hammer';
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
