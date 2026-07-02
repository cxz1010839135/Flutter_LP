#!/usr/bin/env python3
"""生成输入 IO 映射 Blockly XML。"""

from __future__ import annotations

import os
import sys


def mapping_chain(m_start: int, x_start: int, count: int, proc_i: int) -> str:
    lines: list[str] = []
    indent = "          "

    def emit_block(i: int, depth: int) -> None:
        pad = indent + "  " * depth
        m = m_start + i
        x = x_start + i
        lines.append(f'{pad}<block type="math_variable" id="ai_io_m{m}_p{proc_i}">')
        lines.append(f'{pad}  <field name="Variable_Name">M</field>')
        lines.append(f'{pad}  <value name="Variable_Idx">')
        lines.append(f'{pad}    <shadow type="math_number">')
        lines.append(f'{pad}      <field name="NUM">{m}</field>')
        lines.append(f'{pad}    </shadow>')
        lines.append(f'{pad}  </value>')
        lines.append(f'{pad}  <value name="Variable_Value">')
        lines.append(f'{pad}    <block type="thread_get_bitX" id="ai_io_x{x}_p{proc_i}">')
        lines.append(f'{pad}      <field name="ACTIVE_Data">X</field>')
        lines.append(f'{pad}      <value name="Idx">')
        lines.append(f'{pad}        <shadow type="math_number">')
        lines.append(f'{pad}          <field name="NUM">{x}</field>')
        lines.append(f'{pad}        </shadow>')
        lines.append(f'{pad}      </value>')
        lines.append(f'{pad}    </block>')
        lines.append(f'{pad}  </value>')
        if i < count - 1:
            lines.append(f"{pad}  <next>")
            emit_block(i + 1, depth + 1)
            lines.append(f"{pad}  </next>")
        lines.append(f"{pad}</block>")

    emit_block(0, 0)
    return "\n".join(lines)


def main() -> None:
    ext_count = int(sys.argv[1]) if len(sys.argv) > 1 else 8
    rules: list[tuple[str, int, int, int]] = [
        ("本体输入IO", 1000, 0, 24),
    ]
    for n in range(1, ext_count + 1):
        rules.append((f"扩展输入IO-{n}", 1000 + 100 * n, 100 * n, 16))

    parts = ['<xml xmlns="http://www.w3.org/1999/xhtml">']
    for pi, (name, ms, xs, cnt) in enumerate(rules):
        y = 80 + pi * 40
        parts.append(
            f'  <block type="procedures_defnoreturn" id="ai_io_proc_{pi}" x="80" y="{y}">'
        )
        parts.append(f'    <field name="NAME">{name}</field>')
        parts.append('    <statement name="STACK">')
        parts.append(mapping_chain(ms, xs, cnt, pi))
        parts.append("    </statement>")
        parts.append("  </block>")
    parts.append("</xml>")

    out_path = os.path.join("files", "xml", "io_input_mapping_rules.xml")
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(parts) + "\n")

    print(f"已写入 {out_path}（{len(rules)} 个函数）")
    for name, ms, xs, cnt in rules:
        print(
            f"  {name}: M{ms}..{ms + cnt - 1} <- X{xs}..{xs + cnt - 1} ({cnt}点)"
        )


if __name__ == "__main__":
    main()
