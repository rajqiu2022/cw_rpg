"""
用 Playwright 编辑头条已有草稿 v4 — 调试页面结构
"""
import os, sys, time
from playwright.sync_api import sync_playwright

DRAFT_ID = "7644380443193704995"
EDIT_URL = f"https://mp.toutiao.com/profile_v4/graphic/publish?pgc_id={DRAFT_ID}"
COVER = r"F:\Code\RPG_GAME\assets\raw\scene\v2\scene_linxi_tutorial_full_bg.png"
GIF = r"F:\Code\RPG_GAME\assets\previews\sprite\sprite_lengguyun_walk_right_4f_article.gif"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

def main():
    with sync_playwright() as p:
        user_data_dir = os.path.join(SCRIPT_DIR, ".pw_toutiao_profile")
        context = p.chromium.launch_persistent_context(
            user_data_dir=user_data_dir,
            headless=False,
            args=["--disable-blink-features=AutomationControlled"],
            viewport={"width": 1280, "height": 900},
        )
        page = context.new_page()

        print("[1] Navigate to edit page")
        page.goto(EDIT_URL, wait_until="networkidle", timeout=30000)
        page.wait_for_timeout(5000)

        # Close any drawers
        page.keyboard.press("Escape")
        page.wait_for_timeout(1000)
        try:
            page.locator('.byte-drawer-mask').click(timeout=2000)
            page.wait_for_timeout(1000)
        except: pass

        # Save screenshot for debugging
        page.screenshot(path=os.path.join(SCRIPT_DIR, "toutiao_debug.png"))
        print("    Screenshot saved: scripts/toutiao_debug.png")

        # Dump ALL buttons and file inputs info via JS
        info = page.evaluate("""() => {
            const result = {buttons: [], fileInputs: [], coverArea: null};

            document.querySelectorAll('button, [role="button"]').forEach((b, i) => {
                if (i < 40) result.buttons.push({
                    text: (b.textContent || '').trim().slice(0, 40),
                    class: (b.className || '').slice(0, 60),
                    title: (b.title || ''),
                    aria: (b.getAttribute('aria-label') || ''),
                    visible: b.offsetParent !== null
                });
            });

            document.querySelectorAll('input[type="file"]').forEach((inp, i) => {
                result.fileInputs.push({
                    class: (inp.className || '').slice(0, 60),
                    accept: (inp.accept || ''),
                    visible: inp.offsetParent !== null,
                    parent_class: (inp.parentElement?.className || '').slice(0, 60)
                });
            });

            // Check for cover area
            const cover = document.querySelector('[class*="cover"]');
            if (cover) result.coverArea = cover.className.slice(0, 100);

            return result;
        }""")

        print(f"    Buttons: {len(info['buttons'])}")
        for b in info['buttons']:
            if b['visible']:
                print(f"      [{b['text'][:30]}] class={b['class'][:40]} title={b['title'][:20]} aria={b['aria'][:20]}")

        print(f"    File inputs: {len(info['fileInputs'])}")
        for fi in info['fileInputs']:
            print(f"      accept={fi['accept']} class={fi['class'][:40]} parent={fi['parent_class'][:40]} visible={fi['visible']}")

        print(f"    Cover area: {info.get('coverArea')}")

        # === Upload cover ===
        print("[2] Upload cover...")
        cover_done = False
        # Strategy 1: Click cover placeholder then find file input
        try:
            cover_triggers = [
                '[class*="cover-add"]',
                '[class*="cover-upload"]',
                '[class*="CoverUpload"]',
                ':text("添加封面")',
                ':text("上传封面")',
                '[class*="article-cover"]',
            ]
            for sel in cover_triggers:
                try:
                    el = page.locator(sel).first
                    if el.is_visible():
                        el.click(timeout=2000)
                        page.wait_for_timeout(1500)
                        print(f"    Clicked cover trigger: {sel}")
                        break
                except:
                    continue

            # Now try all file inputs
            for inp in page.locator('input[type="file"]').all():
                try:
                    inp.set_input_files(COVER)
                    print(f"    Cover uploaded!")
                    cover_done = True
                    page.wait_for_timeout(3000)
                    break
                except:
                    continue
        except Exception as e:
            print(f"    Cover error: {e}")

        if not cover_done:
            print("    [!] Cover NOT uploaded - need manual")

        # === Upload GIF to editor ===
        print("[3] Insert GIF...")
        gif_done = False

        # Find and click image button in toolbar
        # Look for buttons by class pattern, not just text
        try:
            # Toutiao editor toolbar buttons often have byte-ui classes
            toolbar_area = page.locator('[class*="editor-toolbar"], [class*="toolbar"], .ql-toolbar, [class*="Toolbar"]').first
            if toolbar_area.is_visible():
                # Get all buttons inside toolbar
                btns = toolbar_area.locator('button, [role="button"], .byte-btn, span[class*="icon"]')
                count = btns.count()
                print(f"    Toolbar buttons: {count}")
                for i in range(count):
                    try:
                        b = btns.nth(i)
                        # Try clicking each button that might be image-related
                        html = b.inner_html() or ""
                        cls = b.get_attribute("class") or ""
                        if "image" in html.lower() or "picture" in html.lower() or "img" in cls.lower() or "pic" in cls.lower() or "图片" in html:
                            b.click(timeout=2000)
                            page.wait_for_timeout(1500)
                            print(f"    Clicked image btn #{i}")
                            break
                    except:
                        continue
                else:
                    # Just try clicking buttons until a file dialog appears
                    print("    Trying each toolbar button...")
                    for i in range(min(count, 20)):
                        try:
                            b = btns.nth(i)
                            b.click(timeout=2000)
                            page.wait_for_timeout(500)
                            # Check if a file input appeared
                            new_count = page.locator('input[type="file"]').count()
                            if new_count > len(info['fileInputs']):
                                print(f"    Button #{i} triggered file input!")
                                page.locator('input[type="file"]').last.set_input_files(GIF)
                                gif_done = True
                                print("    [OK] GIF uploaded!")
                                page.wait_for_timeout(3000)
                                break
                        except:
                            continue

                if not gif_done:
                    # Try all file inputs on page
                    all_inps = page.locator('input[type="file"]').all()
                    for inp in all_inps:
                        if gif_done:
                            break
                        try:
                            inp.set_input_files(GIF)
                            print(f"    Tried upload to file input")
                            gif_done = True
                            page.wait_for_timeout(3000)
                        except:
                            pass
        except Exception as e:
            print(f"    Toolbar error: {e}")

        if not gif_done:
            # Last resort: click into editor, press Ctrl+V equivalent, try to find image dialog
            try:
                editor = page.locator('[contenteditable="true"]').first
                editor.click(timeout=5000)
                page.wait_for_timeout(1000)
                # Try keyboard shortcuts that might trigger image insert
                # Some editors use Ctrl+Shift+I or similar
                page.keyboard.press("Control+Shift+i")
                page.wait_for_timeout(1000)
                all_inps = page.locator('input[type="file"]').all()
                if all_inps:
                    all_inps[-1].set_input_files(GIF)
                    gif_done = True
                    print("    [OK] GIF uploaded via keyboard shortcut")
            except Exception as e:
                print(f"    Last resort error: {e}")

        if not gif_done:
            print("    [!] GIF NOT uploaded - need manual")

        # === Save ===
        print("[4] Save...")
        page.wait_for_timeout(1000)
        # Remove footer/drawer overlays first
        page.evaluate("""
            document.querySelectorAll('.footer, .byte-drawer-wrapper, .byte-drawer-mask, [class*="footer"]').forEach(el => el.remove());
        """)
        page.wait_for_timeout(500)
        saved = False
        # Try JS click on all save buttons
        for sel in ['.byte-btn-default', '.byte-btn-primary', 'button:has-text("存草稿")', 'button:has-text("保存")']:
            try:
                btn = page.locator(sel).first
                if btn.is_visible():
                    btn.evaluate("el => el.click()")
                    print(f"    JS-clicked: {sel}")
                    saved = True
                    page.wait_for_timeout(3000)
                    break
            except:
                continue
        if not saved:
            print("    [!] Save failed - check browser")

        print(f"\nFinal URL: {page.url}")
        print(f"Cover done: {cover_done}, GIF done: {gif_done}")
        print("Browser stays open 30s...")
        page.wait_for_timeout(30000)
        context.close()
        print("[DONE]")

if __name__ == "__main__":
    main()
