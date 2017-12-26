"""Initialize DB lambda function"""

import sys
import logging
import pymysql
import rds_config

#rds settings
rds_host = rds_config.db_host
name = rds_config.db_username
password = rds_config.db_password
db_name = rds_config.db_name


logger = logging.getLogger()
logger.setLevel(logging.INFO)

try:
    conn = pymysql.connect(rds_host, user=name, passwd=password, connect_timeout=5)
except Exception as e:
    logger.error("ERROR: Unexpected error: Could not connect to DB: %s.", str(e))
    sys.exit()

logger.info("SUCCESS: Connection to RDS mysql instance succeeded")
def handler(event, context):
    """
    Lambda handler
    """

    item_count = 0

    with conn.cursor() as cur:
        cur.execute("CREATE DATABASE IF NOT EXISTS {0}".format(db_name))
        cur.execute("USE {0}".format(db_name))
        cur.execute("CREATE TABLE IF NOT EXISTS notes ( id INT AUTO_INCREMENT NOT NULL, note VARCHAR(255) NOT NULL, PRIMARY KEY (id))")
        conn.commit()

    return "OK"
