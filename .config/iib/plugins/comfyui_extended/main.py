import json
import re
from PIL import Image
from typing import Dict, Any, List, Optional
from scripts.iib.parsers.model import ImageGenerationInfo, ImageGenerationParams
from scripts.iib.tool import parse_prompt, unique_by

class Main:
    name = "ComfyUI Extended Parser"
    source_identifier = "ComfyUI"

    def test(self, img: Image.Image, file_path: str) -> bool:
        if img.format == "PNG":
            return "prompt" in img.info
        elif img.format == "WEBP":
            exif = img.info.get("exif")
            if exif:
                try:
                    split = [x.decode("utf-8", errors="ignore") for x in exif.split(b"\x00")]
                    return any(x.lower().startswith("prompt:") for x in split)
                except Exception:
                    pass
        return False

    def parse(self, img: Image.Image, file_path: str) -> ImageGenerationInfo:
        prompt_str = None
        if img.format == "PNG":
            prompt_str = img.info.get("prompt")
        elif img.format == "WEBP":
            exif = img.info.get("exif")
            if exif:
                try:
                    split = [x.decode("utf-8", errors="ignore") for x in exif.split(b"\x00")]
                    for item in split:
                        if item.lower().startswith("prompt:"):
                            prompt_str = item.split(":", 1)[1]
                            break
                except Exception:
                    pass

        if not prompt_str:
            raise Exception("No prompt found")

        data: Dict[str, Any] = json.loads(prompt_str)
        width, height = img.size

        # サンプラーノードを探索
        meta_key = None
        for k, v in data.items():
            ctype = v.get("class_type", "")
            if "Sampler" in ctype or "sampler" in ctype.lower():
                meta_key = k
                break

        if not meta_key or meta_key not in data:
            raise Exception("No sampler node found")

        sampler_node = data[meta_key].get("inputs", {})

        meta = {}
        meta["Steps"] = sampler_node.get("steps", "Unknown")
        meta["Sampler"] = sampler_node.get("sampler_name", "Unknown")
        if "cfg" in sampler_node:
            meta["CFG scale"] = sampler_node.get("cfg")
        if "seed" in sampler_node:
            meta["Seed"] = sampler_node.get("seed")

        def get_model_name(idx):
            if idx is None:
                return None
            visited = set()
            stack = [str(idx)]
            while stack:
                cur_id = stack.pop()
                if cur_id in visited or cur_id not in data:
                    continue
                visited.add(cur_id)
                node = data[cur_id]
                inputs = node.get("inputs", {})
                for key in ["ckpt_name", "unet_name", "model_name"]:
                    if key in inputs and isinstance(inputs[key], str):
                        return inputs[key]
                if "model" in inputs and isinstance(inputs["model"], list) and inputs["model"]:
                    stack.append(str(inputs["model"][0]))
            return None

        meta["Model"] = get_model_name(sampler_node.get("model", [None])[0])
        meta["Source Identifier"] = "ComfyUI"
        meta["final_width"] = width
        meta["final_height"] = height

        def get_text_from_clip(idx):
            if idx is None:
                return ""
            visited = set()
            stack = [str(idx)]
            while stack:
                cur_id = stack.pop()
                if cur_id in visited or cur_id not in data:
                    continue
                visited.add(cur_id)
                node = data[cur_id]
                ctype = node.get("class_type", "")
                inputs = node.get("inputs", {})
                if "CLIPText" in ctype or "text" in inputs:
                    txt = inputs.get("text", "")
                    if isinstance(txt, str) and txt.strip():
                        return txt.strip()
                    elif isinstance(txt, list):
                        stack.append(str(txt[0]))
                for k in ["conditioning", "positive", "negative", "clip"]:
                    if k in inputs and isinstance(inputs[k], list) and inputs[k]:
                        stack.append(str(inputs[k][0]))
            return ""

        pos_ref = sampler_node.get("positive", [None])[0]
        neg_ref = sampler_node.get("negative", [None])[0]
        pos_prompt = get_text_from_clip(pos_ref)
        neg_prompt = get_text_from_clip(neg_ref)

        pos_prompt_arr = unique_by(parse_prompt(pos_prompt)["pos_prompt"])

        # raw_info 文字列の組み立て（WebUI互換フォーマット）
        lines = []
        if pos_prompt:
            lines.append(pos_prompt)
        if neg_prompt:
            lines.append(f"Negative prompt: {neg_prompt}")
        
        meta_parts = []
        for k in ["Steps", "Sampler", "CFG scale", "Seed", "Model", "Source Identifier"]:
            if k in meta and meta[k] is not None:
                meta_parts.append(f"{k}: {meta[k]}")
        if meta_parts:
            lines.append(", ".join(meta_parts))

        raw_info = "\n".join(lines)

        return ImageGenerationInfo(
            raw_info,
            ImageGenerationParams(
                meta=meta,
                pos_prompt=pos_prompt_arr,
                extra={
                    "meta": meta,
                    "pos_prompt": pos_prompt_arr,
                    "pos_prompt_raw": pos_prompt,
                    "neg_prompt_raw": neg_prompt,
                },
            ),
        )
