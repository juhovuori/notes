"""Initialize DB lambda function"""

import utils
import rds_config

conn = utils.conn(None)

def handler(event, context):
    """
    Lambda handler
    """

    with conn.cursor() as cur:
        cur.execute("CREATE DATABASE IF NOT EXISTS {0}".format(rds_config.db_name))
        cur.execute("USE {0}".format(rds_config.db_name))
        cur.execute("CREATE TABLE IF NOT EXISTS notes ( id INT AUTO_INCREMENT NOT NULL, note VARCHAR(255) NOT NULL, PRIMARY KEY (id))")
        conn.commit()

    return "OK"
