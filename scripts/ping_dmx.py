"""DMXAPI 渠道探活 + 余额查询

用途：跑批前一站式确认
  1. 当前账户余额（避免余额不足中断跑批）
  2. 上游图像生成渠道是否存活（最小调用）

退出码：
  0 = 渠道可用 + 余额充足
  1 = 渠道连接失败（TLS / IP 风控 / 上游 503）
  2 = 渠道返回空数据（503 渠道熔断前过渡态）
  3 = 余额不足（< ¥0.5，强烈建议充值后再跑）

环境变量：
  必需（OpenAI 兼容接口，已在用）:
    OPENAI_API_KEY    DMXAPI 控制台 → 创建的 API 令牌（sk-...）
    OPENAI_BASE_URL   https://www.dmxapi.cn/v1
  可选（用于余额查询，DMXAPI 自有 API）:
    DMXAPI_SYSTEM_TOKEN  登录 dmxapi.cn → 个人设置 → 系统访问令牌
    DMXAPI_USER_ID       登录 dmxapi.cn → 个人设置 → 用户 ID

注：system_token ≠ API 密钥（sk-...）。
    前者用于 DMXAPI 自有 API（余额、日志统计）；
    后者用于 OpenAI 兼容接口（图像生成）。
    两者在不同入口生成，需分别配置。
"""

from __future__ import annotations

import os
import sys

import httpx
from dotenv import load_dotenv
from openai import OpenAI
from rich.console import Console

load_dotenv()

console = Console()

DMXAPI_BALANCE_URL = "https://www.dmxapi.cn/api/user/self"
QUOTA_TO_CNY = 500_000  # data.quota / 500000 = 实际人民币余额


def query_balance() -> tuple[bool, str, float | None]:
    """查询 DMXAPI 账户余额（走 DMXAPI 自有 API，不上游 OpenAI）。

    Returns
    -------
    (configured, msg, balance_cny)
        configured = False  → 未配置 SYSTEM_TOKEN / USER_ID，跳过查询
        configured = True   → balance_cny 为人民币余额；None = 接口失败
    """
    token = os.getenv("DMXAPI_SYSTEM_TOKEN")
    user_id = os.getenv("DMXAPI_USER_ID")
    if not token or not user_id:
        return False, "未配置 DMXAPI_SYSTEM_TOKEN / DMXAPI_USER_ID（跳过余额查询）", None

    try:
        rsp = httpx.get(
            DMXAPI_BALANCE_URL,
            headers={
                "Accept": "application/json",
                "Authorization": token,
                "Rix-Api-User": user_id,
            },
            timeout=10.0,
        )
        rsp.raise_for_status()
        data = rsp.json()
        if not data.get("success"):
            return True, f"接口业务错误：{data.get('message', '未知')}", None
        quota = int(data.get("data", {}).get("quota", 0))
        balance = quota / QUOTA_TO_CNY
        return True, f"quota={quota:,}", balance
    except Exception as e:
        return True, f"{type(e).__name__}: {e}", None


def ping_channel(model: str = "gpt-image-2", timeout: float = 30.0) -> tuple[int, str]:
    """图像生成最小调用探活（走 OpenAI 兼容 /v1/images/generations）。

    Returns
    -------
    (exit_code, msg)
        0 = ok；1 = connection-error；2 = empty-data
    """
    client = OpenAI(
        api_key=os.getenv("OPENAI_API_KEY"),
        base_url=os.getenv("OPENAI_BASE_URL"),
        timeout=timeout,
    )
    try:
        rsp = client.images.generate(
            model=model,
            prompt="a single white circle on plain background",
            size="1024x1024",
            n=1,
        )
        if rsp.data and rsp.data[0].b64_json:
            return 0, f"OK len={len(rsp.data[0].b64_json)}"
        return 2, "200 但 data[] 为空（渠道熔断前过渡态）"
    except Exception as e:
        return 1, f"{type(e).__name__}: {e}"


def _print_balance(configured: bool, msg: str, balance: float | None) -> bool:
    """打印余额行；返回 True 表示触发 critical alert 应中止后续。"""
    if not configured:
        console.print(f"[dim][balance] {msg}[/dim]")
        console.print(
            "[dim]           获取 system_token / user_id："
            "登录 dmxapi.cn → 个人设置 → 系统访问令牌 / 用户 ID[/dim]"
        )
        return False
    if balance is None:
        console.print(f"[red][balance] 查询失败：{msg}[/red]")
        return False

    if balance < 0.5:
        console.print(
            f"[bold red][balance] CRITICAL  ¥{balance:.4f}  ({msg})[/bold red]"
        )
        console.print(
            "[red]           余额 < ¥0.5，强烈建议充值后再跑批"
            "（一张图约 ¥0.4 ~ 1.2）[/red]"
        )
        return True
    if balance < 5.0:
        console.print(
            f"[yellow][balance] LOW       ¥{balance:.4f}  ({msg})[/yellow]"
        )
        console.print(
            "[yellow]           余额低于 ¥5，建议跑批前评估任务总量[/yellow]"
        )
        return False
    console.print(
        f"[green][balance] OK        ¥{balance:.4f}  ({msg})[/green]"
    )
    return False


def main() -> int:
    console.rule("[bold cyan]DMXAPI 探活 + 余额查询[/bold cyan]")

    configured, msg, balance = query_balance()
    if _print_balance(configured, msg, balance):
        return 3

    console.rule("[dim]channel ping[/dim]")
    code, ping_msg = ping_channel()
    if code == 0:
        console.print(f"[green][ping] {ping_msg}[/green]")
    elif code == 2:
        console.print(f"[yellow][ping] {ping_msg}[/yellow]")
    else:
        console.print(f"[red][ping] {ping_msg}[/red]")
        console.print(
            "[red]        提示：连续 2 次以上失败通常是 IP 风控触发，"
            "等 30+ 分钟后再试[/red]"
        )

    return code


if __name__ == "__main__":
    sys.exit(main())
