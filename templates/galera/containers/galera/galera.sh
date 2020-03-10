#!/bin/bash

if echo $* | grep -v -e '--skip-networking' | grep -v -e '--help'; then

  export IP_ADDRESS=`getent hosts | grep $HOSTNAME | awk '{print $1}'`
  SERVICES_NAME=`giddyup ip stringify | tr "," "\n"`

  echo "My IP Adrress"
  echo $IP_ADDRESS

  echo "Cluster peers:"
  echo $SERVICES_NAME

  # Check we can see enough peers to form a Primary Component
  if [ `giddyup ip stringify | awk -F"," '{print NF}'` -lt $(((${CLUSTER_NODES}+1)/2)) ]; then
    echo "Can't see enough peers to form a cluster; restarting."
    exit 1
  fi

  CLUSTER_MEMBERS=$(echo "${SERVICES_NAME}" | grep -v $IP_ADDRESS | awk '{print $1}')

  echo "Cluster members:"
  echo $CLUSTER_MEMBERS

  # If we're the first node then bootstrap the cluster
  FIRST_IP_ADDRESS=$(echo "${SERVICES_NAME}" | sort -V | head -n 1 | awk '{print $1}')
  echo "First IP Address"
  echo $FIRST_IP_ADDRESS

    if [ $FIRST_IP_ADDRESS = $IP_ADDRESS ]; then
      echo "Looks like we're the first member. Testing for an established cluster between other nodes..."
    # Check to see if the other nodes have an established cluster
    for MEMBER in $CLUSTER_MEMBERS
    do
      echo "Testing $MEMBER..."
      if echo "SHOW STATUS LIKE 'wsrep_local_state_comment';" | mysql -u root -p$MYSQL_ROOT_PASSWORD -h $MEMBER | grep "Synced"; then
        # Connect to existing cluster
        echo "Success! 😁"
        export CLUSTER_ADDRESS="gcomm://$MEMBER?pc.wait_prim=yes"
        break
      else
        echo "Failed 😫"
      fi
    done
    # Can't connect to any other hosts; we need to bootstrap
    if [ -z $CLUSTER_ADDRESS ]; then
      echo "** No cluster found; bootstrapping on this node **"
      export CLUSTER_ADDRESS="gcomm://"
    fi
    fi

    # Join existing cluster
    if [ -z $CLUSTER_ADDRESS ]; then
    # Fetch IPs of service members
    CLUSTER_MEMBERS=`echo $CLUSTER_MEMBERS | tr ' ' ','`
    export CLUSTER_ADDRESS="gcomm://$CLUSTER_MEMBERS?pc.wait_prim=yes"
    export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
    # Prevent entrypoint trying to (re)create the users
    unset MYSQL_USER
    export MYSQL_ROOT_HOST="localhost"
    fi

    echo "Cluster address is $CLUSTER_ADDRESS"
    
  mv /etc/mysql/conf.d/galera.cnf.template /etc/mysql/conf.d/galera.cnf

  echo "`env`" | while IFS='=' read -r NAME VALUE
  do
    sed -i "s#{{${NAME}}}#${VALUE}#g" /etc/mysql/conf.d/galera.cnf
  done

  chmod 660 /etc/mysql/conf.d/galera.cnf

  echo "Running config:"
  echo "==============="
  cat /etc/mysql/conf.d/galera.cnf
  echo "==============="

fi

exec /usr/sbin/mysqld "$@"