#! /usr/bin/env sh
set -ev

mkdir .ebextensions
cp *.config .ebextensions/.

echo "Now move .ebextensions to the root of the directory that is zipped to be deployed to Elastic Beanstalk"