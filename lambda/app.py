"""Notes app lambda handlers"""

import json
import utils

logger = utils.logger()
conn = utils.conn()

def list_notes(event, context):
    """
    List notes
    """

    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes LIMIT 20")
        notes = [row for row in cur]

    return json.dumps(notes)

def fetch_note(event, context):
    """
    Fetch single note
    """

    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes WHERE id = 123")
        for row in cur:
            return json.dumps(row)
    return None

def add_note(event, context):
    """
    Add a note
    """

    text = "Moex"
    with conn.cursor() as cur:
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (text,))
        conn.commit()
        cur.execute("SELECT id, note FROM notes WHERE id = %s", (cur.lastrowid,))
        for row in cur:
            return json.dumps(row)
    return None

if __name__ == "__main__":
    notes = list_notes({}, {})
    print(notes)