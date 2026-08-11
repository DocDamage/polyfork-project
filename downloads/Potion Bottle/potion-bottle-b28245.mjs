/*
 * Potion Bottle
 * https://polyfork.dev/asset/potion-bottle-b28245
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './potion-bottle-b28245.mjs';
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
 * SPECS  119 triangles, 1 material, 0.17 x 0.26 x 0.17 m (real-world scale).
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

const LIQUID = '#3df06a';
const GLASS  = '#bfe6f0';
const CORK   = '#8a5a32';

const R = 0.09;
const CY = R;
const RAD = 7;
const TOP_ANG =  70 * Math.PI/180;
const LIQ_ANG =  18 * Math.PI/180;

const pt = (ang) => new THREE.Vector2(R * Math.cos(ang), CY + R * Math.sin(ang));

{
  const pts = [];
  const a0 = -Math.PI/2, a1 = LIQ_ANG, n = 3;
  for (let i = 0; i <= n; i++) pts.push(pt(a0 + (a1 - a0) * i / n));
  add(new THREE.LatheGeometry(pts, RAD), LIQUID);

  const surfR = R * Math.cos(LIQ_ANG), surfY = CY + R * Math.sin(LIQ_ANG);
  add(new THREE.CircleGeometry(surfR, RAD).rotateX(-Math.PI/2).translate(0, surfY, 0), LIQUID);
}

{
  const pts = [];
  const a0 = LIQ_ANG, a1 = TOP_ANG, n = 2;
  for (let i = 0; i <= n; i++) pts.push(pt(a0 + (a1 - a0) * i / n));
  add(new THREE.LatheGeometry(pts, RAD), GLASS);
}
const neckR = R * Math.cos(TOP_ANG);
const neckTop = CY + R * Math.sin(TOP_ANG) + 0.06;
{
  const yBot = CY + R * Math.sin(TOP_ANG);
  const h = neckTop - yBot;
  add(new THREE.CylinderGeometry(neckR, neckR, h, RAD, 1, true)
        .translate(0, yBot + h/2, 0), GLASS);
}

{
  const h = 0.04, rBot = neckR * 1.05, rTop = neckR * 1.25;
  add(new THREE.CylinderGeometry(rTop, rBot, h, RAD)
        .translate(0, neckTop - 0.01 + h/2, 0), CORK);
}

export function createAsset() {
  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
