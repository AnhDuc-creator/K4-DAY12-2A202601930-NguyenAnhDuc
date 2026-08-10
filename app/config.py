"""CP1 — Cấu hình theo 12-Factor.

Nguyên tắc: không có giá trị cấu hình nào nằm trong code. Tất cả đến từ biến
môi trường, để cùng một image chạy được ở laptop, staging và production.
"""

from __future__ import annotations

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Toàn bộ cấu hình của service, đọc từ biến môi trường."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    port: int = 8000
    api_token: str
    redis_url: str = "redis://localhost:6379/0"
    bucket_capacity: int = 10
    refill_per_minute: int = 10
    daily_budget_usd: float = 1.0
    log_level: str = "INFO"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    """Đọc cấu hình một lần rồi cache lại (đọc env mỗi request là lãng phí)."""
    return Settings()