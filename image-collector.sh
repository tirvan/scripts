#!/bin/bash

RUNNING_POD=pod-running
INIT_CONTAINER_POD=pod-init-running
COMPLETED_POD=pod-completed

echo "-------- RUNNING POD --------"
echo -n "Collecting running pod for all namespace ..."
oc get pods -A | grep Running | awk '{print "oc get pods " $2 " -n " $1 " -o jsonpath=\"{.spec.containers[*].image}{'\''\\n'\''}\" | tr '\'' '\'' '\''\\n'\''" }' > ${RUNNING_POD}.in
echo "... total $(wc -l < ${RUNNING_POD}.in)"

> ${RUNNING_POD}.out
echo -n "Extracting running pod images ..."

while IFS= read -r line;
do
  sh -c "$line" >> ${RUNNING_POD}.out
  echo -n "."
done < ${RUNNING_POD}.in

echo " total $(wc -l < ${RUNNING_POD}.out)"

echo -n "Sorting all the images ..."
cat ${RUNNING_POD}.out | sort -u > ${RUNNING_POD}.final
echo " total $(wc -l < ${RUNNING_POD}.final)"

echo
echo "-------- INIT CONTAINER IMAGES  --------"
echo -n "Collecting running pod for all namespace ..."
oc get pods -A | grep Running | awk '{print "oc get pods " $2 " -n " $1 " -o jsonpath=\"{.spec.initContainers[*].image}{'\''\\n'\''}\" | tr '\'' '\'' '\''\\n'\''" }' > ${INIT_CONTAINER_POD}.in
echo "... total $(wc -l < ${INIT_CONTAINER_POD}.in)"

> ${INIT_CONTAINER_POD}.out
echo -n "Extracting running pod initContainer images ..."

while IFS= read -r line;
do
  sh -c "$line" >> ${INIT_CONTAINER_POD}.out
  echo -n "."
done < ${INIT_CONTAINER_POD}.in

echo " total $(wc -l < ${INIT_CONTAINER_POD}.out)"

echo -n "Sorting all the images ..."
cat ${INIT_CONTAINER_POD}.out | sort -u > ${INIT_CONTAINER_POD}.tmp
echo " total $(wc -l < ${INIT_CONTAINER_POD}.tmp)"

> ${INIT_CONTAINER_POD}.final
echo -n "Checking init container images ..."
while IFS= read -r line;
do
  grep "$line" ${RUNNING_POD}.final 2>&1 > /dev/null
  if [[ $? != 0 ]]
  then
    echo "$line" >> ${INIT_CONTAINER_POD}.final
    echo -n "."
  fi
done < ${INIT_CONTAINER_POD}.tmp
echo " total $(wc -l < ${INIT_CONTAINER_POD}.final)"

echo
echo "-------- COMPLETED JOB IMAGES --------"

echo -n "Collecting completed pod for all namespace ..."
oc get pods -A | grep Completed| awk '{print "oc get pods " $2 " -n " $1 " -o jsonpath=\"{.spec.containers[*].image}{'\''\\n'\''}\" | tr '\'' '\'' '\''\\n'\''" }' > ${COMPLETED_POD}.in
echo "... total $(wc -l < ${COMPLETED_POD}.in)"

> ${COMPLETED_POD}.out
echo -n "Extracting completedpod images ..."

while IFS= read -r line;
do
  sh -c "$line" >> ${COMPLETED_POD}.out
  echo -n "."
done < ${COMPLETED_POD}.in

echo " total $(wc -l < ${COMPLETED_POD}.out)"

echo -n "Sorting all the images ..."
cat ${COMPLETED_POD}.out | sort -u > ${COMPLETED_POD}.tmp
echo " total $(wc -l < ${COMPLETED_POD}.tmp)"

> ${COMPLETED_POD}.final
echo -n "Checking completed container images ..."
while IFS= read -r line;
do
  grep "$line" ${RUNNING_POD}.final 2>&1 > /dev/null
  if [[ $? != 0 ]]
  then
    echo "$line" >> ${COMPLETED_POD}.final
    echo -n "."
  fi
done < ${COMPLETED_POD}.tmp
echo " total $(wc -l < ${COMPLETED_POD}.final)"

echo -n "Cleaning up ..."
find . -regex './pod-.*\(in\|out\|tmp\)' 2> /dev/null -delete
echo " done!"

echo "Please review the pod-*.final file for the images"
