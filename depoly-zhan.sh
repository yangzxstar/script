#!/bin/sh

echo "Best wishes for you *_*"

`:>time.log`

echo "开始时间" 
`echo date`
MAVEN_HOME=/data/web/maven
PATH=$PATH":/data/web/jdk/bin/"
PATH=${PATH}:${MAVEN_HOME}/bin

export LANG="en_US.UTF-8"
export LC_ALL="en_US.utf8"
export LC_LANG="en_US.utf8"

PROJECT_PATH="/data/web/zhan/renren-zhan-web-base"
SVN_PATH="http://svn.d.xiaonei.com/sns/xiaonei/renren-zhan-web-base/trunk"
STATIC_PATH="/data/web/zhan/static"

WAR="renren-zhan-web-base-1.0-SNAPSHOT.war"
WAR_DIR="renren-zhan-web-base-1.0-SNAPSHOT"

STATIC_WEB="/data/web/static"
PROJECT_WEB="/data/web/zhan/www_base"

echo "step 1. update maven project.."
if [ ! -d $PROJECT_PATH/.svn/ ] ;then
        svn co $SVN_PATH $PROJECT_PATH
else
        svn up $PROJECT_PATH
fi
echo "step 2. maven project"
p="`pwd`"
cd $PROJECT_PATH
#mvn -f pom.xml -o clean compile war:exploded 
mvn -f pom.xml -U clean -Dmaven.test.skip=true compile war:exploded
cd -
#if [ ! -f $PROJECT_PATH/target/$WAR ]; then echo "Oops, an ERROR !!! Send the file \"time.log\" to [yao.hu@opi-corp.com]"; exit ; fi

echo "step 3. update static..."
if [ ! -d $STATIC_PATH/.svn/ ] ;then
        svn co http://svn.d.xiaonei.com/frontend/xn.static $STATIC_PATH
else
        svn up $STATIC_PATH
fi

echo "step 4. replace static compress js css html..." 
test -d $STATIC_WEB || mkdir -p $STATIC_WEB
#thanks for liuyan
java -cp `pwd`/xiaonei-split-version.jar com/xiaonei/deploy/tools/Worker $STATIC_PATH $STATIC_WEB $PROJECT_PATH/target/$WAR_DIR/
echo "step 5. cp maven project"
rsync -rtzvl --delete $PROJECT_PATH/target/$WAR_DIR/ $PROJECT_WEB

echo "So fast,so NB!!!"
echo "结束时间" 
`echo date`

rsync -rtzvlC /data/web/zhan/static/smallsite /data/web/static/

sh restart_base.sh
