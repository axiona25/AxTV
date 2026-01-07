import json
import re
from pathlib import Path

M3U_FILE = "playlist.m3u"
OUTPUT_FILE = "channels.json"

def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_-]+", "-", text)
    return text.strip("-")

def parse_m3u(path: Path):
    channels = []
    current = {}

    with path.open(encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()

            if line.startswith("#EXTINF"):
                name_match = re.search(r",(.+)$", line)
                logo_match = re.search(r'tvg-logo="([^"]+)"', line)

                name = name_match.group(1).strip() if name_match else "Unknown"
                logo = logo_match.group(1) if logo_match else None

                current = {
                    "id": slugify(name),
                    "name": name,
                    "logo": logo,
                }

            elif line and not line.startswith("#"):
                current["streamUrl"] = line
                channels.append(current)
                current = {}

    return channels

def main():
    m3u_path = Path(M3U_FILE)
    if not m3u_path.exists():
        raise FileNotFoundError(f"{M3U_FILE} non trovato")

    channels = parse_m3u(m3u_path)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(channels, f, ensure_ascii=False, indent=2)

    print(f"✔ Creato {OUTPUT_FILE} con {len(channels)} canali")

if __name__ == "__main__":
    main()

