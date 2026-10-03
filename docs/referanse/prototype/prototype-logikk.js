// Utdrag av logikken i Main.dc.html (interaktiv prototype), versjon 18 av designcanvaset.
// Dette er REFERANSEOPPFØRSEL, ikke kode som skal kjøres i spillet.
// Det er JavaScript for designverktøyet (klassen DCLogic, renderVals() gir verdier til malen,
// this.state/this.setState som i React). Les det for å se nøyaktig hvordan reglene i SPEC.md
// er tenkt: alvorlighet, telling, ringfarge, hva som dukker opp ved knappen, tekster i tooltip.
// Egenskaper (props) for tavla: {"aapen":{"editor":"boolean","default":false},"side":{"editor":"enum","options":["ingen","venstre","hoyre","begge"],"default":"ingen"},"bakgrunn":{"editor":"boolean","default":true},"$preview":{"width":1040,"height":720}}
class Component extends DCLogic {
  base() {
    return {
      open: undefined,
      openL: undefined,
      openR: undefined,
      pbSide: 'left',
      posX: 488,
      posY: 44,
      dragging: false,
      hover: null,
      locked: false,
      tip: null,
      flash: null,
      shut: {},
      here: 'Stormwind',
      cities: ['Stormwind', 'Ironforge', 'Darnassus'],
      party: [
        { id: 'brakk', name: 'Brakk', color: '#C79C6E', rolle: 'tank' },
        { id: 'lirael', name: 'Lirael', color: '#69CCF0' },
        { id: 'tosk', name: 'Tosk', color: '#FFFFFF' },
        { id: 'vesla', name: 'Vesla', color: '#FFF569' }
      ],
      gruppe: [
        { id: 'pb-motw', name: 'Mark of the Wild', short: 'MotW', kind: 'paw', tier: 1, has: { brakk: 0, lirael: 1, tosk: 1, vesla: 0 } },
        { id: 'pb-thorns', name: 'Thorns', short: 'Thorns', kind: 'thorn', tier: 2, only: ['brakk'], has: { brakk: 0 } }
      ],
      poster: [
        { id: 'motw', type: 'spell', name: 'Mark of the Wild', short: 'MotW', kind: 'paw', tier: 1, secs: 0, left: 'ikke på', full: '30 min', fullSecs: 1800, st: 'off' },
        { id: 'thorns', type: 'spell', name: 'Thorns', short: 'Thorns', kind: 'thorn', tier: 1, secs: 360, left: '6 min', full: '10 min', fullSecs: 600, st: 'ok' },
        { id: 'flask', type: 'buffitem', name: 'Flask of the Titans', short: 'Flask', kind: 'flaske', tier: 1, secs: 0, left: 'ikke på', full: '2 t', fullSecs: 7200, st: 'off', have: 3, want: 2 },
        { id: 'fed', type: 'buffitem', name: 'Well Fed', item: 'Smoked Desert Dumplings', short: 'Well Fed', kind: 'food', tier: 2, secs: 720, left: '12 min', full: '15 min', fullSecs: 900, st: 'ok', have: 10, want: 10 },
        { id: 'mong', type: 'buffitem', name: 'Elixir of the Mongoose', short: 'Mongoose', kind: 'elixir', tier: 2, secs: 2880, left: '48 min', full: '60 min', fullSecs: 3600, st: 'ok', have: 3, want: 4 },
        { id: 'def', type: 'buffitem', name: 'Elixir of Superior Defense', short: 'Defense', kind: 'shield', tier: 2, secs: 0, left: 'ikke på', full: '60 min', fullSecs: 3600, st: 'off', have: 4, want: 5 },
        { id: 'band', type: 'item', name: 'Runecloth Bandage', short: 'Bandage', kind: 'bandage', tier: 2, have: 0, want: 10 },
        { id: 'mana', type: 'item', name: 'Major Mana Potion', short: 'Mana', kind: 'potion', tier: 2, have: 5, want: 5 }
      ]
    };
  }
  cur() {
    return Object.assign(this.base(), this.state || {});
  }
  oppdater(liste, id, fn) {
    const c = this.cur();
    const o = {};
    o[liste] = c[liste].map((x) => (x.id === id ? Object.assign({}, x, fn(x)) : x));
    this.setState(o);
  }
  renderVals() {
    const s = this.cur();
    const C = { ok: '#40BF40', warn: '#FF8C1A', bad: '#FF2020' };
    const SEVC = ['#ECE6D8', C.warn, C.bad];
    const NR = { 1: 'I', 2: 'II' };
    const HINT = { 1: 'Tier I: dukker opp ved knappen når den mangler', 2: 'Tier II: bare i sidemenyen' };
    const open = s.open === undefined ? !!this.props.aapen : s.open;
    const ps = this.props.side;
    const openL = s.openL === undefined ? (ps === 'venstre' || ps === 'begge') : s.openL;
    const openR = s.openR === undefined ? (ps === 'hoyre' || ps === 'begge') : s.openR;
    const showBg = this.props.bakgrunn ?? true;
    const leave = () => this.setState({ tip: null });
    const byId = {};
    s.party.forEach((m) => { byId[m.id] = m; });

    const hasStock = (p) => p.type === 'item' || p.type === 'buffitem';
    const buffSev = (p) => (p.type === 'item' ? 0 : (p.st === 'off' || p.st === 'bad') ? 2 : p.st === 'warn' ? 1 : 0);
    const stockSev = (p) => (!hasStock(p) ? 0 : p.have <= 0 ? 2 : p.have < p.want ? 1 : 0);
    const sev = (p) => Math.max(buffSev(p), stockSev(p));
    const kanTrykkes = (p) => (p.type === 'spell' ? buffSev(p) > 0 : p.type === 'buffitem' ? buffSev(p) > 0 && p.have > 0 : false);
    const pbMissing = (g) => Object.keys(g.has).filter((k) => !g.has[k]);

    const common = (key, p, liste, ny, forsvinner) => ({
      isBuff: true, isSkille: false, isSlot: false,
      id: p.id, name: p.name, kind: p.kind,
      cls: ny ? (s.flash === p.id ? (forsvinner ? 'ut' : '') : 'ny') : '',
      effekt: s.flash === p.id ? 'trykket' : s.tip === key ? 'mus' : 'ingen',
      tierNr: NR[p.tier],
      tierHint: HINT[p.tier],
      tip: s.tip === key,
      enter: () => this.setState({ tip: key }),
      cycle: (e) => {
        if (e && e.preventDefault) e.preventDefault();
        this.oppdater(liste, p.id, (x) => ({ tier: x.tier === 1 ? 2 : 1 }));
      }
    });
    // Trykk: knappen trykkes ned (gull), så er buffen på. Ved knappen forsvinner den da.
    const trykk = (id, apply) => {
      this.setState({ flash: id });
      setTimeout(() => {
        apply();
        const o = {};
        if (this.cur().flash === id) o.flash = null;
        if (String(this.cur().tip || '').indexOf('stub:' + id) !== -1) o.tip = null;
        this.setState(o);
      }, 170);
    };
    const lager = (have, want) => (have >= want ? String(have) : have + '/' + want);

    const mkMB = (p, where, ny) => {
      const key = where + ':' + p.id;
      const isItem = p.type === 'item';
      const isBuffItem = p.type === 'buffitem';
      const bs = buffSev(p);
      let bst; let tid; let rest; let word; let action; let actColor = '#40BF40'; let extra = '';
      if (isItem) {
        tid = lager(p.have, p.want);
        bst = p.have <= 0 ? 'ikke' : 'aktiv';
        rest = Math.round(Math.min(1, p.have / p.want) * 100);
        word = 'Har ' + p.have + ' av ' + p.want;
        action = 'Lagervare: ' + (p.have <= 0 ? 'tom' : p.have < p.want ? 'under ønsket' : 'nok');
        actColor = '#A0A0A0';
        extra = 'Musehjul: ønsket antall (Shift = 5)';
      } else {
        tid = p.left;
        bst = p.st === 'ok' ? 'aktiv' : p.st === 'warn' ? 'snart' : p.st === 'bad' ? 'gatt' : 'ikke';
        rest = bs === 2 ? 0 : Math.round((p.secs / p.fullSecs) * 100);
        word = p.st === 'bad' ? 'Gått ut' : p.st === 'off' ? 'Ikke på' : p.left + ' igjen' + (p.st === 'warn' ? ', snart ute' : '');
        if (isBuffItem) {
          word += ' · ' + p.have + ' av ' + p.want + ' i baggen';
          action = p.have > 0 ? 'Klikk for å bruke' + (p.item ? ' (' + p.item + ')' : '') : 'Ingen i baggen';
          if (!p.have) actColor = '#A0A0A0';
          extra = 'Musehjul: ønsket antall (Shift = 5)';
        } else {
          action = 'Klikk for å kaste på deg selv';
        }
      }
      return Object.assign(common(key, p, 'poster', ny, true), {
        left: tid, bst: bst, rest: rest, gruppe: '',
        antall: isBuffItem ? lager(p.have, p.want) : '',
        stille: !kanTrykkes(p),
        label: p.name + ', ' + word.toLowerCase() + ', tier ' + NR[p.tier] + '. ' + action + '.',
        tipLine: word, tipAction: action, actColor: actColor, tipExtra: extra, hasExtra: !!extra, members: [],
        cast: () => {
          if (isItem) return;
          if (isBuffItem && p.have <= 0) return;
          if (this.cur().flash === p.id) return;
          trykk(p.id, () => this.oppdater('poster', p.id, (x) => (isBuffItem
            ? { st: 'ok', left: x.full, secs: x.fullSecs, have: Math.max(0, x.have - 1) }
            : { st: 'ok', left: x.full, secs: x.fullSecs })));
        },
        wheel: (e) => {
          if (!hasStock(p)) return;
          const step = (e.deltaY < 0 ? 1 : -1) * (e.shiftKey ? 5 : 1);
          this.oppdater('poster', p.id, (x) => ({ want: Math.max(1, x.want + step) }));
        }
      });
    };

    const mkPB = (g, where, ny) => {
      const key = where + ':' + g.id;
      const ids = Object.keys(g.has);
      const miss = pbMissing(g);
      const next = miss.length ? byId[miss[0]] : null;
      const word = miss.length ? miss.length + ' av ' + ids.length + ' mangler' : 'Alle har den';
      return Object.assign(common(key, g, 'gruppe', ny, miss.length <= 1), {
        left: '', bst: 'aktiv', rest: 100, antall: '', stille: false,
        gruppe: ids.map((k) => (g.has[k] ? '1' : '0')).join(''),
        label: g.name + ' til gruppa, ' + word.toLowerCase() + (next ? '. Klikk for å kaste på ' + next.name : '') + '.',
        tipLine: word,
        members: ids.map((k) => ({ name: byId[k].name + (byId[k].rolle ? ' (' + byId[k].rolle + ')' : ''), color: byId[k].color, st: g.has[k] ? 'har' : 'mangler', stColor: g.has[k] ? '#A0A0A0' : '#FF2020' })),
        tipAction: next ? 'Klikk: kast på ' + next.name : 'Ingen å kaste på',
        actColor: next ? '#40BF40' : '#A0A0A0',
        tipExtra: g.only ? 'Følges bare på ' + g.only.map((k) => byId[k].name).join(', ') : 'I kamp: kaster på den som manglet før kampen',
        hasExtra: true,
        cast: () => {
          if (!next) return;
          trykk(g.id, () => this.oppdater('gruppe', g.id, (x) => {
            const h = Object.assign({}, x.has);
            const m = Object.keys(h).filter((k) => !h[k]);
            if (m.length) h[m[0]] = 1;
            return { has: h };
          }));
        },
        wheel: () => {}
      });
    };

    const bygg = (liste, mk, groupKey, kan) => {
      const t1 = liste.filter((p) => p.tier === 1);
      const t2 = liste.filter((p) => p.tier !== 1);
      // Ved knappen: bare tier I som mangler og kan trykkes. Tier II vises bare i sidemenyen.
      const stub = t1.filter(kan).map((p) => mk(p, groupKey + 'stub', true));
      const rad = t1.map((p) => mk(p, groupKey + 'bar', false));
      if (t1.length && t2.length) rad.push({ isBuff: false, isSkille: true, isSlot: false });
      t2.forEach((p) => rad.push(mk(p, groupKey + 'bar', false)));
      const nBtn = t1.length + t2.length;
      const nSlots = Math.max(1, 5 - nBtn);
      for (let i = 0; i < nSlots; i++) rad.push({ isBuff: false, isSkille: false, isSlot: true, plus: i === 0, title: i === 0 ? (groupKey === 'pb' ? 'Dra en buff du kan gi, fra spellboken hit' : 'Dra en spell eller en ting fra baggen hit') : 'Ledig plass' });
      const bredde = 54 + (nBtn + nSlots) * 46 + (t1.length && t2.length ? 10 : 0);
      const empty = groupKey === 'pb' ? 'Dra en buff du kan gi hit' : 'Dra en buff eller ting hit';
      const tiers = [
        { nr: 'I', desc: HINT[1], items: t1.map((p) => mk(p, groupKey + 'menu', false)), empty: !t1.length, emptyText: empty },
        { nr: 'II', desc: HINT[2], items: t2.map((p) => mk(p, groupKey + 'menu', false)), empty: !t2.length, emptyText: empty }
      ];
      return { stub: stub, rad: rad, bredde: bredde, tiers: tiers, hasStub: stub.length > 0 };
    };
    const mb = bygg(s.poster, mkMB, 'mb', kanTrykkes);
    const pb = bygg(s.gruppe, mkPB, 'pb', (g) => pbMissing(g).length > 0);

    const mbProblem = s.poster.filter((p) => sev(p) > 0);
    const pbProblem = s.gruppe.filter((g) => pbMissing(g).length > 0);
    const missing = mbProblem.length + pbProblem.length;
    let worst = 0;
    mbProblem.forEach((p) => { worst = Math.max(worst, sev(p)); });
    if (pbProblem.length) worst = 2;
    const ringColor = worst === 2 ? C.bad : worst === 1 ? C.warn : '#000';
    const ringGlow = worst === 2 ? '0 0 10px 2px rgba(255,32,32,.7)' : worst === 1 ? '0 0 10px 2px rgba(255,140,26,.65)' : 'none';

    const mbOrder = mbProblem.slice().sort((a, b) => sev(b) - sev(a));
    const mbParts = mbOrder.length
      ? mbOrder.slice(0, 4).map((p, i) => {
          const ss = stockSev(p);
          const visLager = hasStock(p) && ss > 0;
          return { sep: i ? ' · ' : '', name: p.short + (visLager ? ' ' : ''), nameColor: buffSev(p) === 2 ? C.bad : buffSev(p) === 1 ? C.warn : '#ECE6D8', num: visLager ? p.have + '/' + p.want : '', numColor: SEVC[ss] };
        }).concat(mbOrder.length > 4 ? [{ sep: ' · ', name: '+' + (mbOrder.length - 4), nameColor: '#A0A0A0', num: '', numColor: '#A0A0A0' }] : [])
      : [{ sep: '', name: 'Alt med', nameColor: C.ok, num: '', numColor: C.ok }];
    const pbParts = pbProblem.length
      ? pbProblem.map((g, i) => ({ sep: i ? ' · ' : '', name: g.short + ': ', nameColor: '#A0A0A0', num: pbMissing(g).map((k) => byId[k].name).join(', '), numColor: '#ECE6D8' }))
      : [{ sep: '', name: 'Alle har det de skal', nameColor: C.ok, num: '', numColor: C.ok }];

    const shut = s.shut || {};
    const flip = (k) => () => {
      const curShut = Object.assign({}, this.cur().shut);
      curShut[k] = !curShut[k];
      this.setState({ shut: curShut });
    };

    const pbLeft = s.pbSide === 'left';
    const side = (key) => {
      const isLeft = key === 'left';
      const g = (isLeft === pbLeft) ? 'pb' : 'mb';
      const d = g === 'pb' ? pb : mb;
      const openSide = isLeft ? openL : openR;
      return {
        key: key, group: g,
        hasStub: d.hasStub, stub: d.stub, rad: d.rad, bredde: d.bredde,
        stubL: isLeft ? 'auto' : '18px', stubR: isLeft ? '18px' : 'auto',
        stubPad: isLeft ? '6px 50px 6px 6px' : '6px 6px 6px 50px',
        barL: isLeft ? 'auto' : '18px', barR: isLeft ? '18px' : 'auto',
        barClip: openSide ? 'inset(-30px -300px -320px -300px)' : (isLeft ? 'inset(0 0 0 100%)' : 'inset(0 100% 0 0)'),
        barOp: openSide ? 1 : 0,
        barPe: openSide ? 'auto' : 'none',
        rowDir: isLeft ? 'row-reverse' : 'row',
        rowPad: isLeft ? '6px 50px 6px 6px' : '6px 6px 6px 50px',
        grooveMargin: isLeft ? '0 50px 0 6px' : '0 6px 0 50px',
        tingPad: isLeft ? '0 50px 0 12px' : '0 12px 0 50px',
        statusLabel: g === 'pb' ? (pbProblem.length ? 'Mangler' : 'Gruppa') : (mbProblem.length ? 'Mangler' : 'Status'),
        parts: g === 'pb' ? pbParts : mbParts
      };
    };

    const PERSON = 'M12 11.5a3.6 3.6 0 1 0 0-7.2 3.6 3.6 0 0 0 0 7.2zM5 20.5c.7-3.6 3.6-5.6 7-5.6s6.3 2 7 5.6';
    const GROUP = 'M8.5 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM2.8 19.5c.6-3 2.8-4.6 5.7-4.6s5.1 1.6 5.7 4.6M15.8 11a3 3 0 1 0 0-6M17 15c2.2.3 3.8 1.8 4.2 4.5';
    const hov = s.hover;
    const ring4 = hov && hov !== 'hub';
    const sym = (k) => ({ op: ring4 ? (hov === k ? 1 : 0.45) : 0, sc: hov === k ? 1.25 : 1, c: hov === k ? '#FFF3B0' : '#C9A24A' });
    const klem = (v, a, b) => Math.max(a, Math.min(b, v));
    const arcDeg = hov === 'left' ? -90 : hov === 'right' ? 90 : hov === 'down' ? 180 : 0;
    const anyOpen = openL || openR;
    // Holdt innenfor skjermen (som SetClampedToScreen): begge sidene fullt utfoldet og menyen skal få plass.
    const wL = (pbLeft ? pb : mb).bredde;
    const wR = (pbLeft ? mb : pb).bredde;
    let minX = Math.max(146, wL - 38);
    let maxX = Math.min(830, 1014 - wR);
    if (minX > maxX) { minX = maxX = Math.round((minX + maxX) / 2); }
    const effX = klem(s.posX, minX, maxX);
    const menyOpp = s.posY > 330;
    const navn =(k) => ((k === 'left') === pbLeft ? 'gruppa' : 'mine buffer');
    const worldBg = showBg
      ? 'radial-gradient(55% 45% at 78% 72%, rgba(98,116,62,.55), rgba(0,0,0,0) 70%), radial-gradient(45% 40% at 18% 88%, rgba(74,86,50,.6), rgba(0,0,0,0) 70%), radial-gradient(70% 55% at 62% 8%, rgba(46,60,50,.9), rgba(0,0,0,0) 70%), linear-gradient(180deg, #1d281f 0%, #2a3525 55%, #20271a 100%)'
      : 'transparent';
    return {
      worldBg: worldBg,
      showBg: showBg,
      sider: [side('left'), side('right')],
      leave: leave,
      missing: missing,
      hasMissing: missing > 0,
      allOk: missing === 0,
      ringColor: ringColor,
      ringGlow: ringGlow,
      party: s.party.map((m, i) => ({ sep: i ? ' · ' : '', name: m.name, color: m.color })),
      seksjoner: [
        { title: 'Mine buffer og ting', icon: PERSON, sideText: pbLeft ? 'høyre' : 'venstre', mt: 0, open: !shut.mb, shut: !!shut.mb, exp: shut.mb ? 'false' : 'true', toggle: flip('mb'), tiers: mb.tiers, hasParty: false },
        { title: 'Til gruppa', icon: GROUP, sideText: pbLeft ? 'venstre' : 'høyre', mt: 5, open: !shut.pb, shut: !!shut.pb, exp: shut.pb ? 'false' : 'true', toggle: flip('pb'), tiers: pb.tiers, hasParty: true }
      ],
      here: s.here,
      cities: s.cities.join(' · '),
      hereGuarded: s.cities.indexOf(s.here) !== -1,
      locked: s.locked,
      byOpen: !shut.by, byShut: !!shut.by, byExp: shut.by ? 'false' : 'true',
      toggleBy: flip('by'),
      pbSideText: pbLeft ? 'til venstre' : 'til høyre',
      mbSideText: pbLeft ? 'til høyre' : 'til venstre',
      swapSides: () => {
        const c = this.cur();
        const oL = c.openL === undefined ? openL : c.openL;
        const oR = c.openR === undefined ? openR : c.openR;
        this.setState({ pbSide: c.pbSide === 'left' ? 'right' : 'left', openL: oR, openR: oL });
      },

      panelTop: menyOpp ? 'auto' : (anyOpen ? 100 : 72) + 'px',
      panelBottom: menyOpp ? '72px' : 'auto',
      clip: open ? (menyOpp ? 'inset(-420px -420px -20px -420px)' : 'inset(-20px -420px -420px -420px)') : (menyOpp ? 'inset(100% -420px 0px -420px)' : 'inset(0px -420px 100% -420px)'),
      panelOp: open ? 1 : 0,
      panelY: open ? 0 : (menyOpp ? 8 : -8),
      panelPe: open ? 'auto' : 'none',

      numOp: hov ? 0 : 1,
      numScale: hov ? 0.7 : 1,
      posX: s.posX,
      effX: effX,
      posY: s.posY,
      moveOp: hov === 'hub' && !s.locked ? 1 : 0,
      hubRingOp: hov === 'hub' && !s.locked ? 1 : 0,
      lockHubOp: hov === 'hub' && s.locked ? 1 : 0,
      hubCursor: s.locked ? 'default' : s.dragging ? 'grabbing' : 'grab',
      lblHub: s.locked ? 'Låst på plass. Lås opp fra toppen av ringen.' : 'Flytt knappen: dra, eller bruk piltastene',
      hoverHub: () => this.setState({ hover: 'hub' }),
      hubDown: (e) => {
        const c = this.cur();
        if (c.locked) return;
        if (e && e.preventDefault) e.preventDefault();
        const sx = e.clientX; const sy = e.clientY; const ox = klem(c.posX, minX, maxX); const oy = c.posY;
        const flytt = (ev) => this.setState({ dragging: true, posX: klem(ox + ev.clientX - sx, minX, maxX), posY: klem(oy + ev.clientY - sy, 10, 600) });
        const slipp = () => { window.removeEventListener('pointermove', flytt); window.removeEventListener('pointerup', slipp); this.setState({ dragging: false }); };
        window.addEventListener('pointermove', flytt);
        window.addEventListener('pointerup', slipp);
      },
      hubKey: (e) => {
        const c = this.cur();
        if (c.locked) return;
        const d = e.shiftKey ? 20 : 5;
        const m = { ArrowLeft: [-d, 0], ArrowRight: [d, 0], ArrowUp: [0, -d], ArrowDown: [0, d] }[e.key];
        if (!m) return;
        e.preventDefault();
        this.setState({ posX: klem(klem(c.posX, minX, maxX) + m[0], minX, maxX), posY: klem(c.posY + m[1], 10, 600) });
      },
      symUp: sym('up'),
      symDown: sym('down'),
      symLeft: sym('left'),
      symRight: sym('right'),
      lockPath: s.locked ? 'M8 11V7a4 4 0 0 1 8 0v4' : 'M8 11V7a4 4 0 0 1 7.6-1.8',
      leftPath: pbLeft ? GROUP : PERSON,
      rightPath: pbLeft ? PERSON : GROUP,
      arcOp: ring4 ? 1 : 0,
      arcDeg: arcDeg,
      hoverUp: () => this.setState({ hover: 'up' }),
      hoverLeft: () => this.setState({ hover: 'left' }),
      hoverRight: () => this.setState({ hover: 'right' }),
      hoverDown: () => this.setState({ hover: 'down' }),
      hoverOff: () => this.setState({ hover: null }),
      clickUp: () => this.setState({ locked: !s.locked }),
      clickLeft: () => this.setState({ openL: !openL }),
      clickRight: () => this.setState({ openR: !openR }),
      clickDown: () => this.setState({ open: !open }),
      menuExp: open ? 'true' : 'false',
      leftExp: openL ? 'true' : 'false',
      rightExp: openR ? 'true' : 'false',
      lockPressed: s.locked ? 'true' : 'false',
      lblUp: s.locked ? 'Lås opp' : 'Lås',
      lblLeft: (openL ? 'Fold inn ' : 'Fold ut ') + navn('left'),
      lblRight: (openR ? 'Fold inn ' : 'Fold ut ') + navn('right'),
      lblDown: (open ? 'Lukk menyen' : 'Åpne menyen') + ', ' + missing + ' å gjøre',
      addHere: () => {
        const c = this.cur();
        if (c.cities.indexOf(c.here) === -1) this.setState({ cities: c.cities.concat([c.here]) });
      }
    };
  }
}
