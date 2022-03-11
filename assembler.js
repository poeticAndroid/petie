(() => {
  let mem = new Uint8Array(1024 * 64)

  let uint8 = new Uint8Array(4),
    int32 = new Int32Array(uint8.buffer),
    float32 = new Float32Array(uint8.buffer)

  let state = 0x42
  // 0:keywords
  // 1:opcodes
  // 2:source
  // 3:global list
  // 4:external list
  // 5:function list
  // 6:data list
  // 7:local list
  // 8:lit lengths
  // 9:executable

  function assemble(asm) {
    let adr

    adr = item(state, 0)//keywords
    store(adr - 4, 4, loadWordList(keywords, adr))
    adr = item(state, 1)//opcodes
    store(adr - 4, 4, loadWordList(opcodes, adr))
    adr = item(state, 2)//source
    store(adr - 4, 4, loadFile(asm, adr))
    toLowerCase(adr)
    removeComments(adr)
    removeOptionals(adr)

    adr = item(state, 3)//globals
    store(adr - 4, 4, listGlobals())
    adr = item(state, 4)//externals
    store(adr - 4, 4, listExt())
    adr = item(state, 5)//functions
    store(adr - 4, 4, listFn())
    adr = item(state, 6)//data list
    store(adr - 4, 4, listData())
    adr = item(state, 7)//local list
    store(adr - 4, 4, listLocals())
    adr = item(state, 8)//lit lengths
    store(adr - 4, 4, listLits())
    adr = item(state, 9)//executable
    store(adr - 4, 4, 42)

    return mem.slice(item(state, 9), item(state, 9) + load(item(state, 9) - 4, 4))
  }

  function listGlobals() {
    let kw, src, globlist, globlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    globlist = item(state, 3) // global list
    globlistPos = globlist
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 1) { //fn
        store(globlistPos, 4, 0)
        globlistPos += 4
        return globlistPos - globlist
      }
      if (indexOf(kw, pos) === 2) { //vars
        pos = nextWord(pos)
        while (load(pos, 1) > 0x20) {
          store(globlistPos, 4, wordLen(pos) + 5)
          globlistPos += 4
          mcopy(pos, globlistPos, wordLen(pos))
          globlistPos += wordLen(pos)
          store(globlistPos, 1, 0)
          globlistPos += 1
          store(globlistPos, 4, 0)
          globlistPos += 4
          pos = nextWord(pos)
        }
      }
      pos = nextLine(pos)
    }
    store(globlistPos, 4, 0)
    globlistPos += 4

    return globlistPos - globlist
  }
  function listExt() {
    let kw, src, extlist, extlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    extlist = item(state, 4) // external list
    extlistPos = extlist
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 0) { //ext
        pos = nextWord(pos)
        store(extlistPos, 4, wordLen(pos) + 9)
        extlistPos += 4
        mcopy(pos, extlistPos, wordLen(pos))
        extlistPos += wordLen(pos)
        store(extlistPos, 1, 0)
        extlistPos += 1
        store(extlistPos, 4, 0)
        extlistPos += 4
        store(extlistPos, 4, 0)
        extlistPos += 4
      }
      pos = nextLine(pos)
    }
    store(extlistPos, 4, 0)
    extlistPos += 4

    return extlistPos - extlist
  }
  function listFn() {
    let kw, src, fnlist, fnlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    fnlist = item(state, 5) // function list
    fnlistPos = fnlist
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 1) { //fn
        pos = nextWord(pos)
        store(fnlistPos, 4, wordLen(pos) + 9)
        fnlistPos += 4
        mcopy(pos, fnlistPos, wordLen(pos))
        fnlistPos += wordLen(pos)
        store(fnlistPos, 1, 0)
        fnlistPos += 1
        store(fnlistPos, 4, 0)
        fnlistPos += 4
        store(fnlistPos, 4, 0)
        fnlistPos += 4
      }
      pos = nextLine(pos)
    }
    store(fnlistPos, 4, 0)
    fnlistPos += 4

    return fnlistPos - fnlist
  }
  function listData() {
    let kw, src, datalist, datalistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    datalist = item(state, 6) // data list
    datalistPos = datalist
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 3) { //data
        pos = nextWord(pos)
        store(datalistPos, 4, wordLen(pos) + 5)
        datalistPos += 4
        mcopy(pos, datalistPos, wordLen(pos))
        datalistPos += wordLen(pos)
        store(datalistPos, 1, 0)
        datalistPos += 1
        store(datalistPos, 4, 0)
        datalistPos += 4
      }
      pos = nextLine(pos)
    }
    store(datalistPos, 4, 0)
    datalistPos += 4

    return datalistPos - datalist
  }
  function listLocals() {
    let kw, src, varlist, varlistPos, pos, maxpos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    varlist = item(state, 7) // local list
    varlistPos = varlist
    maxpos = 0
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) < 3) { //ext fn vars
        if (indexOf(kw, pos) === 1) { //fn
          if (varlistPos > maxpos)
            maxpos = varlistPos
          varlistPos = varlist
        }
        pos = nextWord(pos)
        while (load(pos, 1) > 0x20) {
          store(varlistPos, 4, wordLen(pos) + 5)
          varlistPos += 4
          mcopy(pos, varlistPos, wordLen(pos))
          varlistPos += wordLen(pos)
          store(varlistPos, 1, 0)
          varlistPos += 1
          store(varlistPos, 4, 0)
          varlistPos += 4
          pos = nextWord(pos)
        }
      }
      pos = nextLine(pos)
    }
    store(varlistPos, 4, 0)
    if (varlistPos > maxpos)
      maxpos = varlistPos
    maxpos += 4

    return maxpos - varlist
  }
  function listLits() {
    let kw, src, litlist, litlistPos, pos
    kw = item(state, 0)
    src = item(state, 2)
    pos = src
    litlist = item(state, 8) // lit list
    litlistPos = litlist
    while (load(pos, 1)) {
      pos = skipWS(pos)
      if (indexOf(kw, pos) === 2) { //vars
        while (load(pos, 1) > 0x20) {
          store(litlistPos, 1, 1)
          litlistPos += 1
          pos = nextWord(pos)
        }
      }
      if (indexOf(kw, pos) === 8) { //while
        store(litlistPos, 1, 1)
        litlistPos += 1
        store(litlistPos, 1, 1)
        litlistPos += 1
      }
      if (indexOf(kw, pos) === 9) { //if
        store(litlistPos, 1, 1)
        litlistPos += 1
        store(litlistPos, 1, 1)
        litlistPos += 1
      }
      while (load(pos, 1) > 0x20) {
        if (isNumber(pos)) {
          store(litlistPos, 1, 1)
          litlistPos += 1
        }
        pos = nextWord(pos)
      }
      pos = nextLine(pos)
    }

    return litlistPos - litlist
  }

  function skipWS(pos) {
    while (load(pos, 1) !== 0 && load(pos, 1) < 0x21) pos++
    return pos
  }
  function nextLine(pos) {
    while (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a) pos++
    return pos + 1
  }
  function nextWord(pos) {
    while (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a && load(pos, 1) > 0x20) pos++
    while (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a && load(pos, 1) < 0x21) pos++
    return pos
  }
  function prevWord(pos) {
    if (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a) pos--
    while (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a && load(pos, 1) < 0x21) pos--
    while (load(pos, 1) !== 0 && load(pos, 1) !== 0x0a && load(pos, 1) > 0x20) pos--
    return pos + 1
  }

  function wordLen(word) {
    let len = 0
    while (load(word, 1) > 0x60) {
      word++
      len++
    }
    return len
  }
  function sameWord(a, b) {
    while (load(a, 1) === load(b, 1)) {
      a++
      b++
    }
    if (load(a, 1) < 0x60 && load(b, 1) < 0x60) {
      return true
    }
    return false
  }
  function isNumber(pos) {
    if (load(pos, 1) === 0x2d && isNumber(pos + 1)) return true
    if (load(pos, 1) > 0x2f && load(pos, 1) < 0x3a) return true
    return false
  }

  function toLowerCase(adr) {
    let inString
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (load(adr, 1) > 0x40 && load(adr, 1) < 0x5b) {
          store(adr, 1, load(adr, 1) + 0x20)
        }
      }
      adr++
    }
  }
  function removeComments(adr) {
    let inString, erase
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (load(adr, 1) === 0x0a) erase = false
      if (load(adr, 1) === 0x3b && !inString) erase = true
      if (erase) store(adr, 1, 0x20)
      adr++
    }
  }
  function removeOptionals(adr) {
    let inString
    while (load(adr, 1)) {
      while (inString && load(adr, 1) === 0x5c) adr += 2
      if (load(adr, 1) === 0x22) inString = !inString
      if (load(adr, 1) === 0x0a) inString = false
      if (!inString) {
        if (load(adr, 1) === 0x21) store(adr, 1, 0x20)
        if (load(adr, 1) > 0x22 && load(adr, 1) < 0x2d) store(adr, 1, 0x20)
        if (load(adr, 1) === 0x2d && load(adr + 1, 1) < 0x21) store(adr, 1, 0x20)
        if (load(adr, 1) === 0x2f) store(adr, 1, 0x20)
        if (load(adr, 1) > 0x39 && load(adr, 1) < 0x61) store(adr, 1, 0x20)
      }
      adr++
    }
  }

  function item(list, index) {
    while (index && load(list, 4)) {
      list += 4 + load(list, 4)
      index--
    }
    return list + 4
  }
  function indexOf(list, word) {
    let index = 0
    while (load(list, 4)) {
      list += 4
      if (sameWord(list, word))
        return index
      list += load(list - 4, 4)
      index++
    }
    return -1
  }
  function has(list, word) {
    if (indexOf(list, word) < 0) return false
    else return true
  }

  function mcopy(src, dest, len) {
    if (src > dest) {
      while (len) {
        store(dest, 4, load(src, 4))
        dest++
        src++
        len--
      }
    } else {
      src += len
      dest += len
      while (len) {
        dest--
        src--
        store(dest, 4, load(src, 4))
        len--
      }
    }
  }
  function load(adr, len) {
    if (adr < 0) throw console.error("attempting to load adr", adr)
    len = 8 * (4 - len)
    uint8.set(mem.slice(adr, adr + 4))
    int32[0] = int32[0] << len
    int32[0] = int32[0] >> len
    return int32[0]
  }
  function store(adr, len, val) {
    if (adr < 0) throw console.error("attempting to load adr", adr)
    int32[0] = val
    mem.set(uint8.slice(0, len), adr)
  }

  function loadFile(data, adr) {
    for (let i = 0; i < data.length; i++) {
      if (typeof data === "string") mem[adr + i] = data.charCodeAt(i)
      else mem[adr + i] = data[i]
    }
    mem[adr + data.length] = 0
    return data.length + 1
  }
  function loadWordList(words, adr) {
    let start = adr
    for (let word of words) {
      store(adr, 4, word.length + 1)
      adr += 4
      adr += loadFile(word, adr)
    }
    store(adr, 4, 0)
    adr += 4
    return adr - start
  }

  function dumpBin(bin, pc = -1) {
    let adr = 0
    let txt = ""
    let end = bin.length
    while (adr < end) {
      txt += (adr == pc ? "> " : "  ")
      txt += ("000000" + adr.toString(16)).slice(-5) + " "
      txt += ("00" + bin[adr].toString(16)).slice(-2) + " "
      txt += (opcodes[bin[adr]] || "") + " "
      if (opcodes[bin[adr]] === "lit") {
        uint8.set(bin.slice(adr + 1, adr + 5))
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += 4
      }
      if (bin[adr] >= 0x40) {
        let op = bin[adr] >> 4
        let len = bin[adr] >> 6
        if (op & 2) uint8.fill(255)
        else uint8.fill(0)
        uint8.set(bin.slice(adr + 1, adr + len), 1)
        uint8[0] = bin[adr] << 4
        int32[0] = int32[0] >> 4
        if (op & 1) int32[0] = int32[0] ^ 0x40000000
        txt += "0x" + int32[0].toString(16) + " " + int32[0]
        adr += len - 1
      }
      txt += "\n"
      adr++
    }
    return txt
  }

  const keywords = [
    "ext", "fn", "vars", "data", "-", "-", "-", "-",
    "while", "if", "else", "end", "skipto"
  ]

  const opcodes = [
    "halt", "sleep", "vsync", "-", "jump", "jumpifz", "-", "endcall", "call", "return", "exec", "break", "reset", "absadr", "cpuver", "noop",
    "lit", "get", "stackptr", "memsize", "-", "loadbit", "load", "loadu", "drop", "set", "inc", "dec", "-", "storebit", "store", "-",
    "add", "sub", "mult", "div", "rem", "-", "itof", "uitof", "fadd", "fsub", "fmult", "fdiv", "ffloor", "-", "-", "ftoi",
    "eq", "lt", "gt", "eqz", "and", "or", "xor", "rot", "feq", "flt", "fgt", "-", "-", "-", "-", "-",
    "false", "true"
  ]

  for (let i = 0; i < mem.length; i++) {
    mem[i] = Math.random() * 255
  }

  window.assemble = assemble
  window.opcodes = opcodes
  window.dumpBin = dumpBin
})()