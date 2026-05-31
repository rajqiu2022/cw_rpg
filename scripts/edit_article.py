import asyncio
from playwright.async_api import async_playwright
import os

ARTICLE_URL = "https://mp.toutiao.com/profile_v4/graphic/publish?pgc_id=7644380443193704995"
COVER = "F:/Code/RPG_GAME/game/art/ui/inventory/panel_bg.png"
IMAGES = [
    ("F:/Code/RPG_GAME/assets/previews/article/tabs_preview.png", "Tab页转"),
    ("F:/Code/RPG_GAME/assets/previews/article/buttons_preview.png", "功能按钮"),
    ("F:/Code/RPG_GAME/assets/previews/article/cells_preview.png", "道具格子"),
]

async def main():
    async with async_playwright() as p:
        b = await p.chromium.launch(headless=False)
        page = await b.new_page()
        await page.goto(ARTICLE_URL, wait_until="networkidle")
        await page.wait_for_timeout(3000)
        
        # Close any drawers
        try:
            await page.keyboard.press("Escape")
            await page.wait_for_timeout(500)
        except: pass
        
        # Upload cover
        try:
            cover_trig = page.locator('[class*="cover-add"]').first
            await cover_trig.click()
            await page.wait_for_timeout(1000)
            fi = page.locator('input[type="file"]').first
            await fi.set_input_files(COVER)
            await page.wait_for_timeout(2000)
            print("Cover OK")
        except Exception as e:
            print(f"Cover error: {e}")
        
        # Insert images
        editor = page.locator('[contenteditable="true"]').first
        for img_path, desc in IMAGES:
            if not os.path.exists(img_path): continue
            await editor.click()
            await page.wait_for_timeout(300)
            await page.keyboard.press("Enter")
            await page.keyboard.type(desc)
            await page.keyboard.press("Enter")
            await page.wait_for_timeout(500)
            
            try:
                file_input = page.locator('input[type="file"]').last
                await file_input.set_input_files(img_path)
                await page.wait_for_timeout(3000)
                print(f"IMG OK: {desc}")
            except:
                print(f"IMG failed: {desc}")
        
        # Save
        save_btn = page.locator('.byte-btn-default:has-text("保存")').first
        try:
            await save_btn.evaluate("el => el.click()")
            print("Saved")
        except:
            await page.keyboard.press("Control+s")
            print("Ctrl+S")
        
        print(f"Final: { await page.url }")
        await page.wait_for_timeout(5000)
        await b.close()
