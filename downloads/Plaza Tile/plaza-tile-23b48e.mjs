/*
 * Plaza Tile
 * https://polyfork.dev/asset/plaza-tile-23b48e
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './plaza-tile-23b48e.mjs';
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
 * SPECS  294 triangles, 1 material, 4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;
const THICK = 0.05;
const TOP_Y = 0.0;
const N = 4;
const PITCH = SIZE / N;

const BASE_TOP = TOP_Y - 0.036;
const BED_TOP = TOP_Y - 0.022;

const TOP_INSET = 0.020;
const BOT_INSET = 0.006;

const RAMP = 0.05;
const CHIP = 0.22;

const KIT_STONE = 0xb5aea0;
const COL = {
  slate: 0x3f4247,
  stone: KIT_STONE,
  dark: shade(KIT_STONE, 0.78),

  mortar: shade(KIT_STONE, 0.62),
};

const parts = [];
const add = (g, c) => parts.push({ g, c });

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
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

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function shade(hex, f) {
  const ch = (s) => Math.max(0, Math.min(255, Math.round(((hex >> s) & 255) * f)));
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

function clipCorner(pts, k, d) {
  const n = pts.length;
  const p = pts[k], a = pts[(k - 1 + n) % n], b = pts[(k + 1) % n];
  const towards = (q) => {
    const dx = q[0] - p[0], dz = q[1] - p[1], L = Math.hypot(dx, dz);
    return [p[0] + dx / L * d, p[1] + dz / L * d];
  };
  const out = pts.slice();
  out.splice(k, 1, towards(a), towards(b));
  return out;
}

function paverOutline(i, j, inset) {
  const x0 = -SIZE / 2 + i * PITCH, x1 = x0 + PITCH;
  const z0 = -SIZE / 2 + j * PITCH, z1 = z0 + PITCH;
  const bxn = i === 0, bxp = i === N - 1, bzn = j === 0, bzp = j === N - 1;
  const X0 = x0 + inset, X1 = x1 - inset, Z0 = z0 + inset, Z1 = z1 - inset;

  const C = [
    { bx: bxn, bz: bzp, ox: x0, oz: z1, ix: X0, iz: Z1, rx: x0 + RAMP, rz: z1 - RAMP, xLast: true },
    { bx: bxp, bz: bzp, ox: x1, oz: z1, ix: X1, iz: Z1, rx: x1 - RAMP, rz: z1 - RAMP, xLast: false },
    { bx: bxp, bz: bzn, ox: x1, oz: z0, ix: X1, iz: Z0, rx: x1 - RAMP, rz: z0 + RAMP, xLast: true },
    { bx: bxn, bz: bzn, ox: x0, oz: z0, ix: X0, iz: Z0, rx: x0 + RAMP, rz: z0 + RAMP, xLast: false },
  ];
  const pts = [];
  for (const c of C) {
    const corner = [c.ox, c.oz];
    if (c.bx && !c.bz) {
      const r = [c.rx, c.iz];
      pts.push(...(c.xLast ? [corner, r] : [r, corner]));
    } else if (c.bz && !c.bx) {
      const r = [c.ix, c.rz];
      pts.push(...(c.xLast ? [r, corner] : [corner, r]));
    } else if (c.bx && c.bz) pts.push(corner);
    else pts.push([c.ix, c.iz]);
  }
  return pts;
}

function paver(i, j, chip) {
  let rt = paverOutline(i, j, TOP_INSET), rb = paverOutline(i, j, BOT_INSET);
  if (chip !== undefined) {
    rt = clipCorner(rt, chip, CHIP);
    rb = clipCorner(rb, chip, CHIP);
  }
  const T = rt.map(p => [p[0], TOP_Y, p[1]]);
  const B = rb.map(p => [p[0], BED_TOP, p[1]]);

  const pos = [];
  const n = T.length;
  for (let k = 0; k < n; k++) quad(pos, T[k], B[k], B[(k + 1) % n], T[(k + 1) % n]);

  const cx = T.reduce((s, p) => s + p[0], 0) / n, cz = T.reduce((s, p) => s + p[2], 0) / n;
  const mid = [cx, TOP_Y, cz];
  for (let k = 0; k < n; k++) tri(pos, mid, T[k], T[(k + 1) % n]);
  return posGeo(pos);
}

const CHIPPED = { '1,2': 2, '2,0': 0 };

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'plaza-tile';
  parts.length = 0;

  const baseH = BASE_TOP - (TOP_Y - THICK);
  add(new THREE.BoxGeometry(SIZE, baseH, SIZE).translate(0, BASE_TOP - baseH / 2, 0), COL.slate);
  add(new THREE.BoxGeometry(SIZE, BED_TOP - BASE_TOP, SIZE)
    .translate(0, (BED_TOP + BASE_TOP) / 2, 0), COL.mortar);

  for (let j = 0; j < N; j++) {
    for (let i = 0; i < N; i++) {
      const dark = (i + j) % 2 === 0;
      add(paver(i, j, CHIPPED[`${i},${j}`]), dark ? COL.dark : COL.stone);
    }
  }

  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];
export default createAsset;
