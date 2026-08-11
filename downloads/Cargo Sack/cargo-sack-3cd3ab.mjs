/*
 * Cargo Sack
 * https://polyfork.dev/asset/cargo-sack-3cd3ab
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './cargo-sack-3cd3ab.mjs';
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
 *   colorway     choice  'burlap'       'burlap' | 'bleached-canvas' | 'coffee-brown' | 'sea-salt'
 *   burlap       color   '#C9975C'      any hex or THREE.Color
 *   rope         color   '#6B4526'      any hex or THREE.Color
 *   cargo        color   '#D9BE86'      any hex or THREE.Color
 *   plumpness    range   1              0.78 to 1.28
 *   tallness     range   1              0.82 to 1.24
 *   crownSpread  range   1              0.62 to 1.42
 *
 * Every option is described in full at https://polyfork.dev/cdn/cargo-sack-3cd3ab-params.json
 *
 * SPECS  444 triangles, 1 material, 0.38 x 0.7 x 0.39 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const DEG = Math.PI / 180;

const COLORWAYS = {
  'burlap': {
    burlap: '#C9975C', rope: '#6B4526', cargo: '#D9BE86',
  },
  'bleached-canvas': {
    burlap: '#DCCBA6', rope: '#8A8071', cargo: '#F0E6CE',
  },
  'coffee-brown': {
    burlap: '#9C6B3C', rope: '#4A2E1B', cargo: '#C4A46A',
  },
  'sea-salt': {
    burlap: '#A79680', rope: '#5A6462', cargo: '#E8D6A8',
  },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'burlap', label: 'Colorway',
    options: ['burlap', 'bleached-canvas', 'coffee-brown', 'sea-salt'],
    describe: 'Curated Pirate Cove schemes. "burlap" is the warm tan default sack; ' +
      '"bleached-canvas" is a pale sun-faded grain sack; "coffee-brown" is a dark ' +
      'roasted-bean sack; "sea-salt" is grey salt-crusted linen with white cargo.',
  },
  burlap: {
    type: 'color', default: '#C9975C', label: 'Burlap',
    describe: 'Albedo of the whole cloth sack — body, neck and the gathered crown. ' +
      'The dominant colour: it owns roughly three quarters of the surface, and the rope ' +
      'sits below it in value while the cargo sits above it.',
  },
  rope: {
    type: 'color', default: '#6B4526', label: 'Rope',
    describe: 'Albedo of the hemp tie ring at the neck. Should sit a clear value step ' +
      'below the burlap so the ring reads where it crosses in front of the body.',
  },
  cargo: {
    type: 'color', default: '#D9BE86', label: 'Cargo',
    describe: 'Albedo of the heaped contents mounded in the sack mouth — grain, salt, ' +
      'meal. Keep it LIGHTER than the burlap: the heap sits inside the crown and loses ' +
      'a value step to its own shading, so a darker tone reads as shadow, not cargo.',
  },
  plumpness: {
    type: 'range', default: 1.0, min: 0.78, max: 1.28, affects: 'geometry',
    label: 'Plumpness',
    describe: 'How full the sack is. Scales the belly and base-corner radii while the ' +
      'neck stays cinched. 0.78 is a slack half-empty sack with a narrow waist-to-base ' +
      'taper; 1.28 is a stuffed barrel-bellied sack whose corners splay far out.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.82, max: 1.24, affects: 'geometry',
    label: 'Tallness',
    describe: 'Height, by REBUILDING the cloth: the belly is a stack of fold courses at ' +
      'a constant 0.082 m pitch, and this knob changes how many there are (1 to 5, three ' +
      'at the default), so the mesh gains and loses rings of geometry rather than being ' +
      'stretched. Height therefore steps rather than glides: 0.54 m at 0.82 (a squat ' +
      'one-fold sack), 0.70 m at the default, 0.86 m at 1.24 (a tall five-fold sack). ' +
      'The splayed base, the rope section and the crown are built at the same size at ' +
      'every setting and simply ride up on the folds; girth stays near 0.38 m (the ' +
      'one-fold sack loses the widest belly ring, so it reads 0.35 m). Use plumpness, ' +
      'not this knob, to change how fat the sack is.',
  },
  crownSpread: {
    type: 'range', default: 1.0, min: 0.62, max: 1.42, affects: 'geometry',
    label: 'Crown spread',
    describe: 'How far the gathered cloth above the rope flares back out. 0.62 keeps the ' +
      'cuff nearly tubular and tight around the cargo; 1.42 throws it into a wide open ' +
      'star crown almost as broad as the neck is tall.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
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
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!merged) throw new Error('cargo-sack: mergeGeometries returned null');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const NS = 12;
const COL_A = (i) => (15 + 30 * i) * DEG;

const PK = (i) => Math.min(i, ((5 - i) % NS + NS) % NS);
const IS_CORNER = (i) => i === 1 || i === 4 || i === 7 || i === 10;

const CORNER_W = (i) => (IS_CORNER(i) ? 1 : 0.24);

const RING_Y = [0.000, 0.040, 0.095, 0.165, 0.245, 0.325, 0.410, 0.490, 0.560, 0.640];
const RING_R = [0.078, 0.112, 0.160, 0.180, 0.190, 0.194, 0.181, 0.140, 0.088, 0.070];
const RING_C = [0.100, 0.112, 0.075, 0.018, 0.000, 0.000, 0.000, 0.000, 0.000, 0.000];
const RING_J = [0.030, 0.050, 0.055, 0.055, 0.050, 0.050, 0.045, 0.035, 0.015, 0.000];
const RING_H = [0.000, 0.010, 0.012, 0.012, 0.012, 0.012, 0.010, 0.008, 0.003, 0.000];
const NR = RING_Y.length;

const BELLY_LO = 3, BELLY_HI = 6;
const BELLY_N0 = BELLY_HI - BELLY_LO;
const BELLY_H0 = RING_Y[BELLY_HI] - RING_Y[BELLY_LO];
const COURSE = BELLY_H0 / BELLY_N0;
const BODY_H0 = 0.700;
const MAX_COURSES = 5;
const courseCount = (tall) => Math.max(1, Math.min(MAX_COURSES,
  Math.round(BELLY_N0 + (tall - 1) * BODY_H0 / COURSE)));

const lerp = (a, b, t) => a + (b - a) * t;
const at = (tbl, u) => {
  const i = Math.floor(u), f = u - i;
  return f === 0 ? tbl[i] : lerp(tbl[i], tbl[i + 1], f);
};

const NECK_Y = 0.560;
const PLUMP_FADE = 0.150;

const ROPE_Y = 0.575, ROPE_R = 0.087, ROPE_T = 0.019, ROPE_MAJ = 12;
const ROPE_ARC = [-74, -25, 25, 74];
const ROPE_BACK = 0.070;

export function createAsset(userParams = {}) {
  const p = { ...userParams };
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const C = {
    burlap: p.burlap || cw.burlap,
    rope: p.rope || cw.rope,
    cargo: p.cargo || cw.cargo,
  };
  const plump = p.plumpness ?? params.plumpness.default;
  const tall = p.tallness ?? params.tallness.default;
  const spread = p.crownSpread ?? params.crownSpread.default;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const rnd = prng(90731);
  const jr = [], jy = [];
  for (let k = 0; k < NS; k++) {
    const a = [], b = [];
    for (let j = 0; j < NR; j++) { a.push(rnd() * 2 - 1); b.push(rnd() * 2 - 1); }
    jr.push(a); jy.push(b);
  }

  const plumpAt = (y) => 1 + (plump - 1) * Math.max(0, Math.min(1, (NECK_Y - y) / PLUMP_FADE));

  const nCourse = courseCount(tall);
  const dY = (nCourse - BELLY_N0) * COURSE;
  const yStretch = (nCourse * COURSE) / BELLY_H0;

  const rows = [];
  for (let j = 0; j <= BELLY_LO; j++) rows.push({ u: j, jrow: j, y: RING_Y[j] });
  for (let m = 1; m < nCourse; m++) {
    const u = BELLY_LO + (m * BELLY_N0) / nCourse;
    rows.push({
      u, jrow: (BELLY_LO + m) % NR,
      y: RING_Y[BELLY_LO] + (at(RING_Y, u) - RING_Y[BELLY_LO]) * yStretch,
    });
  }
  for (let j = BELLY_HI; j < NR; j++) rows.push({ u: j, jrow: j, y: RING_Y[j] + dY });

  const rings = rows.map((row) => {
    const out = [];
    const pw = plumpAt(at(RING_Y, row.u));
    const rR = at(RING_R, row.u), rC = at(RING_C, row.u);
    const rJ = at(RING_J, row.u), rH = at(RING_H, row.u);
    for (let i = 0; i < NS; i++) {
      const k = PK(i);
      let r = (rR + rC * CORNER_W(i)) * pw;
      r *= 1 + jr[k][row.jrow] * rJ;
      const y = row.y + jy[k][row.jrow] * rH;
      const a = COL_A(i);
      out.push([Math.cos(a) * r, y, Math.sin(a) * r]);
    }
    return out;
  });

  const body = [];
  for (let j = 0; j < rings.length - 1; j++) {
    for (let i = 0; i < NS; i++) {
      const n = (i + 1) % NS;
      quad(body, rings[j][i], rings[j + 1][i], rings[j + 1][n], rings[j][n]);
    }
  }

  const centre = [0, 0, 0];
  for (let i = 0; i < NS; i++) tri(body, centre, rings[0][i], rings[0][(i + 1) % NS]);
  add(posGeo(body), C.burlap);

  {
    const g = [];
    const ringPt = [];
    for (let j = 0; j <= ROPE_MAJ; j++) {
      const th = (j % ROPE_MAJ) * (360 / ROPE_MAJ) * DEG;
      const knuckle = Math.cos(6 * th);
      const R = ROPE_R + 0.003 * knuckle;
      const rt = ROPE_T * (1 + 0.20 * knuckle);
      const u = [Math.cos(th), 0, Math.sin(th)];

      const col = [[u[0] * ROPE_BACK, ROPE_Y - 0.007 + dY, u[2] * ROPE_BACK]];
      for (const deg of ROPE_ARC) {
        const ph = deg * DEG;
        const rr = R + rt * Math.cos(ph);
        col.push([u[0] * rr, ROPE_Y + rt * Math.sin(ph) + dY, u[2] * rr]);
      }
      col.push([u[0] * ROPE_BACK, ROPE_Y + 0.007 + dY, u[2] * ROPE_BACK]);
      ringPt.push(col);
    }
    for (let j = 0; j < ROPE_MAJ; j++) {
      for (let k = 0; k < ROPE_ARC.length + 1; k++) {
        quad(g, ringPt[j][k], ringPt[j][k + 1], ringPt[j + 1][k + 1], ringPt[j + 1][k]);
      }
    }
    add(posGeo(g), C.rope);
  }

  {

    const CA = (i) => (30 * i) * DEG;
    const A = [], B = [], Cr = [], D = [];
    for (let i = 0; i < NS; i++) {
      const a = CA(i), cx = Math.cos(a), cz = Math.sin(a);
      const point = i % 2 === 0;
      const rimR = (point ? 0.145 : 0.116) * spread;
      const rimY = (point ? 0.678 : 0.652) + dY;
      A.push([cx * 0.074, 0.578 + dY, cz * 0.074]);
      B.push([cx * rimR, rimY, cz * rimR]);
      Cr.push([cx * (rimR - 0.010), rimY, cz * (rimR - 0.010)]);
      D.push([cx * 0.068, 0.618 + dY, cz * 0.068]);
    }
    const g = [];
    for (let i = 0; i < NS; i++) {
      const n = (i + 1) % NS;
      quad(g, A[i], B[i], B[n], A[n]);
      quad(g, B[i], Cr[i], Cr[n], B[n]);
      quad(g, Cr[i], D[i], D[n], Cr[n]);
    }
    add(posGeo(g), C.burlap);
  }

  {
    const NH = 8;
    const hr = prng(4451);
    const jh = [];
    for (let k = 0; k < NH; k++) jh.push([hr() * 2 - 1, hr() * 2 - 1, hr() * 2 - 1]);
    const HPK = (i) => Math.min(i, ((3 - i) % NH + NH) % NH);
    const r0 = [], r1 = [];
    for (let i = 0; i < NH; i++) {
      const a = (22.5 + 45 * i) * DEG, cx = Math.cos(a), cz = Math.sin(a);
      const k = HPK(i);
      const a0 = 0.096 * (1 + jh[k][0] * 0.12);
      const a1 = 0.060 * (1 + jh[k][1] * 0.34);
      r0.push([cx * a0, 0.636 + dY, cz * a0]);
      r1.push([cx * a1, 0.680 + jh[k][2] * 0.012 + dY, cz * a1]);
    }
    const apex = [0, 0.700 + dY, 0];
    const g = [];
    for (let i = 0; i < NH; i++) {
      const n = (i + 1) % NH;
      quad(g, r0[i], r1[i], r1[n], r0[n]);
      tri(g, r1[i], apex, r1[n]);
    }
    add(posGeo(g), C.cargo);
  }

  const group = new THREE.Group();
  group.name = 'cargo-sack';
  group.add(finish(parts));
  return group;
}

export default createAsset;
