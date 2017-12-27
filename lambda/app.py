"""Notes app lambda handlers"""

import logging
import sys
import errors
import utils

logger = utils.logger()
conn = utils.conn()

def row_to_note(row):
    """
    Convert note DB row into dict presentation
    """
    return {
        "id": row[0],
        "text": row[1]
    }

def _input_string(event, name):
    """
    Return string attribute or an app error
    """
    if name not in event:
        raise errors.InvalidRequest("Event must contain a \"{0}\" attribute".format(name))
    if not isinstance(event[name], str):
        raise errors.InvalidRequest("Event attribute \"{0}\" must be a string".format(name))
    return event[name]

def fetch_note_by_id(note_id):
    """
    Return a single note
    """
    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes WHERE id = %s", (note_id, ))
        conn.commit()
        for row in cur:
            return row_to_note(row)
    raise errors.NotFound(note_id)

def list_notes(_event, _context):
    """
    List notes
    """
    logger.info("here")
    with conn.cursor() as cur:
        cur.execute("SELECT id, note FROM notes ORDER BY id DESC LIMIT 10")
        conn.commit()
        notes = [row_to_note(row) for row in cur]

    logger.info("fetched %d rows", len(notes))
    return notes

def fetch_note(event, _context):
    """
    Fetch single note
    """
    note_id = _input_string(event, "id")
    return fetch_note_by_id(note_id)

def add_note(event, _context):
    """
    Add a note
    """

    text = _input_string(event, "text")
    with conn.cursor() as cur:
        cur.execute("INSERT INTO notes (note) VALUES (%s)", (text,))
        conn.commit()
        return fetch_note_by_id(cur.lastrowid)

def edit_note(event, _context):
    """
    Edit a note
    """

    note_id = _input_string(event,"id")
    text = _input_string(event, "text")

    with conn.cursor() as cur:
        cur.execute("UPDATE notes SET note=%s WHERE id=%s", (text, note_id))
        conn.commit()
        return fetch_note_by_id(note_id)

def delete_note(event, _context):
    """
    Delete a note
    """

    note_id = _input_string(event,"id")
    with conn.cursor() as cur:
        cur.execute("DELETE FROM notes WHERE id = %s", (note_id, ))
        conn.commit()
        if cur.rowcount == 0:
            raise errors.NotFound(note_id)
    return "OK"

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
    elif cmd == "delete":
        evt["id"] = args[1]
        print(delete_note(evt, ctx))
    elif cmd == "add":
        evt["text"] = args[1]
        print(add_note(evt, ctx))
    elif cmd == "edit":
        evt["id"] = args[1]
        evt["text"] = args[2]
        print(edit_note(evt, ctx))
    else:
        print("usage!")

if __name__ == "__main__":
    cli(sys.argv[1:])
