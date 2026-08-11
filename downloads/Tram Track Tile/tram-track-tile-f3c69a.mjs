/*
 * Tram Track Tile
 * https://polyfork.dev/asset/tram-track-tile-f3c69a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './tram-track-tile-f3c69a.mjs';
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
 *   colorway     choice  'city-asphalt' 'city-asphalt' | 'fresh-blacktop' | 'sun-faded' | 'wet-slate'
 *   asphalt      color   '#3C4145'      any hex or THREE.Color
 *   rail         color   '#A9AFB4'      any hex or THREE.Color
 *   stone        color   '#6B7278'      any hex or THREE.Color
 *   base         color   '#4E5459'      any hex or THREE.Color
 *   paint        color   '#E4E2DC'      any hex or THREE.Color
 *   piece        choice  'straight'     'straight' | 'corner' | 't-junction' | 'crossroads' | 'end'
 *   railProfile  choice  'grooved'      'grooved' | 'flat' | 'guarded'
 *   margin       choice  'asphalt'      'asphalt' | 'setts' | 'concrete'
 *   gauge        choice  'tram-1370'    'cape-1067' | 'tram-1370' | 'standard-1435'
 *   lines        toggle  false          true | false
 *   crossing     toggle  false          true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/tram-track-tile-f3c69a-params.json
 *
 * SPECS  170 triangles, 1 material, 4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;
const HALF = SIZE / 2;
const TOP_Y = 0.0;
const BOT_Y = -0.05;
const COURSE_Y = -0.04;

const GUT = -0.016;
const CH = -0.004;
const LIP = -0.008;
const FLG = -0.034;

const SETT_Y = -0.006;
const JOINT_Y = -0.012;
const MARGIN_W = 0.45;
const LINE_GAP = 0.16;
const LINE_W = 0.10;

const CORNER_R = HALF;
const ARC_SEG = 10;

const STEEL = {
  grooved: [
    [-0.224, CH], [-0.212, 0], [-0.151, 0], [-0.139, LIP],
    [-0.139, FLG], [-0.077, FLG], [-0.077, LIP], [-0.065, 0],
    [0.065, 0], [0.077, CH], [0.077, GUT],
  ],
  flat: [
    [-0.124, CH], [-0.112, 0],
    [0.112, 0], [0.124, CH], [0.124, GUT],
  ],
  guarded: [
    [-0.224, CH], [-0.212, 0], [-0.151, 0], [-0.139, LIP],
    [-0.139, FLG], [-0.077, FLG], [-0.077, LIP], [-0.065, 0],
    [0.065, 0], [0.077, LIP],
    [0.077, FLG], [0.139, FLG], [0.139, LIP], [0.151, 0],
    [0.212, 0], [0.224, CH], [0.224, GUT],
  ],
};

const ARM = { grooved: [0.269, 0.122], flat: [0.169, 0.169], guarded: [0.269, 0.269] };

const GAUGE = { 'cape-1067': 1.067, 'tram-1370': 1.370, 'standard-1435': 1.435 };
const PIECES = ['straight', 'corner', 't-junction', 'crossroads', 'end'];
const MARGINS = ['asphalt', 'setts', 'concrete'];

const COLORWAYS = {

  'city-asphalt':   { asphalt: '#3C4145', rail: '#A9AFB4', stone: '#6B7278', base: '#4E5459', paint: '#E4E2DC' },
  'fresh-blacktop': { asphalt: '#2E3134', rail: '#C7CBCC', stone: '#6B7278', base: '#1B1D20', paint: '#F2EFE7' },
  'sun-faded':      { asphalt: '#6B7278', rail: '#E4E2DC', stone: '#A9AFB4', base: '#8A9197', paint: '#F2EFE7' },
  'wet-slate':      { asphalt: '#2E3134', rail: '#8A9197', stone: '#4E5459', base: '#1B1D20', paint: '#C7CBCC' },
};

const DEF = {
  colorway: 'city-asphalt',
  railProfile: 'grooved',
  margin: 'asphalt',
  gauge: 'tram-1370',
  piece: 'straight',
  lines: false,
  crossing: false,
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: DEF.colorway, label: 'Colorway',
    options: Object.keys(COLORWAYS),
    describe: 'Curated kit-coherent scheme. city-asphalt is the shipped Little Tokyo road ' +
      'grey with bright steel; fresh-blacktop is near-black new asphalt with pale rails; ' +
      'sun-faded is a bleached mid-grey street; wet-slate is dark and low-contrast for rain.',
  },
  asphalt: {
    type: 'color', default: COLORWAYS['city-asphalt'].asphalt, label: 'Asphalt',
    describe: 'Albedo of the road surface, its settlement gutters and the tile edge course. ' +
      'Matches asphalt-road-tile-f6593c so the two tiles butt with no colour step.',
  },
  rail: {
    type: 'color', default: COLORWAYS['city-asphalt'].rail, label: 'Rail steel',
    describe: 'Albedo of the whole steel rail: head, guard lip, flangeway walls and floor, ' +
      'and the end piece\'s buffer block. The single feature that reads at distance, so keep ' +
      'it well above the asphalt in value.',
  },
  stone: {
    type: 'color', default: COLORWAYS['city-asphalt'].stone, label: 'Paved margin',
    describe: 'Albedo of the sett or concrete margin flanking the rails. Only visible when ' +
      'margin is setts or concrete; ignored at the default margin of asphalt.',
  },
  base: {
    type: 'color', default: COLORWAYS['city-asphalt'].base, label: 'Sub-base',
    describe: 'Albedo of the bottom 10 mm band on the tile edges and the underside — the ' +
      'bedding course seen where a tile meets a kerb or an open cut.',
  },
  paint: {
    type: 'color', default: COLORWAYS['city-asphalt'].paint, label: 'Road paint',
    describe: 'Albedo of the painted markings: the edge lines and the zebra crossing bars. ' +
      'Only emits triangles when lines or crossing is on. Off-white by default; take it to ' +
      'a warmer bone for a sun-bleached street.',
  },
  piece: {
    type: 'choice', default: DEF.piece, label: 'Piece', affects: 'geometry',
    options: PIECES,
    describe: 'Which piece of the tram line this 4 m cell builds. The surface is re-planned ' +
      'from scratch per value and the triangle count moves with it. straight runs the track ' +
      'edge to edge (the shipped default). corner turns 90 degrees inside the cell on two ' +
      'true concentric arcs about the cell corner, constant gauge through the bend, the ' +
      'flangeway on the gauge side all the way round. t-junction is the through track plus a ' +
      'right-angle branch to +X, crossing the through rails through real flangeway gaps. ' +
      'crossroads is a diamond crossing: two tracks at right angles, with the rail heads ' +
      'interrupted at all four crossing points so a flange can pass. end stops the track on a ' +
      'low buffer block with the asphalt closing over the railhead beyond it. EVERY piece is ' +
      'exactly 4.000 x 4.000 m, centred on the origin, and meets every open cell edge at the ' +
      'edge MIDPOINT with the two rail heads at the declared gauge, flush at y=0 — which is ' +
      'what lets any piece butt against any other. Uses the same five names as the kit road ' +
      'tile, so one setting drives both surfaces.',
  },
  railProfile: {
    type: 'choice', default: DEF.railProfile, label: 'Rail profile', affects: 'geometry',
    options: Object.keys(STEEL),
    describe: 'Rebuilds the rail cross-section, identically on every piece. grooved is street ' +
      'tramway rail: a 130 mm head with a 62 mm flangeway sunk 34 mm on the gauge side and a ' +
      'guard lip beyond it. flat is a plain 224 mm flush bar with no flangeway, for paved-over ' +
      'or decorative track. guarded adds a second flangeway and check rail outboard of the ' +
      'head, for bridge and junction sections. Triangle count rises grooved < guarded, falls ' +
      'at flat. The head centreline stays on the declared gauge at every value.',
  },
  margin: {
    type: 'choice', default: DEF.margin, label: 'Paved margin', affects: 'geometry',
    options: MARGINS,
    describe: 'What paves the strip between and immediately outboard of the rails. asphalt ' +
      'is flat road right up to the gutters (the reference look, and the cheapest). setts ' +
      'drops that strip 6 mm and cuts it into granite blocks with 50 mm joints at a 0.40 m ' +
      'pitch that chain across tile joints. concrete drops the same strip 6 mm as one ' +
      'unbroken track slab. setts and concrete use the Paved margin colour. NOTE: the sett ' +
      'coursing is laid only on the straight piece, where the run is straight enough to ' +
      'course; on corner, t-junction, crossroads and end the margin renders plain, so there ' +
      'setts and concrete build the same surface.',
  },
  gauge: {
    type: 'choice', default: DEF.gauge, label: 'Track gauge', affects: 'geometry',
    options: Object.keys(GAUGE),
    describe: 'Distance between the rail head centrelines, in metres: cape-1067 is Japanese ' +
      'narrow gauge, tram-1370 matches the kit tram city-tram-0d092d and is the default, ' +
      'standard-1435 is standard gauge. The rail SECTION is identical at every value — only ' +
      'the spacing changes, which is how real track is regauged — and the corner radii are ' +
      'derived from it, so a regauged corner still lands both rail heads on the edge ' +
      'midpoints. Set it once and every piece agrees.',
  },
  lines: {
    type: 'toggle', default: DEF.lines, label: 'Lane lines', affects: 'geometry',
    describe: 'OFF by default. Paints a solid road edge line on the asphalt 0.16 m outboard ' +
      'of the track corridor, both sides, following the piece: straight on a straight run, ' +
      'concentric arcs round a corner, along every arm of a junction. The paint is cut into ' +
      'the road plane at y=0 in the Road paint zone and never crosses a railhead. Off builds ' +
      'a completely unmarked road.',
  },
  crossing: {
    type: 'toggle', default: DEF.crossing, label: 'Zebra crossing', affects: 'geometry',
    describe: 'OFF by default. Paints a zebra crossing across the track on the -Z arm (radial ' +
      'bars round a corner). The bars are painted on the ASPHALT only and BREAK at every ' +
      'rail, gutter and flangeway, exactly as a real crossing stops at the steel — which is ' +
      'also what stops the stripes reading as a decal laid over the tile. Cut into the road ' +
      'plane at y=0 in the Road paint zone. Off builds a completely unmarked road.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

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

const EPS = 1e-9;
const near = (a, b) => Math.abs(a - b) < EPS;

function halfSection(g2, railProfile, margin, lines, coursed, extendTo) {
  const paved = margin !== 'asphalt';
  const arm = ARM[railProfile];
  const inB = g2 - arm[0];
  const outB = g2 + arm[1];
  const gutCol = paved ? 'stone' : 'asphalt';
  const fieldY = paved ? SETT_Y : TOP_Y;
  const settZ = (paved && margin === 'setts' && coursed) ? 'sett' : null;

  const pts = [], cols = [], zms = [];
  const seg = (x, y, c, z = null) => { pts.push([x, y]); cols.push(c); zms.push(z); };

  if (paved) {

    pts.push([0, JOINT_Y]);
    seg(0.025, JOINT_Y, 'stone');
    seg(0.025, SETT_Y, 'stone');
    seg(inB, SETT_Y, 'stone', settZ);
  } else {
    pts.push([0, TOP_Y]);
    seg(inB, TOP_Y, 'asphalt');
  }
  seg(inB, GUT, gutCol);

  seg(g2 + STEEL[railProfile][0][0], GUT, gutCol);

  for (const [dx, y] of STEEL[railProfile]) seg(g2 + dx, y, 'rail');

  seg(outB, GUT, gutCol);
  seg(outB, fieldY, gutCol);

  if (paved) {
    seg(outB + MARGIN_W, SETT_Y, 'stone', settZ);
    seg(outB + MARGIN_W, TOP_Y, 'asphalt');
  }
  if (lines) {
    const at = pts[pts.length - 1][0];
    seg(at + LINE_GAP, TOP_Y, 'asphalt');
    seg(at + LINE_GAP + LINE_W, TOP_Y, 'paint');
  }
  const W = pts[pts.length - 1][0];
  if (extendTo != null && extendTo > W) seg(extendTo, TOP_Y, 'asphalt');
  return { pts, cols, zms, W };
}

function section(g2, railProfile, margin, lines, coursed, extendTo) {
  const h = halfSection(g2, railProfile, margin, lines, coursed, extendTo);
  const n = h.cols.length;
  const pts = [], cols = [], zms = [];
  for (let i = n; i >= 1; i--) pts.push([-h.pts[i][0], h.pts[i][1]]);
  for (let i = n - 1; i >= 0; i--) { cols.push(h.cols[i]); zms.push(h.zms[i]); }
  for (let i = 0; i <= n; i++) pts.push(h.pts[i]);
  for (let i = 0; i < n; i++) { cols.push(h.cols[i]); zms.push(h.zms[i]); }
  return { pts, cols, zms, W: h.W };
}

function settZProfile() {
  const pitch = 0.40, n = 10, hw = 0.025, d = JOINT_Y - SETT_Y;
  const out = [[-HALF, 0]];
  for (let i = 0; i < n; i++) {
    const c = (i - (n - 1) / 2) * pitch;
    out.push([c - hw, 0], [c - hw, d], [c + hw, d], [c + hw, 0]);
  }
  out.push([HALF, 0]);
  return out;
}

function barBands(t0, t1) {
  const span = t1 - t0;
  if (span < 0.30) return [];
  let n = Math.min(4, Math.max(1, Math.floor((span + 0.24) / 0.60)));
  let bar = Math.min(0.36, (span - 0.24 * (n - 1)) / n);
  if (bar < 0.10) { n = 1; bar = Math.min(0.36, span); }
  const total = n * bar + 0.24 * (n - 1);
  const start = t0 + (span - total) / 2;
  const out = [];
  for (let i = 0; i < n; i++) {
    const a = start + i * (bar + 0.24);
    out.push([a, a + bar]);
  }
  return out;
}

function flatRect(ctx, x0, x1, z0, z1, col = 'asphalt') {
  if (x1 - x0 < EPS || z1 - z0 < EPS) return;
  const bands = (col === 'asphalt' && ctx.bars.length) ? ctx.bars : null;
  const emit = (a, b, c) => {
    const out = ctx.buf[c];
    quad(out, [x0, 0, a], [x0, 0, b], [x1, 0, b], [x1, 0, a]);
  };
  if (!bands) { emit(z0, z1, col); return; }
  let z = z0;
  for (const [b0, b1] of bands) {
    const a = Math.max(z0, b0), c = Math.min(z1, b1);
    if (c <= a) continue;
    if (a > z) emit(z, a, col);
    emit(a, c, 'paint');
    z = c;
  }
  if (z < z1) emit(z, z1, col);
}

function sweepZ(ctx, sec, z0, z1) {
  const settZ = settZProfile();
  for (let i = 0; i < sec.cols.length; i++) {
    const [x0, y0] = sec.pts[i], [x1, y1] = sec.pts[i + 1];
    if (near(x0, x1) && near(y0, y1)) continue;
    const col = sec.cols[i];
    const out = ctx.buf[col];

    let parts;
    if (sec.zms[i] === 'sett') {
      parts = [];
      for (let k = 0; k < settZ.length - 1; k++) {
        parts.push([settZ[k][0], settZ[k + 1][0], settZ[k][1], settZ[k + 1][1], col]);
      }
    } else if (ctx.bars.length && col === 'asphalt' && near(y0, 0) && near(y1, 0)) {
      parts = [];
      let z = -HALF;
      for (const [b0, b1] of ctx.bars) {
        if (b0 > z) parts.push([z, b0, 0, 0, col]);
        parts.push([b0, b1, 0, 0, 'paint']);
        z = b1;
      }
      if (z < HALF) parts.push([z, HALF, 0, 0, col]);
    } else {
      parts = [[-HALF, HALF, 0, 0, col]];
    }
    for (const [pa, pb, da, db, pc] of parts) {
      const za = Math.max(z0, pa), zb = Math.min(z1, pb);
      if (zb - za < EPS && !(near(za, zb) && da !== db)) continue;
      if (zb < za) continue;
      const ta = pb === pa ? 0 : (za - pa) / (pb - pa), tb = pb === pa ? 1 : (zb - pa) / (pb - pa);
      const ya = da + (db - da) * ta, yb = da + (db - da) * tb;
      quad(ctx.buf[pc],
        [x0, y0 + ya, za], [x0, y0 + yb, zb], [x1, y1 + yb, zb], [x1, y1 + ya, za]);
    }
  }
}

function sweepX(ctx, sec, x0, x1) {
  for (let i = 0; i < sec.cols.length; i++) {
    const [z0, y0] = sec.pts[i], [z1, y1] = sec.pts[i + 1];
    if (near(z0, z1) && near(y0, y1)) continue;
    const col = sec.cols[i];
    quad(ctx.buf[col],
      [x1, y0, z0], [x0, y0, z0], [x0, y1, z1], [x1, y1, z1]);
  }
}

function edgeZ(ctx, sign, spans) {
  const z = sign * HALF;
  for (const [x0, x1, y0, y1, col] of spans) {
    if (x1 - x0 < EPS) continue;
    const out = ctx.buf[col];
    if (sign > 0) quad(out, [x0, COURSE_Y, z], [x1, COURSE_Y, z], [x1, y1, z], [x0, y0, z]);
    else quad(out, [x0, y0, z], [x1, y1, z], [x1, COURSE_Y, z], [x0, COURSE_Y, z]);
  }
}

function edgeX(ctx, sign, spans) {
  const x = sign * HALF;
  for (const [z0, z1, y0, y1, col] of spans) {
    if (z1 - z0 < EPS) continue;
    const out = ctx.buf[col];
    if (sign > 0) quad(out, [x, y0, z0], [x, y1, z1], [x, COURSE_Y, z1], [x, COURSE_Y, z0]);
    else quad(out, [x, COURSE_Y, z0], [x, COURSE_Y, z1], [x, y1, z1], [x, y0, z0]);
  }
}

function sectionSpans(sec, flip) {
  const out = [];
  const n = sec.cols.length;
  for (let i = 0; i < n; i++) {
    const a = sec.pts[i], b = sec.pts[i + 1];
    if (flip) out.push([-b[0], -a[0], b[1], a[1], sec.cols[i]]);
    else out.push([a[0], b[0], a[1], b[1], sec.cols[i]]);
  }
  return flip ? out.reverse() : out;
}

function shell(ctx) {
  const B = ctx.buf.base;
  quad(B, [-HALF, BOT_Y, HALF], [HALF, BOT_Y, HALF], [HALF, COURSE_Y, HALF], [-HALF, COURSE_Y, HALF]);
  quad(B, [-HALF, COURSE_Y, -HALF], [HALF, COURSE_Y, -HALF], [HALF, BOT_Y, -HALF], [-HALF, BOT_Y, -HALF]);
  quad(B, [HALF, COURSE_Y, -HALF], [HALF, COURSE_Y, HALF], [HALF, BOT_Y, HALF], [HALF, BOT_Y, -HALF]);
  quad(B, [-HALF, COURSE_Y, HALF], [-HALF, COURSE_Y, -HALF], [-HALF, BOT_Y, -HALF], [-HALF, BOT_Y, HALF]);
  quad(B, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF]);
}

const RANK = { rail: 3, paint: 2, stone: 1, asphalt: 0 };

function crossField(ctx, sec, xApplyMax) {
  const P = sec.pts, C = sec.cols, n = C.length;
  const applies = (i) => xApplyMax == null || P[i][0] < xApplyMax + EPS;

  const yAt = (i, j) => {
    const a = P[i][1];
    if (!applies(i)) return a;
    return Math.min(a, P[j][1]);
  };
  const cells = [];
  for (let j = 0; j < n; j++) {
    const row = [];
    for (let i = 0; i < n; i++) {
      const mz = (P[i][1] + P[i + 1][1]) / 2;
      const mx = (applies(i) && applies(i + 1)) ? (P[j][1] + P[j + 1][1]) / 2 : 1;
      let col;
      if (mx < mz - EPS) col = C[j];
      else if (mz < mx - EPS) col = C[i];
      else col = (RANK[C[i]] >= RANK[C[j]]) ? C[i] : C[j];
      const y00 = yAt(i, j), y10 = yAt(i + 1, j), y01 = yAt(i, j + 1), y11 = yAt(i + 1, j + 1);
      const xConst = near(y00, y10) && near(y01, y11);
      const zConst = near(y00, y01) && near(y10, y11);
      row.push({ col, y00, y10, y01, y11, flat: xConst && zConst, xConst, zConst, used: false });
    }
    cells.push(row);
  }

  const emitCell = (i0, i1, j0, j1) => {
    const x0 = P[i0][0], x1 = P[i1 + 1][0], z0 = P[j0][0], z1 = P[j1 + 1][0];
    if (near(x0, x1) && near(z0, z1)) return;
    const a = cells[j0][i0], b = cells[j0][i1], c = cells[j1][i0], d = cells[j1][i1];
    quad(ctx.buf[a.col],
      [x0, a.y00, z0], [x0, c.y01, z1], [x1, d.y11, z1], [x1, b.y10, z0]);
  };
  const take = (i0, i1, j0, j1) => {
    for (let a = j0; a <= j1; a++) for (let b = i0; b <= i1; b++) cells[a][b].used = true;
    emitCell(i0, i1, j0, j1);
  };

  for (let j = 0; j < n; j++) {
    for (let i = 0; i < n; i++) {
      const c = cells[j][i];
      if (c.used || !c.flat) continue;
      const same = (d) => d && !d.used && d.flat && d.col === c.col && near(d.y00, c.y00);
      let i1 = i; while (i1 + 1 < n && same(cells[j][i1 + 1])) i1++;
      let j1 = j;
      outer: while (j1 + 1 < n) {
        for (let k = i; k <= i1; k++) if (!same(cells[j1 + 1][k])) break outer;
        j1++;
      }
      take(i, i1, j, j1);
    }
  }

  for (let i = 0; i < n; i++) {
    for (let j = 0; j < n; j++) {
      const c = cells[j][i];
      if (c.used || !c.zConst) continue;
      let j1 = j;
      while (j1 + 1 < n) {
        const d = cells[j1 + 1][i];
        if (!d || d.used || !d.zConst || d.col !== c.col ||
          !near(d.y00, c.y00) || !near(d.y10, c.y10)) break;
        j1++;
      }
      take(i, i, j, j1);
    }
  }

  for (let j = 0; j < n; j++) {
    for (let i = 0; i < n; i++) {
      const c = cells[j][i];
      if (c.used) continue;
      if (!c.xConst) { take(i, i, j, j); continue; }
      let i1 = i;
      while (i1 + 1 < n) {
        const d = cells[j][i1 + 1];
        if (!d || d.used || !d.xConst || d.col !== c.col ||
          !near(d.y00, c.y00) || !near(d.y01, c.y01)) break;
        i1++;
      }
      take(i, i1, j, j);
    }
  }
}

function buildStraight(ctx, sec) {
  sweepZ(ctx, sec, -HALF, HALF);
  edgeZ(ctx, 1, sectionSpans(sec, false));
  edgeZ(ctx, -1, sectionSpans(sec, false));
  edgeX(ctx, 1, [[-HALF, HALF, 0, 0, 'asphalt']]);
  edgeX(ctx, -1, [[-HALF, HALF, 0, 0, 'asphalt']]);
}

function buildEnd(ctx, sec, g2) {
  const zEnd = 0.10;
  sweepZ(ctx, sec, -HALF, zEnd);

  flatRect(ctx, -HALF, HALF, zEnd, HALF);

  for (let i = 0; i < sec.cols.length; i++) {
    const [x0, y0] = sec.pts[i], [x1, y1] = sec.pts[i + 1];
    if (x1 - x0 < EPS) continue;
    if (y0 >= -EPS && y1 >= -EPS) continue;
    quad(ctx.buf[sec.cols[i]],
      [x0, y0, zEnd], [x1, y1, zEnd], [x1, 0, zEnd], [x0, 0, zEnd]);
  }

  const bx = g2 + 0.10, bz0 = 0.02, bz1 = 0.30, top = 0.115, sh = 0.095, ins = 0.022;
  const R = ctx.buf.rail;
  const box = (x0, x1, y0, y1, z0, z1) => {
    quad(R, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]);
    quad(R, [x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0]);
    quad(R, [x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1]);
    quad(R, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0]);
  };
  box(-bx, bx, FLG, sh, bz0, bz1);

  quad(R, [-bx, sh, bz1], [bx, sh, bz1], [bx - ins, top, bz1 - ins], [-bx + ins, top, bz1 - ins]);
  quad(R, [bx, sh, bz0], [-bx, sh, bz0], [-bx + ins, top, bz0 + ins], [bx - ins, top, bz0 + ins]);
  quad(R, [bx, sh, bz1], [bx, sh, bz0], [bx - ins, top, bz0 + ins], [bx - ins, top, bz1 - ins]);
  quad(R, [-bx, sh, bz0], [-bx, sh, bz1], [-bx + ins, top, bz1 - ins], [-bx + ins, top, bz0 + ins]);
  quad(R, [-bx + ins, top, bz0 + ins], [-bx + ins, top, bz1 - ins],
    [bx - ins, top, bz1 - ins], [bx - ins, top, bz0 + ins]);

  edgeZ(ctx, -1, sectionSpans(sec, false));
  edgeZ(ctx, 1, [[-HALF, HALF, 0, 0, 'asphalt']]);
  edgeX(ctx, 1, [[-HALF, HALF, 0, 0, 'asphalt']]);
  edgeX(ctx, -1, [[-HALF, HALF, 0, 0, 'asphalt']]);
}

function buildCorner(ctx, sec) {
  const CX = HALF, CZ = -HALF, W = sec.W;
  const pt = (r, a) => [CX - r * Math.cos(a), CZ + r * Math.sin(a)];
  const D = Math.PI / 2;

  const set = new Set();
  for (let k = 0; k <= ARC_SEG; k++) set.add(+(k / ARC_SEG * D).toFixed(9));
  const bars = ctx.cornerBars;
  for (const [a, b] of bars) { set.add(+a.toFixed(9)); set.add(+b.toFixed(9)); }
  const A = [...set].sort((p, q) => p - q);
  const painted = (a0, a1) => bars.some(([b0, b1]) => a0 > b0 - EPS && a1 < b1 + EPS);

  for (let i = 0; i < sec.cols.length; i++) {
    const r0 = CORNER_R + sec.pts[i][0], r1 = CORNER_R + sec.pts[i + 1][0];
    const y0 = sec.pts[i][1], y1 = sec.pts[i + 1][1];
    if (near(r0, r1) && near(y0, y1)) continue;
    const base = sec.cols[i];
    const flatAsph = base === 'asphalt' && near(y0, 0) && near(y1, 0);
    for (let k = 0; k < A.length - 1; k++) {
      const col = (flatAsph && painted(A[k], A[k + 1])) ? 'paint' : base;
      const p0 = pt(r0, A[k]), p1 = pt(r1, A[k]), p2 = pt(r1, A[k + 1]), p3 = pt(r0, A[k + 1]);
      quad(ctx.buf[col],
        [p0[0], y0, p0[1]], [p1[0], y1, p1[1]], [p2[0], y1, p2[1]], [p3[0], y0, p3[1]]);
    }
  }

  const rIn = CORNER_R - W, rOut = CORNER_R + W;
  for (let k = 0; k < A.length - 1; k++) {
    const col = painted(A[k], A[k + 1]) ? 'paint' : 'asphalt';
    const b = pt(rIn, A[k]), c = pt(rIn, A[k + 1]);
    tri(ctx.buf[col], [CX, 0, CZ], [b[0], 0, b[1]], [c[0], 0, c[1]]);
  }

  const exit = (a) => (a <= D / 2 + EPS ? SIZE / Math.cos(a) : SIZE / Math.sin(a));
  for (let k = 0; k < A.length - 1; k++) {
    const col = painted(A[k], A[k + 1]) ? 'paint' : 'asphalt';
    const a0 = A[k], a1 = A[k + 1];
    const p0 = pt(rOut, a0), p1 = pt(exit(a0), a0), p2 = pt(exit(a1), a1), p3 = pt(rOut, a1);
    quad(ctx.buf[col],
      [p0[0], 0, p0[1]], [p1[0], 0, p1[1]], [p2[0], 0, p2[1]], [p3[0], 0, p3[1]]);
  }

  edgeZ(ctx, -1, [
    [-HALF, -W, 0, 0, 'asphalt'],
    ...sectionSpans(sec, true),
    [W, HALF, 0, 0, 'asphalt'],
  ]);
  edgeX(ctx, 1, [
    [-HALF, -W, 0, 0, 'asphalt'],
    ...sectionSpans(sec, false),
    [W, HALF, 0, 0, 'asphalt'],
  ]);
  edgeZ(ctx, 1, [[-HALF, HALF, 0, 0, 'asphalt']]);
  edgeX(ctx, -1, [[-HALF, HALF, 0, 0, 'asphalt']]);
}

function buildJunction(ctx, sec, g2, withPlusX) {
  const W = sec.W;
  sweepZ(ctx, sec, -HALF, -W);
  sweepZ(ctx, sec, W, HALF);
  sweepX(ctx, sec, -HALF, -W);
  if (withPlusX) sweepX(ctx, sec, W, HALF);

  crossField(ctx, sec, withPlusX ? null : g2 + 0.12);

  flatRect(ctx, -HALF, -W, -HALF, -W);
  flatRect(ctx, -HALF, -W, W, HALF);
  if (withPlusX) {
    flatRect(ctx, W, HALF, -HALF, -W);
    flatRect(ctx, W, HALF, W, HALF);
  } else {
    flatRect(ctx, W, HALF, -HALF, HALF);
  }
  const spans = sectionSpans(sec, false);
  const open = [[-HALF, -W, 0, 0, 'asphalt'], ...spans, [W, HALF, 0, 0, 'asphalt']];
  edgeZ(ctx, -1, open);
  edgeZ(ctx, 1, open);
  edgeX(ctx, -1, open);
  edgeX(ctx, 1, withPlusX ? open : [[-HALF, HALF, 0, 0, 'asphalt']]);
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {
    asphalt: p.asphalt || cw.asphalt,
    rail: p.rail || cw.rail,
    stone: p.stone || cw.stone,
    base: p.base || cw.base,
    paint: p.paint || cw.paint,
  };
  const railProfile = STEEL[p.railProfile] ? p.railProfile : DEF.railProfile;
  const margin = MARGINS.includes(p.margin) ? p.margin : DEF.margin;
  const gauge = GAUGE[p.gauge] ? GAUGE[p.gauge] : GAUGE[DEF.gauge];
  const piece = PIECES.includes(p.piece) ? p.piece : DEF.piece;
  const lines = p.lines === undefined ? DEF.lines : !!p.lines;
  const crossing = p.crossing === undefined ? DEF.crossing : !!p.crossing;
  const g2 = gauge / 2;

  const oneRun = piece === 'straight' || piece === 'end';
  const sec = section(g2, railProfile, margin, lines, piece === 'straight',
    oneRun ? HALF : null);

  const ctx = {
    buf: { asphalt: [], rail: [], stone: [], base: [], paint: [] },
    bars: [],
    cornerBars: [],
  };
  if (crossing) {
    if (piece === 'corner') {
      const D = Math.PI / 2;
      ctx.cornerBars = [[0.06 * D, 0.20 * D], [0.28 * D, 0.42 * D], [0.50 * D, 0.64 * D]];
    } else if (oneRun) {
      ctx.bars = barBands(-1.86, -0.34);
    } else {
      ctx.bars = barBands(-HALF + 0.10, -sec.W - 0.10);
    }
  }

  if (piece === 'straight') buildStraight(ctx, sec);
  else if (piece === 'end') buildEnd(ctx, sec, g2);
  else if (piece === 'corner') buildCorner(ctx, sec);
  else buildJunction(ctx, sec, g2, piece === 'crossroads');
  shell(ctx);

  const geos = [];
  for (const zone of ['asphalt', 'rail', 'stone', 'base', 'paint']) {
    if (ctx.buf[zone].length) geos.push(prep(posGeo(ctx.buf[zone]), C[zone]));
  }
  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'tram-track-tile-slab';

  const g = new THREE.Group();
  g.name = 'tram-track-tile';
  g.add(mesh);
  return g;
}

export default createAsset;
