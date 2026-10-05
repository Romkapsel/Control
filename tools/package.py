"""Lager pakken venner laster ned: dist/Control-<versjon>.zip

    python tools/package.py

Bare det spillet trenger: filene i Control.toc, bildene koden bruker (Media/*.tga), og håndboka som LESMEG.md.
Alt ligger i en mappe Control/ i zip-fila, så den pakkes rett ut i Interface/AddOns.
Kjør testene først – pakken lages ikke hvis et bilde mangler.
"""
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TOC = os.path.join(ROOT, "Control.toc")


def toc_files():
    return [ln.strip() for ln in open(TOC, encoding="utf-8") if ln.strip() and not ln.startswith("#")]


def version():
    m = re.search(r"^## Version:\s*(\S+)", open(TOC, encoding="utf-8").read(), re.M)
    return m.group(1)


def media_used():
    names = set()
    for f in toc_files():
        text = open(os.path.join(ROOT, *f.split("\\")), encoding="utf-8").read()
        names.update(re.findall(r'Style\.(?:Image\(\s*[\w.]+\s*,|Media\()\s*"(\w+)"', text))
        names.update(re.findall(r'"((?:sym|medal|chevron)_\w+)"', text))
    return sorted(names)


def main():
    ver = version()
    out_dir = os.path.join(ROOT, "dist")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, "Control-%s.zip" % ver)
    files = ["Control.toc"] + [f.replace("\\", "/") for f in toc_files()]
    for name in media_used():
        path = "Media/%s.tga" % name
        if not os.path.isfile(os.path.join(ROOT, path)):
            sys.exit("mangler bilde: " + path)
        files.append(path)
    files.append("Bindings.xml")  # tasten «Neste buff» (lastes av spillet uten å stå i TOC)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files:
            z.write(os.path.join(ROOT, f), "Control/" + f)
        z.write(os.path.join(ROOT, "README.md"), "Control/LESMEG.md")
    size = os.path.getsize(out)
    print("%s (%d filer, %.0f kB)" % (out, len(files) + 1, size / 1024))


if __name__ == "__main__":
    main()
