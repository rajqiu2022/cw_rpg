"""
用 Playwright 直接发布头条文章（带封面+配图），操作完浏览器保持打开
"""
import os, sys, time
from playwright.sync_api import sync_playwright

ARTICLE_MD_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs", "toutiao-article-battle-scene-skills-2026-08-28.md")
with open(ARTICLE_MD_PATH, "r", encoding="utf-8") as article_file:
    _article_lines = article_file.read().splitlines()

TITLE = next(line[2:].strip() for line in _article_lines if line.startswith("# "))
_body_lines = []
for line in _article_lines:
    if line.startswith("# ") or line.startswith("## ") or line == "---":
        if line.startswith("## "):
            _body_lines.append(line[3:].strip())
        continue
    if line.startswith("**配图建议**"):
        break
    if line.startswith("1. ") or line.startswith("2. ") or line.startswith("3. ") or line.startswith("4. "):
        continue
    _body_lines.append(line)
CONTENT = "\n".join(_body_lines).strip()

COVER = r"F:\Code\RPG_GAME\game\screenshots\field_world_map_jianghu_1787672732.png"
IMAGES = [
    # 正文配图已整理到 docs/toutiao_images_2026-07-24，先留在编辑器中手动多选上传。
]
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROFILE = os.path.join(SCRIPT_DIR, ".pw_pub_profile")


def main():
    with sync_playwright() as p:
        ctx = p.chromium.launch_persistent_context(
            user_data_dir=PROFILE,
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
            viewport={"width": 1280, "height": 900},
        )
        page = ctx.new_page()

        # Step 1: Go to article editor (new draft)
        print("[1] Opening Toutiao article editor...")
        page.goto("https://mp.toutiao.com/profile_v4/graphic/publish", wait_until="networkidle", timeout=30000)
        page.wait_for_timeout(3000)

        # Check if login needed
        if "login" in page.url.lower() or "auth" in page.url.lower():
            print("=" * 60)
            print("!!! 需要登录 - 请在弹出的Chrome窗口中扫码 !!!")
            print("!!! 用今日头条App扫描二维码，等待5分钟 !!!")
            print("=" * 60)
            page.screenshot(path=os.path.join(SCRIPT_DIR, "LOGIN_QR.png"))
            print("    截图保存: scripts/LOGIN_QR.png")
            page.wait_for_timeout(300000)  # 5 min for QR scan
            if "login" in page.url.lower() or "auth" in page.url.lower():
                print("[FAIL] Login timeout")
                ctx.close()
                return
            print("[OK] 登录成功!")
            page.goto("https://mp.toutiao.com/profile_v4/graphic/publish", wait_until="networkidle")
            page.wait_for_timeout(3000)

        print(f"    当前页面: {page.url[:100]}")

        # Dismiss AI assistant drawer that blocks everything
        print("[*] Dismissing AI drawer...")
        try:
            page.evaluate("""
                document.querySelectorAll('.byte-drawer-mask, .byte-drawer-wrapper').forEach(el => el.remove());
                document.querySelectorAll('[class*="drawer"]').forEach(el => el.style.display = 'none');
            """)
            page.wait_for_timeout(1000)
            page.keyboard.press("Escape")
            page.wait_for_timeout(500)
            print("    Drawer dismissed")
        except:
            pass

        # Step 2: Fill in title
        print("[2] Filling title...")
        try:
            title_input = page.locator('input[placeholder*="标题"], textarea[placeholder*="标题"], [class*="title"] input').first
            title_input.click()
            title_input.fill("")
            title_input.type(TITLE, delay=20)
            page.wait_for_timeout(1000)
            print("    Title filled")
        except Exception as e:
            print(f"    Title error: {e}")

        # Step 3: Fill in content
        print("[3] Filling content...")
        try:
            editor = page.locator('[contenteditable="true"]').first
            editor.click()
            page.wait_for_timeout(500)
            # Clear existing content
            page.keyboard.press("Control+a")
            page.keyboard.press("Backspace")
            page.wait_for_timeout(500)
            # Type content paragraph by paragraph
            for para in CONTENT.strip().split('\n\n'):
                if para.strip():
                    editor.type(para.strip(), delay=5)
                    page.keyboard.press("Enter")
                    page.keyboard.press("Enter")
                    page.wait_for_timeout(200)
            print("    Content filled")
        except Exception as e:
            print(f"    Content error: {e}")

        # Step 4: Upload cover
        print("[4] Uploading cover...")
        try:
            # Use file chooser event - click on cover area to trigger
            page.locator('[class*="cover-add"], [class*="cover-upload"], [class*="CoverUpload"]').first.click(timeout=5000)
            page.wait_for_timeout(1000)
            # Look for file chooser
            with page.expect_file_chooser(timeout=5000) as fc_info:
                page.locator('[class*="cover"]').first.click()
            fc = fc_info.value
            fc.set_files(COVER)
            print("    Cover uploaded via file chooser")
            page.wait_for_timeout(2000)
        except Exception as e:
            print(f"    Cover error: {e}")
            # Fallback: direct file input
            try:
                for inp in page.locator('input[type="file"]').all():
                    try:
                        inp.set_input_files(COVER)
                        print("    Cover uploaded via direct input")
                        page.wait_for_timeout(2000)
                        break
                    except:
                        pass
            except:
                pass

        # Step 5: Insert body images
        for i, img_path in enumerate(IMAGES):
            print(f"[5.{i+1}] Inserting image {os.path.basename(img_path)}...")
            try:
                page.evaluate("""
                    document.querySelectorAll('.byte-drawer-mask, .byte-drawer-wrapper').forEach(el => el.remove());
                    document.querySelectorAll('[class*="drawer"]').forEach(el => el.style.display = 'none');
                """)
                page.keyboard.press("Escape")
                # Click in editor, then find image button in toolbar
                editor.click()
                page.wait_for_timeout(500)
                # Find toolbar image button and try file chooser
                toolbar_btns = page.locator('[class*="toolbar"] button, .syl-toolbar-button').all()
                for btn in toolbar_btns:
                    try:
                        with page.expect_file_chooser(timeout=3000) as fc_info:
                            btn.click()
                        fc = fc_info.value
                        fc.set_files(img_path)
                        print(f"    Image uploaded via toolbar btn")
                        page.wait_for_timeout(2000)
                        break
                    except:
                        continue
                else:
                    print(f"    No toolbar button triggered file chooser")
            except Exception as e:
                print(f"    Image error: {e}")

        # Step 6: Add tags
        print("[6] Setting tags...")
        try:
            page.locator('input[placeholder*="标签"], [class*="tag"] input').first.fill("AI游戏开发,独立游戏,Godot,武侠RPG,游戏制作")
            page.wait_for_timeout(500)
        except:
            pass

        print("[7] Saving draft...")
        try:
            draft_button = page.get_by_text("存草稿", exact=True).last
            draft_button.click(timeout=8000)
            page.wait_for_timeout(2000)
            print("    Draft saved")
        except Exception as e:
            print(f"    Draft save skipped: {e}")

        print("\n=== 操作完成，浏览器保持打开 ===")
        print("请检查封面和图片是否上传成功，手动点发布/存草稿")
        print("按 Ctrl+C 关闭浏览器")
        page.wait_for_timeout(600000)  # 10 min


if __name__ == "__main__":
    main()
