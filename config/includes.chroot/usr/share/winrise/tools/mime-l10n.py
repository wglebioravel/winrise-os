#!/usr/bin/python3
"""Gera traduções das descrições de tipos de arquivo (MIME) para o Qt/KDE.

O shared-mime-info do Debian guarda as traduções só em gettext (.mo), mas o Qt
lê as descrições direto dos XML do banco MIME. Sem isso o Dolphin mostra
"Folder" em vez de "Pasta" na coluna Tipo. Este script lê o catálogo .mo e gera
um pacote MIME extra com as descrições traduzidas.
Uso: mime-l10n.py [idioma ...]   (padrão: pt_BR)
"""
import gettext, sys, xml.etree.ElementTree as ET
from xml.sax.saxutils import escape, quoteattr

NS = "{http://www.freedesktop.org/standards/shared-mime-info}"
SRC = "/usr/share/mime/packages/freedesktop.org.xml"
langs = sys.argv[1:] or ["pt_BR"]
types = [(m.get("type"), m.find(NS + "comment").text)
         for m in ET.parse(SRC).getroot().iter(NS + "mime-type")
         if m.find(NS + "comment") is not None]
for lang in langs:
    try:
        tr = gettext.translation("shared-mime-info", "/usr/share/locale", [lang])
    except OSError:
        print(f"sem catálogo para {lang}", file=sys.stderr); continue
    out = [ '<?xml version="1.0" encoding="UTF-8"?>',
            '<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">' ]
    n = 0
    for t, c in types:
        s = tr.gettext(c)
        if s and s != c:
            out.append(f'  <mime-type type={quoteattr(t)}><comment xml:lang="{lang}">{escape(s)}</comment></mime-type>')
            n += 1
    out.append("</mime-info>")
    path = f"/usr/share/mime/packages/winrise-l10n-{lang}.xml"
    open(path, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print(f"{path}: {n} descrições traduzidas")
