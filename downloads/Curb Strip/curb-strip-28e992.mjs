/*
 * Curb Strip
 * https://polyfork.dev/asset/curb-strip-28e992
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './curb-strip-28e992.mjs';
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
 *   piece     choice  'straight'     'straight' | 'corner-outer' | 'corner-inner' | 'ramp' | 'end'
 *   colorway  choice  'granite'      'granite' | 'bluestone' | 'brownstone' | 'limestone'
 *   face      color   '#b5aea0'      any hex or THREE.Color
 *   top       color   '#b2ab9d'      any hex or THREE.Color
 *   joint     color   '#3f4247'      any hex or THREE.Color
 *   height    range   0.12           0.09 to 0.2
 *   stones    range   4              3 to 6
 *   wear      range   0              0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/curb-strip-28e992-params.json
 *
 * SPECS  140 triangles, 1 material, 4 x 0.12 x 0.3 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const LEN   = 4.00;
const HALF  = LEN / 2;
const HW    = 0.150;
const HGT   = 0.120;
const CW    = 0.035;
const CD    = 0.032;
const SW    = 0.015;
const SD    = 0.015;
const JOINT = 0.020;
const CUT   = 0.014;
const RATIO = 0.63 / 1.34;
const QUAD  = 0.35;
const COURSE = 0.13;
const BEDW  = 0.011;
const BEDD  = 0.008;

const SKEWS = [0.10, -0.07, 0.12, -0.09, 0.08];

const RAMP = [0.90, 1.45, 2.55, 3.10];

const r4 = (x) => Math.round(x * 1e4) / 1e4;
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

export const COLORWAYS = {
  granite:    { face: 0xb5aea0, top: 0xb2ab9d, joint: 0x3f4247 },
  bluestone:  { face: 0x6f8fa0, top: 0x6c8c9d, joint: 0x3f4247 },
  brownstone: { face: 0x8a5a44, top: 0x875741, joint: 0x3f4247 },
  limestone:  { face: 0xece5d3, top: 0xe9e2d0, joint: 0x3f4247 },
};
export const presets = COLORWAYS;

export const params = {
  piece: {
    type: 'choice', default: 'straight', label: 'Piece', affects: 'geometry',
    options: ['straight', 'corner-outer', 'corner-inner', 'ramp', 'end'],
    describe: 'which kerb this module builds. All five carry 4.00 m of kerb line and present the ' +
      'same dead-square mating face 2.00 m from the origin along their own axis, so any two chain ' +
      'on the 4 m grid. straight: a run along X from x=-2 to x=+2, kerb line on z=0, street on +Z ' +
      '(the approved default). corner-outer: the line comes in along +X and turns 90 degrees to -Z ' +
      'around the OUTSIDE of a block, mitred at the node, sidewalk on the inside of the turn, arms ' +
      'ending at x=-2 and z=-2. corner-inner: the same turn re-entrant, to +Z, street on the inside, ' +
      'arms ending at x=-2 and z=+2. ramp: a dropped kerb, full height at both mating ends and down ' +
      'to a 30 mm upstand across the middle for a crossing or a driveway. end: the run stops — the ' +
      'chamfers run out over the last 120 mm into a dead-square stop block, the other end still mates.',
  },
  colorway: {
    type: 'choice', default: 'granite', label: 'Colorway',
    options: ['granite', 'bluestone', 'brownstone', 'limestone'],
    describe: 'curated kerb stone, kit-coherent; sets face, top and joint together. granite is the ' +
      'approved warm grey; bluestone a blue-grey slate kerb; brownstone a warm sandstone; limestone ' +
      'a pale cream kerb. The joint stays the kit asphalt dark in every one.',
  },
  face: {
    type: 'color', default: '#b5aea0', label: 'Kerb face',
    describe: 'albedo of every vertical face, both chamfers, the sawn cheeks and the cut ends — the ' +
      'stone itself, and what the kerb line reads as from the street. Roughly 55% of the surface.',
  },
  top: {
    type: 'color', default: '#b2ab9d', label: 'Kerb top',
    describe: 'albedo of the flat top wear face alone. Ships three points off the face so the top is ' +
      'separately addressable and the default still reads as one stone; open it up for a grimed, ' +
      'scrubbed or snow-dusted top.',
  },
  joint: {
    type: 'color', default: '#3f4247', label: 'Joint reveal',
    describe: 'albedo inside the sawn reveals between set stones, and in the bed joint a tall kerb ' +
      'gains. Dark: it is the shadow in a 14 mm cut, about 1% of the surface, never trim.',
  },
  height: {
    type: 'range', default: HGT, min: 0.09, max: 0.20, label: 'Kerb height', affects: 'geometry',
    describe: 'upstand of the kerb above the road, in metres. 0.09 is a low garden edging, 0.12 the ' +
      'approved street kerb, 0.20 a high-back kerb a wheel cannot climb. It REBUILDS rather than ' +
      'stretches: the chamfers are cut at their real absolute size at every height (a tall kerb is a ' +
      'taller FACE, not a magnified drawing), and past 0.165 m the stone runs out of depth so the ' +
      'kerb is laid on a foundation COURSE and gains a sawn bed joint running the whole length — the ' +
      'triangle count more than doubles at 0.20. Below 0.10 m the chamfers shorten with the stone. ' +
      'Every piece shares whatever height is set.',
  },
  stones: {
    type: 'range', default: 4, min: 3, max: 6, step: 1, label: 'Set stones', affects: 'geometry',
    describe: 'how many individual set stones the 4 m of kerb line is laid in, with half stones at ' +
      'the mating ends so the joint rhythm carries across a butt joint. 3 gives long 2.04 m blocks ' +
      'and two reveals, 6 gives short 0.79 m setts and five; the module stays exactly 4.00 m and the ' +
      'triangle count moves with the joint count. A corner lays the count across its two arms either ' +
      'side of a fixed 0.70 m quadrant stone; a ramp keeps its own rhythm, since its joints ARE the ' +
      'transition breaks.',
  },
  wear: {
    type: 'range', default: 0, min: 0, max: 1, label: 'Wear', affects: 'geometry',
    describe: 'chipping along the street arris, where traffic hits it. 0 is a pristine newly set kerb ' +
      '(the approved default — genuinely clean, no marks at all). 1 knocks two 260-380 mm bites out ' +
      'of the top edge, each up to 50 mm deep, cut into the stone itself so the chamfer scallops and ' +
      'the top face narrows there. The chips never touch a reveal, a corner mitre or the outer 300 mm ' +
      'at either end, so the mating cross-section and the footprint are identical at every wear value.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

const DEFAULTS = { piece: 'straight', colorway: 'granite', height: HGT, stones: 4, wear: 0 };

function sectionOf(h, opt = {}) {
  const inset = opt.inset || 0, beds = opt.beds || [], run = opt.run || 0;
  const w = r4(HW - inset);
  const hh = r4(h - inset);

  const k = Math.min(1, h / 0.10) * (1 - 0.88 * run);
  const cd0 = CD * k;

  const bite = clamp(opt.bite || 0, 0, Math.max(0, hh - cd0 - bedRoom(beds, hh) - 0.010));
  const cw = r4(CW * k + bite * 1.2), cd = r4(cd0 + bite);
  const sw = r4(SW * k), sd = r4(SD * k);

  const g = Math.min(BEDW, (hh - cd) / 6);
  const d = Math.min(BEDD, w * 0.4);
  const bedY = beds.map((y) => r4(clamp(y, g + 0.003, Math.max(g + 0.004, hh - cd - g - 0.003))));

  const pts = [];
  const P = (t, y, zone) => pts.push([r4(t), r4(y), zone]);
  P(w, 0, 'face');
  for (const y of bedY) {
    P(w, r4(y - g), 'face');
    P(r4(w - d), y, 'joint');
    P(w, r4(y + g), 'face');
  }
  P(w, r4(hh - cd), 'face');
  P(r4(w - cw), hh, 'top');
  P(r4(-w + sw), hh, 'face');
  P(-w, r4(hh - sd), 'face');
  for (let i = bedY.length - 1; i >= 0; i--) {
    const y = bedY[i];
    P(-w, r4(y + g), 'joint');
    P(r4(-w + d), y, 'face');
    P(-w, r4(y - g), 'face');
  }
  P(-w, 0, 'face');
  return pts;
}

function bedRoom(beds, hh) {
  if (!beds.length) return 0;
  return Math.min(hh * 0.5, Math.max(...beds) + BEDW);
}

function bedsFor(h) {
  const r = h - COURSE;
  if (r < 0.035) return [];
  const n = Math.ceil(r / COURSE);
  const out = [];
  for (let i = 1; i <= n; i++) out.push(r4(r * i / n));
  return out;
}

function stationFn(piece) {
  const out = piece === 'corner-outer', inn = piece === 'corner-inner';
  return (arc, skew, mitre) => {

    if (mitre) return out ? (t) => [t, t] : (t) => [-t, t];
    if ((!out && !inn) || arc < HALF) {
      const x0 = r4(-HALF + arc);
      return (t) => [x0 + skew * t, t];
    }
    const s = r4(arc - HALF);
    return out ? (t) => [t, -s - skew * t]
               : (t) => [-t, s + skew * t];
  };
}

function heightFn(piece, h0) {
  if (piece !== 'ramp') return () => h0;
  const low = Math.min(0.030, h0 * 0.30);
  const [A, B, C, D] = RAMP;
  return (a) => a <= A ? h0
    : a < B ? h0 + (low - h0) * (a - A) / (B - A)
    : a <= C ? low
    : a < D ? low + (h0 - low) * (a - C) / (D - C)
    : h0;
}

function lay(at, run, w) {
  const m = w.length;
  const tot = w.reduce((s, x) => s + x, 0);
  const L = run - (m - 1) * JOINT;
  const out = [];
  let x = at;
  for (let i = 0; i < m; i++) {
    const len = i === m - 1 ? r4(at + run - x) : r4(L * w[i] / tot);
    out.push([r4(x), r4(x + len)]);
    x = r4(x + len + JOINT);
  }
  return out;
}

function stoneSpans(piece, n) {
  if (piece === 'ramp') {
    const out = [];
    let a = 0;
    for (const c of RAMP) { out.push([r4(a), r4(c - JOINT / 2)]); a = r4(c + JOINT / 2); }
    out.push([r4(a), LEN]);
    return out;
  }
  if (piece === 'corner-outer' || piece === 'corner-inner') {

    const m = Math.max(1, Math.round((n - 1) / 2));
    const armRun = r4(HALF - QUAD - JOINT);
    const inner = Array(m - 1).fill(1);
    return [
      ...lay(0, armRun, m === 1 ? [1] : [RATIO, ...inner]),
      [r4(HALF - QUAD), r4(HALF + QUAD)],
      ...lay(r4(HALF + QUAD + JOINT), armRun, m === 1 ? [1] : [...inner, RATIO]),
    ];
  }

  const w = piece === 'end' ? [RATIO, ...Array(n - 1).fill(1)]
                            : [RATIO, ...Array(n - 2).fill(1), RATIO];
  return lay(0, LEN, w);
}

function mulberry32(a) {
  return () => {
    a |= 0; a = a + 0x6D2B79F5 | 0;
    let t = Math.imul(a ^ a >>> 15, 1 | a);
    t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t;
    return ((t ^ t >>> 14) >>> 0) / 4294967296;
  };
}

function chipsOf(wear, spans, piece) {
  if (!(wear > 0)) return [];
  const corner = piece === 'corner-outer' || piece === 'corner-inner';
  const count = corner ? 1 : 1 + Math.round(wear);
  const rnd = mulberry32(0x8ba17c);
  const out = [];
  for (let i = 0; i < count; i++) {
    const c = 0.30 + (LEN - 0.60) * ((i + 0.5 + (rnd() - 0.5) * 0.6) / count);
    const half = (0.26 + rnd() * 0.12) / 2;
    const d = (0.030 + wear * 0.020) * (0.75 + rnd() * 0.5);
    const a0 = c - half, a1 = c + half;

    const host = spans.find((s) => a0 > s[0] + 0.02 && a1 < s[1] - 0.02);
    if (!host) continue;
    if (corner && a0 < HALF + QUAD && a1 > HALF - QUAD) continue;
    out.push({ arc: r4(a0), bite: 0 }, { arc: r4(a0 + 0.02), bite: d },
             { arc: r4(a1 - 0.02), bite: d }, { arc: r4(a1), bite: 0 });
  }
  return out;
}

function capIndices(pts) {
  const idx = pts.map((_, i) => i);

  let area = 0;
  for (let i = 0; i < pts.length; i++) {
    const j = (i + 1) % pts.length;
    area += pts[i][0] * pts[j][1] - pts[j][0] * pts[i][1];
  }
  const sgn = area < 0 ? -1 : 1;
  const cross = (a, b, c) => sgn * ((pts[b][0] - pts[a][0]) * (pts[c][1] - pts[a][1])
                                  - (pts[b][1] - pts[a][1]) * (pts[c][0] - pts[a][0]));
  const out = [];
  let guard = 0;
  while (idx.length > 3 && guard++ < 400) {
    let cut = -1;
    for (let i = 1; i <= idx.length - 2 && cut < 0; i++) {
      const a = idx[i - 1], b = idx[i], c = idx[i + 1];
      if (cross(a, b, c) <= 1e-12) continue;
      let ok = true;
      for (const p of idx) {
        if (p === a || p === b || p === c) continue;
        if (cross(a, b, p) >= 0 && cross(b, c, p) >= 0 && cross(c, a, p) >= 0) { ok = false; break; }
      }
      if (ok) cut = i;
    }
    if (cut < 0) cut = 1;
    out.push([idx[cut - 1], idx[cut], idx[cut + 1]]);
    idx.splice(cut, 1);
  }
  out.push([idx[0], idx[1], idx[2]]);
  return out;
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
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function finish(list) {
  const merged = mergeGeometries(list.filter((p) => p.pos.length).map((p) => prep(posGeo(p.pos), p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const hexOf = (v, d) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return d;
};

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const piece = params.piece.options.includes(o.piece) ? o.piece : 'straight';
  const h0    = clamp(+o.height || HGT, 0.06, 0.30);
  const n     = clamp(Math.round(+o.stones || 4), 3, 6);
  const wear  = clamp(+o.wear || 0, 0, 1);
  const corner = piece === 'corner-outer' || piece === 'corner-inner';

  const cw = COLORWAYS[o.colorway] || COLORWAYS.granite;
  const C = {
    face:  hexOf(opts.face,  cw.face),
    top:   hexOf(opts.top,   cw.top),
    joint: hexOf(opts.joint, cw.joint),
  };

  const beds     = bedsFor(h0);
  const station  = stationFn(piece);
  const heightAt = heightFn(piece, h0);
  const spans    = stoneSpans(piece, n);

  const solids = [];
  spans.forEach((s, i) => {
    solids.push({ a0: s[0], a1: s[1], kind: 'stone' });
    if (i < spans.length - 1) {
      solids.push({ a0: s[1], a1: spans[i + 1][0], kind: 'joint', skew: SKEWS[i % SKEWS.length] });
    }
  });

  const skewAt = new Map();
  for (const s of solids) {
    if (s.kind !== 'joint') continue;
    skewAt.set(s.a0.toFixed(6), s.skew);
    skewAt.set(s.a1.toFixed(6), s.skew);
  }

  const extras = chipsOf(wear, spans, piece);
  if (corner) extras.push({ arc: HALF, mitre: true });

  if (piece === 'end') extras.push({ arc: r4(LEN - 0.22), run: 0 }, { arc: r4(LEN - 0.10), run: 1 });

  const zones = { face: [], top: [], joint: [] };
  const tri = (out, a, b, c) => {
    const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
    const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
    const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
    if (nx * nx + ny * ny + nz * nz < 1e-14) return;
    out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
  };
  const quad = (out, a, b, c, d) => { tri(out, a, b, c); tri(out, a, c, d); };

  for (const s of solids) {
    const inside = extras.filter((e) => e.arc > s.a0 + 1e-6 && e.arc < s.a1 - 1e-6)
                         .sort((a, b) => a.arc - b.arc);
    const s0 = skewAt.get(s.a0.toFixed(6)) || 0;
    const s1 = skewAt.get(s.a1.toFixed(6)) || 0;
    const span = s.a1 - s.a0;
    let run = 0;
    const ringAt = (arc, e = {}) => {

      const f = span > 1e-9 ? (arc - s.a0) / span : 0;
      const skew = e.mitre ? 0 : s0 + (s1 - s0) * f;
      const pts = sectionOf(heightAt(arc), {
        inset: s.kind === 'joint' ? CUT : 0, beds,
        bite: s.kind === 'stone' ? (e.bite || 0) : 0,
        run: e.run !== undefined ? e.run : run,
      });
      return { pts, at: station(arc, skew, e.mitre) };
    };
    const rings = [ringAt(s.a0)];
    for (const e of inside) {
      if (e.run !== undefined) run = e.run;
      rings.push(ringAt(e.arc, e));
    }
    rings.push(ringAt(s.a1));

    const out = s.kind === 'joint' ? zones.joint : null;
    const V = (ring, j) => { const [t, y] = ring.pts[j]; const [x, z] = ring.at(t); return [x, y, z]; };
    for (let i = 0; i < rings.length - 1; i++) {
      const A = rings[i], B = rings[i + 1], m = A.pts.length;
      for (let j = 0; j < m; j++) {
        const k = (j + 1) % m;
        quad(out || zones[A.pts[j][2]], V(A, j), V(B, j), V(B, k), V(A, k));
      }
    }

    const first = rings[0], last = rings[rings.length - 1];
    const fa = capIndices(first.pts);
    const fb = capIndices(last.pts.slice().reverse());
    const cap = out || zones.face;
    const R = last.pts.length - 1;
    for (let i = 0; i < fa.length; i++) {
      tri(cap, V(first, fa[i][0]), V(first, fa[i][1]), V(first, fa[i][2]));
      const b = fb[i];
      tri(cap, V(last, R - b[0]), V(last, R - b[1]), V(last, R - b[2]));
    }
  }

  const g = new THREE.Group();
  g.name = 'curb-strip';
  const mesh = finish([
    { pos: zones.face,  c: C.face },
    { pos: zones.top,   c: C.top },
    { pos: zones.joint, c: C.joint },
  ]);
  mesh.name = 'curb-stones';
  g.add(mesh);
  return g;
}
export default createAsset;
