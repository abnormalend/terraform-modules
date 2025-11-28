import json
import os

def handler(event, context):
    """Minimal test handler that echoes input and env."""
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({
            "ok": True,
            "event": event,
            "env": {"EXAMPLE_VAR": os.getenv("EXAMPLE_VAR", "")}
        })
    }
