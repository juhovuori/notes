""" Helper functions for notes """

import logging
import sys
import pymysql
import rds_config

def logger():
    "Returns a logger"
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    return logger

def conn(db = rds_config.db_name):
    "Returns a DB connection"
    log = logger()
    rds_host = rds_config.db_host
    name = rds_config.db_username
    password = rds_config.db_password
    try:
        conn = pymysql.connect(rds_host, user=name, passwd=password, database=db, connect_timeout=5)
    except pymysql.Error as exc:
        log.error("ERROR: Unexpected error: Could not connect to DB: %s.", str(exc))
        sys.exit()

    log.info("SUCCESS: Connection to RDS mysql instance succeeded")
    return conn
