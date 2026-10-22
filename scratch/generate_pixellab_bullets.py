import urllib.request
import json
import time
import base64
import os

TOKEN = "e2819e5f-13cb-42e6-8e04-9178b7588f74"
API_URL = "https://api.pixellab.ai/mcp"
OUT_DIR = "d:/GitHub/contraRe/assets/bullets"

BULLETS_TO_GENERATE = [
    {
        "filename": "pixellab_bullet_laser.png",
        "description": "Retro arcade pixel art laser beam bullet: glowing neon cyan and electric blue horizontal laser pulse projectile, clean pixel art, isolated sprite, transparent background",
        "width": 24,
        "height": 24
    },
    {
        "filename": "pixellab_bullet_fire.png",
        "description": "Retro arcade pixel art fireball bullet: spinning fiery orange and bright yellow fireball projectile, flaming core, clean pixel art, isolated sprite, transparent background",
        "width": 24,
        "height": 24
    },
    {
        "filename": "pixellab_bullet_boss_plasma.png",
        "description": "Retro arcade pixel art heavy plasma bullet: menacing glowing violet and magenta alien spiked energy sphere, crisp retro pixel art, isolated sprite, transparent background",
        "width": 24,
        "height": 24
    }
]

def mcp_call(method, params, req_id):
    req = urllib.request.Request(
        API_URL,
        data=json.dumps({
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": req_id
        }).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json, text/event-stream",
            "Authorization": f"Bearer {TOKEN}"
        }
    )
    with urllib.request.urlopen(req) as resp:
        txt = resp.read().decode("utf-8")
        for line in txt.splitlines():
            if line.startswith("data: "):
                return json.loads(line[6:])
    return None

def generate_bullet(item, idx):
    print(f"\n--- Generating {item['filename']} ---")
    start_resp = mcp_call("tools/call", {
        "name": "create_image_pro_flash",
        "arguments": {
            "description": item["description"],
            "width": item["width"],
            "height": item["height"],
            "no_background": True
        }
    }, req_id=100 + idx)

    result = start_resp.get("result", {})
    sc = result.get("structuredContent", {})
    job_id = sc.get("job_id")
    if not job_id:
        print(f"Error starting job: {start_resp}")
        return False

    print(f"Job launched! job_id: {job_id}")
    
    # Poll get_image
    for attempt in range(25):
        time.sleep(3)
        poll_resp = mcp_call("tools/call", {
            "name": "get_image",
            "arguments": {"job_id": job_id}
        }, req_id=200 + attempt)
        
        poll_res = poll_resp.get("result", {})
        poll_sc = poll_res.get("structuredContent", {})
        status = poll_sc.get("status")
        
        if not status:
            content = poll_res.get("content", [])
            for c in content:
                if c.get("type") == "text":
                    text = c.get("text", "")
                    for line in text.splitlines():
                        if "status:" in line:
                            status = line.strip()
        
        print(f"Attempt {attempt+1}: {status}")
        
        if poll_sc.get("status") == "completed" or (isinstance(status, str) and "status: completed" in status):
            content = poll_res.get("content", [])
            img_b64 = None
            for c in content:
                if c.get("type") == "image":
                    img_b64 = c.get("data")
                    break
            
            out_path = os.path.join(OUT_DIR, item["filename"])
            if img_b64:
                with open(out_path, "wb") as f:
                    f.write(base64.b64decode(img_b64))
                print(f"Successfully saved to {out_path} ({os.path.getsize(out_path)} bytes)")
                return True
            else:
                download_url = poll_sc.get("download_url")
                if download_url:
                    d_req = urllib.request.Request(download_url)
                    with urllib.request.urlopen(d_req) as d_resp:
                        with open(out_path, "wb") as f:
                            f.write(d_resp.read())
                    print(f"Successfully downloaded to {out_path} ({os.path.getsize(out_path)} bytes)")
                    return True
                print("Could not find image payload in completed job!")
                return False

    print("Timed out waiting for generation.")
    return False

if __name__ == "__main__":
    for i, item in enumerate(BULLETS_TO_GENERATE):
        success = generate_bullet(item, i)
        if not success:
            print("Failed generation, stopping.")
            break
        time.sleep(1)
    print("\nAll bullet generations completed!")
