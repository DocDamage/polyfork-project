/*
 * Stone Fence Panel
 * https://polyfork.dev/asset/stone-fence-panel-56d138
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './stone-fence-panel-56d138.mjs';
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
 *   colorway  choice  'pale-granite' 'pale-granite' | 'grey-granite' | 'warm-sandstone' | 'mossy-shrine'
 *   cap       color   '#e4e2dc'      any hex or THREE.Color
 *   stone     color   '#c7cbcc'      any hex or THREE.Color
 *   rail      color   '#f2efe7'      any hex or THREE.Color
 *   sill      color   '#a9afb4'      any hex or THREE.Color
 *   tallness  range   1              0.9 to 1.5
 *   modules   range   1              1 to 2
 *   girth     range   0.26           0.22 to 0.34
 *
 * Every option is described in full at https://polyfork.dev/cdn/stone-fence-panel-56d138-params.json
 *
 * SPECS  400 triangles, 1 material, 4 x 1 x 0.38 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BASE = {
  rail:  0xF2EFE7,
  cap:   0xE4E2DC,
  stone: 0xC7CBCC,
  sill:  0xA9AFB4,
};

const COLORWAYS = {

  'pale-granite':   { rail: 0xF2EFE7, cap: 0xE4E2DC, stone: 0xC7CBCC, sill: 0xA9AFB4 },
  'grey-granite':   { rail: 0xC7CBCC, cap: 0xA9AFB4, stone: 0x8A9197, sill: 0x4E5459 },
  'warm-sandstone': { rail: 0xF2EFE7, cap: 0xD9CFBC, stone: 0xB9A88C, sill: 0x8C7355 },
  'mossy-shrine':   { rail: 0xE4E2DC, cap: 0xC7CBCC, stone: 0xA9AFB4, sill: 0x2F6B4F },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'pale-granite', label: 'Colorway',
    options: ['pale-granite', 'grey-granite', 'warm-sandstone', 'mossy-shrine'],
    describe: 'curated kit-coherent scheme; sets all four zones together, and every '
      + 'scheme keeps the same value ladder — brightest rails, dressed caps, shafts a '
      + 'clear step below, and a sill darker again — so the elevation never collapses '
      + 'into one block. pale-granite is the reference: near-white rails and cap stones '
      + 'over pale granite shafts on a grey sill, as in the refs and the kit-concept '
      + 'shrine. grey-granite drops the whole run to cold city granite on a near-black '
      + 'base course. warm-sandstone takes it to honey sandstone with a brown sill. '
      + 'mossy-shrine keeps pale weathered stone above a deep green moss-grown sill, for '
      + 'a shaded corner of the shrine garden.',
  },
  cap: {
    type: 'color', default: 0xE4E2DC, label: 'Cap stones',
    describe: 'albedo of BOTH dressed fittings on every post — the pyramidal head cap '
      + 'with its collar, and the splayed foot block at the sill. They are one zone '
      + 'because they are one element: the cut stone that terminates each pier top and '
      + 'bottom, and a scheme that moved one without the other would read as a mistake. '
      + 'Held above the shaft colour so the row of pyramids reads against the sky at '
      + 'thumbnail size; taking it down to the shaft colour turns each post into a plain '
      + 'cut-off rectangle. It is also the ONLY zone the sill ever touches, so the pair '
      + 'of them sets how hard the run reads against the ground.',
  },
  stone: {
    type: 'color', default: 0xC7CBCC, label: 'Post shafts',
    describe: 'albedo of the square post shafts — the vertical masses that carry the '
      + 'whole silhouette between the foot blocks and the caps. The largest painted area '
      + 'on the piece, so it sets the overall stone colour. It is the hub of the object: '
      + 'the rails and the caps BOTH touch only this, so keep it clearly under both or '
      + 'the three collapse into one slab in elevation.',
  },
  rail: {
    type: 'color', default: 0xF2EFE7, label: 'Rails',
    describe: 'albedo of the square-section horizontal rails spanning every bay — 0.130 m '
      + 'baulks against a 4 m run, the members that turn the gaps into two long slots of '
      + 'daylight. It carries the WIDEST gap of any pair on the object because a rail '
      + 'overlaps a post shaft on screen from nearly every angle: within a rung of the '
      + 'shaft colour the rails vanish into the posts and the fence reads as three '
      + 'unconnected pillars. It is the brightest tone here, as in the ref front panel; '
      + 'the one direction that fails is taking it DARK, which reads as steel rather than '
      + 'as cut stone.',
  },
  sill: {
    type: 'color', default: 0xA9AFB4, label: 'Ground sill',
    describe: 'albedo of the continuous stepped ground beam that runs the full length and '
      + 'carries every post — the piece that touches the ground and takes the flat module '
      + 'ends. The darkest zone by default so the run sits DOWN onto the pavement instead '
      + 'of floating; lightening it to the cap colour (the only zone it touches) makes the '
      + 'whole panel look like it is hovering. It is also the one zone a consumer may want '
      + 'green (moss) or brown (earth-stained) to match the ground it stands on, and it '
      + 'can go a long way dark without the piece reading as anything but stone, because '
      + 'nothing pale sits directly against it.',
  },
  tallness: {
    type: 'range', default: 1.00, min: 0.90, max: 1.50, label: 'Fence height',
    affects: 'geometry',
    describe: 'REBUILDS the fence at a different height, 0.90 m (a low shrine garden kerb '
      + 'you see straight over) to 1.50 m (a tall precinct boundary wall). It is NOT a '
      + 'scale: the post section, the cap, the foot block, the sill, the rail section and '
      + 'the 0.315 m rail pitch all STAY PUT, and rails are added at that fixed pitch '
      + 'downward from the cap as the height allows — 1 rail below 0.93 m, 2 from 0.93 m, '
      + '3 from 1.25 m — so the triangle count moves with the knob (368 / 400 / 432 at '
      + '0.90 / 1.00 / 1.50 m). The top rail always hangs the same 0.300 m below '
      + 'the post head and the lowest one always clears the foot blocks, so the open band '
      + 'above the sill that makes this a fence rather than a wall survives the whole '
      + 'range instead of filling in at the tall end.',
  },
  modules: {
    type: 'range', default: 1, min: 1, max: 2, label: 'Modules',
    affects: 'geometry',
    describe: 'how many 4 m grid modules the panel spans: 1 = 4.00 m with 3 posts '
      + '(default), 2 = 8.00 m with 5. REBUILT, not stretched — real posts are added on '
      + 'the fixed 2 m station spacing and the rails are cut into one span per bay rather '
      + 'than one long baulk, so the bay proportion is identical at both values and the '
      + 'triangle count moves with the knob. The ends stay dead flat at exactly '
      + '±(2 x modules) m. The post that lands on the interior 4 m boundary carries a '
      + 'DOUBLE section, because that is exactly what a chained joint is — two end posts '
      + 'butted outer face to outer face — so an 8 m panel and two chained 4 m panels '
      + 'mass the same at every joint (see connect.png).',
  },
  girth: {
    type: 'range', default: 0.26, min: 0.22, max: 0.34, label: 'Post girth',
    affects: 'geometry',
    describe: 'the square section of every post, 0.22 m (a slender garden fence, more '
      + 'daylight through the bays) to 0.34 m (a heavy temple precinct pier). The whole '
      + 'stone FAMILY is derived from it so the members stay in proportion: the rails '
      + 'are always 0.50x the post section, the cap and foot blocks always stand the same '
      + '0.040-0.050 m proud of the shaft, and the sill always runs wider than the foot '
      + 'blocks it carries. Heights and rail positions do not move, so this changes the '
      + 'weight of the fence without changing its stance.',
  },
};

const MODULE     = 4.000;
const STATION    = 2.000;
const CHAM       = 0.0220;

const SILL_H     = 0.1600;
const SILL_STEP  = 0.0550;
const SILL_OUT0  = 0.0600;
const SILL_OUT1  = 0.0350;

const FOOT_BURY  = 0.0200;

const FOOT_TOP   = 0.2200;
const FOOT_SLOPE = 0.0150;
const FOOT_OUT   = 0.0500;

const CAP_H      = 0.2000;
const CAP_FLARE  = 0.0350;

const CAP_COLLAR = 0.0750;
const CROWN_FRAC = 0.420;

const RAIL_FRAC  = 0.500;

const RAIL_DROP  = 0.3000;

const RAIL_PITCH = 0.3150;

const RAIL_FLOOR = 0.2500;
const RAIL_MAX   = 3;
const EMBED      = 0.0300;

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

function triangulate(profile) {
  return THREE.ShapeUtils.triangulateShape(
    profile.map(([u, v]) => new THREE.Vector2(u, v)), []);
}
function extrudeX(profile, x0, x1, capX0, capX1) {
  const pos = [], n = profile.length;
  for (let k = 0; k < n; k++) {
    const p = profile[k], q = profile[(k + 1) % n];
    quad(pos, [x0, p[0], p[1]], [x0, q[0], q[1]], [x1, q[0], q[1]], [x1, p[0], p[1]]);
  }
  if (capX0 || capX1) {
    const at = (x, i) => [x, profile[i][0], profile[i][1]];
    for (const [a, b, c] of triangulate(profile)) {
      if (capX1) tri(pos, at(x1, a), at(x1, b), at(x1, c));
      if (capX0) tri(pos, at(x0, a), at(x0, c), at(x0, b));
    }
  }
  return posGeo(pos);
}

function sillProfile(hz0, hz1, c) {
  return [
    [SILL_H, hz1 - c], [SILL_H - c, hz1], [SILL_STEP, hz1], [SILL_STEP, hz0],
    [0, hz0], [0, -hz0], [SILL_STEP, -hz0], [SILL_STEP, -hz1],
    [SILL_H - c, -hz1], [SILL_H, -(hz1 - c)],
  ];
}

function railProfile(h, cy, c) {
  return [
    [cy + h, h - c], [cy + h - c, h], [cy - h + c, h], [cy - h, h - c],
    [cy - h, -h + c], [cy - h + c, -h], [cy + h - c, -h], [cy + h, -h + c],
  ];
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

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

export function createAsset(opts = {}) {

  const cw = COLORWAYS[opts.colorway] || COLORWAYS[params.colorway.default];
  const C = { ...BASE, ...cw };
  for (const k of ['cap', 'stone', 'rail', 'sill']) {
    if (opts[k] !== undefined && opts[k] !== null) C[k] = new THREE.Color(opts[k]).getHex();
  }

  const H = clamp(opts.tallness !== undefined ? +opts.tallness : params.tallness.default,
                  params.tallness.min, params.tallness.max);
  const M = clamp(Math.round(opts.modules !== undefined ? +opts.modules : params.modules.default),
                  params.modules.min, params.modules.max);
  const G = clamp(opts.girth !== undefined ? +opts.girth : params.girth.default,
                  params.girth.min, params.girth.max);

  const L = MODULE * M, HL = L / 2;
  const HX = G / 2;
  const RAIL_H = RAIL_FRAC * G / 2;
  const RAIL_C = Math.min(CHAM, 0.28 * RAIL_H);
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const railY = [];
  for (let y = H - RAIL_DROP; y - RAIL_H >= RAIL_FLOOR && railY.length < RAIL_MAX; y -= RAIL_PITCH)
    railY.push(y);

  add(extrudeX(sillProfile(HX + SILL_OUT0, HX + SILL_OUT1, CHAM), -HL, HL, true, true), C.sill);

  const posts = [];
  for (let k = 0; k <= 2 * M; k++) {
    const isMinusEnd = k === 0, isPlusEnd = k === 2 * M;
    const onModule = !isMinusEnd && !isPlusEnd && (k % 2 === 0);
    const cx = isMinusEnd ? -HL + HX : isPlusEnd ? HL - HX : -HL + STATION * k;
    posts.push({ cx, hx: onModule ? HX * 2 : HX, sharpMinusX: isMinusEnd, sharpPlusX: isPlusEnd });
  }

  const capBase = H - CAP_H;
  for (const P of posts) {

    const sec = (hxM, hxP, hz) =>
      postSection(hxM, hxP, hz, CHAM, P.sharpMinusX, P.sharpPlusX).map(([x, z]) => [x + P.cx, z]);
    const shaft = (hz) => sec(P.hx, P.hx, hz);
    const proud = (hz, out) =>
      sec(P.hx + (P.sharpMinusX ? 0 : out), P.hx + (P.sharpPlusX ? 0 : out), hz);

    const crownHX = CROWN_FRAC * P.hx;
    const crown = (hz) => sec(crownHX, crownHX, hz);

    const footBase = (hz) => {
      const free = P.hx + FOOT_OUT - 0.020;
      return sec(P.sharpMinusX ? P.hx - 0.015 : free, P.sharpPlusX ? P.hx - 0.015 : free, hz);
    };
    add(loftRings([
      { y: SILL_H - FOOT_BURY,   pts: footBase(HX + SILL_OUT1 - 0.015) },
      { y: SILL_H,               pts: proud(HX + FOOT_OUT, FOOT_OUT) },
      { y: FOOT_TOP,             pts: proud(HX + FOOT_OUT, FOOT_OUT) },
      { y: FOOT_TOP + FOOT_SLOPE, pts: shaft(HX) },
    ], false, false), C.cap);

    add(loftRings([
      { y: FOOT_TOP + FOOT_SLOPE, pts: shaft(HX) },
      { y: capBase,               pts: shaft(HX) },
    ], false, false), C.stone);

    add(loftRings([
      { y: capBase,                          pts: shaft(HX) },
      { y: capBase + CAP_FLARE,              pts: proud(HX + FOOT_OUT - 0.010, FOOT_OUT - 0.010) },
      { y: capBase + CAP_COLLAR,             pts: proud(HX + FOOT_OUT - 0.010, FOOT_OUT - 0.010) },
      { y: H,                                pts: crown(crownHX) },
    ], true, false), C.cap);
  }

  for (let k = 0; k + 1 < posts.length; k++) {
    const a = posts[k], b = posts[k + 1];
    const x0 = a.cx + a.hx - EMBED, x1 = b.cx - b.hx + EMBED;
    for (const y of railY) add(extrudeX(railProfile(RAIL_H, y, RAIL_C), x0, x1, false, false), C.rail);
  }

  const merged = mergeGeometries(parts.map(({ g, c }) => prep(g, c)));
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'stone-fence-panel-mesh';

  const g = new THREE.Group();
  g.name = 'stone-fence-panel';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};

export default createAsset;
