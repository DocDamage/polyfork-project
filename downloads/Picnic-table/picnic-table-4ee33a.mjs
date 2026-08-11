/*
 * Picnic-table
 * https://polyfork.dev/asset/picnic-table-4ee33a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './picnic-table-4ee33a.mjs';
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
 *   colorway  choice  'weathered-cedar' 'weathered-cedar' | 'redwood-charcoal' | 'diner-red' | 'seaside-blue'
 *   wood      color   '#ae8566'      any hex or THREE.Color
 *   frame     color   '#3d3f46'      any hex or THREE.Color
 *   rail      color   '#4c4f57'      any hex or THREE.Color
 *   bolt      color   '#898c95'      any hex or THREE.Color
 *   length    range   1.8            1.4 to 2.4
 *   slats     range   5              4 to 7
 *   spread    range   1              0.95 to 1.18
 *
 * Every option is described in full at https://polyfork.dev/cdn/picnic-table-4ee33a-params.json
 *
 * SPECS  484 triangles, 1 material, 1.8 x 0.75 x 1.51 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-cedar':   { wood: 0xae8566, frame: 0x3d3f46, rail: 0x4c4f57, bolt: 0x898c95 },
  'redwood-charcoal':  { wood: 0x875e43, frame: 0x2a2d35, rail: 0x3d3f46, bolt: 0x898c95 },
  'diner-red':         { wood: 0xddceb0, frame: 0x823630, rail: 0x98443d, bolt: 0xc2c7cd },
  'seaside-blue':      { wood: 0xc7baa6, frame: 0x2a3a6b, rail: 0x4e7692, bolt: 0xc2c7cd },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-cedar', label: 'Colorway',
    options: ['weathered-cedar', 'redwood-charcoal', 'diner-red', 'seaside-blue'],
    describe: 'curated kit-coherent scheme. weathered-cedar: tan timber on charcoal ' +
      'steel (the reference). redwood-charcoal: darker red-brown timber, near-black ' +
      'frame. diner-red: pale bleached planks on a retro diner-red frame. ' +
      'seaside-blue: pale planks on a navy frame with steel-blue rails.',
  },
  wood: {
    type: 'color', default: '#ae8566', label: 'Wood',
    describe: 'albedo of all nine plank slats — the five tabletop planks and the two ' +
      'planks of each bench. The dominant colour of the asset.',
  },
  frame: {
    type: 'color', default: '#3d3f46', label: 'Frame',
    describe: 'albedo of the four splayed A-frame legs and the two top cleats under ' +
      'the tabletop. Keep it clearly darker than the wood; the two-tone split is the ' +
      "asset's identity.",
  },
  rail: {
    type: 'color', default: '#4c4f57', label: 'Seat rail',
    describe: 'albedo of the two seat rails that carry the benches and of the centre ' +
      'stringer. Intended one value step LIGHTER than the frame so the rail reads as ' +
      'crossing in front of the legs; set it equal to the frame for a monotone frame.',
  },
  bolt: {
    type: 'color', default: '#898c95', label: 'Bolt heads',
    describe: 'albedo of the eight bare-steel bolt heads on the frame. A light step ' +
      'against the frame makes them read as real fittings rather than dimples.',
  },
  length: {
    type: 'range', default: 1.8, min: 1.4, max: 2.4, label: 'Length', affects: 'geometry',
    describe: 'table length in metres along the planks. 1.4 is a compact two-seater ' +
      'square-ish table; 2.4 is a long banquet table. The end frames stay inset 0.35m ' +
      'from each end, so they slide apart as the table grows.',
  },
  slats: {
    type: 'range', default: 5, min: 4, max: 7, step: 1, label: 'Top slats',
    affects: 'geometry',
    describe: 'how many planks make up the 0.80m-wide tabletop. The deck width is ' +
      'fixed, so 4 gives four broad 188mm boards and 7 gives seven narrow 106mm ' +
      'boards with more visible gaps. Bench slats are unaffected.',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.95, max: 1.18, label: 'Bench spread',
    affects: 'geometry',
    describe: 'how far the benches and leg feet sit out from the centreline. 0.95 ' +
      'tucks the seats in tight against the tabletop edge for a narrow 1.44m ' +
      'footprint; 1.18 splays them to a generous 1.73m with a much wider leg stance. ' +
      'The tabletop itself does not change.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function rectProf(cz, cy, w, t, c) {
  const W = w / 2, T = t / 2;
  return [
    [-W + c, -T], [W - c, -T], [W, -T + c], [W, T - c],
    [W - c, T], [-W + c, T], [-W, T - c], [-W, -T + c],
  ].map(([a, b]) => [cz + a, cy + b]);
}

function legProf(zBot, zTop, y0, y1, hw, ch, cv) {
  const zAt = (y) => zBot + (zTop - zBot) * ((y - y0) / (y1 - y0));
  const bo = zAt(y0 + cv), to = zAt(y1 - cv);
  return [
    [zBot - hw + ch, y0], [zBot + hw - ch, y0],
    [bo + hw, y0 + cv], [to + hw, y1 - cv],
    [zTop + hw - ch, y1], [zTop - hw + ch, y1],
    [to - hw, y1 - cv], [bo - hw, y0 + cv],
  ];
}

function mirrorZ(prof) { return prof.map(([z, y]) => [-z, y]).reverse(); }

function sweepX(prof, x0, x1) {
  const pos = [];
  for (let i = 0; i < prof.length; i++) {
    const p = prof[i], q = prof[(i + 1) % prof.length];
    quad(pos, [x0, p[1], p[0]], [x1, p[1], p[0]], [x1, q[1], q[0]], [x0, q[1], q[0]]);
  }
  for (let i = 1; i < prof.length - 1; i++) {
    const a0 = [x0, prof[0][1], prof[0][0]];
    const b0 = [x0, prof[i][1], prof[i][0]];
    const c0 = [x0, prof[i + 1][1], prof[i + 1][0]];
    tri(pos, a0, b0, c0);
    tri(pos, [x1, a0[1], a0[2]], [x1, c0[1], c0[2]], [x1, b0[1], b0[2]]);
  }
  return posGeo(pos);
}

function rivet(cx, cy, cz, nx, ny, nz, r = 0.014, h = 0.008) {
  const n = new THREE.Vector3(nx, ny, nz).normalize();
  const up = Math.abs(n.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
  const t = new THREE.Vector3().crossVectors(up, n).normalize();
  const b = new THREE.Vector3().crossVectors(n, t).normalize();
  const apex = [cx + n.x * h, cy + n.y * h, cz + n.z * h];
  const ring = [];
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2, cs = Math.cos(a) * r, sn = Math.sin(a) * r;
    ring.push([cx + t.x * cs + b.x * sn, cy + t.y * cs + b.y * sn, cz + t.z * cs + b.z * sn]);
  }
  const pos = [];
  for (let i = 0; i < 6; i++) tri(pos, apex, ring[i], ring[(i + 1) % 6]);
  return posGeo(pos);
}

const DECK_W = 0.796;
const GAP = 0.014;
const TOP_Y0 = 0.700, TOP_Y1 = 0.750;
const SEAT_Y0 = 0.405, SEAT_Y1 = 0.450;
const BURY = 0.012;
const LEG_HW = 0.073;
const LEG_T = 0.075;
const Z_FOOT = 0.643;
const Z_HEAD = 0.130;
const BENCH_Z = 0.600;
const RAIL_Z = 0.735;
const OVERHANG = 0.35;

export function createAsset(opts = {}) {

  const cw = COLORWAYS[opts.colorway] || COLORWAYS[params.colorway.default];
  const C = { ...cw };
  for (const k of ['wood', 'frame', 'rail', 'bolt']) {
    if (opts[k] !== undefined) C[k] = new THREE.Color(opts[k]).getHex();
  }
  const L = opts.length !== undefined ? +opts.length : params.length.default;
  const N = Math.max(4, Math.min(7, Math.round(opts.slats !== undefined ? +opts.slats : params.slats.default)));
  const S = opts.spread !== undefined ? +opts.spread : params.spread.default;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const HX = L / 2;
  const BX = HX - 0.04;
  const FX = Math.max(0.30, HX - OVERHANG);
  const zFoot = Z_FOOT * S, zBench = BENCH_Z * S, zRail = RAIL_Z * S;

  const pw = (DECK_W - (N - 1) * GAP) / N;
  const pc = Math.min(0.008, pw * 0.12);
  for (let i = 0; i < N; i++) {
    const cz = -DECK_W / 2 + pw / 2 + i * (pw + GAP);
    add(sweepX(rectProf(cz, (TOP_Y0 + TOP_Y1) / 2, pw, TOP_Y1 - TOP_Y0, pc), -HX, HX), C.wood);
  }

  const bw = 0.148, bt = SEAT_Y1 - SEAT_Y0, by = (SEAT_Y0 + SEAT_Y1) / 2;
  for (const sz of [1, -1]) {
    for (const off of [-(bw + GAP) / 2, (bw + GAP) / 2]) {
      const prof = rectProf(sz * zBench + off, by, bw, bt, 0.007);
      add(sweepX(prof, -BX, BX), C.wood);
    }
  }

  for (const sx of [1, -1]) {
    const fx = sx * FX;
    const x0 = fx - LEG_T / 2, x1 = fx + LEG_T / 2;

    const leg = legProf(zFoot, Z_HEAD, 0, TOP_Y0 + BURY, LEG_HW, 0.016, 0.013);
    add(sweepX(leg, x0, x1), C.frame);
    add(sweepX(mirrorZ(leg), x0, x1), C.frame);

    const cx = fx - sx * 0.060;
    add(box(0.065, TOP_Y0 + BURY - 0.620, 0.680, cx, (0.620 + TOP_Y0 + BURY) / 2, 0), C.frame);

    const rx = fx + sx * 0.0575;
    add(box(0.060, SEAT_Y0 + BURY - 0.345, 2 * zRail, rx, (0.345 + SEAT_Y0 + BURY) / 2, 0), C.rail);

    add(box(0.060, TOP_Y0 + BURY - 0.395, 0.072, rx, (0.395 + TOP_Y0 + BURY) / 2, 0), C.rail);

    const zAt = (y) => zFoot + (Z_HEAD - zFoot) * (y / (TOP_Y0 + BURY));
    for (const sz of [1, -1]) {
      add(rivet(fx + sx * 0.0885, 0.378, sz * zAt(0.378), sx, 0, 0), C.bolt);
      add(rivet(fx + sx * (LEG_T / 2 + 0.001), 0.648, sz * zAt(0.648), sx, 0, 0), C.bolt);
    }
  }

  const geos = parts.map(({ g, c }) => {
    const geo = g.toNonIndexed();
    geo.deleteAttribute('uv');
    geo.deleteAttribute('normal');
    const col = new THREE.Color(c);
    const n = geo.attributes.position.count;
    const arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i * 3] = col.r; arr[i * 3 + 1] = col.g; arr[i * 3 + 2] = col.b; }
    geo.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    return geo;
  });
  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'picnic-table-mesh';

  const g = new THREE.Group();
  g.name = 'picnic-table';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};
export default createAsset;
