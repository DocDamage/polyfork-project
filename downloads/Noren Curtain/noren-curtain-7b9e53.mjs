/*
 * Noren Curtain
 * https://polyfork.dev/asset/noren-curtain-7b9e53
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './noren-curtain-7b9e53.mjs';
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
 *   colorway  choice  'indigo'       'indigo' | 'crimson' | 'matcha' | 'linen'
 *   cloth     color   '#5B6E8C'      any hex or THREE.Color
 *   sleeve    color   '#8FB4C9'      any hex or THREE.Color
 *   glyph     color   '#F2EFE7'      any hex or THREE.Color
 *   rod       color   '#8C7355'      any hex or THREE.Color
 *   rodCap    color   '#63503C'      any hex or THREE.Color
 *   panels    range   2              2 to 4
 *   drop      range   0.7            0.45 to 1.05
 *
 * Every option is described in full at https://polyfork.dev/cdn/noren-curtain-7b9e53-params.json
 *
 * SPECS  448 triangles, 1 material, 1.4 x 0.78 x 0.09 m (real-world scale).
 * PARTS  animate: panel-1, panel-2
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'indigo', label: 'Colorway',
    options: ['indigo', 'crimson', 'matcha', 'linen'],
    describe: 'curated dyed-cotton scheme for the whole curtain. indigo is the approved '
            + 'default: deep blue cloth, pale blue sleeves, white kanji on warm timber. '
            + 'crimson is the dark red izakaya noren; matcha a deep green tea-house one; '
            + 'linen a pale undyed cloth that inverts the glyph to near-black. The rod '
            + 'timber darkens with the darker cloths.',
  },
  cloth: {
    type: 'color', default: '#5B6E8C', label: 'Cloth',
    describe: 'albedo of both panel halves — front, back, hem and slit cheeks. The '
            + 'dominant mass of the part and almost all of its silhouette; everything '
            + 'else is read against it, so keep it well clear in value of the glyph.',
  },
  sleeve: {
    type: 'color', default: '#8FB4C9', label: 'Sleeve loops',
    describe: 'albedo of the four square fabric loops threaded over the rod. Meant to sit '
            + 'a clear step LIGHTER than the cloth so the top line reads as four crisp '
            + 'blocks; matched to the cloth they disappear into the sag.',
  },
  glyph: {
    type: 'color', default: '#F2EFE7', label: 'Kanji',
    describe: 'albedo of the painted character 東 dyed flush into the front of the cloth. '
            + 'It carries the whole graphic identity, so it needs maximum value contrast '
            + 'against the cloth: near-white on a dark cloth, near-black on a pale one.',
  },
  rod: {
    type: 'color', default: '#8C7355', label: 'Rod',
    describe: 'albedo of the round timber dowel spanning the top and overhanging both '
            + 'ends. Dry unvarnished wood; the only warm hue on an otherwise cool part.',
  },
  rodCap: {
    type: 'color', default: '#63503C', label: 'Rod end grain',
    describe: 'albedo of the two circular end-grain discs closing the rod. Kept a step '
            + 'DARKER than the rod so the overhanging ends read as solid timber rather '
            + 'than as open pipe in the side elevations.',
  },
  panels: {
    type: 'range', default: 2, min: 2, max: 4, step: 1, affects: 'geometry',
    label: 'Panels',
    describe: 'how many separately hanging cloth strips the 1.2 m width is cut into, '
            + 'divided by 16 mm slits. 2 is the reference two-way split (0.59 m strips); '
            + '3 and 4 give the narrower multi-strip shop noren (0.39 m and 0.29 m). '
            + 'Every strip is rebuilt with its own pair of sleeve loops, its own sag and '
            + 'its own share of the kanji, so both the loop count and the triangle count '
            + 'move with this knob. Total width stays exactly 1.200 m at every value.',
  },
  drop: {
    type: 'range', default: 0.70, min: 0.45, max: 1.05, affects: 'geometry',
    label: 'Drop',
    describe: 'how far the cloth hangs below the rod, in metres. 0.45 is a short shop '
            + 'noren that clears the head by a long way; 1.05 is a full bathhouse curtain '
            + 'reaching chest height. The cloth is REBUILT, never stretched: it gains '
            + 'horizontal fold bands at a constant ~0.16 m pitch, so the billow keeps the '
            + 'same facet size and the triangle count steps with the band count: 3 bands '
            + 'up to 0.55 m, 4 to 0.71 m, 5 from 0.72 m up. Rod, sleeve loops, cloth '
            + 'thickness and slit width are the same size at every drop. The kanji stays '
            + 'proportional at 60% of the drop until it reaches 40% of the cloth width, '
            + 'then holds that size.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  indigo:  { cloth: '#5B6E8C', sleeve: '#8FB4C9', glyph: '#F2EFE7', rod: '#8C7355', rodCap: '#63503C' },
  crimson: { cloth: '#8E1F1B', sleeve: '#B5462F', glyph: '#F2EFE7', rod: '#63503C', rodCap: '#42352A' },
  matcha:  { cloth: '#2F6B4F', sleeve: '#6FA860', glyph: '#F2EFE7', rod: '#8C7355', rodCap: '#63503C' },
  linen:   { cloth: '#D9CFBC', sleeve: '#B9A88C', glyph: '#2E3134', rod: '#63503C', rodCap: '#42352A' },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: {
      cloth: hex(p.cloth), sleeve: hex(p.sleeve), glyph: hex(p.glyph),
      rod: hex(p.rod), cap: hex(p.rodCap),
    },
    N: Math.round(clamp(p.panels, 2, 4)),
    drop: clamp(p.drop, 0.45, 1.05),
  };
}

const W = 1.200, HW = W / 2;
const SLIT = 0.016;
const CT = 0.015;
const BULGE = 0.030;
const SAG = 0.042;
const SAG_SPAN = 0.22;
const BAND_PITCH = 0.16;
const NSX = 4;

const ROD_R = 0.024, ROD_SEG = 8, ROD_OVER = 0.100;
const RING_CL = 0.008, RING_T = 0.014, RING_W = 0.075;
const RING_IN = ROD_R + RING_CL;
const RING_OUT = RING_IN + RING_T;
const RING_BED = 0.012;
const RING_INSET = 0.010;

const EPS = 0.0006;
const GLYPH_GAP = 0.005;
const MIN_W = 0.008, MIN_H = 0.004;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
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
function meshOf(buckets, name, dy, mat) {
  const list = Object.entries(buckets).filter(([, p]) => p.length)
    .map(([hex, p]) => prep(posGeo(p), Number(hex)));
  const merged = mergeGeometries(list);
  if (dy) merged.translate(0, dy, 0);
  merged.computeVertexNormals();
  const m = new THREE.Mesh(merged, mat);
  m.name = name;
  return m;
}

function clipHalf(poly, axis, limit, keepBelow) {
  const out = [];
  const d = (p) => (keepBelow ? limit - p[axis] : p[axis] - limit);
  for (let i = 0; i < poly.length; i++) {
    const a = poly[i], b = poly[(i + 1) % poly.length];
    const da = d(a), db = d(b);
    if (da >= 0) out.push(a);
    if ((da >= 0) !== (db >= 0)) {
      const t = da / (da - db);
      out.push([a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t]);
    }
  }
  return out;
}
function clipBox(poly, x0, x1, y0, y1) {
  let p = poly;
  p = clipHalf(p, 0, x0, false); if (p.length < 3) return null;
  p = clipHalf(p, 0, x1, true);  if (p.length < 3) return null;
  p = clipHalf(p, 1, y0, false); if (p.length < 3) return null;
  p = clipHalf(p, 1, y1, true);  if (p.length < 3) return null;
  let mnx = Infinity, mxx = -Infinity, mny = Infinity, mxy = -Infinity;
  for (const q of p) {
    mnx = Math.min(mnx, q[0]); mxx = Math.max(mxx, q[0]);
    mny = Math.min(mny, q[1]); mxy = Math.max(mxy, q[1]);
  }
  if (mxx - mnx < MIN_W || mxy - mny < MIN_H) return null;
  return p;
}
function signedArea(p) {
  let s = 0;
  for (let i = 0; i < p.length; i++) {
    const a = p[i], b = p[(i + 1) % p.length];
    s += a[0] * b[1] - b[0] * a[1];
  }
  return s / 2;
}

const HW_H = 0.042;

const HW_STEM = 0.076;

const BOX = 0.280;

function glyphShapes(gap, ar) {
  const g = gap, VW = HW_H * ar, SW = HW_STEM * ar, HH = HW_H;
  const R = (x0, x1, y0, y1) => [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];
  const BL = BOX - VW, BR = BOX + VW;
  const bar = (yc) => [R(-BR, -SW - g, yc - HH, yc + HH), R(SW + g, BR, yc - HH, yc + HH)];
  const out = [
    R(-SW, SW, 0.01, 0.98),
    R(-0.47, -SW - g, 0.858, 0.942),
    R(SW + g, 0.47, 0.858, 0.942),
    ...bar(0.755), ...bar(0.545), ...bar(0.335),
    R(-BR, -BL, 0.587 + g, 0.713 - g),
    R(-BR, -BL, 0.377 + g, 0.503 - g),
    R(BL, BR, 0.587 + g, 0.713 - g),
    R(BL, BR, 0.377 + g, 0.503 - g),
  ];

  for (const s of [-1, 1]) {
    const u0 = s * (SW + g) / ar, y0 = 0.275, u1 = s * 0.40 / ar, y1 = 0.015;
    const du = u1 - u0, dy = y1 - y0, L = Math.hypot(du, dy);
    const nu = -dy / L * HH, ny = du / L * HH;
    let leg = [[u0 + nu, y0 + ny], [u1 + nu, y1 + ny], [u1 - nu, y1 - ny], [u0 - nu, y0 - ny]]
      .map(([u, y]) => [u * ar, y]);
    leg = clipHalf(leg, 0, s * (SW + g), s < 0);
    leg = clipHalf(leg, 1, 0.293 - g, true);
    if (leg.length >= 3) out.push(leg);
  }
  return out;
}

export function createAsset(userParams = {}) {
  const { C, N, drop } = resolve(userParams);

  const TOP = drop;
  const NB = Math.min(5, Math.max(3, Math.round(drop / BAND_PITCH)));
  const ROD_Y = TOP + RING_OUT - RING_BED;
  const ROD_L = W + 2 * ROD_OVER;

  const zMid = (t) => BULGE * Math.sin(Math.PI * Math.pow(t, 0.85));

  const bandZ = (k) => {
    const yT = TOP * (1 - k / NB), yB = TOP * (1 - (k + 1) / NB);
    const zT = zMid(k / NB), zB0 = zMid((k + 1) / NB);
    const m = (zT - zB0) / (yT - yB);
    return (y) => zB0 + (y - yB) * m;
  };

  const root = new THREE.Group();
  root.name = 'noren-curtain';

  const MAT = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  {
    const buf = { [C.rod]: [], [C.cap]: [] };
    const ring = [];
    for (let k = 0; k < ROD_SEG; k++) {
      const a = (k / ROD_SEG) * Math.PI * 2;
      ring.push([ROD_Y + ROD_R * Math.cos(a), ROD_R * Math.sin(a)]);
    }
    const x0 = -ROD_L / 2, x1 = ROD_L / 2;
    for (let k = 0; k < ROD_SEG; k++) {
      const p = ring[k], q = ring[(k + 1) % ROD_SEG];
      quad(buf[C.rod], [x0, p[0], p[1]], [x0, q[0], q[1]], [x1, q[0], q[1]], [x1, p[0], p[1]]);
    }
    for (let k = 0; k < ROD_SEG; k++) {
      const p = ring[k], q = ring[(k + 1) % ROD_SEG];
      tri(buf[C.cap], [x1, ROD_Y, 0], [x1, p[0], p[1]], [x1, q[0], q[1]]);
      tri(buf[C.cap], [x0, ROD_Y, 0], [x0, q[0], q[1]], [x0, p[0], p[1]]);
    }
    root.add(meshOf(buf, 'noren-rod', 0, MAT));
  }

  const pw = (W - (N - 1) * SLIT) / N;

  let glyphH = 0.60 * drop, glyphW = 1.15 * glyphH;
  if (glyphW > 0.50) { glyphW = 0.50; glyphH = glyphW / 1.15; }

  const gY0 = 0.46 * drop - glyphH / 2;
  const gRects = glyphShapes(GLYPH_GAP / glyphH, glyphH / glyphW).map(
    (poly) => poly.map(([gx, gy]) => [gx * glyphW, gY0 + gy * glyphH]));

  for (let pi = 0; pi < N; pi++) {
    const xa = -HW + pi * (pw + SLIT), xb = xa + pw;
    const tL = xa + RING_W / 2 + RING_INSET;
    const tR = xb - RING_W / 2 - RING_INSET;
    const sagAt = (x) => {
      const u = (x - tL) / (tR - tL);
      if (u <= 0 || u >= 1) return 0;
      return SAG * Math.pow(Math.sin(Math.PI * u), 1.3);
    };
    const lineY = (k, x) => {
      const t = k / NB;
      return TOP * (1 - t) - sagAt(x) * Math.max(0, 1 - t / SAG_SPAN);
    };
    const lineXs = (k) => {
      const t = k / NB;
      if (1 - t / SAG_SPAN <= 0) return [xa, xb];
      const xs = [];
      for (let j = 0; j <= NSX; j++) xs.push(j === NSX ? xb : xa + (pw * j) / NSX);
      return xs;
    };

    const buf = { [C.cloth]: [], [C.glyph]: [], [C.sleeve]: [] };
    const cloth = buf[C.cloth], ink = buf[C.glyph];

    for (let k = 0; k < NB; k++) {
      const zc = bandZ(k);
      const zF = (y) => zc(y) + CT / 2, zB = (y) => zc(y) - CT / 2;
      const xsT = lineXs(k), xsB = lineXs(k + 1);

      const contour = [];
      for (const x of xsB) contour.push([x, lineY(k + 1, x)]);
      for (let j = xsT.length - 1; j >= 0; j--) contour.push([xsT[j], lineY(k, xsT[j])]);

      let yT = Infinity, yB = -Infinity;
      for (const x of xsT) yT = Math.min(yT, lineY(k, x));
      for (const x of xsB) yB = Math.max(yB, lineY(k + 1, x));
      const holes = [];
      for (const r of gRects) {
        const c = clipBox(r, xa + EPS, xb - EPS, yB + EPS, yT - EPS);
        if (c) holes.push(signedArea(c) < 0 ? c.slice().reverse() : c);
      }

      const cV = contour.map((p) => new THREE.Vector2(p[0], p[1]));
      const hV = holes.map((h) => h.map((p) => new THREE.Vector2(p[0], p[1])));
      const faces = THREE.ShapeUtils.triangulateShape(cV, hV);
      const pts = [...contour, ...holes.flat()];
      for (const f of faces) {
        let [a, b, c] = f.map((i) => pts[i]);
        if (signedArea([a, b, c]) < 0) { const t = b; b = c; c = t; }
        tri(cloth, [a[0], a[1], zF(a[1])], [b[0], b[1], zF(b[1])], [c[0], c[1], zF(c[1])]);
      }

      for (const h of holes) {
        for (let j = 1; j + 1 < h.length; j++) {
          const a = h[0], b = h[j], c = h[j + 1];
          tri(ink, [a[0], a[1], zF(a[1])], [b[0], b[1], zF(b[1])], [c[0], c[1], zF(c[1])]);
        }
      }

      const bc = contour;
      const bFaces = THREE.ShapeUtils.triangulateShape(
        bc.map((p) => new THREE.Vector2(p[0], p[1])), []);
      for (const f of bFaces) {
        let [a, b, c] = f.map((i) => bc[i]);
        if (signedArea([a, b, c]) < 0) { const t = b; b = c; c = t; }
        tri(cloth, [a[0], a[1], zB(a[1])], [c[0], c[1], zB(c[1])], [b[0], b[1], zB(b[1])]);
      }

      for (const [x, sx] of [[xa, -1], [xb, 1]]) {
        const yTop = lineY(k, x), yBot = lineY(k + 1, x);
        const F0 = [x, yTop, zF(yTop)], B0 = [x, yTop, zB(yTop)];
        const F1 = [x, yBot, zF(yBot)], B1 = [x, yBot, zB(yBot)];
        if (sx < 0) quad(cloth, B1, F1, F0, B0); else quad(cloth, B0, F0, F1, B1);
      }

      if (k === 0) {
        for (let j = 0; j + 1 < xsT.length; j++) {
          const x0 = xsT[j], x1 = xsT[j + 1], y0 = lineY(0, x0), y1 = lineY(0, x1);
          quad(cloth, [x0, y0, zF(y0)], [x1, y1, zF(y1)], [x1, y1, zB(y1)], [x0, y0, zB(y0)]);
        }
      }
      if (k === NB - 1) {
        quad(cloth, [xa, 0, zB(0)], [xb, 0, zB(0)], [xb, 0, zF(0)], [xa, 0, zF(0)]);
      }
    }

    for (const cx of [tL, tR]) {
      const s = buf[C.sleeve];
      const x0 = cx - RING_W / 2, x1 = cx + RING_W / 2;
      const O = RING_OUT, I = RING_IN;

      const outer = [[-O, -O], [-O, O], [O, O], [O, -O]];
      const inner = [[-I, -I], [-I, I], [I, I], [I, -I]];
      const P = (x, p) => [x, ROD_Y + p[1], p[0]];
      for (let k = 0; k < 4; k++) {
        const a = outer[k], b = outer[(k + 1) % 4];
        quad(s, P(x0, a), P(x0, b), P(x1, b), P(x1, a));
      }
      for (let k = 0; k < 4; k++) {
        const a = inner[k], b = inner[(k + 1) % 4];
        quad(s, P(x0, b), P(x0, a), P(x1, a), P(x1, b));
      }
      for (let k = 0; k < 4; k++) {
        const a = outer[k], b = outer[(k + 1) % 4];
        const c = inner[k], d = inner[(k + 1) % 4];
        quad(s, P(x1, a), P(x1, b), P(x1, d), P(x1, c));
        quad(s, P(x0, b), P(x0, a), P(x0, c), P(x0, d));
      }
    }

    const grp = new THREE.Group();
    grp.name = `panel-${pi + 1}`;
    grp.position.set(0, ROD_Y, 0);
    grp.add(meshOf(buf, `panel-${pi + 1}-mesh`, -ROD_Y, MAT));
    root.add(grp);
  }

  return root;
}

export const rig = {
  'panel-1': { axis: 'x', range: [0, -34] },
  'panel-2': { axis: 'x', range: [0, 30] },
};
export const detach = [];
export const night = {};
export default createAsset;
