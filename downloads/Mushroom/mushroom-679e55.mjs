/*
 * Mushroom
 * https://polyfork.dev/asset/mushroom-679e55
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './mushroom-679e55.mjs';
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
 * SPECS  112 triangles, 1 material, 0.11 x 0.1 x 0.11 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED   = '#d02a1e';
const CREAM = '#f2e7cf';
const WHITE = '#ffffff';

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
  const g = new THREE.Group();

  const capR   = 0.055;
  const capH   = 0.042;
  const stemH  = 0.055;
  const stemRt = 0.016;
  const stemRb = 0.024;

  const stemTopY = stemH;
  const capBaseY = stemTopY - 0.004;

  const stem = new THREE.CylinderGeometry(stemRt, stemRb, stemH, 7)
    .translate(0, stemH / 2, 0);
  add(stem, CREAM);

  const thetaEnd = Math.PI * 0.52;
  const cap = new THREE.SphereGeometry(capR, 9, 3, 0, Math.PI * 2, 0, thetaEnd);
  cap.scale(1, capH / capR, 1);
  cap.translate(0, capBaseY, 0);
  add(cap, RED);

  const rimR = capR * Math.sin(thetaEnd);
  const rimY = capBaseY + capH * Math.cos(thetaEnd);
  const under = new THREE.CircleGeometry(rimR, 9)
    .rotateX(Math.PI / 2)
    .rotateY(Math.PI)
    .translate(0, rimY, 0);
  add(under, CREAM);

  const spotDefs = [

    [0.4,  0.28, 0.017],
    [1.7,  0.58, 0.015],
    [3.0,  0.42, 0.016],
    [4.2,  0.60, 0.014],
    [5.5,  0.50, 0.015],
  ];
  for (const [az, pol, sr] of spotDefs) {
    const theta = pol * Math.PI * 0.5;
    const dir = new THREE.Vector3(
      Math.sin(theta) * Math.cos(az),
      Math.cos(theta),
      Math.sin(theta) * Math.sin(az),
    );

    const surf = new THREE.Vector3(dir.x * capR, dir.y * capH, dir.z * capR);
    const normal = new THREE.Vector3(surf.x / (capR*capR), surf.y / (capH*capH), surf.z / (capR*capR)).normalize();
    const pos = surf.clone().addScaledVector(normal, 0.001);
    pos.y += capBaseY;

    const spot = new THREE.CircleGeometry(sr, 6);

    const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 0, 1), normal);
    spot.applyQuaternion(q);
    spot.translate(pos.x, pos.y, pos.z);
    add(spot, WHITE);
  }

  const mesh = finish(parts);
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
