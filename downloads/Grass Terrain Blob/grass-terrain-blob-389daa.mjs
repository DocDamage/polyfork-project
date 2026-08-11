/*
 * Grass Terrain Blob
 * https://polyfork.dev/asset/grass-terrain-blob-389daa
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './grass-terrain-blob-389daa.mjs';
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
 * SPECS  140 triangles, 1 material, 8.11 x 0.08 x 6 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const C_GRASS = new THREE.Color('#7d8a5a');
const C_SOIL  = new THREE.Color('#8c6a4a');

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'grass-terrain-blob';

  const pos = [];
  const col = [];
  const pushTri = (a, b, c, color) => {
    pos.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    for (let k = 0; k < 3; k++) col.push(color.r, color.g, color.b);
  };
  const pushQuad = (a, b, c, d, color) => { pushTri(a, b, c, color); pushTri(a, c, d, color); };

  const NA = 14;
  const RX = 4.1;
  const SQUASH = 0.76;
  const TOP = 0.05;
  const randO = prng(23);
  const outR = [];
  for (let i = 0; i < NA; i++) {

    const a = (i / NA) * Math.PI * 2;
    const lobes = 1.0 + 0.10 * Math.sin(3 * a + 0.7) + 0.055 * Math.sin(5 * a + 2.1);
    outR.push(Math.max(0.82, Math.min(1.04, lobes + (randO() - 0.5) * 0.06)));
  }
  const ang = (i) => (i / NA) * Math.PI * 2;
  const outXZ = (i, frac = 1) => {
    const a = ang(i), r = RX * outR[i] * frac;
    return [Math.cos(a) * r, Math.sin(a) * r * SQUASH];
  };

  const relief = (x, z) =>
    0.020 * Math.sin(x * 0.9 + 0.4) * Math.cos(z * 1.1 - 0.7)
    + 0.011 * Math.sin(x * 1.7 - z * 0.8 + 1.3);

  const ringFracs = [0.34, 0.63, 0.85, 1.0];
  const center = [0, TOP + relief(0, 0), 0];
  const rings = ringFracs.map((f, ri) => {
    const arr = [];
    for (let i = 0; i < NA; i++) {
      const [x, z] = outXZ(i, f);

      const y = ri === ringFracs.length - 1 ? TOP : TOP + relief(x, z);
      arr.push([x, y, z]);
    }
    return arr;
  });

  for (let i = 0; i < NA; i++) {
    pushTri(center, rings[0][(i + 1) % NA], rings[0][i], C_GRASS);
  }

  for (let r = 0; r < rings.length - 1; r++) {
    for (let i = 0; i < NA; i++) {
      const j = (i + 1) % NA;
      const a = rings[r][i], b = rings[r][j];
      const cc = rings[r + 1][j], d = rings[r + 1][i];
      pushTri(a, b, cc, C_GRASS); pushTri(a, cc, d, C_GRASS);
    }
  }

  const rim = rings[rings.length - 1];
  const baseInset = 0.94;
  const base = [];
  for (let i = 0; i < NA; i++) {
    const [x, z] = outXZ(i, baseInset);
    base.push([x, 0, z]);
  }

  const soilSeg = new Set([2, 8]);
  for (let i = 0; i < NA; i++) {
    const j = (i + 1) % NA;
    pushQuad(rim[i], rim[j], base[j], base[i], soilSeg.has(i) ? C_SOIL : C_GRASS);
  }

  const bottomCenter = [0, 0, 0];
  for (let i = 0; i < NA; i++) {
    pushTri(bottomCenter, base[i], base[(i + 1) % NA], C_SOIL);
  }

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  geo.computeBoundingBox();
  geo.translate(0, -geo.boundingBox.min.y, 0);

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'blob-mesh';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export default createAsset;
