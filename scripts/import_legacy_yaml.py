#!/usr/bin/env python3
"""
One-off helper to import legacy fclipboard.yaml data into the new backend.

Usage:
  python scripts/import_legacy_yaml.py --email you@example.com --password '***'
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import uuid
from pathlib import Path
from typing import Any, Dict, Iterable, List, Tuple


def _require_modules() -> Tuple[Any, Any]:
    try:
        import requests  # type: ignore
    except ImportError as exc:  # pragma: no cover - runtime check only
        raise SystemExit("Missing dependency 'requests'. Install with: pip install requests pyyaml") from exc
    try:
        import yaml  # type: ignore
    except ImportError as exc:  # pragma: no cover - runtime check only
        raise SystemExit("Missing dependency 'pyyaml'. Install with: pip install requests pyyaml") from exc
    return requests, yaml


def _chunked(items: List[Dict[str, Any]], size: int) -> Iterable[List[Dict[str, Any]]]:
    for i in range(0, len(items), size):
        yield items[i : i + size]


def _sanitize_yaml_text(text: str) -> str:
    # Legacy file has a few unescaped double quotes inside already quoted strings.
    bad = 'initial: "ps aux|grep "D "|grep -v grep|grep -v sshd"'
    if bad in text:
        text = text.replace(bad, 'initial: \'ps aux|grep "D "|grep -v grep|grep -v sshd\'')
    return text


def _load_legacy(path: Path, yaml_mod: Any) -> Dict[str, Any]:
    raw_text = path.read_text(encoding="utf-8")
    raw_text = _sanitize_yaml_text(raw_text)
    try:
        data = yaml_mod.safe_load(raw_text)
    except yaml_mod.YAMLError as exc:  # pragma: no cover - defensive
        raise SystemExit(f"Failed to parse YAML ({path}): {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"Unexpected YAML structure in {path}")
    return data


def _build_tags(raw: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    tag_map: Dict[str, Dict[str, Any]] = {}
    categories = raw.get("categories") or []
    if not isinstance(categories, list):
        return tag_map
    for item in categories:
        name = item.get("name")
        if not name or not isinstance(name, str):
            continue
        tag_map[name] = {
            "id": str(uuid.uuid4()),
            "name": name,
            "color": None,
            "version": 1,
            "created_at": now,
            "updated_at": now,
        }
    return tag_map


def _normalize_parameters(params: Any) -> List[Dict[str, Any]]:
    normalized: List[Dict[str, Any]] = []
    for p in params or []:
        if not isinstance(p, dict):
            continue
        normalized.append(
            {
                "name": p.get("name") or "",
                "description": p.get("description"),
                "initial": p.get("initial"),
                "required": bool(p.get("required", False)),
            }
        )
    return normalized


def _merge_entries(raw_entries: List[Any]) -> List[Dict[str, Any]]:
    """Legacy file alternates between bare uuid rows and actual content rows."""
    merged: List[Dict[str, Any]] = []
    pending_uuid: str | None = None
    for item in raw_entries:
        if not isinstance(item, dict):
            continue
        if "uuid" in item and len(item.keys()) == 1:
            pending_uuid = item.get("uuid") or str(uuid.uuid4())
            continue
        if "title" in item:
            entry = dict(item)
            entry["uuid"] = entry.get("uuid") or pending_uuid or str(uuid.uuid4())
            merged.append(entry)
            pending_uuid = None
            continue
    return merged


def _build_snippets(raw: Dict[str, Any], tag_map: Dict[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    entries_raw = raw.get("entries") or []
    if not isinstance(entries_raw, list):
        entries_raw = []
    merged = _merge_entries(entries_raw)
    snippets: List[Dict[str, Any]] = []
    for item in merged:
        title = item.get("title")
        body = item.get("subtitle", "")
        if not title:
            continue
        category = item.get("category")
        if category and category not in tag_map:
            tag_map[category] = {
                "id": str(uuid.uuid4()),
                "name": category,
                "color": None,
                "version": 1,
                "created_at": now,
                "updated_at": now,
            }
        tag_id = tag_map.get(category, {}).get("id") if category else None
        tags_field = [category] if category else []
        version = item.get("version") or 1
        try:
            version_int = int(version)
        except Exception:
            version_int = 1
        snippets.append(
            {
                "id": item.get("uuid") or str(uuid.uuid4()),
                "title": title,
                "body": body,
                "tags": tags_field,
                "source": "legacy-yaml",
                "pinned": False,
                "parameters": _normalize_parameters(item.get("parameters")),
                "version": max(version_int, 1),
                "tag_id": tag_id,
                "created_at": now,
                "updated_at": now,
            }
        )
    return snippets


def _login(session: Any, api_base: str, email: str, password: str) -> None:
    url = f"{api_base.rstrip('/')}/auth/login"
    res = session.post(url, json={"email": email, "password": password})
    if res.status_code != 200:
        raise SystemExit(f"Login failed ({res.status_code}): {res.text}")
    data = res.json()
    token = data.get("access_token")
    if not token:
        raise SystemExit("Login response missing access_token")
    session.headers.update({"Authorization": f"Bearer {token}", "Content-Type": "application/json"})


def _push_payload(
    session: Any, api_base: str, path: str, payload_key: str, rows: List[Dict[str, Any]], chunk_size: int
) -> int:
    pushed = 0
    for chunk in _chunked(rows, chunk_size):
        url = f"{api_base.rstrip('/')}{path}"
        res = session.post(url, json={payload_key: chunk})
        if res.status_code not in (200, 201):
            raise SystemExit(f"Request failed for {path} ({res.status_code}): {res.text}")
        saved_ids: set[str] | None = None
        try:
            data = res.json()
            if isinstance(data, dict) and "saved" in data and isinstance(data["saved"], list):
                saved_ids = set()
                for item in data["saved"]:
                    if isinstance(item, dict):
                        saved_ids.add(str(item.get("id")))
        except Exception:
            data = None
        if saved_ids is not None:
            chunk_ids = set(str(item.get("id")) for item in chunk)
            missing = chunk_ids - saved_ids
            if missing:
                sample = ", ".join(list(missing)[:5])
                raise SystemExit(
                    f"Server saved {len(saved_ids)}/{len(chunk)} items for {path}. Missing ids sample: {sample}"
                )
        pushed += len(chunk)
    return pushed


def _fetch_all_tags(session: Any, api_base: str) -> List[Dict[str, Any]]:
    items: List[Dict[str, Any]] = []
    page = 1
    while True:
        url = f"{api_base.rstrip('/')}/tags?limit=100&page={page}"
        res = session.get(url)
        if res.status_code != 200:
            raise SystemExit(f"Fetch tags failed ({res.status_code}): {res.text}")
        try:
            page_data = res.json()
        except Exception as exc:  # pragma: no cover - runtime check only
            raise SystemExit(f"Unable to parse tags response: {res.text}") from exc
        if not isinstance(page_data, list) or not page_data:
            break
        items.extend(page_data)
        if len(page_data) < 100:
            break
        page += 1
    return items


def _fetch_all_snippets(session: Any, api_base: str) -> List[Dict[str, Any]]:
    all_items: List[Dict[str, Any]] = []
    page = 1
    while True:
        url = f"{api_base.rstrip('/')}/snippets?limit=100&page={page}"
        res = session.get(url)
        if res.status_code != 200:
            raise SystemExit(f"Fetch snippets failed ({res.status_code}): {res.text}")
        try:
            items = res.json()
        except Exception as exc:  # pragma: no cover - runtime check only
            raise SystemExit(f"Unable to parse snippets response: {res.text}") from exc
        if not isinstance(items, list) or not items:
            break
        all_items.extend(items)
        if len(items) < 100:
            break
        page += 1
    return all_items


def main() -> None:
    requests, yaml_mod = _require_modules()

    parser = argparse.ArgumentParser(description="Import legacy fclipboard.yaml into the new API.")
    parser.add_argument("--yaml", dest="yaml_path", default="fclipboard.yaml", help="Path to legacy fclipboard.yaml")
    parser.add_argument("--api", dest="api_base", default="https://fclipboard-api.lingmind.cn", help="API base URL")
    parser.add_argument("--email", required=True, help="Account email for the new service")
    parser.add_argument("--password", required=True, help="Account password for the new service")
    parser.add_argument("--chunk-size", type=int, default=200, help="Batch size for sync calls")
    parser.add_argument("--dry-run", action="store_true", help="Parse and show counts without calling the API")
    parser.add_argument("--show-password", action="store_true", help="Echo password to console for troubleshooting")
    parser.add_argument("--verify", action="store_true", help="Fetch back counts/ids after import to ensure completeness")
    args = parser.parse_args()

    yaml_path = Path(args.yaml_path)
    if not yaml_path.exists():
        raise SystemExit(f"YAML file not found: {yaml_path}")

    legacy = _load_legacy(yaml_path, yaml_mod)
    tags = _build_tags(legacy)
    snippets = _build_snippets(legacy, tags)

    print(f"Parsed {len(tags)} categories -> tags, {len(snippets)} snippets from {yaml_path}")
    if args.dry_run:
        print("Dry-run complete; nothing sent.")
        return

    if args.show_password:
        print(f"Logging in as {args.email} with password: {args.password}")
    else:
        print(f"Logging in as {args.email} (password hidden, length={len(args.password)})")

    session = requests.Session()
    _login(session, args.api_base, args.email, args.password)

    tags_payload = list(tags.values())
    tags_sent = _push_payload(session, args.api_base, "/tags/sync", "tags", tags_payload, args.chunk_size)
    snippets_sent = _push_payload(session, args.api_base, "/snippets/sync", "snippets", snippets, args.chunk_size)

    summary = {"tags_sent": tags_sent, "snippets_sent": snippets_sent}

    if args.verify:
        remote_tags = _fetch_all_tags(session, args.api_base)
        remote_snippets = _fetch_all_snippets(session, args.api_base)
        expected_tag_ids = {t["id"] for t in tags_payload}
        remote_tag_ids = {str(t.get("id")) for t in remote_tags}
        expected_snippet_ids = {str(s.get("id")) for s in snippets}
        remote_snippet_ids = {str(s.get("id")) for s in remote_snippets}
        summary.update(
            {
                "tags_remote": len(remote_tags),
                "snippets_remote": len(remote_snippets),
                "missing_tag_ids": list(expected_tag_ids - remote_tag_ids)[:5],
                "missing_snippet_ids": list(expected_snippet_ids - remote_snippet_ids)[:5],
            }
        )

    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
