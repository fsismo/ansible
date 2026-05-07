#!/bin/bash
mongo -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin <<EOF
db = db.getSiblingDB("$MONGO_DBNAME");
db.createUser({
  user: "$MONGO_USER",
  pwd: "$MONGO_PASS",
  roles: [{ role: "dbOwner", db: "$MONGO_DBNAME" }]
});
EOF
