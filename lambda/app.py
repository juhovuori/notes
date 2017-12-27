"""Notes app lambda handlers"""

import logging
import sys
import errors
import utils

logger = utils.logger()
conn = utils.conn()

def list_notes(_event, _context):
    """
    List notes
    """

    logger.info("here")
    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes LIMIT 20")
        conn.commit()
        notes = [row for row in cur]

    logger.info("fetched %d rows", len(notes))
    return notes

def fetch_note(event, _context):
    """
    Fetch single note
    """

    note_id = event["id"]
    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes WHERE id = %s", (note_id, ))
        conn.commit()
        for row in cur:
            return row
    raise errors.NotFound(id)

def add_note(event, _context):
    """
    Add a note
    """

    if "text" not in event:
        raise errors.InvalidRequest("Body must contain a \"text\" attribute")
    text = event["text"]

    with conn.cursor() as cur:
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (text,))
        cur.execute("SELECT id, note FROM notes WHERE id = %s", (cur.lastrowid,))
        conn.commit()
        for row in cur:
            return row
    return None

def cli(args):
    """CLI frontend"""
    ctx = {}
    evt = {}
    cmd = args[0]
    logger.addHandler(logging.StreamHandler())
    if cmd == "list":
        print(list_notes(evt, ctx))
    elif cmd == "get":
        evt["id"] = args[1]
        print(fetch_note(evt, ctx))
    elif cmd == "add":
        evt["text"] = args[1]
        print(add_note(evt, ctx))
    else:
        print("usage!")

if __name__ == "__main__":
    cli(sys.argv[1:])
