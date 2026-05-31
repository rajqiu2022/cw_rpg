"""
用 Playwright 直接发布头条文章（带封面+配图），操作完浏览器保持打开
"""
import os, sys, time
from playwright.sync_api import sync_playwright

TITLE = "我用Claude Code+DeepSeek做武侠RPG：《云影侠传》开发实录（3）"
CONTENT = """前两篇讲了主菜单场景和主角精灵动画的人工智能生成过程。这回搞背包界面，把整组界面素材体系化地生成出来。

设计稿与实际素材的差距

最开始有一张背包界面的设计稿，画面里面板、按钮、道具图标一应俱全。但设计稿是示意图，不是素材。抠出来的按钮尺寸不对，道具图标也不能动态加载。第一步：扔掉设计稿，从零生成干净的底图面板。

四种素材，一套风格锚点

背包界面需要四类素材：底图（1280乘720暗色面板，内部完全空白）、Tab按钮（全部、消耗、装备、剧情、材料，每种三个状态，共15张）、功能按钮（使用、装备、丢弃、关闭，每种三个状态，共12张）、道具格子（默认、选中、空，3张）。全部走图像生成接口，提示词统一挂风格锚点：深海军蓝底色，暗金装饰，磨砂暗玻璃质感。

中文不写在提示词里

图像模型生成中文极不稳定。提示词明确写"不要文字，只要装饰框"，拿到纯装饰底框后，用图像处理库加载系统字体精确居中写上中文。文字位置像素级可控。

按钮三种状态的做法

默认态是模型底框加普通文字。选中悬停态叠加半透明青色加高斯模糊发光边框。按下态亮度降到六成五加深色调叠加。三种状态不额外调接口，一张底框出全部。

结果和成本

四类素材共六次接口调用，二十五个变体文件全部由程序生成。界面素材是人工智能生成最能稳定输出的领域，只要风格锚点对，一次就过。"""

COVER = r"F:\Code\RPG_GAME\game\art\ui\inventory\panel_bg.png"
IMAGES = [
    r"F:\Code\RPG_GAME\game\art\ui\inventory\panel_bg.png",
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
            page.locator('input[placeholder*="标签"], [class*="tag"] input').first.fill("Claude Code,DeepSeek,AI游戏开发,武侠RPG,云影侠传")
            page.wait_for_timeout(500)
        except:
            pass

        print("\n=== 操作完成，浏览器保持打开 ===")
        print("请检查封面和图片是否上传成功，手动点发布/存草稿")
        print("按 Ctrl+C 关闭浏览器")
        page.wait_for_timeout(600000)  # 10 min


if __name__ == "__main__":
    main()
