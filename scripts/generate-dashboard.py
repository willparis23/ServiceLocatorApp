#!/usr/bin/env python3
"""
Parses an .xcresult bundle produced by xcodebuild and generates a simple
HTML dashboard summarizing the test run.

Usage:
    python3 generate-dashboard.py <path-to-xcresult> <output-dir>

The output directory will contain index.html and any supporting files.
Handles both legacy xcresulttool (Xcode <=15) and new command structure
(Xcode 16+), falling back gracefully if the bundle is missing.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def run_xcresulttool(xcresult_path: Path) -> dict:
    """Run xcresulttool and return parsed JSON. Tries new command first,
    falls back to legacy flags. Returns empty dict on total failure."""
    
    # Xcode 16+ uses: xcresulttool get test-results summary --path <bundle>
    attempts = [
        ["xcrun", "xcresulttool", "get", "test-results", "summary",
         "--path", str(xcresult_path)],
        # Legacy (Xcode <= 15)
        ["xcrun", "xcresulttool", "get", "--format", "json",
         "--path", str(xcresult_path)],
    ]
    
    for cmd in attempts:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                check=True,
                timeout=60,
            )
            return json.loads(result.stdout)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired, json.JSONDecodeError):
            continue
    
    return {}


def extract_summary(raw: dict) -> dict:
    """Normalize xcresulttool output into a common shape regardless of
    which command produced it."""
    
    summary = {
        "total": 0,
        "passed": 0,
        "failed": 0,
        "skipped": 0,
        "duration_seconds": 0.0,
        "tests": [],
    }
    
    if not raw:
        return summary
    
    # Xcode 16+ shape: top-level has passedTests/failedTests/skippedTests/expectedFailures
    if "passedTests" in raw or "failedTests" in raw:
        summary["passed"] = raw.get("passedTests", 0)
        summary["failed"] = raw.get("failedTests", 0)
        summary["skipped"] = raw.get("skippedTests", 0)
        summary["total"] = summary["passed"] + summary["failed"] + summary["skipped"]
        
        for failure in raw.get("testFailures", []):
            summary["tests"].append({
                "name": failure.get("testName", "<unknown>"),
                "target": failure.get("targetName", ""),
                "status": "failed",
                "message": failure.get("failureText", ""),
            })
        return summary
    
    # Legacy shape: metrics nested under metrics._values or similar
    metrics = raw.get("metrics", {})
    tests_ref = metrics.get("testsCount", {}).get("_value")
    failed_ref = metrics.get("testsFailedCount", {}).get("_value")
    if tests_ref is not None:
        total = int(tests_ref)
        failed = int(failed_ref or 0)
        summary["total"] = total
        summary["failed"] = failed
        summary["passed"] = total - failed
    
    return summary


def render_html(summary: dict, run_info: dict) -> str:
    pass_rate = (
        (summary["passed"] / summary["total"] * 100)
        if summary["total"] > 0 else 0.0
    )
    
    status_class = "pass" if summary["failed"] == 0 and summary["total"] > 0 else "fail"
    status_text = "PASSING" if status_class == "pass" else "FAILING"
    if summary["total"] == 0:
        status_class = "unknown"
        status_text = "NO RESULTS"
    
    failed_rows = ""
    for test in summary["tests"]:
        message = (test.get("message") or "").replace("<", "&lt;").replace(">", "&gt;")
        failed_rows += f"""
        <tr>
            <td>{test.get('name', '')}</td>
            <td>{test.get('target', '')}</td>
            <td class="msg">{message}</td>
        </tr>"""
    
    failures_section = ""
    if summary["failed"] > 0 and failed_rows:
        failures_section = f"""
        <section class="failures">
            <h2>Failures</h2>
            <table>
                <thead>
                    <tr><th>Test</th><th>Target</th><th>Message</th></tr>
                </thead>
                <tbody>{failed_rows}
                </tbody>
            </table>
        </section>"""
    
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ServiceLocator Test Results</title>
    <style>
        :root {{
            --bg: #f5f5f7;
            --card: #ffffff;
            --text: #1d1d1f;
            --muted: #86868b;
            --pass: #30b460;
            --fail: #e03131;
            --unknown: #868e96;
            --border: #e5e5ea;
        }}
        * {{ box-sizing: border-box; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: var(--bg);
            color: var(--text);
            margin: 0;
            padding: 2rem 1rem;
            line-height: 1.5;
        }}
        .container {{ max-width: 900px; margin: 0 auto; }}
        header {{ margin-bottom: 2rem; }}
        h1 {{ margin: 0 0 0.25rem 0; font-size: 1.75rem; }}
        .subtitle {{ color: var(--muted); font-size: 0.95rem; }}
        .status-banner {{
            display: inline-block;
            padding: 0.5rem 1rem;
            border-radius: 8px;
            font-weight: 600;
            font-size: 0.9rem;
            letter-spacing: 0.05em;
            margin-top: 1rem;
        }}
        .status-banner.pass {{ background: var(--pass); color: white; }}
        .status-banner.fail {{ background: var(--fail); color: white; }}
        .status-banner.unknown {{ background: var(--unknown); color: white; }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }}
        .card {{
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1.25rem;
        }}
        .card .label {{
            font-size: 0.8rem;
            color: var(--muted);
            text-transform: uppercase;
            letter-spacing: 0.08em;
        }}
        .card .value {{
            font-size: 2rem;
            font-weight: 600;
            margin-top: 0.25rem;
        }}
        .card.pass .value {{ color: var(--pass); }}
        .card.fail .value {{ color: var(--fail); }}
        .pass-rate-bar {{
            height: 8px;
            background: var(--border);
            border-radius: 4px;
            overflow: hidden;
            margin-top: 0.75rem;
        }}
        .pass-rate-bar .fill {{
            height: 100%;
            background: var(--pass);
            transition: width 0.3s ease;
        }}
        section {{ margin-top: 2rem; }}
        section h2 {{
            font-size: 1.1rem;
            margin: 0 0 1rem 0;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid var(--border);
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 8px;
            overflow: hidden;
            font-size: 0.9rem;
        }}
        th, td {{
            padding: 0.75rem 1rem;
            text-align: left;
            border-bottom: 1px solid var(--border);
            vertical-align: top;
        }}
        tr:last-child td {{ border-bottom: none; }}
        th {{
            background: var(--bg);
            font-weight: 600;
            font-size: 0.8rem;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            color: var(--muted);
        }}
        td.msg {{
            font-family: "SF Mono", Monaco, monospace;
            font-size: 0.8rem;
            color: var(--fail);
        }}
        .meta {{
            background: var(--card);
            border: 1px solid var(--border);
            border-radius: 8px;
            padding: 1rem 1.25rem;
            font-size: 0.85rem;
            color: var(--muted);
        }}
        .meta dl {{ margin: 0; display: grid; grid-template-columns: auto 1fr; gap: 0.25rem 1rem; }}
        .meta dt {{ font-weight: 500; color: var(--text); }}
        .meta dd {{ margin: 0; font-family: "SF Mono", Monaco, monospace; }}
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>ServiceLocator Test Results</h1>
            <div class="subtitle">Generated {run_info['generated_at']}</div>
            <div class="status-banner {status_class}">{status_text}</div>
        </header>
        
        <div class="grid">
            <div class="card">
                <div class="label">Total</div>
                <div class="value">{summary['total']}</div>
            </div>
            <div class="card pass">
                <div class="label">Passed</div>
                <div class="value">{summary['passed']}</div>
            </div>
            <div class="card fail">
                <div class="label">Failed</div>
                <div class="value">{summary['failed']}</div>
            </div>
            <div class="card">
                <div class="label">Skipped</div>
                <div class="value">{summary['skipped']}</div>
            </div>
        </div>
        
        <section>
            <h2>Pass Rate</h2>
            <div class="card">
                <div style="display: flex; justify-content: space-between; align-items: baseline;">
                    <span style="font-size: 2rem; font-weight: 600;">{pass_rate:.1f}%</span>
                    <span style="color: var(--muted); font-size: 0.9rem;">
                        {summary['passed']} of {summary['total']} passed
                    </span>
                </div>
                <div class="pass-rate-bar">
                    <div class="fill" style="width: {pass_rate}%;"></div>
                </div>
            </div>
        </section>
        {failures_section}
        <section>
            <h2>Run Information</h2>
            <div class="meta">
                <dl>
                    <dt>Commit</dt><dd>{run_info.get('commit', 'unknown')}</dd>
                    <dt>Branch</dt><dd>{run_info.get('branch', 'unknown')}</dd>
                    <dt>Run number</dt><dd>{run_info.get('run_number', 'unknown')}</dd>
                    <dt>Triggered by</dt><dd>{run_info.get('actor', 'unknown')}</dd>
                </dl>
            </div>
        </section>
    </div>
</body>
</html>
"""


