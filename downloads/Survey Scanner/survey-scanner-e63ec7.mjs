/*
 * Survey Scanner
 * https://polyfork.dev/asset/survey-scanner-e63ec7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './survey-scanner-e63ec7.mjs';
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
 * SPECS  144 triangles, 1 material, 0.2 x 0.2 x 0.07 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DARK  = '#3d3f47';
const STEEL = '#737785';
const CYAN  = '#7fe9e0';

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
function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function shapeEnd(g, edge, { taperX = 1, taperZ = 1, shiftX = 0 } = {}) {
  const p = g.attributes.position;
  for (let i = 0; i < p.count; i++) {
    if (Math.sign(p.getY(i)) === edge) {
      p.setX(i, p.getX(i) * taperX + shiftX);
      p.setZ(i, p.getZ(i) * taperZ);
    }
  }
  return g;
}

function hexBarrel(r, len, zSquash = 1) {
  return new THREE.CylinderGeometry(r, r, len, 6)
    .rotateZ(Math.PI / 2).rotateX(Math.PI / 6).scale(1, 1, zSquash);
}

export function createAsset() {

  const BC = 0.125;

  add(shapeEnd(new THREE.BoxGeometry(0.050, 0.100, 0.048), -1,
    { taperX: 0.9, taperZ: 0.9, shiftX: -0.022 }).translate(-0.010, 0.050, 0), DARK);
  add(box(0.050, 0.018, 0.048, -0.032, 0.009, 0), STEEL);
  add(hexBarrel(0.0462, 0.170, 0.823).translate(0, BC, 0), DARK);
  add(shapeEnd(new THREE.BoxGeometry(0.130, 0.036, 0.062), +1,
    { taperX: 0.9, taperZ: 0.78 }).translate(0.010, BC + 0.048, 0), STEEL);
  add(box(0.070, 0.008, 0.020, 0.010, BC + 0.067, 0), CYAN);
  add(new THREE.CylinderGeometry(0.034, 0.034, 0.016, 6)
    .rotateZ(Math.PI / 2).rotateX(Math.PI / 6).translate(0.091, BC, 0), DARK);
  add(new THREE.CylinderGeometry(0.026, 0.026, 0.018, 6)
    .rotateZ(Math.PI / 2).rotateX(Math.PI / 6).translate(0.098, BC, 0), CYAN);
  add(box(0.016, 0.030, 0.018, 0.035, 0.072, 0), DARK);
  add(box(0.010, 0.064, 0.064, -0.088, BC, 0), STEEL);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
