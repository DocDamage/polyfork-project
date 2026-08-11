/*
 * Traffic Cone
 * https://polyfork.dev/asset/traffic-cone-33e81e
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './traffic-cone-33e81e.mjs';
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
 *   colorway  choice  'taxi-yellow'  'taxi-yellow' | 'hazard-red' | 'weathered'
 *   body      color   '#e8a825'      any hex or THREE.Color
 *   band      color   '#ece5d3'      any hex or THREE.Color
 *   base      color   '#d2901f'      any hex or THREE.Color
 *   tallness  range   0.7            0.5 to 0.95
 *   facets    range   12             6 to 16
 *   bands     choice  'one'          'one' | 'two'
 *
 * Every option is described in full at https://polyfork.dev/cdn/traffic-cone-33e81e-params.json
 *
 * SPECS  200 triangles, 1 material, 0.56 x 0.7 x 0.56 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'taxi-yellow': { body: '#e8a825', band: '#ece5d3', base: '#d2901f' },
  'hazard-red':  { body: '#c7504d', band: '#cfc6b9', base: '#b63735' },
  'weathered':   { body: '#9a8472', band: '#cfc6b9', base: '#736e69' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'taxi-yellow', label: 'Colorway',
    options: ['taxi-yellow', 'hazard-red', 'weathered'],
    describe: 'Curated kit-palette scheme for the whole cone. taxi-yellow is the kit ' +
              'standard (yellow cone, off-white tape, slightly deeper yellow plate); ' +
              'hazard-red is a fire-lane cone in the kit brick reds; weathered is a ' +
              'sun-bleached grey-tan cone with a grubby cream band. Sets body, band and ' +
              'base unless those are passed explicitly.',
  },
  body: {
    type: 'color', default: '#e8a825', label: 'Cone',
    describe: 'Albedo of the moulded cone and its flared skirt — the dominant colour, ' +
              'about three quarters of the visible surface. Taxi yellow by default.',
  },
  band: {
    type: 'color', default: '#ece5d3', label: 'Band',
    describe: 'Albedo of the reflective tape collar. It is the only strong value break on ' +
              'the object, so keep it far lighter (or far darker) than `body`; a band ' +
              'close in value to the cone erases the identity feature.',
  },
  base: {
    type: 'color', default: '#d2901f', label: 'Base plate',
    describe: 'Albedo of the square ground plate. One value step down from `body` by ' +
              'default so the plate separates from the skirt at thumbnail size; set it ' +
              'equal to `body` for a single-moulding look, or to a dark grey for a ' +
              'rubber-weighted cone.',
  },
  tallness: {
    type: 'range', default: 0.70, min: 0.50, max: 0.95, label: 'Tallness',
    affects: 'geometry',
    describe: 'Overall height in metres. The plate (0.56 m square) and the flared skirt ' +
              'are moulded parts and stay fixed; only the straight taper above the skirt ' +
              'stretches, so the cone reads squat and wide at 0.50 and as a slim tall ' +
              'motorway cone at 0.95. The band keeps its fractions of the height.',
  },
  facets: {
    type: 'range', default: 12, min: 6, max: 16, step: 2, label: 'Facets',
    affects: 'geometry',
    describe: 'Number of flat vertical facets around the cone, snapped to an EVEN number ' +
              '(odd counts would break the bilateral symmetry the kit gate checks). 6 is ' +
              'a hard hexagonal prism-cone with very visible planes, 12 is the reference ' +
              'read, 16 is nearly round. Only the cone changes; the plate stays square.',
  },
  bands: {
    type: 'choice', default: 'one', label: 'Bands',
    options: ['one', 'two'], affects: 'geometry',
    describe: 'Reflective tape layout. "one" is the wide single collar of the reference ' +
              '(0.34H-0.58H). "two" splits it into a pair of narrower rings (0.26H-0.40H ' +
              'and 0.56H-0.68H) for a highway/motorway cone; the profile gains a ring pair ' +
              'so both variants keep dead-level band edges.',
  },
};

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const clamp = (v, s) => Math.min(s.max, Math.max(s.min, v ?? s.default));
  return {
    body: p.body ?? cw.body,
    band: p.band ?? cw.band,
    base: p.base ?? cw.base,
    height: clamp(p.tallness, params.tallness),

    seg: Math.max(6, Math.round(clamp(p.facets, params.facets) / 2) * 2),
    bands: p.bands === 'two' ? 'two' : 'one',
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
  if (!merged) throw new Error('traffic-cone: mergeGeometries returned null (attribute mismatch)');
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

const HALF  = 0.28;
const CUT   = 0.058;
const PLATE = 0.05;
const CH_W  = 0.016;
const CH_H  = 0.011;

const R_TIP  = 0.060;
const TIP_CH = 0.014;
const TIP_IN = 0.012;
const SLOPE  = 0.248;
const Y_SKIRT = 0.145;
const Y_FOOT  = 0.045;
const R_FOOT  = 0.222;

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const H = P.height;
  const SEG = P.seg;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const ring = (a, c) => [
    [-(a - c), a], [a - c, a], [a, a - c], [a, -(a - c)],
    [a - c, -a], [-(a - c), -a], [-a, -(a - c)], [-a, a - c],
  ];
  const lo = ring(HALF, CUT);
  const hi = ring(HALF - CH_W, CUT);
  const yShoulder = PLATE - CH_H;
  const pl = [];
  for (let i = 0; i < lo.length; i++) {
    const j = (i + 1) % lo.length;
    const [ax, az] = lo[i], [bx, bz] = lo[j];
    const [cx, cz] = hi[i], [dx, dz] = hi[j];
    quad(pl, [ax, 0, az], [bx, 0, bz], [bx, yShoulder, bz], [ax, yShoulder, az]);
    quad(pl, [ax, yShoulder, az], [bx, yShoulder, bz], [dx, PLATE, dz], [cx, PLATE, cz]);
  }
  for (let i = 1; i < lo.length - 1; i++) {
    tri(pl, [hi[0][0], PLATE, hi[0][1]], [hi[i][0], PLATE, hi[i][1]], [hi[i + 1][0], PLATE, hi[i + 1][1]]);
    tri(pl, [lo[0][0], 0, lo[0][1]], [lo[i + 1][0], 0, lo[i + 1][1]], [lo[i][0], 0, lo[i][1]]);
  }
  add(posGeo(pl), P.base);

  const rCone = (y) => R_TIP + SLOPE * (H - TIP_CH - y);
  const bandRanges = P.bands === 'two'
    ? [[0.26 * H, 0.40 * H], [0.56 * H, 0.68 * H]]
    : [[0.336 * H, 0.579 * H]];

  const profile = [];

  for (let i = 0; i <= 2; i++) {
    const y = Y_FOOT + (Y_SKIRT - Y_FOOT) * i / 2;
    const t = (Y_SKIRT - y) / (Y_SKIRT - Y_FOOT);
    profile.push([y, rCone(Y_SKIRT) + (R_FOOT - rCone(Y_SKIRT)) * Math.pow(t, 1.7)]);
  }
  for (const [b0, b1] of bandRanges) profile.push([b0, rCone(b0)], [b1, rCone(b1)]);
  profile.push([H - TIP_CH, R_TIP]);
  const rTop = R_TIP - TIP_IN;
  profile.push([H, rTop]);

  const lathe = new THREE.LatheGeometry(profile.map(([y, r]) => new THREE.Vector2(r, y)), SEG);
  lathe.rotateY(Math.PI / SEG);

  const coneColor = (y) => (bandRanges.some(([b0, b1]) => y > b0 && y < b1) ? P.band : P.body);
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
