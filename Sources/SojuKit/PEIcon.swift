import AppKit
import Foundation

/// Best-effort extraction of the main icon from a Windows PE executable.
/// Clean-room parser of the PE resource tree (RT_GROUP_ICON + RT_ICON),
/// reassembled into an ICO that NSImage can decode. Returns nil on anything
/// malformed rather than trusting attacker-controlled offsets.
public enum PEIcon {
    public static func image(for exe: URL) -> NSImage? {
        guard let ico = extractICO(from: exe) else { return nil }
        return NSImage(data: ico)
    }

    public static func extractICO(from exe: URL) -> Data? {
        guard let data = try? Data(contentsOf: exe) else { return nil }
        let pe = Reader(data)

        // DOS header -> PE header
        guard pe.u16(0) == 0x5A4D, let e_lfanew = pe.u32(0x3C) else { return nil }
        let peOff = Int(e_lfanew)
        guard pe.u32(peOff) == 0x0000_4550 else { return nil }   // "PE\0\0"
        let coff = peOff + 4
        guard let optSize = pe.u16(coff + 16), optSize > 0,
              let sectionCount = pe.u16(coff + 2),
              let magic = pe.u16(coff + 20)
        else { return nil }

        // Data directory 2 = resources
        let optStart = coff + 20
        let dirOffset: Int
        switch magic {
        case 0x10B: dirOffset = optStart + 96    // PE32
        case 0x20B: dirOffset = optStart + 112   // PE32+
        default: return nil
        }
        guard let resourceRVA = pe.u32(dirOffset + 2 * 8), resourceRVA != 0 else { return nil }

        // Section table, for RVA -> file offset mapping
        struct Section { let va: UInt32, rawSize: UInt32, rawPtr: UInt32, virtSize: UInt32 }
        var sections: [Section] = []
        let sectionTable = optStart + Int(optSize)
        for i in 0..<Int(sectionCount) {
            let s = sectionTable + i * 40
            guard let virtSize = pe.u32(s + 8), let va = pe.u32(s + 12),
                  let rawSize = pe.u32(s + 16), let rawPtr = pe.u32(s + 20)
            else { return nil }
            sections.append(Section(va: va, rawSize: rawSize, rawPtr: rawPtr, virtSize: virtSize))
        }
        func fileOffset(rva: UInt32) -> Int? {
            for s in sections {
                let span = max(s.rawSize, s.virtSize)
                if rva >= s.va, rva < s.va &+ span {
                    return Int(rva - s.va + s.rawPtr)
                }
            }
            return nil
        }
        guard let resBase = fileOffset(rva: resourceRVA) else { return nil }

        // Resource tree: root -> type -> name -> language -> data entry
        func entries(dirOff: Int) -> [(id: UInt32, offset: UInt32, isDir: Bool)] {
            guard let named = pe.u16(dirOff + 12), let ids = pe.u16(dirOff + 14) else { return [] }
            let count = Int(named) + Int(ids)
            guard count <= 4096 else { return [] }
            var result: [(UInt32, UInt32, Bool)] = []
            for i in 0..<count {
                let e = dirOff + 16 + i * 8
                guard let id = pe.u32(e), let raw = pe.u32(e + 4) else { continue }
                result.append((id, raw & 0x7FFF_FFFF, raw & 0x8000_0000 != 0))
            }
            return result
        }
        func firstLeaf(from entry: (id: UInt32, offset: UInt32, isDir: Bool), depth: Int = 0) -> (rva: UInt32, size: UInt32)? {
            guard depth < 4 else { return nil }
            if entry.isDir {
                for child in entries(dirOff: resBase + Int(entry.offset)) {
                    if let leaf = firstLeaf(from: child, depth: depth + 1) { return leaf }
                }
                return nil
            }
            let dataEntry = resBase + Int(entry.offset)
            guard let rva = pe.u32(dataEntry), let size = pe.u32(dataEntry + 4) else { return nil }
            return (rva, size)
        }
        func resourceData(_ leaf: (rva: UInt32, size: UInt32)) -> Data? {
            guard let off = fileOffset(rva: leaf.rva) else { return nil }
            return pe.slice(off, Int(leaf.size))
        }

        let root = entries(dirOff: resBase)
        let RT_ICON: UInt32 = 3, RT_GROUP_ICON: UInt32 = 14
        guard let groupType = root.first(where: { $0.id == RT_GROUP_ICON }),
              let iconType = root.first(where: { $0.id == RT_ICON }),
              iconType.isDir, groupType.isDir,
              let firstGroup = entries(dirOff: resBase + Int(groupType.offset)).first,
              let groupLeaf = firstLeaf(from: firstGroup),
              let group = resourceData(groupLeaf)
        else { return nil }

        // GRPICONDIR: pick the largest, deepest entry
        let grp = Reader(group)
        guard let count = grp.u16(4), count > 0 else { return nil }
        var best: (score: Int, id: UInt16)?
        for i in 0..<Int(count) {
            let e = 6 + i * 14
            guard let widthByte = grp.u8(e), let bits = grp.u16(e + 6), let id = grp.u16(e + 12)
            else { continue }
            let width = widthByte == 0 ? 256 : Int(widthByte)
            let score = width * 64 + Int(bits)
            if best == nil || score > best!.score { best = (score, id) }
        }
        guard let bestID = best?.id else { return nil }

        // Fetch that RT_ICON by id and wrap it as a single-image ICO
        guard let iconEntry = entries(dirOff: resBase + Int(iconType.offset))
                .first(where: { $0.id == UInt32(bestID) }),
              let iconLeaf = firstLeaf(from: iconEntry),
              let icon = resourceData(iconLeaf),
              let entryMeta = groupEntryMeta(grp: grp, count: Int(count), id: bestID)
        else { return nil }

        var ico = Data()
        func put16(_ v: UInt16) { ico.append(contentsOf: [UInt8(v & 0xFF), UInt8(v >> 8)]) }
        func put32(_ v: UInt32) {
            ico.append(contentsOf: [UInt8(v & 0xFF), UInt8((v >> 8) & 0xFF), UInt8((v >> 16) & 0xFF), UInt8(v >> 24)])
        }
        put16(0); put16(1); put16(1)                       // ICONDIR
        ico.append(entryMeta.width); ico.append(entryMeta.height)
        ico.append(entryMeta.colors); ico.append(0)
        put16(entryMeta.planes); put16(entryMeta.bits)
        put32(UInt32(icon.count)); put32(22)               // data follows the 22-byte header
        ico.append(icon)
        return ico
    }

