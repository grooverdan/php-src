#!/bin/bash
set -ex

# Test extra stuff if we touch a set of files


TEST_M_CONTAINERS=( mysql:5.6 mysql:5.7 mysql:8.0 mariadb:10.5 )
MYSQL_VERSIONS="5.6.49 5.7.31"
MARIADB_VERSIONS=3.1.9

M_VERSIONS=()

download_mysqls()
{
        for m in $MYSQL_VERSIONS
        do
                v=mysql-${m}-linux-glibc2.12-x86_64
                M_VERSIONS+=( $v )
                wget https://cdn.mysql.com//Downloads/MySQL-${m%.*}/${v}.tar.gz -O - \
                        | tar -zxf - -C $HOME
        done
        m=8.0.21
        v=mysql-${m}-linux-glibc2.12-x86_64
        M_VERSIONS+=( $v )
        wget https://cdn.mysql.com//Downloads/MySQL-${m%.*}/${v}.tar.xz -O - \
                | tar -Jxf - -C $HOME
        for m in $MARIADB_VERSIONS
        do
                v=mariadb-connector-c-${m}-ubuntu-${TRAVIS_DIST}-${TRAVIS_CPU_ARCH}
                M_VERSIONS+=( $v )
                wget https://downloads.mariadb.com/Connectors/c/connector-c-${m}/${v}.tar.gz -O - \
                        | tar -zxf - -C $HOME
        done
}


#for file in $(git diff --name-only $TRAVIS_COMMIT_RANGE)
#do
#        case "$file" in
#        ext/mysqli/*)
                mysqli=1
                mysqlpdo=1 
#                ;;
#        ext/pdo_mysql/*)
#                mysqlpdo=1 
#                ;;
#        esac
#done

if [ -n $mysqli ] || [ -n $mysqlpdo ]
then
        #service mysql stop
        download_mysqls
	for m in ${M_VERSIONS[@]}
        do
                mkdir build-php-$m
                pushd build-php-$m
                export MYSQL_DIR=$HOME/$m
                ${TRAVIS_BUILD_DIR}/travis/compile.sh
                export TEST_PHP_EXECUTABLE=$PWD/sapi/cli/php

	        #for c in ${TEST_M_CONTAINERS[@]}
                #do
		#	docker run -it --rm \
                #               -e  MYSQL_USER=$MYSQL_TEST_USER -e MYSQL_DATABSE=test \
                #               -e  MYSQL_RANDOM_ROOT_PASSWORD=1 \
                #                --name ${c/:/_} --expose 3306  $c
                #        for i in {60..0}
                #        do
                #               if ! mysql --protocol=tcp -u${MYSQL_TEST_USER} -h127.0.0.1 -e 'select version()'; then
                #                        break
                #               fi
                #               echo 'data server still not active'
                #               sleep 1
                #        done
                        if [ -n $mysqli ]; then
                               ./sapi/cli/php ${TRAVIS_BUILD_DIR}/run-tests.php \
					-P -d extension=`pwd`/modules/zend_test.so \
					$(if [ $ENABLE_DEBUG == 0 ]; then echo "-d opcache.enable_cli=1 -d zend_extension=`pwd`/modules/opcache.so"; fi) \
					-g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --show-slow 1000 --set-timeout 120 \
					 ${TRAVIS_BUILD_DIR}/ext/mysqli/tests/*phpt
                        fi
                        if [ -n $mysqlpdo ]; then
                               ./sapi/cli/php ${TRAVIS_BUILD_DIR}/run-tests.php \
					-P -d extension=`pwd`/modules/zend_test.so \
					$(if [ $ENABLE_DEBUG == 0 ]; then echo "-d opcache.enable_cli=1 -d zend_extension=`pwd`/modules/opcache.so"; fi) \
					-g "FAIL,XFAIL,BORK,WARN,LEAK,SKIP" --offline --show-diff --show-slow 1000 --set-timeout 120 \
					 ${TRAVIS_BUILD_DIR}/ext/pdo_mysql/tests/*phpt
                        fi
                #        docker kill ${c/:/_} 
                #        sleep 3
                #done
                popd
        done
fi
