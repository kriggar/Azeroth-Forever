"""Reproduce the four approved Starcaller specialization portraits from the supplied 1536x1024 concept."""

import argparse
from pathlib import Path
from PIL import Image

CROPS = {
    "moon_priest": (32, 83, 200, 241),
    "sentinel": (218, 83, 386, 241),
    "warden": (399, 83, 568, 241),
    "moon_guard": (579, 83, 748, 241),
}


def generate(image, output):
    image, output = Path(image), Path(output)
    with Image.open(image) as reference:
        if reference.size != (1536, 1024):
            raise ValueError("Requires the original approved 1536x1024 concept image")
        output.mkdir(parents=True, exist_ok=True)
        for name, rectangle in CROPS.items():
            picture = reference.convert("RGB").crop(rectangle)
            picture = picture.resize((256, 256), Image.Resampling.LANCZOS)
            picture.save(output / (name + ".tga"), format="TGA", compression="tga_rle")
    return list(CROPS)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("concept", type=Path)
    parser.add_argument("--output", type=Path, default=Path("client/forever-talents/assets"))
    args = parser.parse_args()
    print("Art generated:", ", ".join(generate(args.concept, args.output)))