    private struct EntryMeta { let width: UInt8, height: UInt8, colors: UInt8, planes: UInt16, bits: UInt16 }

    private static func groupEntryMeta(grp: Reader, count: Int, id: UInt16) -> EntryMeta? {
        for i in 0..<count {
            let e = 6 + i * 14
            guard grp.u16(e + 12) == id else { continue }
            guard let w = grp.u8(e), let h = grp.u8(e + 1), let colors = grp.u8(e + 2),
                  let planes = grp.u16(e + 4), let bits = grp.u16(e + 6)
            else { return nil }
            return EntryMeta(width: w, height: h, colors: colors, planes: planes, bits: bits)
        }
        return nil
    }

    /// Bounds-checked little-endian reads.
    private struct Reader {
        let data: Data
        init(_ data: Data) { self.data = data }

        func u8(_ offset: Int) -> UInt8? {
            guard offset >= 0, offset < data.count else { return nil }
            return data[data.startIndex + offset]
        }
        func u16(_ offset: Int) -> UInt16? {
            guard let a = u8(offset), let b = u8(offset + 1) else { return nil }
            return UInt16(a) | UInt16(b) << 8
        }
        func u32(_ offset: Int) -> UInt32? {
            guard let a = u16(offset), let b = u16(offset + 2) else { return nil }
            return UInt32(a) | UInt32(b) << 16
        }
        func slice(_ offset: Int, _ length: Int) -> Data? {
            guard offset >= 0, length > 0, offset + length <= data.count else { return nil }
            let start = data.startIndex + offset
            return data.subdata(in: start..<(start + length))
        }
    }
}
