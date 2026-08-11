/*
 * Ice Cream Cone
 * https://polyfork.dev/asset/ice-cream-cone-9d3d4b
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './ice-cream-cone-9d3d4b.mjs';
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
 * SPECS  62 triangles, 1 material, 0.08 x 0.21 x 0.08 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CONE  = 0xc8862f;
const SCOOP = 0xf49abf;
const CHERRY= 0xcf1f2b;
const STEM  = 0x5a3a1c;

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

  const CONE_H = 0.10, TOP_R = 0.036;
  const cone = new THREE.ConeGeometry(TOP_R, CONE_H, 7)
    .rotateX(Math.PI)
    .translate(0, CONE_H / 2, 0);
  add(cone, CONE);

  const SCOOP_R = 0.049;
  const scoopY = CONE_H + SCOOP_R * 0.52;
  const scoop = new THREE.IcosahedronGeometry(SCOOP_R, 0)
    .translate(0, scoopY, 0);
  add(scoop, SCOOP);

  const CHERRY_R = 0.014;
  const cherryY = scoopY + SCOOP_R + CHERRY_R * 0.05;
  const cherry = new THREE.IcosahedronGeometry(CHERRY_R, 0)
    .translate(0, cherryY, 0);
  add(cherry, CHERRY);

  const stem = new THREE.CylinderGeometry(0.0018, 0.0026, 0.028, 4, 1, true)
    .translate(0, 0.014, 0)
    .rotateZ(0.32)
    .translate(0.004, cherryY + CHERRY_R * 0.6, 0);
  add(stem, STEM);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};