def gather_run_info() -> dict:
    return {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S %Z").strip(),
        "commit": (os.environ.get("GITHUB_SHA", "") or "local")[:8],
        "branch": os.environ.get("GITHUB_REF_NAME", "local"),
        "run_number": os.environ.get("GITHUB_RUN_NUMBER", "0"),
        "actor": os.environ.get("GITHUB_ACTOR", os.environ.get("USER", "unknown")),
    }


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <xcresult-path> <output-dir>", file=sys.stderr)
        sys.exit(2)
    
    xcresult_path = Path(sys.argv[1])
    output_dir = Path(sys.argv[2])
    output_dir.mkdir(parents=True, exist_ok=True)
    
    if xcresult_path.exists():
        raw = run_xcresulttool(xcresult_path)
        summary = extract_summary(raw)
    else:
        print(f"Warning: {xcresult_path} does not exist. Generating placeholder dashboard.", file=sys.stderr)
        summary = {
            "total": 0, "passed": 0, "failed": 0, "skipped": 0,
            "duration_seconds": 0, "tests": [],
        }
    
    run_info = gather_run_info()
    html = render_html(summary, run_info)
    
    output_file = output_dir / "index.html"
    output_file.write_text(html, encoding="utf-8")
    
    # Also write a JSON for anyone who wants to consume the data
    summary_with_info = {**summary, "run_info": run_info}
    (output_dir / "summary.json").write_text(
        json.dumps(summary_with_info, indent=2), encoding="utf-8"
    )
    
    print(f"Dashboard written to {output_file}")
    print(f"Summary: {summary['passed']}/{summary['total']} passed, {summary['failed']} failed")


if __name__ == "__main__":
    main()
