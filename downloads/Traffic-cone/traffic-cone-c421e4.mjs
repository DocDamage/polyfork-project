/*
 * Traffic-cone
 * https://polyfork.dev/asset/traffic-cone-c421e4
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './traffic-cone-c421e4.mjs';
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
 * OPTIONS  createAsset({ ... })
 *
 *   colorway  choice  'safety-orange' 'safety-orange' | 'hazard-red' | 'weathered'
 *   body      color   '#e58132'      any hex or THREE.Color
 *   band      color   '#f1f2ef'      any hex or THREE.Color
 *   bands     choice  'two'          'two' | 'one'
 *   height    range   0.5            0.45 to 0.75
 *
 * Every option is described in full at https://polyfork.dev/cdn/traffic-cone-c421e4-params.json
 *
 * SPECS  312 triangles, 1 material, 0.35 x 0.5 x 0.35 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'safety-orange': { body: '#e58132', band: '#f1f2ef' },
  'hazard-red':    { body: '#d13d34', band: '#f1f2ef' },
  'weathered':     { body: '#98443d', band: '#ddceb0' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'safety-orange', label: 'Colorway', icon: '🎨',
    options: ['safety-orange', 'hazard-red', 'weathered'],
    describe: 'Curated kit-palette scheme for the whole cone. safety-orange is the standard ' +
              'highway cone; hazard-red is a fire-lane variant; weathered is a sun-faded, ' +
              'grimy cone with cream tape. Sets body and band unless those are given explicitly.',
  },
  body: {
    type: 'color', default: '#e58132', label: 'Cone', icon: '🔶',
    describe: 'Albedo of the moulded plastic: cone, flare and base slab (the slab uses this ' +
              'value nudged 1/255 so it stays a separately addressable colour zone).',
  },
  band: {
    type: 'color', default: '#f1f2ef', label: 'Band', icon: '⬜',
    describe: 'Albedo of the reflective tape rings. Keep a large value gap from `body`; the ' +
              'bands are the only value break on the object.',
  },
  bands: {
    type: 'choice', default: 'two', label: 'Bands', icon: '🎗️',
    options: ['two', 'one'],
    describe: 'Number of reflective tape rings. "two" is the full-height highway cone shown ' +
              'in the references; "one" keeps only the lower ring (short-cone / work-zone look). ' +
              'Colour change only — the geometry is identical.',
  },
  height: {
    type: 'range', default: 0.50, min: 0.45, max: 0.75, label: 'Height', icon: '📏',
    describe: 'Overall cone height in metres. The base slab stays 0.35 m square and 0.035 m ' +
              'thick; only the cone above the flare stretches, and the two bands stay at ' +
              'their fixed fractions of the height (0.33-0.50H and 0.67-0.80H). ' +
              '0.50 = standard cone, 0.75 = tall motorway cone.',
  },
};

function nudge(hex) {
  const n = parseInt(String(hex).replace('#', ''), 16) & 0xffffff;
  const r = (n >> 16) & 255;
  return '#' + ((((r > 0 ? r - 1 : 1) << 16) | (n & 0xffff)) >>> 0).toString(16).padStart(6, '0');
}

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const body = p.body ?? cw.body;
  return {
    body,
    base: nudge(body),
    band: p.band ?? cw.band,
    bands: p.bands ?? params.bands.default,
    height: Math.min(params.height.max, Math.max(params.height.min, p.height ?? params.height.default)),
  };
}

function prep(geo, colorFn) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const pos = geo.attributes.position;
  const n = pos.count;
  const col = new Float32Array(n * 3);
  const c = new THREE.Color();
  for (let i = 0; i < n; i += 3) {
    const cy = (pos.getY(i) + pos.getY(i + 1) + pos.getY(i + 2)) / 3;
    c.set(colorFn(cy));
    for (let k = 0; k < 3; k++) {
      col[(i + k) * 3] = c.r; col[(i + k) * 3 + 1] = c.g; col[(i + k) * 3 + 2] = c.b;
    }
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, typeof p.c === 'function' ? p.c : () => p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const HALF = 0.175;
const CUT  = 0.058;
const BEV  = 0.012;
const BT   = 0.008;
const SLAB = 0.035;

const SEG   = 12;
const R_FOOT = 0.156;
const R_CONE = 0.098;
const Y_FOOT = 0.030;
const Y_CONE = 0.105;
const R_TIP  = 0.026;
const TIP_CH = 0.010;
const TIP_IN = 0.007;

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const H = P.height;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const a = HALF - BEV;
  const b = a - CUT;
  const outline = [[a, b], [b, a], [-b, a], [-a, b], [-a, -b], [-b, -a], [b, -a], [a, -b]];
  const shape = new THREE.Shape();
  shape.moveTo(outline[0][0], outline[0][1]);
  for (let i = 1; i < outline.length; i++) shape.lineTo(outline[i][0], outline[i][1]);
  shape.closePath();
  const slab = new THREE.ExtrudeGeometry(shape, {
    depth: SLAB - 2 * BT, bevelEnabled: true,
    bevelThickness: BT, bevelSize: BEV, bevelOffset: 0, bevelSegments: 1,
  });
  slab.rotateX(-Math.PI / 2).translate(0, BT, 0);
  add(slab, P.base);

  const rCone = (y) => R_CONE + (R_TIP - R_CONE) * (y - Y_CONE) / (H - Y_CONE);
  const profile = [];
  for (let i = 0; i <= 4; i++) {
    const y = Y_FOOT + (Y_CONE - Y_FOOT) * i / 4;
    const t = (Y_CONE - y) / (Y_CONE - Y_FOOT);
    profile.push([y, R_CONE + (R_FOOT - R_CONE) * Math.pow(t, 1.6)]);
  }

  for (const y of [0.33 * H, 0.50 * H, 0.67 * H, 0.80 * H, H - TIP_CH]) profile.push([y, rCone(y)]);
  const rTop = rCone(H - TIP_CH) - TIP_IN;
  profile.push([H, rTop]);

  const lathe = new THREE.LatheGeometry(profile.map(([y, r]) => new THREE.Vector2(r, y)), SEG);
  lathe.rotateY(Math.PI / SEG);

  const bandRanges = P.bands === 'one'
    ? [[0.33 * H, 0.50 * H]]
    : [[0.33 * H, 0.50 * H], [0.67 * H, 0.80 * H]];
  const coneColor = (y) => (bandRanges.some(([lo, hi]) => y > lo && y < hi) ? P.band : P.body);
  add(lathe, coneColor);

  const cap = new THREE.CircleGeometry(rTop, SEG);
  cap.rotateX(-Math.PI / 2);
  cap.rotateY(-Math.PI / 2 + Math.PI / SEG);
  cap.translate(0, H, 0);
  add(cap, P.body);

  const g = new THREE.Group();
  g.name = 'traffic-cone';
  const mesh = finish(parts);
  mesh.name = 'cone';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;
