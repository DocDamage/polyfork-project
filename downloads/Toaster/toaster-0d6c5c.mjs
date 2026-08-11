/*
 * Toaster
 * https://polyfork.dev/asset/toaster-0d6c5c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './toaster-0d6c5c.mjs';
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
 * SPECS  136 triangles, 1 material, 0.32 x 0.23 x 0.17 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const RED  = '#d6382b';
const DARK = '#242424';
const TOAST = '#d79b46';

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
    vertexColors: true, flatShading: true, roughness: 0.7, metalness: 0,
  }));
}

function toasterProfile(w, h, r) {
  const s = new THREE.Shape();
  const hw = w / 2;
  s.moveTo(-hw, 0);
  s.lineTo(hw, 0);
  s.lineTo(hw, h - r);
  s.absarc(hw - r, h - r, r, 0, Math.PI / 2, false);
  s.lineTo(-hw + r, h);
  s.absarc(-hw + r, h - r, r, Math.PI / 2, Math.PI, false);
  s.lineTo(-hw, 0);
  return s;
}

export function createAsset() {
  const g = new THREE.Group();

  const W = 0.30;
  const H = 0.17;
  const D = 0.16;
  const R = 0.055;

  const body = new THREE.ExtrudeGeometry(toasterProfile(W, H, R), {
    depth: D, bevelEnabled: false, curveSegments: 2,
  });
  body.translate(0, 0, -D / 2);
  add(body, RED);

  const slotW = 0.055;
  const slotL = 0.11;
  const slotDepth = 0.03;
  const topY = H;
  const slotOffX = 0.065;
  for (const sx of [-slotOffX, slotOffX]) {
    const slot = new THREE.BoxGeometry(slotW, slotDepth, slotL)
      .translate(sx, topY - slotDepth / 2 + 0.006, 0);
    add(slot, DARK);
  }

  function breadProfile(bw, bh, br) {
    const s = new THREE.Shape();
    const hw = bw / 2;
    s.moveTo(-hw, 0);
    s.lineTo(hw, 0);
    s.lineTo(hw, bh - br);
    s.absarc(hw - br, bh - br, br, 0, Math.PI / 2, false);
    s.lineTo(-hw + br, bh);
    s.absarc(-hw + br, bh - br, br, Math.PI / 2, Math.PI, false);
    s.lineTo(-hw, 0);
    return s;
  }
  const breadW = 0.10;
  const breadH = 0.085;
  const breadThick = 0.03;
  const breadBaseY = topY - 0.02;
  for (const sx of [-slotOffX, slotOffX]) {
    const bread = new THREE.ExtrudeGeometry(breadProfile(breadW, breadH, 0.04), {
      depth: breadThick, bevelEnabled: false, curveSegments: 1,
    });

    bread.rotateY(Math.PI / 2);
    bread.translate(sx - breadThick / 2, breadBaseY, 0);
    add(bread, TOAST);
  }

  const lever = new THREE.BoxGeometry(0.028, 0.055, 0.03)
    .translate(W / 2 + 0.004, H * 0.55, D / 2 - 0.006);
  add(lever, DARK);

  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
