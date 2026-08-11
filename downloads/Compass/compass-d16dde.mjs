/*
 * Compass
 * https://polyfork.dev/asset/compass-d16dde
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './compass-d16dde.mjs';
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
 * SPECS  86 triangles, 1 material, 0.05 x 0.06 x 0.09 m (real-world scale).
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
    vertexColors: true, flatShading: true, roughness: 0.7, metalness: 0.1,
  }));
}
function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const BRASS = '#c9a24b';
const FACE  = '#f4efe2';
const RED   = '#cf3b2e';
const NAVY  = '#24344f';

const R      = 0.028;
const CASE_H = 0.014;
const TOP    = CASE_H;
const SIDES  = 7;

add(new THREE.CylinderGeometry(R, R, CASE_H, SIDES).translate(0, CASE_H/2, 0), BRASS);

add(new THREE.CircleGeometry(R * 0.86, SIDES).rotateX(-Math.PI/2).translate(0, TOP + 0.0004, 0), FACE);

const yN = TOP + 0.0012;
const cN = [0, yN, 0], Nt = [0, yN, R*0.80], St = [0, yN, -R*0.80];
const Wm = [-R*0.15, yN, 0], Em = [R*0.15, yN, 0];
{ const p = []; tri(p, cN, Nt, Em); tri(p, cN, Wm, Nt); add(posGeo(p), RED); }
{ const p = []; tri(p, cN, St, Wm); tri(p, cN, Em, St); add(posGeo(p), NAVY); }

add(new THREE.BoxGeometry(0.013, 0.005, 0.006).translate(0, TOP, -R), BRASS);

const LID_TH = 0.004, OPEN = 2 * Math.PI / 3;
function placeLid(g) {
  g.translate(0, 0, R);
  g.rotateX(-OPEN);
  g.translate(0, TOP, -R);
  return g;
}
add(placeLid(new THREE.CylinderGeometry(R, R, LID_TH, SIDES)), BRASS);

add(placeLid(new THREE.CircleGeometry(R * 0.82, SIDES).rotateX(Math.PI/2).translate(0, -LID_TH/2 - 0.0004, 0)), FACE);

export function createAsset() {
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}
export const rig = {};
export const detach = [];

export const night = {};
