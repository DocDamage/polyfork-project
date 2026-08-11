/*
 * Gangplank
 * https://polyfork.dev/asset/gangplank-572d4e
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './gangplank-572d4e.mjs';
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
 *   colorway    choice  'weathered-oak' 'weathered-oak' | 'tar-pine' | 'sun-bleached'
 *   deck        color   '#9C6B3C'      any hex or THREE.Color
 *   cleat       color   '#C9975C'      any hex or THREE.Color
 *   rail        color   '#B99B68'      any hex or THREE.Color
 *   frame       color   '#6B4526'      any hex or THREE.Color
 *   sill        color   '#4A2E1B'      any hex or THREE.Color
 *   rise        range   1.2            0.85 to 1.6
 *   planks      range   12             9 to 16
 *   railHeight  range   0.62           0.42 to 0.95
 *   crossBrace  toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/gangplank-572d4e-params.json
 *
 * SPECS  486 triangles, 1 material, 0.9 x 1.9 x 3.42 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-oak': { deck: '#9C6B3C', cleat: '#C9975C', rail: '#B99B68', frame: '#6B4526', sill: '#4A2E1B' },
  'tar-pine':      { deck: '#6B4526', cleat: '#A88458', rail: '#8A8071', frame: '#4A2E1B', sill: '#2A2320' },
  'sun-bleached':  { deck: '#C4A46A', cleat: '#E8D6A8', rail: '#DCCBA6', frame: '#A88458', sill: '#8A8071' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'tar-pine', 'sun-bleached'],
    describe: 'Curated Pirate Cove timber schemes. weathered-oak is warm mid-brown oak with pale cleats (default); tar-pine is a dark tarred ramp with near-black ground skids; sun-bleached is pale driftwood, almost sand-coloured.',
  },
  deck: {
    type: 'color', default: '#9C6B3C', label: 'Deck planks',
    describe: 'Albedo of the whole plank layer you walk on — plank tops, the chamfered noses, the deck edges and its underside. The largest colour area on the part.',
  },
  cleat: {
    type: 'color', default: '#C9975C', label: 'Cleats',
    describe: 'Albedo of the paired stub grip blocks on the deck. Keep it lighter than the deck or the cleats disappear into the planks at distance.',
  },
  rail: {
    type: 'color', default: '#B99B68', label: 'Rails & posts',
    describe: 'Albedo of the two top rails, the slim intermediate posts and the chunky end posts/legs. This is the zone that silhouettes against the sky.',
  },
  frame: {
    type: 'color', default: '#6B4526', label: 'Under-frame',
    describe: 'Albedo of the structure below the deck: the two side stringers, the two transverse bearers, the header beam and bottom cross beam at the high end, and the X cross-brace. Darker than the deck so the ramp reads as planks resting on beams.',
  },
  sill: {
    type: 'color', default: '#4A2E1B', label: 'Ground sills',
    describe: 'Albedo of the two skids lying on the ground. Darkest zone on the part — reads as wet, mud-stained timber at the waterline.',
  },
  rise: {
    type: 'range', default: 1.2, min: 0.85, max: 1.6, affects: 'geometry', label: 'Rise',
    describe: 'Height in metres of the walking surface at the high end, i.e. what the ramp bridges to. 0.85 is a shallow beach ramp lying almost flat; 1.2 matches the kit pier deck; 1.6 is a steep ships-side plank with a tall braced trestle. Changes the slope and the whole side silhouette.',
  },
  planks: {
    type: 'range', default: 12, min: 9, max: 16, affects: 'geometry', label: 'Planks',
    describe: 'How many transverse deck boards span the run. 9 gives wide chunky boards with big proud noses and a coarse stepped tread; 16 gives narrow boards and a fine ribbed surface. Length is unchanged — only the pitch of the sawtooth.',
  },
  railHeight: {
    type: 'range', default: 0.62, min: 0.42, max: 0.95, affects: 'geometry', label: 'Rail height',
    describe: 'Height of the top rail above the deck, in metres. 0.42 is a shin-high kerb rail that barely breaks the outline; 0.62 is the reference low rail at waist height; 0.95 is a full chest-high handrail that doubles the object silhouette above the deck. The end posts always stand 0.10 m proud of the rail.',
  },
  crossBrace: {
    type: 'toggle', default: true, affects: 'geometry', label: 'Cross-brace',
    describe: 'The X of diagonal timbers filling the trestle bay under the high end. On, the end bay is a braced X (reference build). Off, the trestle is an open portal frame of two legs, a header and a ground beam — lighter, and reads as a simpler shore-built ramp.',
  },
};

const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function taperedBox(cx, cz, y0, y1, wb, db, wt, dt, skipBottom = false, skipTop = false) {
  const ring = (w, d, y) => ([
    [cx - w / 2, y, cz + d / 2], [cx + w / 2, y, cz + d / 2],
    [cx + w / 2, y, cz - d / 2], [cx - w / 2, y, cz - d / 2],
  ]);
  const b = ring(wb, db, y0), t = ring(wt, dt, y1);
  const out = [];
  for (let i = 0; i < 4; i++) {
    const j = (i + 1) % 4;
    quad(out, b[i], b[j], t[j], t[i]);
  }
  if (!skipTop) quad(out, t[0], t[1], t[2], t[3]);
  if (!skipBottom) quad(out, b[3], b[2], b[1], b[0]);
  return posGeo(out);
}

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  const cw = COLORWAYS[userParams.colorway] || COLORWAYS[p.colorway];
  Object.assign(p, cw);
  for (const [k, v] of Object.entries(userParams)) {
    if (v !== undefined && k in p) p[k] = v;
  }

  const C = { deck: p.deck, cleat: p.cleat, rail: p.rail, frame: p.frame, sill: p.sill };

  parts.length = 0;

  const HALF   = 0.45;
  const ZH     = -1.70;
  const ZT     =  1.72;
  const RISE   = p.rise;
  const TOE_Y  = 0.05;
  const S      = (RISE - TOE_Y) / (ZT - ZH);
  const SLOPE  = Math.atan(S);
  const base   = (z) => RISE - S * (z - ZH);

  const DT     = 0.07;
  const under  = (z) => Math.max(0, base(z) - DT);

  const N      = Math.max(9, Math.min(16, Math.round(p.planks)));
  const pitch  = (ZT - ZH) / N;
  const LIP    = Math.min(0.030, pitch * 0.12);
  const CH     = Math.min(0.020, pitch * 0.08);

  const SX     = 0.38;
  const W_LEG  = 0.12;
  const W_RAIL = 0.10;
  const W_POST = 0.08;
  const RAILH  = p.railHeight;
  const RAILT  = 0.11;

  function slopeBeam(cx, zc, len, yTop, h, wb, wt) {
    const g = taperedBox(0, 0, -h, 0, wb, len / Math.cos(SLOPE), wt, len / Math.cos(SLOPE));
    g.rotateX(SLOPE);
    g.translate(cx, yTop, zc);
    return g;
  }

  {
    const out = [];
    for (let i = 0; i < N; i++) {
      const z0 = ZH + i * pitch, z1 = z0 + pitch, zb = z1 - CH;
      const yA = base(z0);
      const yB = base(zb) + LIP * (pitch - CH) / pitch;
      const yD = base(z1);

      quad(out, [-HALF, yB, zb], [HALF, yB, zb], [HALF, yA, z0], [-HALF, yA, z0]);
      quad(out, [-HALF, yD, z1], [HALF, yD, z1], [HALF, yB, zb], [-HALF, yB, zb]);

      const uA = under(z0), uD = under(z1);
      const R = [[HALF, yA, z0], [HALF, yB, zb], [HALF, yD, z1], [HALF, uD, z1], [HALF, uA, z0]];
      tri(out, R[0], R[1], R[2]); tri(out, R[0], R[2], R[3]); tri(out, R[0], R[3], R[4]);
      const L = R.map(v => [-HALF, v[1], v[2]]);
      tri(out, L[2], L[1], L[0]); tri(out, L[3], L[2], L[0]); tri(out, L[4], L[3], L[0]);
    }

    const zLand = ZH + (RISE - DT) / S;
    quad(out, [HALF, under(ZH), ZH], [HALF, 0, zLand], [-HALF, 0, zLand], [-HALF, under(ZH), ZH]);
    quad(out, [HALF, 0, zLand], [HALF, 0, ZT], [-HALF, 0, ZT], [-HALF, 0, zLand]);

    quad(out, [-HALF, base(ZH), ZH], [HALF, base(ZH), ZH], [HALF, under(ZH), ZH], [-HALF, under(ZH), ZH]);
    quad(out, [-HALF, 0, ZT], [HALF, 0, ZT], [HALF, base(ZT), ZT], [-HALF, base(ZT), ZT]);
    add(posGeo(out), C.deck);
  }

  {
    const ROWS = 6;
    const tilt = Math.atan(S - LIP / pitch);
    for (let r = 0; r < ROWS; r++) {
      const i = Math.min(N - 1, Math.round((r + 0.55) * N / ROWS));
      const z0 = ZH + i * pitch, zc = z0 + pitch * 0.45;
      const y = base(zc) + LIP * (zc - z0) / pitch;
      for (const sx of [0.23, -0.23]) {
        const g = taperedBox(0, 0, -0.03, 0.058, 0.21, 0.125, 0.18, 0.095, true);
        g.rotateX(tilt);
        g.translate(sx, y, zc);
        add(g, C.cleat);
      }
    }
  }

  const Z_LEG_C  = ZH + 0.07;
  const Z_LEG_IN = ZH + 0.14;
  const Z_TOE_C  = ZT - 0.24;
  const Z_TOE_IN = Z_TOE_C - 0.06;
  const Z_SILL_END = ZH + (RISE - 0.40) / S;

  function sideFrame(side) {
    const cx = SX * side;
    const flip = side < 0;
    const wind = (out) => {
      if (!flip) return out;
      const r = [];
      for (let i = 0; i < out.length; i += 9) {
        r.push(out[i + 6], out[i + 7], out[i + 8], out[i + 3], out[i + 4], out[i + 5], out[i], out[i + 1], out[i + 2]);
      }
      return r;
    };

    {
      const zEnd = ZH + (RISE - 0.22) / S;
      const zFin = Math.min(ZT - 0.5, zEnd + 0.45);
      const zs = [Z_LEG_IN, zEnd, zFin];
      const top = zs.map(z => base(z) - 0.05);
      const bot = zs.map(z => Math.max(0, base(z) - 0.29));

      const x0 = (SX - 0.06) * side, x1 = (SX + 0.06) * side;
      const out = [];
      for (let i = 0; i < zs.length - 1; i++) {
        const za = zs[i], zb = zs[i + 1];
        quad(out, [x1, top[i], za], [x1, top[i + 1], zb], [x1, bot[i + 1], zb], [x1, bot[i], za]);
        quad(out, [x0, bot[i], za], [x0, bot[i + 1], zb], [x0, top[i + 1], zb], [x0, top[i], za]);
        quad(out, [x1, bot[i], za], [x1, bot[i + 1], zb], [x0, bot[i + 1], zb], [x0, bot[i], za]);
      }
      const n = zs.length - 1;
      quad(out, [x0, bot[0], zs[0]], [x0, top[0], zs[0]], [x1, top[0], zs[0]], [x1, bot[0], zs[0]]);
      quad(out, [x1, bot[n], zs[n]], [x1, top[n], zs[n]], [x0, top[n], zs[n]], [x0, bot[n], zs[n]]);
      add(posGeo(wind(out)), C.frame);
    }

    add(taperedBox(cx, (ZH + Z_SILL_END) / 2, 0, 0.11,
      0.12, Z_SILL_END - ZH, 0.105, Z_SILL_END - ZH - 0.05), C.sill);

    add(taperedBox(cx, Z_LEG_C, 0.08, base(Z_LEG_C) + RAILH + 0.10,
      W_LEG, 0.14, W_LEG * 0.86, 0.12), C.rail);

    add(taperedBox(cx, Z_TOE_C, base(Z_TOE_C) - 0.05, base(Z_TOE_C) + RAILH + 0.10,
      W_LEG, 0.13, W_LEG * 0.86, 0.112, true), C.rail);

    for (let k = 1; k <= 3; k++) {
      const z = Z_LEG_IN + k * (Z_TOE_IN - Z_LEG_IN) / 4;
      add(taperedBox(cx, z, base(z) - 0.05, base(z) + RAILH - 0.04,
        W_POST, 0.10, W_POST * 0.88, 0.09, true, true), C.rail);
    }

    const zA = Z_LEG_IN - 0.03, zB = Z_TOE_IN + 0.03;
    add(slopeBeam(cx, (zA + zB) / 2, zB - zA, base((zA + zB) / 2) + RAILH,
      RAILT, W_RAIL, W_RAIL * 0.62), C.rail);
  }
  for (const side of [1, -1]) sideFrame(side);

  const yHead = base(Z_LEG_C) - DT - 0.16;
  add(taperedBox(0, Z_LEG_C, yHead, base(Z_LEG_C) - 0.05, 0.66, 0.13, 0.64, 0.11, false, true), C.frame);
  add(taperedBox(0, Z_LEG_C, 0, 0.12, 0.66, 0.13, 0.645, 0.115), C.frame);

  for (const zc of [ZH + (ZT - ZH) * 0.34, ZH + (ZT - ZH) * 0.60]) {
    const g = taperedBox(0, 0, -0.13, 0, 0.64, 0.15, 0.62, 0.13, false, true);
    g.rotateX(SLOPE);
    g.translate(0, base(zc) - DT + 0.01, zc);
    add(g, C.frame);
  }

  if (p.crossBrace) {
    const x = 0.35, yLo = 0.13, yHi = yHead - 0.02;
    const len = Math.hypot(2 * x, yHi - yLo);
    const ang = Math.atan2(yHi - yLo, 2 * x);
    for (const [dir, zc] of [[1, Z_LEG_C - 0.035], [-1, Z_LEG_C + 0.035]]) {
      const g = taperedBox(0, 0, -0.05, 0.05, 0.075, len, 0.065, len);
      g.rotateY(Math.PI / 2);
      g.rotateZ(dir * ang);
      g.translate(0, (yLo + yHi) / 2, zc);
      add(g, C.frame);
    }
  }

  const g = new THREE.Group();
  g.name = 'gangplank';
  g.add(finish(parts));
  parts.length = 0;
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

function finish(list) {
  const merged = mergeGeometries(list.map(q => prep(q.g, q.c)));
  if (!merged) throw new Error('gangplank: mergeGeometries returned null');
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'gangplank-mesh';
  return mesh;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;
