/*
 * Guardrail Section
 * https://polyfork.dev/asset/guardrail-section-68c3c4
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './guardrail-section-68c3c4.mjs';
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
 *   colorway  choice  'pale-steel'   'pale-steel' | 'graphite' | 'cream' | 'municipal-green'
 *   rail      color   '#c7cbcc'      any hex or THREE.Color
 *   post      color   '#8a9197'      any hex or THREE.Color
 *   cap       color   '#6b7278'      any hex or THREE.Color
 *   bolt      color   '#2e3134'      any hex or THREE.Color
 *   tallness  range   1              0.8 to 1.5
 *   modules   range   1              1 to 2
 *
 * Every option is described in full at https://polyfork.dev/cdn/guardrail-section-68c3c4-params.json
 *
 * SPECS  432 triangles, 1 material, 4 x 1 x 0.21 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BASE = {
  rail: 0xC7CBCC,
  post: 0x8A9197,
  cap:  0x6B7278,
  bolt: 0x2E3134,
};

const COLORWAYS = {

  'pale-steel':       { rail: 0xC7CBCC, post: 0x8A9197, cap: 0x6B7278, bolt: 0x2E3134 },
  'graphite':         { rail: 0xA9AFB4, post: 0x6B7278, cap: 0x4E5459, bolt: 0x1B1D20 },
  'cream':            { rail: 0xF2EFE7, post: 0xB9A88C, cap: 0x8C7355, bolt: 0x42352A },
  'municipal-green':  { rail: 0xC7CBCC, post: 0x3F8A5E, cap: 0x2F6B4F, bolt: 0x1B1D20 },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'pale-steel', label: 'Colorway',
    options: ['pale-steel', 'graphite', 'cream', 'municipal-green'],
    describe: 'curated kit-coherent scheme; sets all four zones together. Every scheme '
      + 'keeps all four APART — a wide gap from the tubes to the post, a clear step down '
      + 'to the cast fittings, and the bolts well below both — so the elevation never '
      + 'collapses into one mass and the four declared zones deliver four. '
      + 'pale-steel is the reference: bright pale grey tubes on a mid-grey municipal '
      + 'post, as in the refs and the kit-concept pavements. graphite drops it to dark '
      + 'galvanised grey for a back alley or a rail bridge. cream warms it to painted '
      + 'beige that sits with the kit\'s plaster shopfronts. municipal-green is the deep '
      + 'Japanese park-and-riverbank green under the same pale tubes.',
  },
  rail: {
    type: 'color', default: 0xC7CBCC, label: 'Rail tubes',
    describe: 'albedo of both horizontal tubes — the two bright bars that ARE the '
      + 'silhouette at street distance. Keep it the lightest value on the object and keep '
      + 'a WIDE gap to the post colour: the tubes are 0.160 m thick against a 4 m span, '
      + 'and a tube within a rung or two of the post merges into it, leaving the piece '
      + 'reading as one grey mass at street distance.',
  },
  post: {
    type: 'color', default: 0x8A9197, label: 'Posts',
    describe: 'albedo of the two slab end-post shafts — the full-height masses the tubes '
      + 'die into, between the base cover and the head cap. Defaults a wide value step '
      + 'below the tubes so the posts read as the heavier structure behind them; taking '
      + 'it near the rail colour flattens the whole elevation into one block.',
  },
  cap: {
    type: 'color', default: 0x6B7278, label: 'Cast fittings',
    describe: 'albedo of BOTH cast fittings on every post — the base cover at the foot '
      + 'and the battered cap on the head — which together turn each post into a '
      + 'three-part column instead of a plain slab. A clear dark step by default so both '
      + 'ends of the post terminate; matching it to the post colour collapses the column '
      + 'back into one rectangle in every elevation.',
  },
  bolt: {
    type: 'color', default: 0x2E3134, label: 'Bolt heads',
    describe: 'albedo of the hexagonal through-bolt heads on both faces of every post, '
      + 'one per tube — 0.100 m across with a flat head over a steep chamfered flank, the '
      + 'only surface incident on the piece. The darkest zone, and it has to clear TWO '
      + 'things: the mid-grey shaft it sits on, and the cast fittings. Held one rung under '
      + 'the fittings it merged with them and the four declared zones delivered three, so '
      + 'it now sits well below both. It is the darkest tone on the object but not flat '
      + 'black — the flank still has to catch light or the hex reads as a punched hole.',
  },
  tallness: {
    type: 'range', default: 1.00, min: 0.80, max: 1.50, label: 'Rail height',
    affects: 'geometry',
    describe: 'REBUILDS the barrier at a different height, 0.80 m (a low kerbside rail '
      + 'you see over) to 1.50 m (a tall crossing-prevention barrier). It is not a '
      + 'scale: the post section, both cast fittings, the tube diameter and the 0.370 m '
      + 'tube pitch all STAY PUT, and tubes are added at that fixed pitch downward from '
      + 'the head as the height allows — 2 tubes below 1.30 m, 3 at and above it — so the '
      + 'triangle count moves with the knob (432 at the default, 576 at 1.50). The top '
      + 'tube always hangs the same 0.070 m below the post head, and the lowest one '
      + 'always leaves at least a QUARTER of the height as open air beneath it, so the '
      + 'wide empty band that separates a guardrail from a fence survives the whole '
      + 'range instead of filling in at the tall end.',
  },
  modules: {
    type: 'range', default: 1, min: 1, max: 2, label: 'Modules',
    affects: 'geometry',
    describe: 'how many 4 m grid modules the run spans: 1 = 4 m (default), 2 = 8 m. '
      + 'REBUILT, not stretched — a real post is added on the 4 m boundary and the tubes '
      + 'are cut into one span per bay rather than one long tube, so the bay proportion '
      + 'and the triangle count both change (432 to 752). The ends stay flat at exactly '
      + '±(2 x modules) m. A mid-run post carries a DOUBLE 0.500 m section, because that '
      + 'is exactly what a chained joint is — two 0.250 m end posts butted outer face to '
      + 'outer face — so an 8 m piece and two chained 4 m pieces mass the same at the '
      + 'joint. The ceiling is 2 rather than 3 because the tubes now carry loops along '
      + 'their run and a 12 m piece could not hold the triangle budget, while chaining '
      + 'three clones gives the same 12 m run with an invisible seam (see connect.png).',
  },
};

const MODULE   = 4.000;
const POST_HX  = 0.1250;
const POST_HZ  = 0.0850;
const CHAM     = 0.0260;
const PROUD    = 0.0200;

const PLINTH_H = 0.1050;
const PLINTH_SL = 0.0150;
const FOOT_FLARE = 0.0080;

const CAP_H    = 0.0620;
const CAP_FLARE = 0.0100;
const CAP_TOP  = 0.0260;
const TUBE_R   = 0.0800;

const TUBE_SEG = 8;
const TUBE_LOOP = 0.7200;
const RAIL_DROP = 0.1500;
const PITCH    = 0.3700;

const MIN_AIR_FRAC = 0.25;

const EMBED    = 0.0500;

const BOLT_R   = 0.0500, BOLT_R_TOP = 0.0300;
const BOLT_H   = 0.0140, BOLT_SINK = 0.0040, BOLT_SEG = 6;

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function postSection(hxM, hxP, hz, c, sharpMinusX, sharpPlusX) {
  const p = [];
  if (sharpPlusX) p.push([hxP, -hz], [hxP, hz]);
  else            p.push([hxP, -(hz - c)], [hxP, hz - c], [hxP - c, hz]);
  if (sharpMinusX) p.push([-hxM, hz], [-hxM, -hz]);
  else             p.push([-(hxM - c), hz], [-hxM, hz - c], [-hxM, -(hz - c)], [-(hxM - c), -hz]);
  if (!sharpPlusX) p.push([hxP - c, -hz]);
  return p;
}

const ringCentre = (pts) => [
  pts.reduce((s, p) => s + p[0], 0) / pts.length,
  pts.reduce((s, p) => s + p[1], 0) / pts.length,
];
function loftRings(rings, capTop, capBottom) {
  const pos = [];
  for (let i = 0; i + 1 < rings.length; i++) {
    const a = rings[i], b = rings[i + 1], n = a.pts.length;
    for (let k = 0; k < n; k++) {
      const j = (k + 1) % n;
      quad(pos,
        [a.pts[k][0], a.y, a.pts[k][1]], [b.pts[k][0], b.y, b.pts[k][1]],
        [b.pts[j][0], b.y, b.pts[j][1]], [a.pts[j][0], a.y, a.pts[j][1]]);
    }
  }
  if (capTop) {
    const t = rings[rings.length - 1], n = t.pts.length, [cx, cz] = ringCentre(t.pts);
    for (let k = 0; k < n; k++) {
      const j = (k + 1) % n;
      tri(pos, [cx, t.y, cz], [t.pts[j][0], t.y, t.pts[j][1]], [t.pts[k][0], t.y, t.pts[k][1]]);
    }
  }
  if (capBottom) {
    const b = rings[0], n = b.pts.length, [cx, cz] = ringCentre(b.pts);
    for (let k = 0; k < n; k++) {
      const j = (k + 1) % n;
      tri(pos, [cx, b.y, cz], [b.pts[k][0], b.y, b.pts[k][1]], [b.pts[j][0], b.y, b.pts[j][1]]);
    }
  }
  return posGeo(pos);
}

function tubeX(x0, x1, r, seg, cy, loop) {
  const pos = [];
  const n = Math.max(1, Math.round(Math.abs(x1 - x0) / loop));

  const p = (k) => {
    const a = ((k + 0.5) / seg) * Math.PI * 2;
    return [cy + Math.cos(a) * r, Math.sin(a) * r];
  };
  for (let i = 0; i < n; i++) {
    const xa = x0 + (x1 - x0) * (i / n), xb = x0 + (x1 - x0) * ((i + 1) / n);
    for (let k = 0; k < seg; k++) {
      const A = p(k), B = p((k + 1) % seg);
      quad(pos, [xa, A[0], A[1]], [xa, B[0], B[1]], [xb, B[0], B[1]], [xb, A[0], A[1]]);
    }
  }
  return posGeo(pos);
}

function boss(cx, cy, cz, nx, ny, nz, rBase, rTop, h, seg) {
  const n = new THREE.Vector3(nx, ny, nz).normalize();
  const up = Math.abs(n.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const t = new THREE.Vector3().crossVectors(up, n).normalize();
  const b = new THREE.Vector3().crossVectors(n, t).normalize();
  const top = [cx + n.x * h, cy + n.y * h, cz + n.z * h];
  const ringAt = (c, r) => {
    const out = [];
    for (let i = 0; i < seg; i++) {
      const a = (i / seg) * Math.PI * 2, cs = Math.cos(a) * r, sn = Math.sin(a) * r;
      out.push([c[0] + t.x * cs + b.x * sn, c[1] + t.y * cs + b.y * sn, c[2] + t.z * cs + b.z * sn]);
    }
    return out;
  };
  const lo = ringAt([cx, cy, cz], rBase), hi = ringAt(top, rTop);
  const pos = [];
  for (let i = 0; i < seg; i++) {
    const j = (i + 1) % seg;

    quad(pos, lo[i], lo[j], hi[j], hi[i]);
  }
  for (let i = 1; i + 1 < seg; i++) tri(pos, hi[0], hi[i], hi[i + 1]);
  return posGeo(pos);
}

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

export function createAsset(opts = {}) {

  const cw = COLORWAYS[opts.colorway] || COLORWAYS[params.colorway.default];
  const C = { ...BASE, ...cw };
  for (const k of ['rail', 'post', 'cap', 'bolt']) {
    if (opts[k] !== undefined && opts[k] !== null) C[k] = new THREE.Color(opts[k]).getHex();
  }

  const H = Math.min(params.tallness.max, Math.max(params.tallness.min,
    opts.tallness !== undefined ? +opts.tallness : params.tallness.default));
  const M = Math.min(params.modules.max, Math.max(params.modules.min,
    Math.round(opts.modules !== undefined ? +opts.modules : params.modules.default)));

  const L = MODULE * M, HL = L / 2;
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const railY = [];
  for (let y = H - RAIL_DROP; y - TUBE_R >= MIN_AIR_FRAC * H; y -= PITCH) railY.push(y);

  const posts = [];
  for (let k = 0; k <= M; k++) {
    const isMinusEnd = k === 0, isPlusEnd = k === M;
    const cx = isMinusEnd ? -HL + POST_HX : isPlusEnd ? HL - POST_HX : -HL + MODULE * k;
    const hx = (isMinusEnd || isPlusEnd) ? POST_HX : POST_HX * 2;
    posts.push({ cx, hx, sharpMinusX: isMinusEnd, sharpPlusX: isPlusEnd });
  }

  const capBase = H - CAP_H;
  for (const P of posts) {

    const sec = (hxM, hxP, hz) =>
      postSection(hxM, hxP, hz, CHAM, P.sharpMinusX, P.sharpPlusX).map(([x, z]) => [x + P.cx, z]);
    const shaft = (hz) => sec(P.hx, P.hx, hz);

    const proud = (hz, extra = 0) =>
      sec(P.hx + (P.sharpMinusX ? 0 : PROUD + extra),
          P.hx + (P.sharpPlusX  ? 0 : PROUD + extra), hz);

    const crown = (hz) =>
      sec(P.hx + (P.sharpMinusX ? 0 : PROUD) - CAP_TOP,
          P.hx + (P.sharpPlusX  ? 0 : PROUD) - CAP_TOP, hz);

    add(loftRings([
      { y: 0,                    pts: proud(POST_HZ + PROUD, FOOT_FLARE) },
      { y: PLINTH_H - PLINTH_SL, pts: proud(POST_HZ + PROUD) },
      { y: PLINTH_H,             pts: shaft(POST_HZ) },
    ], false, true), C.cap);
    add(loftRings([
      { y: PLINTH_H, pts: shaft(POST_HZ) },
      { y: capBase,  pts: shaft(POST_HZ) },
    ], false, false), C.post);

    add(loftRings([
      { y: capBase,             pts: shaft(POST_HZ) },
      { y: capBase + CAP_FLARE, pts: proud(POST_HZ + PROUD) },
      { y: H,                   pts: crown(POST_HZ + PROUD - CAP_TOP) },
    ], true, false), C.cap);

    for (const y of railY) for (const s of [1, -1]) {
      add(boss(P.cx, y, s * (POST_HZ - BOLT_SINK), 0, 0, s,
               BOLT_R, BOLT_R_TOP, BOLT_H + BOLT_SINK, BOLT_SEG), C.bolt);
    }
  }

  for (let k = 0; k < M; k++) {
    const a = posts[k], b = posts[k + 1];
    const x0 = a.cx + a.hx - EMBED, x1 = b.cx - b.hx + EMBED;
    for (const y of railY) add(tubeX(x0, x1, TUBE_R, TUBE_SEG, y, TUBE_LOOP), C.rail);
  }

  const merged = mergeGeometries(parts.map(({ g, c }) => prep(g, c)));
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'guardrail-mesh';

  const g = new THREE.Group();
  g.name = 'guardrail-section';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};

export default createAsset;
