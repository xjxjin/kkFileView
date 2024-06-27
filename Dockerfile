# 指定基础镜像和构建平台
FROM --platform=$BUILDPLATFORM ubuntu:20.04 AS base

# 维护者信息
LABEL maintainer="xjxjin <1702@163.com>"

# 内置一些常用的中文字体，避免普遍性乱码
# COPY fonts/* /usr/share/fonts/chinese/

# 更改软件源为阿里云镜像
RUN sed -i 's/http:\/\/archive.ubuntu.com/https:\/\/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    sed -i 's/# deb/deb/g' /etc/apt/sources.list

# 安装依赖和Java JDK
#RUN apt-get clean && apt-get update && \
#    apt-get install -y --no-install-recommends \
#        ca-certificates \
#        locales \
#        language-pack-zh-hans \
#        fontconfig \
#        ttf-mscorefonts-installer \
#        ttf-wqy-microhei \
#        ttf-wqy-zenhei \
#        xfonts-wqy \
#        wget && \
#    localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 && \
#    locale-gen zh_CN.UTF-8 && \
#    export DEBIAN_FRONTEND=noninteractive && \
#    apt-get install -y tzdata && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    # cd /tmp && \
    # wget https://kkview.cn/resource/server-jre-8u251-linux-x64.tar.gz && \
    # tar -zxf /tmp/server-jre-8u251-linux-x64.tar.gz && mv /tmp/jdk1.8.0_251 /usr/local/ && \
#    rm -rf /var/lib/apt/lists/*


RUN apt-get clean && apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        locales \
        fontconfig \
        wget && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        language-pack-zh-hans \
        ttf-mscorefonts-installer \
        ttf-wqy-microhei \
        ttf-wqy-zenhei \
        xfonts-wqy && \
    localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 && \
    locale-gen zh_CN.UTF-8 && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    cd /tmp && \
    wget https://kkview.cn/resource/server-jre-8u251-linux-x64.tar.gz && \
    tar -zxf /tmp/server-jre-8u251-linux-x64.tar.gz && \
    mv /tmp/jdk1.8.0_251 /usr/local/ && \
    apt-get purge -y --auto-remove && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 安装LibreOffice
RUN apt-get update && \
    apt-get install -y libxrender1 libxinerama1 libxt6 libxext-dev libfreetype6-dev libcairo2 libcups2 libx11-xcb1 libnss3 && \
    wget https://downloadarchive.documentfoundation.org/libreoffice/old/7.5.3.2/deb/x86_64/LibreOffice_7.5.3.2_Linux_x86-64_deb.tar.gz && \
    tar -zxf /tmp/LibreOffice_7.5.3.2_Linux_x86-64_deb.tar.gz && cd /tmp/LibreOffice_7.5.3.2_Linux_x86-64_deb/DEBS && \
    dpkg -i *.deb && \
    rm -rf /tmp/* /var/lib/apt/lists/*

# 更新字体缓存
RUN cd /usr/share/fonts/chinese && \
    mkfontscale && \
    mkfontdir && \
    fc-cache -fv

# 设置环境变量
ENV JAVA_HOME /usr/local/jdk1.8.0_251
ENV CLASSPATH "$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar"
ENV PATH "$PATH:$JAVA_HOME/bin"
ENV LANG zh_CN.UTF-8
ENV LC_ALL zh_CN.UTF-8

# 应用程序构建阶段，复制应用程序文件并设置ENTRYPOINT
# 应用程序构建阶段，从上下文复制Maven构建的artifacts
FROM base AS app
WORKDIR /opt
COPY --from=0 /.docker-artifacts/kkFileView-*.tar.gz /opt/
RUN tar -xzf /opt/kkFileView-*.tar.gz -C /opt && \
    rm /opt/kkFileView-*.tar.gz

# 设置环境变量和ENTRYPOINT
ENV KKFILEVIEW_BIN_FOLDER /opt/kkFileView-4.4.0-beta/bin
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-Dspring.config.location=/opt/kkFileView-4.4.0-beta/config/application.properties", "-jar", "$KKFILEVIEW_BIN_FOLDER/kkFileView-4.4.0-beta.jar"]
